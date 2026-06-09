# Creating AWS EC2 Instance from your Local System (Windows PowerShell Guide)

This guide walks you through launching an Ubuntu EC2 instance, setting up security groups, and allocating a static Elastic IP using the **AWS CLI** directly from your computer.

---

## Prerequisites
1. **AWS CLI installed**:
   - Download and run the AWS CLI MSI installer: [AWS CLI Installer](https://awscli.amazonaws.com/AWSCLIV2.msi).
   - Verify installation by opening a new PowerShell window and running:
     ```powershell
     aws --version
     ```
2. **AWS IAM Credentials**:
   - You need an AWS Access Key ID and Secret Access Key from your AWS Console (under IAM -> Users -> Your User -> Security Credentials -> Create access key).

---

## Step 1: Configure AWS CLI on your system
Run the following command to log in and set your default region:
```powershell
aws configure
```
You will be prompted to enter:
* **AWS Access Key ID**: `YOUR_ACCESS_KEY`
* **AWS Secret Access Key**: `YOUR_SECRET_KEY`
* **Default region name**: e.g., `ap-south-1` (Mumbai, recommended for India) or `us-east-1` (N. Virginia)
* **Default output format**: `json`

---

## Step 2: Create a Key Pair
Run this command to create a key pair named `ocpp-key-new` and save the private key directly as a `.pem` file on your system:
```powershell
aws ec2 create-key-pair --key-name ocpp-key-new --query "KeyMaterial" --output text > ocpp-key-new.pem
```
> **Security Note (Windows)**: You may need to restrict permission on the `.pem` file before SSH will accept it. In PowerShell, run:
> ```powershell
> Icacls .\ocpp-key-new.pem /inheritance:r
> Icacls .\ocpp-key-new.pem /grant:r "${env:USERNAME}:(R)"
> ```

---

## Step 3: Create a Security Group
Create a security group named `ocpp-backend-sg`:
```powershell
aws ec2 create-security-group --group-name ocpp-backend-sg --description "Security Group for OCPP Backend" --query "GroupId" --output text
```
This will print a Security Group ID (e.g., `sg-0123456789abcdef0`). Note this down as `<SECURITY_GROUP_ID>`.

---

## Step 4: Open Required Ports (Inbound Rules)
1. **Allow SSH (Port 22)** from anywhere (or change `0.0.0.0/0` to your public IP for better security):
   ```powershell
   aws ec2 authorize-security-group-ingress --group-id <SECURITY_GROUP_ID> --protocol tcp --port 22 --cidr 0.0.0.0/0
   ```
2. **Allow OCPP Backend (Port 9221)** for physical chargers and the web dashboard:
   ```powershell
   aws ec2 authorize-security-group-ingress --group-id <SECURITY_GROUP_ID> --protocol tcp --port 9221 --cidr 0.0.0.0/0
   ```

---

## Step 5: Launch the EC2 Instance
First, choose the Ubuntu 22.04 LTS AMI ID for your region. Common AMI IDs (as of mid-2026):
* **ap-south-1 (Mumbai)**: `ami-007020fd9c84e18c7`
* **us-east-1 (N. Virginia)**: `ami-053b0d53c279acc90`
* *To dynamically query the latest Ubuntu 22.04 AMI in your configured region, run:*
  ```powershell
  aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text
  ```

Launch a `t2.micro` or `t3.micro` instance using your key pair and security group:
```powershell
aws ec2 run-instances --image-id <AMI_ID_FROM_ABOVE> --count 1 --instance-type t2.micro --key-name ocpp-key-new --security-group-ids <SECURITY_GROUP_ID> --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ocpp-backend-server}]" --query "Instances[0].InstanceId" --output text
```
This will return an Instance ID (e.g., `i-0abcdef123456789f`). Note this down as `<INSTANCE_ID>`.

---

## Step 6: Allocate and Associate an Elastic IP (Static IP)
1. **Allocate** a static IP address:
   ```powershell
   aws ec2 allocate-address --domain vpc --query "[PublicIp, AllocationId]" --output table
   ```
   Note down the output:
   * The **Public IP** (your static IP `<NEW_AWS_IP>`).
   * The **Allocation ID** (e.g., `eipalloc-0123456789abcdef0`).

2. **Associate** the static IP with your running EC2 instance:
   ```powershell
   aws ec2 associate-address --instance-id <INSTANCE_ID> --allocation-id <ALLOCATION_ID>
   ```

---

## Step 7: Connect to your Server
Now you can SSH into your server:
```powershell
ssh -i .\ocpp-key-new.pem ubuntu@<NEW_AWS_IP>
```
Once connected, you can copy the `setup-ec2.sh` script to set up Node.js and PM2, then upload the backend folder and start the server!
