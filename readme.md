# 1. Azure App Registration Info Script in Az Cli

This repository contains an Az cli script to fetch basic information about Azure App Registrations using Azure CLI. The script gathers key details basic non-sensitive information such as API permissions for a list of App Registration (client) IDs.

## Prerequisites

- Install Azure cli
- Sufficient permissions to read App Registrations and Service Principals in your Azure tenant
- Run it after 

## Usage

1. **Clone this repository**  
   ```bash
   git clone https://github.com/changchunlei/GetAppRegistrationAzCli.git
   cd AppRegistrationInAzCli
   ```

2. **Edit the script**  
   Open `get_app_registration.sh` and update the `APP_IDS` array with your App Registration (Application) IDs.

3. **Run the script**  
in macOS/linux
   ```bash
   az login
   chmod +x get_app_registration.sh
   ./get_app_registration.sh
   ```
in Azure portal, click a cloud shell and simply copy paste your code to run. 

4. **View the output**  
   The results will be saved in `app_info.txt` in the same directory.

## What Information does this script retrieve?

For each App Registration, the script collects:
- **Basic Info:** Display name, App ID, Object ID, creation date, sign-in audience
- **Authentication:** 
- **Certificates & Secrets:** Lists credentials basic info: id, expiry date
- **Token Configuration:** 
- **Expose an API:** App roles and OAuth2 permissions (scopes)
- **API Permissions:**  
  - API/Permission name  
  - Type (Delegated/Application)  
  - Description  
  - Admin consent required  



# 2. Alternative scripts in PowerShell (Getting there in a different path)

A PowerShell script using Microsoft Graph PowerShell SDK to export app registration info to CSV, including:

- **Application Name, ID, and Notes**
- **API Permissions:** With resolved names, types, and admin consent requirements
- **Secrets:** Name, start and end date
- **Owners:** Display name and user principal name
- **Other metadata:** SNOW Ref, Service Management Reference



#### Usage

1. **Install MgGraph Ps sdk**  
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```

2. **Run the script**  
   ```powershell
   .\get_appreg_graph.ps1 -ApptoSearch "<search string>"
   ```

   in Azure Bash cloud shell it will be 
   ```powershell
   pwsh ./EntraID_SPECIFICAppRegs_NoPrompt.ps1 -ApptoSearch "<search string>"
   ```

3. **Output**  
   The script will export a CSV file to your Downloads folder with all relevant app registration details.

## Notes
- The script may take a couple of minutes to run if you have many App Registrations or permissions.
- It will only retrieve the app basic info but not sensitive info like the secret value. non-sensitive data only
- This script is intended for streamline the access for large and highly regulated cooperate environment devops teams who don't have direct access to entra ID.

## License
MIT License
