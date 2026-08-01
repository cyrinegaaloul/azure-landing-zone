# Phase 7 DevSecOps Design

## Objective

This phase prepares the delivery workflow so infrastructure and application changes can be validated continuously while deployments remain manually controlled.

## Planned Controls

- Terraform format, init, and validate checks
- Terraform plan review
- application syntax validation
- Docker image build validation
- Kubernetes manifest presence checks
- IaC and container scanning
- manual approval for deployment

## Current Repository State

GitHub Actions workflows are included for validation and controlled deployment operations. The current delivery path now includes container build validation and a documented image/secret strategy in addition to Terraform checks.
