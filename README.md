﻿
<h1 align="center">
  <br>
  <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="WordPress on AWS" width="200">
  <br>
  WordPress on AWS with Terraform
  <br>
</h1>

<h4 align="center">Automate the deployment of a WordPress site on AWS using Terraform.</h4>


<p align="center">
  <a href="#introduction">Introduction</a> •
  <a href="#prerequisites">Prerequisites</a> •
  <a href="#project-structure">Project Structure</a> •
  <a href="#steps-to-deploy">Steps to Deploy</a> •
  <a href="#Best Practices for Deploying a WordPress Site on EC2">Best Practices</a> •
  


</p>

![Screenshot 2024-07-01 192113](https://github.com/zyusuf88/WordPress-deployment-on-EC2/assets/97973445/cd526f93-7c9e-4721-ac5a-68aaf565df37)

## Introduction

Welcome to the **WordPress on AWS with Terraform** project! This guide will walk you through automating the deployment of a WordPress site on AWS using Terraform. By the end, you'll have a fully functional WordPress site hosted on an EC2 instance.

> [!NOTE]
> This section covers automating the deployment of WordPress on an EC2 instance using Terraform. By using Infrastructure as Code (IaC), we can streamline and replicate the deployment process with ease. If you'd like to see how this was done manually before being automated, click **[HERE](https://github.com/zyusuf88/WordPress-on-AWS-EC2)**
1. **Provider Configuration:** Sets the AWS region to "eu-west-1".
2. **VPC:** Creates a Virtual Private Cloud (VPC) for network isolation.
3. **Subnet:** Defines a subnet within the VPC.
4. **Internet Gateway:** Provides internet access to the VPC.
5. **Route Table:** Configures routing for the subnet to use the internet gateway.
6. **Security Group:** Sets up firewall rules to allow HTTP, HTTPS, and SSH traffic.
7. **Key Pair:** Generates and manages an SSH key pair for EC2 access.
8. **AMI Lookup:** Fetches the latest Bitnami WordPress AMI.
9. **EC2 Instance:** Deploys an EC2 instance using the fetched AMI, within the defined subnet and security group.

## Prerequisites

Before you begin, ensure you have the following:

- An **AWS account**
- **Terraform** installed on your local machine
- **AWS CLI** configured with your credentials

> [!TIP]
> Ensure your AWS CLI is configured with appropriate access to create resources like VPCs, subnets, EC2 instances, and security groups.

## Project Structure

The project is organized into several key files:

- `main.tf`: Core infrastructure components
- `variables.tf`: Input variables
- `output.tf`: Output values

### `main.tf`

The `main.tf` file defines the core infrastructure components using Terraform's HCL (HashiCorp Configuration Language). Here's a breakdown:

1. **Provider Configuration**

- This specifies the AWS provider and sets the region to eu-west-1:

```hcl
provider "aws" {
  region = "eu-west-1"
}

```

-  Defines a VPC with a specified CIDR block (var.vpc_cidr), enables DNS support and hostnames, and assigns tags for identification:
   
``` hcl
resource "aws_vpc" "wordpress_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "WordPress-VPC"
  }
}
```


- Creates a subnet within the VPC defined earlier, specifying its CIDR block and availability zone:

```hcl
resource "aws_subnet" "wordpress_subnet" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "WordPress-subnet-01"
  }
}

```

-  Sets up an internet gateway for the VPC to enable internet access for resources within the VPC:


```hcl
resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress_vpc.id

  tags = {
    Name = "WordPress-AWS-Internet-Gateway"
  }
}
``` 
- Define a security group with rules to allow HTTP, HTTPS, and SSH traffic:
  
```hcl
resource "aws_security_group" "wordpress_sg" {
  vpc_id = aws_vpc.wordpress_vpc.id

  name        = "wordpress_sg"
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress_sg"
  }
}
```


- Defines a route table that directs all traffic (0.0.0.0/0) to the internet gateway for egress traffic:

```hcl
resource "aws_route_table" "wordpress_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_igw.id
  }

  tags = {
    Name = "WordPress-AWS-Route-Table"
  }
} 

```
- Generates an RSA key pair and creates an AWS key pair:
  
```hcl 
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "wordpress_key" {
  key_name   = "wordpress_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "wordpress_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "wordpresskey.pem"
}
```

### The `data "aws_ami" "wordpress"` block in Terraform is used to look up the Amazon Machine Image (AMI) for deploying a WordPress instance. Here's  what each part of this block does:
- Using AWS AMI Data Source: The `aws_ami `data source fetches the most recent AMI provided by the specified owner.
- Filtering AMIs: By **name**, to match the specific Bitnami WordPress image version.
- By **root-device-type**, ensuring the AMI uses Elastic Block Store (EBS).
- By **virtualization-type,** to select Hardware Virtual Machine (HVM) images.



```hcl 

data "aws_ami" "wordpress" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["bitnami-wordpress-6.5.4-2-r02-linux-debian-12-x86_64-hvm-ebs-nami-7d426cb7-9522-4dd7-a56b-55dd8cc1c8d0"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```
> [!NOTE]
> This filter searches for AMIs that match the exact name provided. 
> The name `"bitnami-wordpress-6.5.4-2-r02-linux-debian-12-x86_64-hvm-ebs-nami-7d426cb7-9522-4dd7-a56b-55dd8cc1c8d0"` identifies a specific version of the Bitnami WordPress AMI.

> [!TIP]
> This filter ensures that the AMI uses **Amazon Elastic Block Store (EBS)** for its root device.
> EBS-backed instances can be stopped and restarted without losing data stored on the EBS volume.
> By using this AMI lookup, we ensure that our WordPress site is always deployed on the latest and most secure image available from Bitnami.


By using the AMI lookup, the deployment becomes more flexible and can automatically adapt to new versions of the WordPress AMI, ensuring the latest updates and security patches are applied without manual intervention.


### variables.tf
- The `variables.tf` file specifies the variables used in the `main.tf` file.

```hcl
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

```
-  Defines a variable vpc_cidr with a default value representing the CIDR block for the VPC.
### output.tf

The `output.tf` file defines outputs that can be queried after deployment:

```hcl 
output "wordpress_public_ip" {
  value = aws_instance.wordpress.public_ip
}
```
-  Specifies an output to retrieve the public IP address of the WordPress instance deployed.

## Steps to Deploy

1. Initialize Terraform:

`terraform init` Initializes Terraform, downloading necessary providers and initializing the backend.

2. Plan the Deployment:

`terraform plan` Creates an execution plan showing what actions Terraform will take.

![Screenshot 2024-07-01 174337](https://github.com/zyusuf88/WordPress-deployment-on-EC2/assets/97973445/daaab1d0-2035-4a4b-b18c-f4b79993ccc0)

3. Apply the Deployment:

`terraform apply` Applies the changes required to reach the desired state of the configuration.

4. Retrieve the Public IP:

After deployment, retrieve the public IP address of the WordPress instance:

`terraform output wordpress_public_ip`

5. Retrieving the Public IP:

After deployment, use `terraform output wordpress_public_ip` to retrieve the public IP address of your WordPress instance.

![Screenshot 2024-07-01 192113](https://github.com/zyusuf88/WordPress-deployment-on-EC2/assets/97973445/81054996-cbd8-4c09-bcfb-718747870b78)

### Cleanup
To destroy the infrastructure created by Terraform, use:
`terraform destroy`



    
## Best Practices for Deploying a WordPress Site on EC2
- **Use the Latest AMI:** Always fetch the latest AMI to ensure security patches and updates are included.
- **VPC and Subnets:** Properly configure VPC and subnets to segment your network and improve security.
- **Security Groups:** Define strict security group rules to limit access to necessary ports (HTTP, HTTPS, SSH).
- **Key Management:** Use secure key management practices, such as storing private keys securely and rotating keys regularly.
- **Auto-scaling and Load Balancing:** Consider using Auto Scaling Groups and Load Balancers for high availability and scalability.
- **IAM Roles and Policies:** Use IAM roles and policies to manage permissions securely and follow the principle of least privilege.
