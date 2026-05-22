# AWS 3-Tier Production-Ready Architecture

This project is a Proof of Concept (PoC) demonstrating a highly available, scalable, and secure 3-tier web architecture on AWS, provisioned entirely via Terraform (Infrastructure as Code).

## Architecture Highlights
* **High Availability:** Deployed across Multi-AZs.
* **Security (Defense in Depth):** Strict public/private subnet isolation and Security Group chaining.
* **Scalability:** Auto Scaling Group behind an Application Load Balancer.