from flask import Flask, render_template

app = Flask(__name__)

role = {
    "admin": ["create_user", "delete_user", "list_users"],
    "hr": ["onboard", "offboard", "list_employees"],
    "Finance": ["salaries"]
}

@app.route("/")
def index():
    return render_template("index.html", role=role)

@app.route("/admin")
def admin():
    return render_template("admin.html", actions=role["admin"])

@app.route("/hr")
def hr():
    return render_template("hr.html", actions=role["hr"])

@app.route("/finance")
def finance():
    return render_template("finance.html", actions=role["Finance"])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)