from flask import Flask, abort, redirect, render_template, request, url_for
import db_connection

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/admin")
def admin():
    return render_template("admin.html")

@app.route("/hr")
def hr():
    return render_template("hr.html")

@app.route("/finance")
def finance():
    return render_template("finance.html")

@app.route("/onboard", methods=["GET", "POST"])
def onboard():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        role = request.form.get("role", "").strip()
        ip_address = request.form.get("ip", "").strip()
        if not name or not role or not ip_address:
            abort(400, description="Name, role and IP address are required.")

        db_connection.onboard_employee(name, role, ip_address)
        return redirect(url_for("hr")) # after successful onboarding, redirect to HR page. this prevents form resubmission on page refresh.

    return render_template("onboard.html")

@app.route("/offboard")
def offboard():
    return render_template("offboard.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
    
    
    
# MySQL: naam, role en IP-adres opslaan.
# Boto3: Cognito-account aanmaken en koppelen aan de juiste groep.
# Ansible: GitHub Actions workflow triggeren met het IP-adres voor de security baseline en applicatie-installatie.