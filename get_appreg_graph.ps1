#get search param
param (
    [string]$ApptoSearch  # Default value, can be overridden
)
# Connect to MS Grap
Connect-MgGraph -NoWelcome -Scopes 'Application.Read.All'

# Messages
$Messages = @{
    DurationNotice = @{
        Info = @(
            'The operation is running and will take longer the more applications the tenant has...'
            'Please wait...'
        ) -join ' '
    }
    Export         = @{
        Info = 'File exporting to... '
    }
    Counter        = @{
        Info = 'Count... '
    }
}

# Parameters required - Number of days, local path, include expired.
$LocalPath = Join-Path $HOME 'Downloads'
$NumResults = 0


Write-Host $Messages.DurationNotice.Info -ForegroundColor yellow

$Applications = Get-MgApplication -all

$Logs = @()

foreach ($App in $Applications) {
    echo $App

    if ($App.DisplayName.ToLower().Contains($ApptoSearch.ToLower())) {

        $NumResults++
        $AppName = $App.DisplayName
        $AppID = $App.Id
        $ApplID = $App.AppId
        $AppSMR = $App.ServiceManagementReference
        $AppNote = $App.Notes
        $AppType = ''

        # getting API permissions
        # Dictionary to cache resolved API permissions by resourceAppId
        $PermissionCache = @{}

        # API Permissions (with names)
        # Dictionary to cache resolved API permissions by resourceAppId
        $PermissionCache = @{}
        $ApiPermissions = @()

        if ($App.RequiredResourceAccess) {
            foreach ($resource in $App.RequiredResourceAccess) {
                $resourceAppId = $resource.ResourceAppId

                # Use cache to avoid repeated calls
                if (-not $PermissionCache.ContainsKey($resourceAppId)) {
                    $sp = Get-MgServicePrincipal -Filter "appId eq '$resourceAppId'" -ErrorAction SilentlyContinue
                    $PermissionCache[$resourceAppId] = $sp
                }
                else {
                    $sp = $PermissionCache[$resourceAppId]
                }

                foreach ($access in $resource.ResourceAccess) {
                    $permId = $access.Id
                    $permType = $access.Type
                    $permName = "Unknown"
                    $apiName = $sp.DisplayName
                    $adminConsent = "Unknown"

                    if ($permType -eq "Scope" -and $sp.Oauth2PermissionScopes) {
                        $match = $sp.Oauth2PermissionScopes | Where-Object { $_.Id -eq $permId }
                        if ($match) {
                            $permName = $match.Value
                            $adminConsent = if ($match.IsAdminConsentRequired) { "Admin Consent Required" } else { "User Consent Allowed" }
                        }
                    }

                    if ($permType -eq "Role" -and $sp.AppRoles) {
                        $match = $sp.AppRoles | Where-Object { $_.Id -eq $permId }
                        if ($match) {
                            $permName = $match.Value
                            $adminConsent = if ($match.IsEnabled -eq $true) { "Enabled" } else { "Disabled" }
                        }
                    }

                    $ApiPermissions += "[{3}] {1} ({2}) - {4}" -f $permType, $permName, $permId, $apiName, $adminConsent
                }
            }
        }

        $ApiPermissionsText = $ApiPermissions -join "`n"


        



        $AppCreds = Get-MgApplication -ApplicationId $AppID |
        Select-Object PasswordCredentials, KeyCredentials

        $Secrets = $AppCreds.PasswordCredentials

        if (!$null -eq $Secrets) {
            foreach ($Secret in $Secrets) {
                $StartDate = $Secret.StartDateTime
                $EndDate = $Secret.EndDateTime
                $SecretName = $Secret.DisplayName
                $AppType = 'Secret'

                $Owner = Get-MgApplicationOwner -ApplicationId $App.Id
                $Username = $Owner.AdditionalProperties.userPrincipalName -join ';'
                $OwnerID = $Owner.Id -join ';'

                if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                    $Username = @(
                        $Owner.AdditionalProperties.displayName
                        '**<This is an Application>**'
                    ) -join ' '
                }
                if ($null -eq $Owner.AdditionalProperties.displayName) {
                    $Username = '<<No Owner>>'
                }

                $Logs += [PSCustomObject]@{
                    'ApplicationName'   = $AppName
                    'ApplicationID'     = $ApplID
                    'Type'              = $AppType
                    'Secret Name'       = $SecretName
                    'Secret Start Date' = $StartDate
                    'Secret End Date'   = $EndDate
                    'Owner'             = $Username
                    'OwnerID'           = $OwnerID
                    'SNOW Ref'          = $AppSMR
                    'Notes'             = $AppNote
                    'API Permissions'   = $ApiPermissionsText

                }
            }
        }
        else {

            $AppType = 'AppRegOnly'

            $Owner = Get-MgApplicationOwner -ApplicationId $App.Id
            $Username = $Owner.AdditionalProperties.userPrincipalName -join ';'
            $OwnerID = $Owner.Id -join ';'

            if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                $Username = @(
                    $Owner.AdditionalProperties.displayName
                    '**<This is an Application>**'
                ) -join ' '
            }
            if ($null -eq $Owner.AdditionalProperties.displayName) {
                $Username = '<<No Owner>>'
            }

            $Logs += [PSCustomObject]@{
                'ApplicationName'   = $AppName
                'ApplicationID'     = $ApplID
                'Type'              = $AppType
                'Secret Name'       = ""
                'Secret Start Date' = ""
                'Secret End Date'   = ""
                'Owner'             = $Username
                'OwnerID'           = $OwnerID
                'SNOW Ref'          = $AppSMR
                'Notes'             = $AppNote
                'API Permissions'   = $ApiPermissionsText

            }
        }


    }

}

$LogDate = Get-Date -f yyyyMMddhhmm
$Path = "$LocalPath\AppReg-$ApptoSearch-Exp_$LogDate.csv"
Write-Host $Messages.Counter $NumResults -ForegroundColor Green
Write-Host $Messages.Export.Info $Path -ForegroundColor Green
echo $Logs
$Logs | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8