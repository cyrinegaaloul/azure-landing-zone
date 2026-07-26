# Phase 7 DevSecOps Design

## Objective

This phase prepares the delivery workflow so infrastructure and application changes can be validated continuously while deployments remain manually controlled.

## Planned Controls

- Terraform format, init, and validate checks
- future Terraform plan review
- application syntax validation
- future IaC and container scanning
- manual approval for demo deployment

## Current Repository State

GitHub Actions workflows are included for validation and controlled demo deployment. The default behavior is validation only.
