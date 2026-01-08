# Terraform AWS Infrastructure

This repository contains Terraform configurations for setting up AWS networking infrastructure

## Infrastructure Components

This Terraform configuration creates:

- **VPC** with DNS support and hostnames enabled
- **3 Public Subnets** across 3 availability zones
- **3 Private Subnets** across 3 availability zones
- **Internet Gateway** for public internet access
- **Route Tables** (public and private)
- **Route Table Associations** connecting subnets to route tables

## Created Github Actions to check terraform code fromatting and validation ...