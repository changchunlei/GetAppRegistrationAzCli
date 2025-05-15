# Adding your Azure app registration IDs here
APP_IDS=(
    "a8b4c868-0099-4799-8863-208cfd0b80c1"
    "f938a6d7-3e70-4034-9038-c6c5653807e7"
)

OUTPUT_FILE="app_info.txt"
> "$OUTPUT_FILE"

for app_id in "${APP_IDS[@]}"
do
    if [[ -n "$app_id" ]]; then
        echo "Fetching info for App ID: $app_id"
        app_json=$(az ad app show --id "$app_id" --output json)
        display_name=$(echo "$app_json" | jq -r '.displayName')
        echo "App: $display_name ($app_id)" >> "$OUTPUT_FILE"
        echo "Object ID: $(echo "$app_json" | jq -r '.id')" >> "$OUTPUT_FILE"
        echo "Created: $(echo "$app_json" | jq -r '.createdDateTime // "N/A"')" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # Auth
        echo "Authentication:" >> "$OUTPUT_FILE"
        echo "$app_json" | jq '.web, .spa' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # Certificates & Secrets Basic Info
        echo "Certificates & Secrets (id only, no secret value here):" >> "$OUTPUT_FILE"
        az ad app credential list --id "$app_id" --query '[].{KeyId:keyId, Type:type, displayName:displayName, Created:startDateTime, Expiry:endDateTime}' -o table >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # Token Configuration
        echo "Token Configuration:" >> "$OUTPUT_FILE"
        az ad app federated-credential list --id "$app_id" --output table >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # Expose an API
        echo "Expose an API:" >> "$OUTPUT_FILE"
        echo "App Roles:" >> "$OUTPUT_FILE"
        echo "$app_json" | jq '.appRoles' >> "$OUTPUT_FILE"
        echo "OAuth2 Permissions (Scopes):" >> "$OUTPUT_FILE"
        echo "$app_json" | jq '.oauth2Permissions' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # List Scopes and Authorized Client Applications
        echo "Scopes and Authorized Client Applications:" >> "$OUTPUT_FILE"
        echo "$app_json" | jq -c '.api.oauth2PermissionScopes[]?' | while read -r scope; do
            scope_id=$(echo "$scope" | jq -r '.id')
            scope_value=$(echo "$scope" | jq -r '.value')
            scope_admin_consent=$(echo "$scope" | jq -r '.adminConsentDescription // "N/A"')
            echo "  Scope: $scope_value (ID: $scope_id)" >> "$OUTPUT_FILE"
            echo "    Admin Consent Description: $scope_admin_consent" >> "$OUTPUT_FILE"
            # List authorized client applications for this scope
            authorized_clients=$(echo "$app_json" | jq -c --arg sid "$scope_id" '.api.preAuthorizedApplications[]? | select(.delegatedPermissionIds[]? == $sid)')
            if [[ -n "$authorized_clients" ]]; then
                echo "    Authorized Client Applications:" >> "$OUTPUT_FILE"
                echo "$authorized_clients" | jq -r '.appId' | while read -r client_id; do
                    echo "      - $client_id" >> "$OUTPUT_FILE"
                done
            else
                echo "    Authorized Client Applications: None" >> "$OUTPUT_FILE"
            fi
        done
        echo "" >> "$OUTPUT_FILE"

        # Owners
        echo "Owners:" >> "$OUTPUT_FILE"
        az ad app owner list --id "$app_id" --query '[].{DisplayName:displayName, UserPrincipalName:userPrincipalName, ObjectId:id}' -o table >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # API Permissions
        echo "API Permissions:" >> "$OUTPUT_FILE"
        echo "$app_json" | jq -c '.requiredResourceAccess[]?' | while read -r resource; do
            resource_app_id=$(echo "$resource" | jq -r '.resourceAppId')
            resource_sp=$(az ad sp list --filter "appId eq '$resource_app_id'" --query '[0]' --output json)
            resource_name=$(echo "$resource_sp" | jq -r '.displayName // "Unknown API"')
            echo "  API: $resource_name ($resource_app_id)" >> "$OUTPUT_FILE"
            # Delegated permissions
            for perm_id in $(echo "$resource" | jq -r '.resourceAccess[] | select(.type=="Scope") | .id'); do
                perm=$(echo "$resource_sp" | jq -c --arg id "$perm_id" '.oauth2Permissions[]? | select(.id==$id)')
                name=$(echo "$perm" | jq -r '.value // .displayName // "Unknown"')
                desc=$(echo "$perm" | jq -r '.adminConsentDescription // "N/A"')
                admin=$(echo "$perm" | jq -r '.isAdminConsentRequired // false')
                echo "    - Permission: $name" >> "$OUTPUT_FILE"
                echo "      Type: Delegated" >> "$OUTPUT_FILE"
                echo "      Description: $desc" >> "$OUTPUT_FILE"
                echo "      Admin consent required: $admin" >> "$OUTPUT_FILE"
            done
            # Application permissions
            for perm_id in $(echo "$resource" | jq -r '.resourceAccess[] | select(.type=="Role") | .id'); do
                perm=$(echo "$resource_sp" | jq -c --arg id "$perm_id" '.appRoles[]? | select(.id==$id)')
                name=$(echo "$perm" | jq -r '.value // .displayName // "Unknown"')
                desc=$(echo "$perm" | jq -r '.description // "N/A"')
                admin="true"
                echo "    - Permission: $name" >> "$OUTPUT_FILE"
                echo "      Type: Application" >> "$OUTPUT_FILE"
                echo "      Description: $desc" >> "$OUTPUT_FILE"
                echo "      Admin consent required: $admin" >> "$OUTPUT_FILE"
            done
        done
        echo "" >> "$OUTPUT_FILE"
    fi
done

echo "Done. Results saved to $OUTPUT_FILE under the current directory."