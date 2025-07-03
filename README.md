# Adaptiv Device Incident Management – Architecture & Implementation

**The Adaptiv Device Incident Management (DIM) app** is designed as a digital logbook for support engineers to track device-related incidents over time. The goal is to easily record each incident, then later review the history for recurring issues that might need a deeper fix. This document provides a high-level overview of how the app is built – covering its web front-end, AWS cloud backend, and the Terraform Cloud infrastructure-as-code setup – as well as what’s currently missing and next steps for completion. The focus is on understanding the architecture and promoting good DevOps practices (like using Terraform Cloud for Infrastructure as Code) that are especially beneficial for a small company like Adaptiv.

![image](https://github.com/user-attachments/assets/6f81b32f-ae3c-47a4-a877-e508f83f371c)

![image](https://github.com/user-attachments/assets/d3b46731-f98a-47f3-930b-67e7a3a7367e)

## 🎯 App Purpose and Key Features

* **Incident Logbook:** The core function is to allow support engineers to create incident entries for devices. Each entry might include details like device identifier, date/time, issue description, resolution status, etc. Over time, this builds a knowledge base of incidents.
* **Search & Analysis:** With incidents recorded, engineers can retrieve and review past incidents. This helps in spotting recurring problems – for example, if a certain device model or error keeps appearing, it flags a need for a permanent fix.
* **Simple UI for Engineers:** The app provides a straightforward web interface (the “CPE Tracker” web app) where engineers can input new incidents and query existing ones. It’s essentially a simple form and a list/report of incidents – a user-friendly tool rather than a complex system.
* **Export & Reporting:** One planned feature is the ability to export incidents (e.g. as CSV) for reporting. There is also a notion of identifying “recurring offenders” – possibly a function to automatically analyze the data and highlight frequently recurring issues.

By starting with these capabilities, Adaptiv gets an immediate benefit: a historical incident log to drive proactive device improvements. Now let’s see how this is implemented under the hood.

## 🖼️ Architecture Overview

At a high level, the DIM app follows a **serverless web application architecture** on AWS. The main pieces are:

* **Frontend:** A static web app (HTML/CSS/JS) that runs in the browser. This provides the user interface for logging and viewing incidents.
* **Backend:** A set of AWS Lambda functions (written in Python) that implement the app’s logic – creating new incident records, fetching all incidents, analyzing recurring issues, and exporting data.
* **Data Storage:** A persistent store for incident data built on AWS DynamoDB table where the incident records will be saved and queried.
* **Infrastructure:** AWS cloud services set up via Terraform Cloud. This includes an S3 bucket for hosting the frontend, Amazon CloudFront for content delivery (with a custom domain and SSL), an AWS API endpoint (to invoke the Lambda functions), and supporting resources like AWS ACM for SSL certificates and Route53 for DNS.

The flow works like this:

1. **User accesses the web app:** The support engineer opens the incident tracker web page in their browser. The static site is served from an Amazon S3 bucket (through CloudFront, which provides a fast, secure CDN and a custom domain).
2. **Logging an incident (Frontend to Backend):** When the engineer fills out the incident form and submits, the frontend JavaScript (`app.js`) will send the incident data to a backend API request to Amazon API Gateway that triggers the appropriate Lambda function (e.g., `create_incident`).
3. **Lambda processes the request:** The `create_incident` AWS Lambda function receives the data and will save the new incident record in the database. Similarly, when the frontend needs to list incidents or generate a report, it will call other Lambdas (`get_all_incidents`, `recurring_offender`, `export_csv`) which will read or analyze data from the database.
4. **Data storage:** Amazon DynamoDB will to hold all incident records. There will be 2 tables, "Devices" and "Incidents". Each Lambda function would interact with this database (for example, `create_incident` would put a new item into the incidents table, `get_all_incidents` would scan or query the table, while the devices table stores all devices that have evr recorded an incident).
5. **Responses back to frontend:** After a Lambda function completes (e.g., incident created or data fetched), it returns a response. The frontend app receives this and can update the UI – for example, showing a success message, refreshing the incident list, or prompting a download of a CSV file.

This architecture is cloud-native and scales with demand. If many incidents are logged at once, AWS Lambdas can scale out, and the static frontend can handle concurrent users easily via CloudFront. There are no servers to manage, which keeps operational overhead low.

## 🌐 Frontend: Static Web App on S3/CloudFront

The **cpe-tracker webapp frontend** is a static website (HTML, CSS, JavaScript) that provides the user interface. Because the frontend is static, it doesn’t rely on any server-side rendering – it’s delivered via CDN, then runs entirely in the user’s browser, communicating with backend services via JavaScript.

**Hosting & Delivery:** The static files are stored in an **Amazon S3 bucket** (configured for web hosting). However, direct access to the S3 bucket is restricted – instead, an **Amazon CloudFront distribution** sits in front. 

**DNS:** The domain can be purchased via Amazon Route 53 for DNS. A hosted zone for the domain is managed via Terraform, and DNS records are created to point the custom domain (and perhaps a “www” subdomain) to the CloudFront distribution. The outputs from Terraform even include the CloudFront distribution domain name and the website URL for reference. For example, after deployment an output called “website\_url” might be `"https://<your-domain-name>"`, which confirms the front-end will be accessible via a friendly URL, secured with HTTPS.

In summary, the frontend is a static single-page app, hosted on S3 and accelerated by CloudFront, providing a simple interface for the DIM logbook.

## 🖥️ Backend: Python Lambda Functions on AWS

On the backend, the app uses **AWS Lambda** to run code on-demand in response to HTTP requests. The repository defines **four Python Lambda functions** that correspond to the main use cases:

1. **`create_incident`** – Takes incident details (from the frontend form) and creates a new incident record in the data store. It likely validates the input and then saves a new item (e.g., putting an item into a DynamoDB table). This function returns a status (success/failure) and perhaps the ID of the created record.
2. **`get_all_incidents`** – Retrieves all incident records (or perhaps recent ones) from the data store. The frontend can call this to populate the incident log table on the UI. The function probably reads from the DynamoDB table (scan or query) and returns a JSON list of incidents.
3. **`recurring_offender`** – Analyzes the incidents to identify patterns – for example, it might scan the records to find devices or issues that occur repeatedly above a certain threshold. This could return a summary (e.g., “Device X had 5 similar incidents in last month”). Engineers could run this analysis on demand to proactively spot problem devices. (This might be invoked via the UI or possibly as an automated periodic job in the future.)
4. **`export_csv`** – Gathers all incidents (perhaps similar to get\_all\_incidents) but formats the data as a CSV file. The Lambda likely generates a CSV content string and returns it (possibly as a Base64 or a presigned URL). The frontend would then prompt the user to download this CSV file. This makes it easy to pull the logbook into Excel or other reporting tools.

In the repo, the Lambda function code resides in the **`cpe-tracker-webapp/backend`** directory. The project uses a build script to package this code:

* A Terraform **null resource** (`null_resource.lambda_build`) runs a `build.sh` script to zip up the Python code for each function. For instance, for `create_incident`, the script would package `create_incident.py` (and its dependencies) into `create_incident.zip`. Terraform then points the Lambda function resource to this zip file. We see this pattern in the Terraform code for the Lambda module, where the `aws_lambda_function` definitions reference ZIP files like `create_incident.zip`, `get_all_incidents.zip`, etc., in a backend folder. To ensure smooth Terraform runs, the code uses a trick: the Lambda’s `source_code_hash` is tied to the build process trigger rather than a fixed file hash (since the zip file might not exist until built). This ensures Terraform knows when to update the Lambdas (by detecting code changes via a computed hash).
* Each Lambda function has an IAM role (with permissions to write to DynamoDB, CloudWatch logs, etc.) defined in Terraform (necessary for them to function). They also have configuration like memory size, timeouts, etc., which can be tuned as needed.

**API Integration:** Currently, this is one of the *“missing pieces”* to be implemented. In the final architecture, expose the Lambda functions via a REST API or HTTP API:

* Using Amazon API Gateway to define endpoints like `/createIncident`, `/getIncidents`, etc., each tied to the respective Lambda. The frontend would call these endpoints via HTTPS.
* Alternatively, AWS’s newer **Lambda Function URLs** could be used (each Lambda can have a direct URL - however I do not have the right experience or expertise to fully endorse this, please consider this). This might simplify things by avoiding an API Gateway, though it’s less flexible for a multi-function API. Currently, no Lambda function URL or API Gateway is defined (as confirmed by the absence of any `aws_apigateway` resources in the Terraform code).

So, for now, think of the backend as “ready to go” code-wise, but waiting to be wired up to HTTPS endpoints. The team can test Lambdas individually, but the front-to-back integration will be completed by adding an API layer.
 
* **Amazon DynamoDB**: A serverless NoSQL database which fits this use-case well (incident records can be stored as items with a device ID or incident ID as primary key, etc.). DynamoDB will scale automatically and requires no maintenance.

**Logging & Monitoring:** Every Lambda writes logs to Amazon CloudWatch by default (e.g., logging any errors or debug info). Terraform can define CloudWatch log groups for these or let AWS create them on first run. In the future, we might set up CloudWatch Alarms or AWS X-Ray for monitoring the performance of these functions. For now, basic logging is likely in place (the Python functions would use `print` or logging, and CloudWatch will record that).

In essence, the backend is a set of microservices (each Lambda is a microservice function) that together provide the needed operations for the incident app. This approach keeps the back-end **scalable** (each function can scale independently) and **cost-efficient** (you pay only for actual usage of functions). It’s also easier to develop and maintain – each function has a single responsibility.

## ⚙️ Infrastructure as Code with Terraform Cloud (IaC)

One of the standout aspects of this project is that all the infrastructure (S3 bucket, CloudFront, DNS, Lambdas, etc.) is defined using **Infrastructure as Code (IaC)**, specifically Terraform. Moreover, this brings a lot of benefits for a small team aiming to adopt DevOps best practices.
**Terraform Code Structure:** Under `cpe-tracker-webapp/terraform`, the code is organized into reusable modules for clarity:

* `modules/s3_frontend`: likely contains Terraform for the S3 bucket that hosts the frontend. This would include the bucket resource (with appropriate settings like static website hosting or access policies) and maybe an output for the bucket domain name. It was updated in commit history (e.g., on commit 8359bcf) indicating adjustments to the S3 setup.
* `modules/cloudfront`: contains Terraform for the CloudFront distribution and related resources (ACM certificate, Route53 DNS, etc.). We saw in the initial creation that it sets up the ACM cert in us-east-1 and a Route53 hosted zone using a `domain_name` variable. It also defines the CloudFront distribution that points to the S3 bucket and uses an origin access control. Outputs from this module provide info like the distribution ID, distribution domain, and name servers for the DNS zone.
* `modules/lambda`: contains Terraform for deploying the Lambda functions. This includes packaging (the `build.sh` we discussed), the four `aws_lambda_function` resources (create\_incident, get\_all\_incidents, recurring\_offender, export\_csv) and likely IAM role definitions and any triggers. The code shows multiple Lambda resources defined – one can see references to each function name in the Terraform diff (e.g., `aws_lambda_function "create_incident"` and others). This module will be expanded to include API Gateway integration in the future (currently, it focuses on the Lambdas themselves).

Above these modules, there is probably a root module (perhaps in `cpe-tracker-webapp/terraform/main.tf`) that instantiates each module. For example, it would pass in the domain name and bucket name to the CloudFront module, and pass the necessary configurations to the Lambda module. Although we haven’t directly viewed the root configuration, the existence of these modules and variables suggests this layering.

**Terraform Cloud Usage:** Terraform Cloud is HashiCorp’s managed service for Terraform, and using it brings several advantages to Adaptiv:

* *Remote State Management:* Terraform Cloud keeps the state file (which records what infrastructure is provisioned) on a remote backend, safely stored and versioned. This prevents the classic “state file conflicts” and allows team members to collaborate without worry. It also locks the state during runs to avoid overlaps.
* *Automated Runs (CI/CD for Infra):* When connected to the VCS (e.g., GitHub), any commit to the repo can trigger a Terraform plan/apply in Terraform Cloud. This means infrastructure changes go through code review and then are applied consistently. For instance, if someone updates a variable or adds a DynamoDB resource in code, Terraform Cloud will plan and show the changes, then an engineer can approve and apply. This is much safer than manual click-ops in the AWS console.
* *Collaboration and Governance:* Even as a small team, it’s good to have audit trails and collaboration. Terraform Cloud offers role-based access control and policy checks. Everyone sees a log of what was changed, when, and by whom, which is great for transparency and debugging. It essentially treats infrastructure the same way as application code – enabling **GitOps for infrastructure**.
* *Consistency and Reusability:* With everything in code, setting up a new environment (say a staging environment) would be as simple as re-running the Terraform in a new workspace with different variables. This consistency ensures that development, staging, and production could be nearly identical – preventing “it works on my environment” issues.
* *Productivity and Velocity:* Adopting IaC early saves time in the long run. Terraform automates creating and configuring AWS resources, so engineers spend less time clicking around and more time developing features. In general, **automating infrastructure with IaC improves productivity, reduces risk, and increases business velocity**. In a small company, this means you can do more with a lean team, and avoid mistakes that come from manual setup.

For Adaptiv, using Terraform Cloud and IaC is a forward-looking choice. It instills good DevOps habits (version control for infrastructure, code reviews for changes, easy rollback, etc.) and will make scaling the infrastructure or onboarding new engineers much easier.

By addressing the above, the Adaptiv DIM app will go from a mostly-functional prototype to a production-ready system. Each next step can be implemented iteratively, with Terraform making the infrastructure changes low-risk and trackable.

## 📝 Conclusion

In summary, the Adaptiv Device Incident Management application is a modern, serverless web app aimed at making the life of support engineers easier through a centralized incident log. It uses a static **React-less** frontend (just HTML/JS) for simplicity, and leverages powerful AWS managed services on the backend – all glued together by Terraform Cloud-managed infrastructure as code.

for a simpler summary - 
https://salomoncloud.github.io/Adaptiv-Device-Incident-MGMT/

## STEP-BY-STEP GUIDE TO IMPLEMENTATION

**Connecting Terraform Cloud, AWS, and Github**

Navigate to AWS and navigate to security credentials. 

![image](https://github.com/user-attachments/assets/a7ceb17d-04f5-4b1b-a346-0f1498c505b7)

Create and Save an Access key (the secret and its ID - store this securely and save it as this will connect your AWS account to terraform).

Next, go to the HCP Terraform login page and either create an account or login (sign in using your Github account when prompted).

![image](https://github.com/user-attachments/assets/1fc5a045-4c1f-4e19-91eb-d59114b68116)

Create a Terraform organization (there are business plans and the free tier personal plan - make sure name is unique).

![image](https://github.com/user-attachments/assets/5cbf06ed-a7fc-4a99-9da0-b9196d43288b)

After you have an organization created, create a project.

![image](https://github.com/user-attachments/assets/5fba4735-bdc5-4f1e-96d1-168d9739a393)
![image](https://github.com/user-attachments/assets/8eb48b9f-c8c6-4823-9140-fec69edb4da8)

Once created, click on the "New" dropdown menu and create a workspace, name this accordingly.

![image](https://github.com/user-attachments/assets/33cf805b-4b75-4d14-859d-46c4d26cb904)

You will need to select **Version Control Workflow**, followed by **Github App**, select your repo, and create.

![image](https://github.com/user-attachments/assets/918a9e45-047f-4e11-be1b-1cc954f30df0)

Once everything here is set up, you will need to add the access key and ID as shown below to the variables section in you're Terraform workspace settings.

![image](https://github.com/user-attachments/assets/fe9f8b8e-5cd0-4a90-aeca-784e6fcd3d4f)

The variables need to be marked as sensitive, and as terraform environment variables. 

![image](https://github.com/user-attachments/assets/b1f1d838-81e2-47bf-be83-cf81feedb3f7)

Once this is all complete, run a test **plan run** to validate that you see a successful plan. 

![image](https://github.com/user-attachments/assets/ba5b85f6-9218-418d-8e49-5041ac22654e)

Common issues in this step include keys that were not properly pasted (errors in pasting) or the directory structure not being properly indicated for Terraform (navigate to General settings in Terraform cloud and scroll down).
