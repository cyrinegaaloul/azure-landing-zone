# Pipeline Strategy

This repository uses a cost-aware pipeline approach:

- `validate.yml` runs on every push and pull request
- `demo-deploy.yml` is manual only
- `plan` is the default cloud-facing action
- `apply` and `destroy` are reserved for final demo windows

## Required Secrets For Demo Deployment

- `AZURE_CREDENTIALS` for GitHub Actions Azure login

## Recommended Protection

- require environment approval on the `demo` environment
- only use `demo.tfvars` for short-lived final presentations
- always follow `apply` with `destroy`
