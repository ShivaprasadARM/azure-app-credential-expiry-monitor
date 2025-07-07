# Azure App Credential Expiry Monitor

This PowerShell script monitors Azure App Registrations for expiring **client secrets** and **certificates**, and sends an HTML email alert if any credentials are set to expire within the next configurable number of days.

---

## Features

- ✅ Monitors any number of Azure App Registrations
- ✅ Detects expiring secrets and certificates
- ✅ Sends formatted email alerts
- ✅ Supports scheduling via Task Scheduler or CI/CD pipelines
- ✅ Secure credential handling via Windows Credential Manager

---

## Prerequisites

- PowerShell 5.1 or later
- Modules:
  - `Microsoft.Graph.Authentication`
  - `Microsoft.Graph.Applications`
  - `CredentialManager`
- SMTP server access for sending emails
- A registered Azure App with:
  - `Application.Read.All` permission
  - Admin consent granted
  - Valid client secret stored securely

---

## Setup Instructions
**Configure Credential in Windows Credential Manager**
Use the following command under the context of the account that will run the script:

**cmdkey /add:"AzureAppExpiryNotifier" /user:"<client-id>" /pass:"<client-secret>"**
Replace <client-id> and <client-secret> with your Azure App credentials.

1. **Customize the Script**
$TenantId = "<your-tenant-id>"

# App Registrations to monitor
$AppIdsToCheck = @('<object-id-1>', '<object-id-2>')

# Email Notification Settings
$SMTPServer = "smtp.yourdomain.com"
$SMTPFromAddress = "noreply@yourdomain.com"
$SMTPToAddress = @("alerts@yourdomain.com", "admin@yourdomain.com")

2. Test the Script
Run the script manually to verify: .\AppCredentialExpiryMonitor.ps1
Check the console output and verify whether an email was received (if any credentials are expiring).

3. Schedule the Script
Use Windows Task Scheduler for automation:
•	Trigger: Weekly (e.g., every Monday at 9:00 AM)
•	User: A service account with access to Credential Manager and SMTP
•	Settings: Run with highest privileges and set to run whether user is logged in or not
Or optionally, use a CI/CD tool such as Azure DevOps, GitLab CI, or GitHub Actions with a secure runner and credentials.

4. Email Output
If expiring credentials are found, the script sends an email with a table like:
Application Name	Application ID	Type	Credential Name	Start Date	End Date	Days Remaining
MyApp	xxxxxxxx	Secret	ClientSecret	2024-08-01T12:00Z	2024-08-31T12:00Z	24
MyApp	xxxxxxxx	Certificate	SSL-Cert	2024-01-01T12:00Z	2024-08-15T12:00Z	8

5. Best Practices
1.	Use a dedicated service principal with the least privilege.
2.	Store client secrets securely using CredentialManager.
3.	Schedule the script to run regularly (e.g., weekly).
4.	Rotate secrets and certificates well before expiry.
5.	Extend functionality to integrate with ITSM tools like ServiceNow (optional).

Tags
#Azure #PowerShell #Automation #MicrosoftGraph #AppRegistration
#CredentialMonitoring #CI/CD #AzureAD #IdentityManagement
