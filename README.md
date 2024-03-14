# Fast & Secure Microservices on Kubernetes with IaC

This project delivers a streamlined IaC (Infrastructure as Code) approach for deploying a microservices application on Kubernetes, prioritizing:

1. Fast Deployments: Automate infrastructure and application deployment for swift rollouts.
2. Easy Maintenance: Prioritize clear, modular code for future modifications.
3. DevOps Integration: Align with DevOps principles through IaC practices.

## Tech Stack
Microservices Architecture, Kubernetes, Terraform (IaC), Prometheus (Monitoring)

This document details the technical aspects, including: Deploy Pipeline, Metrics & Monitoring, Logging, and Terraform Configuration. This IaC approach and technology stack empower us to achieve rapid, secure microservices deployments!

## EKS Cluster with Terraform on AWS

This document describes the infrastructure components and configuration files used to manage an EKS cluster and deployments on AWS with Terraform and Jenkins.

### EKS Cluster Configuration with Terraform

The Terraform configuration files are organized into several directories, each containing definitions for specific resources:

1. **Variable Files** 
   - `version.tf`: Specifies the required Terraform version and AWS provider version.
   - `genericvariables.tf`: Defines input variables for region, environment, business division, etc.
   - `localvalues.tf`: Sets local values based on input variables, including names and tags.
   - `vpc-variables.tf`: Defines VPC configuration variables (CIDR block, subnets, etc.).
  
2. **VPC Module**
   - `vpcmodules.tf`: Defines a Terraform module for creating a VPC using the terraform-aws-modules/vpc module.
   - `vpcoutputs.tf`: Outputs information about the VPC (ID, CIDR block, subnet IDs, etc.).
  
3. **Bastion Host**
   - `bastion-variables.tf`: Contains outputs from the bastion host module (IP addresses, etc.).
   - `bastion.sg.tf`: Defines a Terraform module for creating a security group for the bastion host with SSH access.
   - `ami-datasource.tf`: Finds the latest Amazon Linux 2 AMI using the aws_ami data source.
   - `bastion-outputs.tf`: Outputs bastion host instance IDs and Elastic IP address.
   - `bastion.ec2instance.tf`: Defines a Terraform module for creating a bastion host EC2 instance with SSH access in a public subnet.
   - `bastion-elastic-ip.tf`: Creates an Elastic IP for the bastion host dependent on the VPC and bastion instance modules.
   - `ec2-bastion-provisioner.tf`: Defines a null resource with provisioners for configuring the bastion host (SSH access, file copy, etc.).
  
4. **EKS Cluster**
   - `eks-variables.tf`: Defines EKS cluster name, Kubernetes version, service CIDR block, and endpoint access configurations.
   - `eks-outputs.tf`: Outputs information about the EKS cluster (ID, ARN, endpoint, IAM roles, etc.).
   - `iamrole-eks.tf`: Creates an IAM role for the EKS control plane with access to AWS services for EKS management.
   - `iamrole-nodegroup.tf`: Creates a separate IAM role for Node Groups with policies for worker nodes to communicate with the API server, manage ENIs, and pull container images.
   - `eks-cluster.tf`: Creates the EKS cluster using defined variables, IAM roles, VPC configuration, and cluster logging settings.
  
5. **Node Groups**
   - `node-grp-pub.tf`: Creates a public EKS Node Group with details about the cluster, IAM role, subnet placement, instance type, AMI, SSH access, and desired capacity with scaling rules.
   - `eks-node-grp-priv.tf`: Defines a private EKS Node Group configuration similar to the public group but uses private subnets for worker node placement.
  
6. **Auto-Configuration Files**
   - `.auto.tfvars` and `terraform.tfvars`: Define default values for variables used in the Terraform configuration.

### Kubernetes Resources with Terraform

Directories within the `kubernetes` folder contain Terraform configurations for managing deployments and services on the EKS cluster.

1. **ingress-rule**
   - `ingress.yaml`: Defines an Ingress resource for Grafana in the monitoring namespace using the external-nginx Ingress controller.
   - `micro.tf`, `prome.tf`: Define Terraform resources for creating Ingress rules named sock-shop and prometheus-grafana using the nginx Ingress class controller.
   - `voting.tf`: Sets up two Ingress rules for voting-app and result-service using an Nginx ingress controller.
   - `provider.tf`: Defines Terraform providers for managing Kubernetes resources, Helm charts, and interacting with the EKS cluster using kubectl.

