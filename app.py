from flask import Flask, render_template, request
from db_connection import create_ticket
import os


app = Flask(__name__)

@app.route("/")
def home():
    return render_template("home.html")

@app.route("/ticket")
def ticket():
    return render_template("ticket.html")

@app.route("/confirmation", methods=["POST"])
def confirmation():
    buyer_name = request.form.get("name")
    create_ticket(buyer_name)
    return render_template("confirmation.html", name=buyer_name)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)