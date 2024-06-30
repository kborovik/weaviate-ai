# Google Cloud Infrastructure for Weaviate AI-native vector database

This repository contains the Google Cloud infrastructure deployment for the [Weaviate](https://weaviate.io/) AI-native vector database and [Verba](https://github.com/weaviate/verba) Open-source RAG framework

## Pipeline Design Principles

Our development and deployment pipeline adheres to the following principles:

1. **Rapid Iteration**: All dependencies are kept within the project to maximize short feedback development cycles.
2. **Seamless Deployment**: End-to-end deployment and testing can be executed with a single command: `make deploy`.
3. **Configuration Management**: Deployment target differences are managed through `google_project.tfvars` configuration files.
4. **Version Control**: Code base changes are tracked using `git branch`, while deployment states are tracked with `git tag`.
5. **Continuous Integration**: Automated testing and code quality checks are performed on every commit to ensure code integrity.
6. **Infrastructure as Code**: All infrastructure configurations are managed using Terraform, enabling version-controlled and reproducible deployments.
7. **Security First**: Regular security scans using Checkov are integrated into the pipeline to identify and address potential vulnerabilities early.
8. **Documentation**: Comprehensive documentation is maintained alongside the code, including deployment diagrams and usage instructions.
9. **Scalability**: The pipeline is designed to handle increasing workloads and team sizes without compromising efficiency.

## Deployment Architecture

Our deployment stack leverages various Google Cloud services and open-source tools to create a robust and scalable infrastructure.

## Security Static Analysis

We use [Checkov](https://www.checkov.io/), a static code analysis tool, to scan our infrastructure as code (IaC) files for potential security misconfigurations or compliance issues.

To run the security analysis:

```shell
make checkov
```

## Infrastructure as Code with Terraform

We use Terraform to manage and provision our Google Cloud infrastructure. This Infrastructure as Code (IaC) approach allows for version-controlled, repeatable, and consistent deployments across different environments. By codifying our infrastructure, we ensure transparency, facilitate collaboration, and enable easy auditing of changes.

To apply the Terraform configuration:

```shell
make terraform
```

## Kubernetes and HELM

Kubernetes offers superior scalability and resource efficiency compared to traditional VM deployments. It enables easier management of containerized applications, allowing for faster deployments, automatic scaling, and more efficient use of underlying infrastructure resources.