2. **micro-service**
   - `cart.tf`, `catalogue.tf`, `front-end.tf`, etc.: Define separate deployments and services for different components of the Sock Shop application (cart, catalogue, front-end, etc.).
   - `micro-provider.tf`: Sets up the Kubernetes provider configuration for interacting with the EKS cluster.
   - `orders.tf`, `payment.tf`, etc.: Manage deployments and services for other functionalities within the Sock Shop application (orders, payment, queue-master, etc.).
   - `rabbitmq.tf`: Provides a message queue and messaging broker for communication between services using RabbitMQ.
   - `session-db.tf`: Deploys a Redis instance for storing session data.
   - `shipping.tf`: Handles order fulfillment and shipping logic within the Sock Shop application.
   - `user.tf`: Manages user accounts and interacts with a separate User Database.

### Multi-Deployment Automation with Jenkins

The `cluster-jenkinsfile` defines a pipeline with two options: create or destroy. Based on the chosen option, the pipeline executes the corresponding stage, utilizing Terraform commands to interact with AWS and provision the EKS cluster. Security is a priority, so we ensure the AWS credentials used have minimal permissions.

### Nginx Ingress Controller on EKS with Terraform

This guide walks you through configuring the Nginx Ingress Controller to manage external traffic for your applications deployed on an EKS cluster created with Terraform.

#### Helm to the Rescue

I leverage Helm charts to deploy the Nginx Ingress Controller. Terraform waits patiently for the EKS cluster to be available before we proceed. I create a dedicated namespace (`nginx-ingress`) to house the controller deployment. Helm values are used to configure various settings:
   - Deployment name: `load` (I customize the name using `fullnameOverride`)
   - Controller name: `nginx` - straightforward, right?
   - Service type: `LoadBalancer` for external world access
   - Pod Security Policy: Enabled for enhanced security - gotta be secure!
   - Persistent volumes: Disabled for the controller (we don't need them here)
   - Resource requests/limits: Defined for CPU and memory of Nginx pods (ensuring proper resource allocation)

#### Provider Powerhouse

Terraform defines providers to interact with different resources:
   - `helm`: Manages Helm charts, including deploying the Nginx Ingress Controller.
   - `kubernetes`: Talks directly to the Kubernetes API server.
   - `kubectl`: Enables me to interact with the Kubernetes cluster using the command line (powerful stuff).
   - `aws`: Fetches information about the EKS cluster from AWS services.

#### Going Deeper values.yaml 

This file defines configurations for the Nginx Ingress Controller, such as:
   - Ingress annotations: Additional metadata or options for Ingress resources.
   - External traffic policy: How the controller handles traffic targeting backend services not accessible from the internet.
   - Additional resources: Might configure RBAC (Role-Based Access Control) for the controller to access necessary Kubernetes resources.

#### Variable Magic

I define two variables used within the Nginx ingress controller configuration:
   - `domain_name`: Stores the primary domain name for the application (default: "awspro.com.ng").
   - `alt_domain_name`: Stores an alternative domain name the controller should recognize (default: "*.awspro.com.ng").
   These variables are likely referenced in the `values.yaml` file to configure the Ingress controller.

#### Routing the Way

The Nginx Ingress Controller is responsible for routing traffic arriving at the defined domain names to the appropriate backend services within your application running on Kubernetes. In essence, this configuration leverages Terraform and Helm to deploy the Nginx Ingress Controller and orchestrate external traffic for your EKS cluster applications.

### Unveiling Prometheus on EKS with Terraform

This section dives into the configuration files used to deploy Prometheus, a monitoring champion, on your EKS cluster. I leverage Helm charts and Terraform for this magic.

#### Key Components

- `helm-prometheus.tf`: Retrieves information about a specific EKS node group named `hr-dev-eks-ng-public` . Waits patiently for the EKS cluster to be up and running before proceeding. Creates a dedicated namespace (`prometheus`) to house the Prometheus deployment.
- `provider-prometheus.tf`: Defines the essential providers for interacting with Kubernetes and AWS resources (same as the Nginx ingress controller configuration).

A separate file, named `values.yaml`, provides configurations for the Prometheus deployment, including:

- Alertmanager Config: Fine-tuning how Prometheus routes and handles alerts generated by monitoring.
- Pushgateway Config: Settings for the Prometheus Pushgateway, allowing applications to directly push metrics.
- Retention: Controlling how long Prometheus stores collected metrics data.
- Scraping Targets: Specifying the services or endpoints within your Kubernetes cluster that Prometheus should monitor.
- Resources: Defining resource requests and limits for the Prometheus pods (CPU and memory).

In essence, this configuration leverages Helm charts and Terraform to deploy Prometheus and establish a monitoring system for your EKS cluster.

### Installer Script for Streamlined Setup

To ensure we have the necessary tools in place, we have a script, `installer.sh`, that automates the installation and configuration of:
- Terraform
- kubectl
- AWS CLI (v2)
- Helm
- Jenkins

This script streamlines the initial setup on our Ubuntu server, providing a ready-to-use environment for managing our EKS cluster with IaC and Jenkins.

In essence, this approach empowers us to automate the provisioning, configuration, and management of resources on our EKS cluster in a controlled and efficient manner.
