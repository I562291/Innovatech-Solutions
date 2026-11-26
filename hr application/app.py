from flask import Flask, abort, redirect, render_template, request, url_for
import db_connection, json, urllib.request
import boto3
import git

git_token = boto3.client('ssm', region_name='eu-central-1').get_parameter(Name='/innovatech/github/token', WithDecryption=True)['Parameter']['Value']

client = boto3.client('cognito-idp', region_name='eu-central-1') # we gaan hier gebruik maken van boto3 om een cognito account aan te maken en te koppelen aan de juiste groep/verwijderen bij offboarding.
def get_user_pool_id(): # we halen het vanafnu op via de parameter store ssm
    ssm_client = boto3.client('ssm', region_name='eu-central-1')
    response = ssm_client.get_parameter(Name='/innovatech/cognito/pool_id')
    return response['Parameter']['Value'] # hiermee krijgen we het userpool id van de parameter store

USER_POOL_ID = get_user_pool_id() # we slaan het userpool id op in een variabele zodat we het later kunnen gebruiken bij het aanmaken van een gebruiker en het toevoegen aan de juiste groep. 

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/admin")
def admin():
    return render_template("admin.html")

@app.route("/hr")
def hr():
    employees = db_connection.list_employees()
    return render_template("hr.html", employees=employees) # hier geven we de lijst van medewerkers door aan de hr.html template zodat deze kan worden weergegeven op de HR pagina.

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
            abort(400, description="Name, role and IP address are required.") # if any of the fields are missing, stop the process.

        client.admin_create_user(UserPoolId=USER_POOL_ID, Username=name) # hier maken we een nieuwe gebruiker aan in cognito
        client.admin_add_user_to_group(UserPoolId=USER_POOL_ID, Username=name, GroupName=role) # hiermee voegen we de gebruiker toe aan de juiste groep in Cognito op basis van hun rol.

        try:
            db_connection.onboard_employee(name, role, ip_address)
            return redirect(url_for("hr")) # after successful onboarding, redirect to HR page. this prevents form resubmission on page refresh.
        except Exception as e:
            abort(500, description=f"Error onboarding employee: {str(e)}")  
        def trigger_github_workflow(ip_address):
            url = 
        
    return render_template("onboard.html")

@app.route("/offboard", methods=["GET", "POST"])
def offboard():
    employees = db_connection.list_employees() # first the list of employees get fetched from the database
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        if not name:
            abort(400, description="Name is required for offboarding.")
        try: 
            db_connection.offboard_employee(name)
        except Exception as e: 
            abort(500, description=f"Error offboarding employee: {str(e)}")
        try: 
            client.admin_delete_user(UserPoolId=USER_POOL_ID, Username=name)
        except Exception as e: 
            abort(500, description=f"Error deleting user from Cognito: {str(e)}")

        return redirect(url_for("hr")) # after successful offboarding, redirect to HR page.
    return render_template("offboard.html", employees=employees)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
    
    
    
# MySQL: naam, role en IP-adres opslaan.
# Boto3: Cognito-account aanmaken en koppelen aan de juiste groep.
# Ansible: GitHub Actions workflow triggeren met het IP-adres voor de security baseline en applicatie-installatie.