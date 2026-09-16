from flask import Flask, render_template
import db_connection

app = Flask(__name__)

@app.route("/")
def home():
    return render_template("home.html")

@app.route("/ticket")
def ticket():
    return render_template("ticket.html")

@app.route("/confirmation")
def confirmation():
    return render_template("confirmation.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)