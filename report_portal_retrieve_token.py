#!/usr/bin/env python3
import argparse
import requests
import warnings
import sys
import json

# Redirect warnings to stderr
warnings.simplefilter('always', category=UserWarning, append=True)
warnings.showwarning = lambda message, category, filename, lineno, file=None, line=None: \
    sys.stderr.write(warnings.formatwarning(message, category, filename, lineno, line))

# Fixed client credentials
CLIENT_ID = "ui"
CLIENT_SECRET = "uiman"

# Function to get the access token
def get_access_token(token_url, username, password):
    response = requests.post(
        token_url,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "grant_type": "password",
            "username": username,
            "password": password
        },
        auth=(CLIENT_ID, CLIENT_SECRET)
    )
    
    if response.status_code == 200:
        access_token = response.json().get("access_token")
        return access_token, None, None
    else:
        return None, response.status_code, response.json()

# Parse command-line arguments
def parse_args():
    parser = argparse.ArgumentParser(description="Retrieve access token from Report Portal.")
    parser.add_argument("--url", required=True, help="Base URL for Report Portal.")
    parser.add_argument("--username", required=True, help="Username for authentication.")
    parser.add_argument("--password", required=True, help="Password for authentication.")
    return parser.parse_args()

def main():
    args = parse_args()

    # Construct the full token URL
    token_url = f"{args.url}/uat/sso/oauth/token"
    
    access_token, status_code, response_json = get_access_token(
        token_url=token_url,
        username=args.username,
        password=args.password
    )
    
    # Prepare JSON output
    output = {}
    if access_token:
        output["access_token"] = access_token
        output["status"] = "success"
    else:
        output["status"] = "failure"
        output["error_code"] = status_code
        output["error_message"] = response_json
    
    # Print JSON output
    print(json.dumps(output, indent=4))

if __name__ == "__main__":
    main()

