# AWS 3-Tier Production-Ready Infrastructure via Terraform

This repository contains the Infrastructure as Code (IaC) configuration for a secure, highly available, and resilient 3-Tier web architecture deployed on AWS using Terraform. The architecture is engineered following enterprise cloud design principles, strictly avoiding "ClickOps" and shifting security left.

## 🛠️ Architecture Blueprint & Core Components

The infrastructure is logically separated into three isolated layers across multiple Availability Zones (Multi-AZ) in the `eu-central-1` (Frankfurt) region to guarantee fault tolerance and high availability.

*   **Presentation Tier (Network Interface):** Public-facing Application Load Balancer (ALB) distributed across 2 Public Subnets. It handles incoming traffic, performs SSL/TLS termination routing, and acts as the first line of defense.
*   **Application Tier (Compute):** Multi-AZ Auto Scaling Group (ASG) hosting dynamic EC2 instances inside isolated Private Subnets. Instances spin up or down automatically based on demand and are fully self-healing.
*   **Data Tier (Storage):** Production-grade PostgreSQL database deployed via Amazon RDS in Multi-AZ configuration across dedicated Data Subnets. The tier is completely dark, lacking any route to the internet.

---

## 🚀 Case Study: The Engineering Journey (STAR Method)

### 📌 Situation
To support the digital migration of legacy systems—such as the **Medresa Digital Guide (Kırmızı Medrese)** web application—there was a critical business requirement to transition from local development stacks to a cloud-native architecture. The target environment needed to ensure zero single points of failure, handle traffic spikes without manual intervention, secure sensitive user data, and eliminate manual cloud configuration anomalies ("Configuration Drift").

### 🎯 Task
My objective was to architect and provision a production-ready, fully automated 3-Tier infrastructure on AWS using Terraform. The platform had to comply with rigorous corporate compliance standards:
1. Complete isolation of the data layer from public networks.
2. Dynamic scaling of compute resources inside private zones.
3. Asymmetric, decoupled credential management avoiding hardcoded secrets.
4. Resilience against data center outrages (Availability Zone failure) without data loss.

### ⚡ Action (Architectural Decisions & Implementation)
*   **Network Segregation:** Designed a custom VPC (`10.20.0.0/16`) spanning two Availability Zones (`eu-central-1a` and `eu-central-1b`). Provisioned 6 distinct subnets (2 Public, 2 Private, 2 Data). Configured asymmetric routing tables; Data Subnets utilize only local routes, ensuring complete public invisibility.
*   **Security Chaining (Firewall Topology):** Implemented a zero-trust network model via strict Security Group Chaining. The ALB Security Group allows inbound HTTP/HTTPS from anywhere. The EC2 Security Group drops all traffic except requests originating specifically from the ALB's Security Group ID. The RDS Security Group strictly accepts traffic only from the EC2 application instances over port 5432.
*   **Immutable Infrastructure & Compute Automation:** Created an auto-managed server tier utilizing AWS Launch Templates and Auto Scaling Groups. Used dynamic Terraform Data Sources (`aws_ami`) to automatically fetch the latest, fully patched Amazon Linux 2023 images at runtime, avoiding stale machine images.
*   **Enterprise Secret Management & Multi-AZ RDS:** Leveraged Terraform's `random_password` provider to generate a cryptographically strong, 16-character database password. Provisioned an **AWS Secrets Manager** vault to secure these credentials out-of-code. Configured the RDS instance with `multi_az = true` to enable synchronous replication across two separate data centers, ensuring active-passive failover mechanisms.

### 🏆 Results & Business Impact
*   **High Availability & Fault Tolerance:** Validated data center failover. Simulating a complete availability zone outage proved that the ALB gracefully reroutes active connections to surviving infrastructure in adjacent zones with zero application downtime.
*   **Shift-Left Security Compliance:** Zero hardcoded credentials exist within the source code repo, mitigating credential leak risks. Database endpoints are strictly inaccessible from outside the internal VPC network perimeter.
*   **Idempotency & Maintainability:** The entire environment can be completely provisioned, updated, or destroyed within minutes via standard IaC lifecycles (`terraform plan/apply`), providing rapid feedback loops and predictable cost control ($0 waste when idling).

---

## 📂 Project Directory Structure

```text
3-tier-aws-architecture/
├── .gitignore           # Excludes local state files (.tfstate) and .terraform cache
├── README.md            # Architectural documentation and project vitrine
├── provider.tf          # AWS Provider and version lock settings
├── variables.tf         # Centralized variables, region, and CIDR blocks
├── vpc.tf               # VPC, Subnets, IGW, NAT Gateway, Route Tables
├── security.tf          # Tiered Security Group Chaining rules
├── compute.tf           # Launch Template, Auto Scaling Group, AL2023 Data Source
├── alb.tf               # Application Load Balancer, Listeners, Target Group
└── rds.tf               # Multi-AZ PostgreSQL Instance and AWS Secrets Manager integration