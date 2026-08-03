# DevSecOps Workflow Design

## Objective

This document describes the repository delivery workflow so infrastructure and application changes can be validated continuously while deployments remain manually controlled.

## Planned Controls

- Terraform format, init, and validate checks
- Terraform plan review
- application syntax validation
- Docker image build validation
- Kubernetes manifest presence checks
- IaC and container scanning
- manual approval for deployment

## Current Repository State

GitHub Actions workflows are included for validation and controlled deployment operations. The current delivery path includes container build validation in addition to Terraform checks.
