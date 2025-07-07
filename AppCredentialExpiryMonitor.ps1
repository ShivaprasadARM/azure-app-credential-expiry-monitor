# #Azure #PowerShell #MicrosoftGraph #DevOps #Automation #Identity #AppRegistration #AzureAD #CredentialMonitoring

# -------------------- LOAD MODULES --------------------
Import-Module CredentialManager
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

# -------------------- FUNCTION: Get App Credential from Credential Manager --------------------
function Get-AppCredentialFromManager($TargetName) {
    $StoredCred = Get-StoredCredential -Target $TargetName
    if (-not $StoredCred) {
        throw "No credentials found in Windows Credential Manager for '$TargetName'"
    }

    $ClientId = $StoredCred.Username
    $SecretPlain = [System.Net.NetworkCredential]::new("", $StoredCred.Password).Password
    return New-Object System.Management.Automation.PSCredential($ClientId, (ConvertTo-SecureString $SecretPlain -AsPlainText -Force))
}

# -------------------- AUTHENTICATION --------------------
$TenantId = "<Your-Tenant-ID-Here>"
$Credential = Get-AppCredentialFromManager -TargetName "<Stored-Credential-Name>"

Connect-MgGraph -TenantId $TenantId -Credential $Credential

# -------------------- CONFIG: SCRIPT SETTINGS --------------------
$DaysUntilExpiration = 30
$Now = Get-Date

# Replace with App Object IDs to monitor
$AppIdsToCheck = @('<ObjectId-1>', '<ObjectId-2>', '<ObjectId-N>')

# Email settings (Update as per your SMTP server & recipients)
$SMTPServer = "<SMTP-Server>"
$SMTPFromAddress = "<from@example.com>"
$SMTPToAddress = @("<recipient1@example.com>", "<recipient2@example.com>")

# -------------------- PROCESS: Get Applications --------------------
$Applications = Get-MgApplication -All | Where-Object { $AppIdsToCheck -contains $_.Id }

$Logs = @()

foreach ($App in $Applications) {
    $AppName = $App.DisplayName
    $AppID   = $App.Id
    $ApplID  = $App.AppId

    $AppCreds = Get-MgApplication -ApplicationId $AppID |
        Select-Object PasswordCredentials, KeyCredentials

    # --- Check Latest Secret ---
    $LatestSecret = $AppCreds.PasswordCredentials |
        Where-Object { $_.EndDateTime -gt $Now } |
        Sort-Object EndDateTime -Descending |
        Select-Object -First 1

    if ($LatestSecret) {
        $RemainingDaysSecret = ($LatestSecret.EndDateTime - $Now).Days
        if ($RemainingDaysSecret -le $DaysUntilExpiration) {
            $Logs += [PSCustomObject]@{
                'ApplicationName' = $AppName
                'ApplicationID'   = $ApplID
                'CredentialType'  = "Secret"
                'Credential Name' = $LatestSecret.DisplayName
                'Start Date'      = $LatestSecret.StartDateTime
                'End Date'        = $LatestSecret.EndDateTime
                'Expiry Alert'    = "Secret expires in $RemainingDaysSecret days"
            }
        }
    }

    # --- Check Latest Certificate ---
    $LatestCert = $AppCreds.KeyCredentials |
        Where-Object { $_.EndDateTime -gt $Now } |
        Sort-Object EndDateTime -Descending |
        Select-Object -First 1

    if ($LatestCert) {
        $RemainingDaysCert = ($LatestCert.EndDateTime - $Now).Days
        if ($RemainingDaysCert -le $DaysUntilExpiration) {
            $Logs += [PSCustomObject]@{
                'ApplicationName' = $AppName
                'ApplicationID'   = $ApplID
                'CredentialType'  = "Certificate"
                'Credential Name' = $LatestCert.DisplayName
                'Start Date'      = $LatestCert.StartDateTime
                'End Date'        = $LatestCert.EndDateTime
                'Expiry Alert'    = "Certificate expires in $RemainingDaysCert days"
            }
        }
    }
}

# -------------------- FUNCTION: Send Email Alert --------------------
function Send-ResultEmail {
    param([System.Collections.ArrayList]$result_array)

    $today = Get-Date -format "dddd, MMMM dd, yyyy"
    $emailto = $SMTPToAddress
    $emailfrom = $SMTPFromAddress
    $emailsub = "Azure App Credentials Expiry Alert - $DaysUntilExpiration Days"

    $htmlstring = "<html><body><p><b>The following credentials are expiring within the next $DaysUntilExpiration days:</b></p><table border='1'><tr><th>Application Name</th><th>Application ID</th><th>Credential Type</th><th>Credential Name</th><th>Start Date</th><th>End Date</th><th>Expiry Alert</th></tr>"

    foreach ($obj in $result_array) {
        $htmlstring += "<tr><td>$($obj.ApplicationName)</td><td>$($obj.ApplicationID)</td><td>$($obj.CredentialType)</td><td>$($obj.'Credential Name')</td><td>$($obj.'Start Date')</td><td>$($obj.'End Date')</td><td>$($obj.'Expiry Alert')</td></tr>"
    }

    $htmlstring += "</table></body></html>"

    Send-MailMessage -From $emailfrom -To $emailto -Subject $emailsub -BodyAsHtml -Body $htmlstring -SmtpServer $SMTPServer
}

# -------------------- ACTION: Send Email if Expirations Found --------------------
if ($Logs.Count -gt 0) {
    Send-ResultEmail -result_array $Logs
    Write-Host "Email has been sent with expiring credentials." -ForegroundColor Green
} else {
    Write-Host "No expiring credentials found. Email not sent." -ForegroundColor Yellow
}

# -------------------- CLEANUP --------------------
Disconnect-MgGraph
exit 0