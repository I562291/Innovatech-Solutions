from flask import Flask, render_template, request
from datetime import datetime
import boto3
import json
import requests
import ipaddress


app = Flask(__name__)


alerts_list = []

@app.route("/alerts", methods=["GET", "POST"])
def event_listener():
    if request.method == "POST":
        data = request.get_json()
        actions = rule_engine(data)
        print(f"SOAR DEBUG: title={data.get('title')}, actions={actions}, alerts={data.get('alerts')}", flush=True)
        executor(actions, data)

        alerts_list.append({
            "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "data": data,
            "actions": actions
        })

        return "OK", 200

    return render_template("alerts.html", alerts=alerts_list)

def rule_engine(data):
    if "possible bruteforce" in data.get("title", "").lower():
        return ["discord", "block_ip"]
    else:
        return []
    
def executor(actions, data):
    if "discord" in actions:
        try:
            send_discord(data)
        except Exception as e:
            print(f"Error sending Discord message: {e}")
            
    if "block_ip" in actions:
        try:
            block_ip(data)
        except Exception as e:
            print(f"Error blocking IP: {e}")

def send_discord(data):
    ssm = boto3.client("ssm", region_name="eu-central-1")
    parameter = ssm.get_parameter(
        Name="/innovatech/discord/webhook",
        WithDecryption=True
    )
    webhook_url = parameter["Parameter"]["Value"].strip() # strip to remove any whitespace in the webhook URL (without it the request failed)

    response = requests.post(
        webhook_url,
        json={"content": f"Possible brute-force alert:\n{data.get('title', 'Unknown alert')}"},
        timeout=10
    )
    response.raise_for_status()
    
def block_ip(data): # on premise ip block by adding the source ip to the pfsense alias / block list with the rule
    ip = data["alerts"][0]["labels"]["ip"] # get the source ip from the alert data

    # only attackers from the test subnet
    if ipaddress.ip_address(ip) not in ipaddress.ip_network("192.168.2.0/24"): # only block attackers from the test subnet
        return

    ssm = boto3.client("ssm", region_name="eu-central-1") # get the pfsense api key from the parameter store
    api_key = ssm.get_parameter(
        Name="/innovatech/pfsense/api-key",
        WithDecryption=True
    )["Parameter"]["Value"].strip() # strip omdat we anders een foutmelding krijgen bij de request (whitespace in the api key)

    url = "http://192.168.1.1/api/v2/firewall"
    headers = {"X-API-Key": api_key}

    response = requests.get(f"{url}/aliases", headers=headers, timeout=10)
    response.raise_for_status()

    alias = next( # get the alias and put it in the variable alias
        a for a in response.json()["data"]
        if a["name"] == "Soar_blocked_IP_addresses"
    )

    addresses = alias.get("address", []) # get the addresses from the alias and put them in the variable addresses
    if ip in addresses: # if the ip is already in the alias, return and do nothing
        return

    response = requests.patch( # update the alias with the new ip address
        f"{url}/alias",
        headers=headers,
        json={"id": alias["id"], "address": addresses + [ip], "apply": True},
        timeout=15
    )
    response.raise_for_status()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)