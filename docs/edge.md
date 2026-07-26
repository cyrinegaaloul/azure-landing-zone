# Phase 4 Edge Design

## Objective

This phase prepares the edge layer for the final demonstration without provisioning expensive resources during development.

## Planned Components

- Application Gateway
- WAF
- API Management

## Cost Guidance

These services are intentionally deferred because they are not free structural resources. They should be enabled only for the final demo and destroyed immediately afterward.

## Current Repository State

The Terraform module `terraform/03-edge` is a scaffold. It captures naming, intended subnet placement, and demo-time decisions without creating billable resources yet.
