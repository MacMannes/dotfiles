---
name: aws
description: AWS infrastructure and CDK (Cloud Development Kit) expertise. Use when writing, reviewing, or debugging AWS CDK code (TypeScript/Python), designing cloud architecture, working with CloudFormation, or using AWS CLI/SDK. Covers CDK constructs (L1/L2/L3), stacks, apps, testing, deployment pipelines, and all major AWS services including Lambda, S3, DynamoDB, API Gateway, ECS, VPC, IAM, SNS, SQS, EventBridge, RDS, and more.
---

# AWS Skill

## Reference Docs

Load these on demand based on the task:

- [CDK Core Concepts](references/cdk-core.md) — App, Stack, Construct levels, tokens, context, environments, aspects, bootstrapping
- [CDK Constructs by Service](references/cdk-constructs.md) — L2 construct API for Lambda, S3, DynamoDB, API Gateway, ECS, VPC, IAM, SNS, SQS, EventBridge, RDS, and more
- [CDK Patterns & Architecture](references/cdk-patterns.md) — Serverless, event-driven, microservices, multi-stack, cross-stack references, custom constructs
- [CDK Testing](references/cdk-testing.md) — Unit tests with `assertions`, snapshot tests, fine-grained assertions, integration tests
- [CDK CLI & Deployment](references/cdk-cli.md) — `cdk` commands, bootstrapping, context flags, deployment strategies, CI/CD pipelines

## Quick Rules

- **Always use L2 constructs** unless an L1 (Cfn*) property is unavailable at L2
- **Never hardcode account IDs or regions** — use `Stack.of(this).account` / `Stack.of(this).region` or environment variables
- **Tag everything** — use `Tags.of(scope).add(key, value)` or Aspects for bulk tagging
- **Grant, don't policy** — prefer `.grantRead()`, `.grantWrite()`, `.grantInvoke()` over manual IAM policies
- **Removal policies** — always set explicit `removalPolicy` on stateful resources (S3, DynamoDB, RDS)
- **Bundling** — use `aws-cdk-lib/aws-lambda-nodejs` `NodejsFunction` for TypeScript Lambdas (esbuild bundling)
- **Output sparingly** — `CfnOutput` only for values consumed by other stacks or humans
- **CDK Nag** — run `cdk-nag` in tests to catch security/compliance issues early
