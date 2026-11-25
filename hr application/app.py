from flask import Flask, render_template
import db_connection

app = Flask(__name__)

role = {
    "admin_group": ["create_user", "delete_user", "list_users"],
    "hr_group": ["onboard", "offboard", "list_employees"],
    "finance_group": ["salaries"]
}

@app.route("/")
def index():
    return render_template("index.html", role=role)

@app.route("/admin")
def admin():
    return render_template("admin.html", actions=role["admin_group"])

@app.route("/hr")
def hr():
    return render_template("hr.html", actions=role["hr_group"])

@app.route("/onboard")
def onboard():
    return render_template("onboard.html", actions=role["hr_group, admin_group"])

@app.route("/offboard")
def offboard():
    return render_template("offboard.html", actions=role["hr_group, admin_group"])

@app.route("/finance")
def finance():
    return render_template("finance.html", actions=role["finance_group"])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)