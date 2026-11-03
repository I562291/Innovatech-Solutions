from flask import Flask, render_template, request
from datetime import datetime
import boto3
import json
import requests


app = Flask(__name__)


alerts_list = []

@app.route("/alerts", methods=["GET", "POST"])
def event_listener():
    if request.method == "POST":
        data = request.get_json()
        actions = rule_engine(data)
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
        send_discord(data)
    if "block_ip" in actions:
        block_ip(data)

def send_discord(data):
    ssm = boto3.client("ssm", region_name="eu-central-1")
    parameter = ssm.get_parameter(
        Name="/innovatech/discord/webhook",
        WithDecryption=True
    )
    webhook_url = parameter["Parameter"]["Value"].strip() # strip to remove any whitespace in the webhook URL (without it the request failed)

    response = requests.post(
        webhook_url,
        json={"content": f"Possible brute-force alert:\n{json.dumps(data)}"},
        timeout=10
    )
    response.raise_for_status()
    
def block_ip(data):
    print("IP blokkeren")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)