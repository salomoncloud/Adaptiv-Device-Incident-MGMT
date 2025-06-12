Project Summary
---

I've built a centralized web application for the support team to track CPE device incidents (E40, E60, etc.), including outage times, troubleshooting notes, and recurring issues. The application is designed to be simple, team-accessible, and cloud-native, deployed on AWS using Terraform, with future integrations planned (like Slack alert checks).

Architecture Overview

- **Frontend:** HTML/CSS/JS (hosted on S3, styled like Adaptiv's branding)
- **API Layer:** AWS API Gateway (HTTP routes)
- **Backend:** Python-based AWS Lambda functions (via zip files)
- **Database:** Amazon DynamoDB for storing incident data
- **Authentication:** Amazon Cognito User Pool (shared login)
- **Automation:** EventBridge scheduled check for recurring incidents --- Would need to be set up later on
- **Infrastructure-as-Code:** Terraform (modular, stored in GitHub and deployed via Terraform Cloud --- Terraform Cloud handles the remote state)

---

Features

- Submit incident reports (CPE info, root cause, fix, etc.)
- Lookup recurring issues by serial number
- View all logged incidents in a table
- Export incidents to CSV
- Daily automation (EventBridge + Lambda) to flag repeat offenders

---

Configure Terraform Cloud:

Connect this repo to Terraform Cloud
Add the following workspace variables and set value as sensitive and terraform environment variables (that way anything sensitive gets saved securely and remotely rather than in code):
| Name                    | Value               |
| ----------------------- | ------------------- |
| `aws_access_key_id`     | Your AWS access key |
| `aws_secret_access_key` | Your AWS secret     |
| `shared_password`       | (Set securely)      |

Deploy Infrastructure:
Go to Terraform Cloud and run a plan + apply

After deployment, Terraform will output:
api_endpoint — for backend API calls (used in frontend app.js)
website_url — where your HTML/CSS/JS app is hosted

API Routes:
| Route         | Method | Description                             |
| ------------- | ------ | --------------------------------------- |
| `/incident`   | POST   | Submits a new CPE incident              |
| `/recurring`  | GET    | Returns incident count by serial number |
| `/incidents`  | GET    | Returns all incidents as JSON           |
| `/export-csv` | GET    | Downloads all incidents as CSV          |

Auth Info (Internal Use)
Shared username: Adaptiv_user
Password: (Stored in Terraform Cloud)

Notes ---
Slack alert correlation logic can be planned
The system is modular and extensible for additional views, dashboards, or integrations

Future Enhancements ---
Slack integration for live recurring offender analysis
Partner/client dashboards
SMS/email alerting via SNS

Built by Salomon Fritz Lubin for internal operational use at Adaptiv Networks.
