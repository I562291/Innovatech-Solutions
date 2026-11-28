from flask import Flask, abort, redirect, render_template, request, url_for, session
import db_connection, json, urllib.request
import boto3
from authlib.integrations.flask_client import OAuth
# import ipaddress: ik gadit gebruiken om te checken of een ip adress daadwekrelijk een ip adress is.

git_token = boto3.client('ssm', region_name='eu-central-1').get_parameter(Name='/innovatech/github/token', WithDecryption=True)['Parameter']['Value']
client = boto3.client('cognito-idp', region_name='eu-central-1') # hiermee kan ik admin handelingen doen via cognito
ssm_client = boto3.client('ssm', region_name='eu-central-1') # bedoelt om toegang te krijgen tot ssm parameter store\

def get_user_pool_id(): # we halen het vanafnu op via de parameter store ssm
    response = ssm_client.get_parameter(Name='/innovatech/cognito/pool_id')
    return response['Parameter']['Value'] # hiermee krijgen we het userpool id van de parameter store


def get_cognito_client_id(): # voor de client id van application
    response = ssm_client.get_parameter(Name='/innovatech/cognito/client_id')
    return response['Parameter']['Value'] # hiermee krijgen we het userpool id van de parameter store

def trigger_github_workflow(ip_address): # github api for triggering the workflow
    url = "https://api.github.com/repos/I562291/Innovatech-Solutions/actions/workflows/device_enrollment.yml/dispatches"
    data = json.dumps({"ref": "main", "inputs": {"ip": ip_address}}).encode()
    request = urllib.request.Request(url, data=data, method="POST", headers={
        "Authorization": f"Bearer {git_token}", # login using the token
    })
    urllib.request.urlopen(request) # we sturen een POST request naar de GitHub API om de workflow te triggeren met het opgegeven IP-adres als input.
    
def get_cognito_client_secret(): # hiermee halen we de client secret op uit parameter store
    response = ssm_client.get_parameter(
        Name='/innovatech/cognito/client_secret',
        WithDecryption=True
    )
    return response['Parameter']['Value']

def get_session_secret():
    response = ssm_client.get_parameter(
        Name='/innovatech/flask/session_secret',
        WithDecryption=True
    )
    return response['Parameter']['Value']

USER_POOL_ID = get_user_pool_id() # we slaan het userpool id op in een variabele zodat we het later kunnen gebruiken bij het aanmaken van een gebruiker en het toevoegen aan de juiste groep. 
CLIENT_ID = get_cognito_client_id()
CLIENT_SECRET = get_cognito_client_secret()
SESSION_SECRET = get_session_secret()

app = Flask(__name__)
app.secret_key = SESSION_SECRET
oauth = OAuth(app)

oauth.register( # registering the cognito client with the oauth library
    name="cognito",
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET,
    server_metadata_url=f"https://cognito-idp.eu-central-1.amazonaws.com/{USER_POOL_ID}/.well-known/openid-configuration",
    client_kwargs={"scope": "openid"}
)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/login")
def login():
    return oauth.cognito.authorize_redirect(
        "https://hr.innovatech.internal/callback"
    )

@app.route("/callback") # hier beslist flask welke pagina de gebruiker krijgt te zien op basis van hun groep/role in cognito.
def callback():
    token = oauth.cognito.authorize_access_token()
    groups = token["userinfo"].get("cognito:groups", []) # deze checkt in welke groep de ingelogde gebruiker zit

    session["groups"] = groups # we slaan dat resultaat op in de session zodat we het later kunnen gebruiken om te checken of de gebruiker toegang heeft tot bepaalde pagina's
    if "admin" in groups:
        return redirect(url_for("admin"))

    if "hr" in groups:
        return redirect(url_for("hr"))

    if "finance" in groups:
        return redirect(url_for("finance"))

    abort(403)

@app.route("/admin")
def admin():
    if "admin" not in session.get("groups", []):
        abort(403)
    employees = db_connection.list_employees()
    return render_template("admin.html", employees=employees)

@app.route("/hr")
def hr():
    if "hr" not in session.get("groups", []):
        abort(403)
    employees = db_connection.list_employees()
    return render_template("hr.html", employees=employees) # hier geven we de lijst van medewerkers door aan de hr.html template zodat deze kan worden weergegeven op de HR pagina.

@app.route("/finance")
def finance():
    if "finance" not in session.get("groups", []):
        abort(403)
    return render_template("finance.html")

@app.route("/onboard", methods=["GET", "POST"])
def onboard():
    groups = session.get("groups", [])
    if "hr" not in groups and "admin" not in groups:
        abort(403)
        
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
        except Exception as e:
            abort(500, description=f"Error onboarding employee: {str(e)}")
        try:
            trigger_github_workflow(ip_address) # trigger de workflow, voor de return zodat hij niet stopt als de db functie niet werkt.
        except Exception as e:
            abort(500, description=f"Error triggering GitHub workflow: {str(e)}")
        if "admin" in groups:
            return redirect(url_for("admin"))
        return redirect(url_for("hr"))

    return render_template("onboard.html")

@app.route("/offboard", methods=["GET", "POST"])
def offboard():
    groups = session.get("groups", [])
    if "hr" not in groups and "admin" not in groups:
        abort(403)
        
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
        
        if "admin" in groups:
            return redirect(url_for("admin"))
        return redirect(url_for("hr"))
        
    return render_template("offboard.html", employees=employees)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)