# Final Demo Runbook

## Goal

Deploy the full demonstration stack only for a short time window, present the architecture, and destroy the resources immediately afterward.

## Recommended Sequence

1. Merge the final code to `main`.
2. Confirm `terraform/root/demo.tfvars` contains the demo configuration.
3. Run `terraform plan -var-file=demo.tfvars`.
4. Review cost-sensitive services before approval.
5. Run `terraform apply -var-file=demo.tfvars`.
6. Demonstrate:
   - landing zone resource groups
   - networking segmentation
   - RBAC baseline
   - app health and metrics
   - future edge, workloads, and observability readiness
7. Run `terraform destroy -var-file=demo.tfvars` immediately after the demo.

## Demo Principles

- keep all expensive toggles off until the final review window
- use the smallest acceptable demo sizes
- prefer screenshots and saved plans for features that remain intentionally deferred
