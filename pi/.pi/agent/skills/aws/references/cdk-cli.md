# CDK CLI & Deployment

## Installation & Project Setup

```bash
# Install CDK CLI
npm install -g aws-cdk

# Bootstrap (once per account/region)
cdk bootstrap aws://ACCOUNT_ID/REGION

# Create new project
mkdir my-app && cd my-app
cdk init app --language typescript
```

## Core Commands

```bash
# Synthesize CloudFormation templates (writes to cdk.out/)
cdk synth
cdk synth MyStack          # specific stack

# Show diff between deployed and local
cdk diff
cdk diff MyStack

# Deploy
cdk deploy                 # all stacks
cdk deploy MyStack         # specific stack
cdk deploy "App*"          # glob pattern
cdk deploy --all           # all stacks

# Destroy
cdk destroy MyStack
cdk destroy --all

# List stacks
cdk list
cdk ls

# Show context values
cdk context
cdk context --clear        # clear cached context (VPC lookups etc.)
```

## Deploy Flags

```bash
# Skip approval prompt (for CI/CD)
cdk deploy --require-approval never

# Deploy with specific parameters
cdk deploy --parameters MyStack:Env=prod

# Deploy outputs to file (useful for integration tests / scripts)
cdk deploy --outputs-file cdk-outputs.json

# Deploy and pass context
cdk deploy --context stage=prod --context vpcId=vpc-12345

# Hotswap deploy (fast, skips CloudFormation for Lambda/ECS updates — dev only)
cdk deploy --hotswap
cdk deploy --hotswap-fallback  # hotswap when possible, full deploy otherwise

# Watch mode (auto deploy on file changes — dev only)
cdk watch

# Force deploy even if no changes detected
cdk deploy --force

# Rollback on failure (default: true)
cdk deploy --rollback
cdk deploy --no-rollback   # keep partially deployed stack for debugging

# Concurrently deploy independent stacks
cdk deploy --all --concurrency 5

# Asset publishing only (no stack update)
cdk deploy --asset-parallelism true
```

## Profiles & Credentials

```bash
# Use named AWS profile
cdk deploy --profile my-profile

# Set via environment
AWS_PROFILE=my-profile cdk deploy
AWS_DEFAULT_REGION=eu-west-1 cdk deploy
CDK_DEFAULT_ACCOUNT=123456789012 cdk deploy

# Assume role
cdk deploy --role-arn arn:aws:iam::123456789012:role/CdkDeployRole
```

## cdk.json

```json
{
  "app": "npx ts-node --prefer-ts-exts bin/app.ts",
  "watch": {
    "include": ["**"],
    "exclude": [
      "README.md",
      "cdk*.json",
      "**/*.d.ts",
      "**/*.js",
      "tsconfig.json",
      "package*.json",
      "node_modules",
      "test"
    ]
  },
  "context": {
    "@aws-cdk/aws-lambda:recognizeLayerVersion": true,
    "@aws-cdk/core:checkSecretUsage": true,
    "@aws-cdk/core:target-partitions": ["aws", "aws-cn"],
    "@aws-cdk-containers/ecs-service-extensions:enableDefaultLogDriver": true,
    "@aws-cdk/aws-ec2:uniqueImdsv2TemplateName": true,
    "@aws-cdk/aws-ecs:arnFormatIncludesClusterName": true,
    "@aws-cdk/aws-iam:minimizePolicies": true,
    "@aws-cdk/core:validateSnapshotRemovalPolicy": true,
    "@aws-cdk/aws-codepipeline:crossAccountKeyAliasStackSafeResourceName": true,
    "@aws-cdk/aws-s3:createDefaultLoggingPolicy": true,
    "@aws-cdk/aws-sns-subscriptions:restrictSqsDescryption": true,
    "@aws-cdk/aws-apigateway:disableCloudWatchRole": true,
    "@aws-cdk/core:enablePartitionLiterals": true,
    "@aws-cdk/aws-s3:serverAccessLogsUseBucketPolicy": true
  }
}
```

## CloudFormation Stack Management

```bash
# View stack events (useful when deploy fails)
aws cloudformation describe-stack-events --stack-name MyStack --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Describe stack outputs
aws cloudformation describe-stacks --stack-name MyStack --query 'Stacks[0].Outputs'

# List stack resources
aws cloudformation list-stack-resources --stack-name MyStack

# Get stack template
aws cloudformation get-template --stack-name MyStack

# Delete stack manually (if CDK destroy fails)
aws cloudformation delete-stack --stack-name MyStack
```

## Troubleshooting

### Stack stuck in UPDATE_ROLLBACK_FAILED

```bash
# Continue rollback, skipping broken resources
aws cloudformation continue-update-rollback --stack-name MyStack \
  --resources-to-skip LogicalResourceId1 LogicalResourceId2
```

### Bootstrap out of date

```bash
# Re-run bootstrap to upgrade
cdk bootstrap --profile prod
```

### Context cache stale (VPC/SSM lookups returning old values)

```bash
cdk context --clear
cdk synth   # re-fetches all context
```

### CDK metadata version mismatch

```bash
npm install -g aws-cdk@latest
npm install aws-cdk-lib@latest constructs@latest
```

### Asset upload fails (S3 access denied)

Check the `cdk-*` IAM roles created by bootstrap have the right permissions and trust the deploying account/role.

## CI/CD Environment Setup

```bash
# GitHub Actions example
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeployRole
    aws-region: us-east-1

- name: Install dependencies
  run: npm ci

- name: CDK diff (PR check)
  run: npx cdk diff --require-approval never

- name: CDK deploy (main branch)
  run: npx cdk deploy --all --require-approval never --outputs-file cdk-outputs.json
```

### Required IAM permissions for CI role

At minimum the CI role needs:
- `sts:AssumeRole` on `arn:aws:iam::ACCOUNT:role/cdk-*` (CDK bootstrap roles)
- Or `AdministratorAccess` for full deploy rights (simpler but less secure)

## Useful CDK CLI Shortcuts

```bash
# See what CloudFormation will actually receive (fully resolved template)
cdk synth --no-staging > template.yaml

# Print just the resources section
cdk synth | cfn-flip | jq '.Resources | keys'

# Compare two environments
cdk diff --app "cdk.out" --exclusively MyStack

# Acknowledge security changes in one command (CI)
cdk deploy --require-approval never

# Check CDK version
cdk --version

# Doctor (checks environment)
cdk doctor
```
