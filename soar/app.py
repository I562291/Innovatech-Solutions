import boto3
import requests
from flask import Flask, render_template, request
from datetime import datetime


app = Flask(__name__)

alerts_list = []


def rule_engine(alert):
    if "possible bruteforce" in alert.get("title", "").lower(): # lower om hoofdletters om te zetten naar kleine letters
        return ["notify_discord", "block_ip"]
    return []


def notify_discord(alert):
    try:
        ssm = boto3.client("ssm", region_name="eu-central-1")
        parameter = ssm.get_parameter(
            Name="/innovatech/discord/webhook",
            WithDecryption=True,
        )
        webhook_url = parameter["Parameter"]["Value"] # we stoppen webhook url in webhook variable
        requests.post(
            webhook_url,
            json={"content": f"SOAR alert: {alert.get('title', 'Unknown alert')}"},
        )
    except Exception as e:
        print(f"Error sending notification to Discord: {e}")


@app.get("/health")
def health():
    return "ok", 200


@app.get("/")
def home():
    return render_template("index.html")


@app.route("/alerts", methods=["GET", "POST"])
def alerts():
    try:
        if request.method == "POST":
            data = request.get_json()
            actions = rule_engine(data) # hier stoppen we "data" in de "alert" parameter

            if "notify_discord" in actions:
                notify_discord(data)

            alerts_list.append({
                "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "data": data,
                "actions": actions
            })
            print(actions)
            return "ok", 200
    except Exception as e:
        print(f"Error during alert processing: {e}")
    return render_template("alerts.html", alerts=alerts_list)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)