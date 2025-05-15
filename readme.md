# Azure App Registration Info Script

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

## Notes
- The script may take a couple of minutes to run if you have many App Registrations or permissions.
- It will only retrieve the app basic info but not sensitive info like the secret value. non-sensitive data only
- This script is intended for streamline the access for large and highly regulated cooperate environment devops teams who don't have direct access to entra ID.

## License
MIT License
