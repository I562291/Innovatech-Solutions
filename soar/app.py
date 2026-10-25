from flask import Flask, render_template


app = Flask(__name__)


@app.get("/health")
def health():
    return "ok", 200


@app.get("/")
def home():
    return render_template("index.html")

@app.get("/alerts")
def alerts():
    return render_template("alerts.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)