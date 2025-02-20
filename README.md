# AWS Text-to-Speech Converter

> **Convert text into natural-sounding speech using AWS Polly, Lambda, and S3.**

## 📖 Overview

The **AWS Text-to-Speech Converter** is a serverless application leveraging **AWS Polly** for text-to-speech synthesis, **AWS Lambda** for processing, and **Amazon S3** for storage. This project allows users to convert input text into high-quality speech and store the output for easy access and playback.

## 🚀 Features

- **AWS Polly Integration** – Generate realistic speech from text in multiple languages and voices.
- **Serverless Architecture** – Powered by AWS Lambda, eliminating the need for dedicated servers.
- **Cloud Storage** – Outputs are stored in Amazon S3 for easy retrieval and playback.
- **Web Interface** – Interact with the service directly from a browser.
- **Scalable & Cost-Effective** – Pay-as-you-go pricing model with AWS services.

## 🛠️ Architecture

🔹 **AWS Lambda** – Handles incoming text and triggers Polly for speech synthesis.<br>
🔹 **AWS Polly** – Converts the text input into an audio file.<br>
🔹 **Amazon S3** – Stores the generated speech files for later access.<br>
🔹 **Amazon API Gateway** – Provides an endpoint for users to submit text for conversion.<br>
🔹 **AWS CloudFront (Optional)** – Speeds up content delivery for improved performance.<br>
🔹 **S3 Static Website Hosting** – Hosts the frontend UI for user interaction.<br>

## 🏗 Prerequisites

Before deploying this solution, ensure you have:

- ✅ An **AWS Account** with permissions to use Polly, Lambda, API Gateway, and S3.
- ✅ **AWS CLI** installed and configured.
- ✅ **Terraform** installed (if using Infrastructure as Code deployment).
- ✅ **Python** installed (if running scripts locally).

## 🚀 Deployment Instructions

### 1️⃣ **Clone the Repository**
```bash
git clone https://github.com/Judewakim/text-to-speech.git
cd text-to-speech
```

### 2️⃣ **Create and Configure the Terraform Script**
1. Open the `main.tf` file and define the necessary AWS resources, including:
   - An S3 bucket for storing speech files and hosting the frontend UI.
   - An AWS Lambda function that uses Polly to generate speech.
   - An API Gateway to expose the backend service.
   - IAM roles and policies granting Lambda access to Polly and S3.
2. Adjust variables and configurations as needed to fit your AWS setup.

### 3️⃣ **Deploy the Infrastructure Using Terraform**
```bash
terraform init
terraform plan
terraform apply
```
Confirm the deployment when prompted.

### 4️⃣ **Test the Deployment from the Web Interface**
1. Open your browser and navigate to the **S3 Static Website Hosting URL** displayed in the Terraform output.
2. Enter text in the provided input field and submit it for conversion.
3. The generated speech file will be available for download or playback directly from the browser.

## 🗑 Cleanup

To remove all deployed resources, run:
```bash
terraform destroy
```

Or manually delete the Lambda function, API Gateway, S3 bucket, and associated AWS resources.

## 📚 References

📌 [AWS Polly Documentation](https://docs.aws.amazon.com/polly/)<br>
📌 [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)<br>
📌 [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/)<br>
📌 [Amazon API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)

---

💡 **Happy Building! 🎙️**

