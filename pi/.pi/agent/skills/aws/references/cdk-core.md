# CDK Core Concepts

## App & Stack Structure

```typescript
// bin/app.ts — entry point
const app = new cdk.App();

new MyStack(app, 'MyStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});

app.synth();
```

```typescript
// lib/my-stack.ts
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

export class MyStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
    // resources here
  }
}
```

## Construct Levels

| Level | Prefix | Description | Example |
|-------|--------|-------------|---------|
| L1 | `Cfn*` | Direct CloudFormation resource, 1:1 mapping | `CfnBucket`, `CfnFunction` |
| L2 | (none) | Opinionated, safe defaults, helper methods | `Bucket`, `Function`, `Table` |
| L3 | Patterns | Multi-resource solutions | `ApplicationLoadBalancedFargateService` |

Always start with L2. Drop to L1 only when you need a property L2 doesn't expose:

```typescript
const bucket = new s3.Bucket(this, 'MyBucket');
// Access underlying L1 when needed:
const cfnBucket = bucket.node.defaultChild as s3.CfnBucket;
cfnBucket.accelerateConfiguration = { accelerationStatus: 'Enabled' };
```

## Construct ID Rules

- IDs must be unique within a scope (parent construct)
- IDs become part of the logical CloudFormation ID — changing them forces replacement
- Use PascalCase, descriptive names: `'UserTable'`, `'ApiHandler'`, `'IngestQueue'`
- Avoid IDs that encode environment/stage (use separate stacks or props instead)

## Tokens & Resolution

CDK values are **tokens** at synth time — they resolve to CloudFormation intrinsics:

```typescript
const bucket = new s3.Bucket(this, 'B');
console.log(bucket.bucketName);       // "${Token[TOKEN.123]}" at synth time
console.log(bucket.bucketArn);        // "arn:${AWS::Partition}:s3:::..."

// Don't use tokens in conditionals at synth time — they're not resolved yet
// BAD:
if (bucket.bucketName === 'my-bucket') { ... }  // always false

// Use CfnCondition or pass literal values through props instead
```

## Environment

```typescript
// Environment-agnostic (deploy anywhere, but limits some features)
new MyStack(app, 'MyStack');

// Environment-specific (required for VPC lookups, SSM lookups, etc.)
new MyStack(app, 'MyStack', {
  env: { account: '123456789012', region: 'us-east-1' }
});

// From CLI context (recommended for pipelines)
new MyStack(app, 'MyStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});
```

## Context & Feature Flags

```typescript
// Read context in stack/construct
const vpcId = this.node.tryGetContext('vpcId') as string;

// cdk.json — context and feature flags
{
  "context": {
    "vpcId": "vpc-12345",
    "@aws-cdk/aws-s3:serverAccessLogsUseBucketPolicy": true,
    "@aws-cdk/aws-lambda:recognizeLayerVersion": true
  }
}

// Pass via CLI
cdk deploy --context vpcId=vpc-12345
```

Always enable new feature flags for new projects. Check `cdk.json` for recommended flags.

## Aspects

Aspects traverse the entire construct tree and can mutate or validate:

```typescript
import { IAspect, Aspects } from 'aws-cdk-lib';
import { IConstruct } from 'constructs';

class EnforceEncryption implements IAspect {
  visit(node: IConstruct): void {
    if (node instanceof s3.Bucket) {
      if (node.encryptionKey === undefined) {
        Annotations.of(node).addError('Bucket must be encrypted with CMK');
      }
    }
  }
}

Aspects.of(app).add(new EnforceEncryption());
```

## Tags

```typescript
// Tag a single resource
cdk.Tags.of(bucket).add('Environment', 'production');

// Tag everything in a stack
cdk.Tags.of(this).add('Team', 'platform');

// Tag everything in the app
cdk.Tags.of(app).add('ManagedBy', 'cdk');
```

## Removal Policy

Always set explicitly on stateful resources:

```typescript
import { RemovalPolicy } from 'aws-cdk-lib';

new s3.Bucket(this, 'Data', {
  removalPolicy: RemovalPolicy.RETAIN,      // default for prod
});

new s3.Bucket(this, 'Temp', {
  removalPolicy: RemovalPolicy.DESTROY,     // for dev/test
  autoDeleteObjects: true,                  // required to destroy non-empty bucket
});
```

| Policy | Behaviour |
|--------|-----------|
| `RETAIN` | Resource stays after stack deletion (default for most stateful) |
| `DESTROY` | Resource deleted with stack |
| `SNAPSHOT` | RDS/Redshift: take snapshot then delete |
| `RETAIN_ON_UPDATE_OR_DELETE` | Same as RETAIN but only on update/delete |

## Cross-Stack References

```typescript
// Stack A — export a value
export class InfraStack extends cdk.Stack {
  public readonly table: dynamodb.Table;
  constructor(scope: Construct, id: string, props: cdk.StackProps) {
    super(scope, id, props);
    this.table = new dynamodb.Table(this, 'Table', { ... });
  }
}

// Stack B — import via props (preferred: strongly typed)
interface AppStackProps extends cdk.StackProps {
  table: dynamodb.Table;
}
export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AppStackProps) {
    super(scope, id, props);
    props.table.grantReadWriteData(myLambda);
  }
}

// bin/app.ts
const infra = new InfraStack(app, 'Infra', { env });
new AppStack(app, 'App', { env, table: infra.table });
```

**Avoid** exporting raw ARNs via `CfnOutput` + `Fn.importValue` — it creates tight CloudFormation dependencies and complicates updates. Pass constructs through props instead.

## Bootstrapping

Required once per account/region before first deployment:

```bash
cdk bootstrap aws://ACCOUNT_ID/REGION
# With custom qualifier (for multiple CDK apps in one account):
cdk bootstrap --qualifier myapp
# With trust for CI/CD pipeline account:
cdk bootstrap --trust PIPELINE_ACCOUNT_ID --cloudformation-execution-policies arn:aws:iam::aws:policy/AdministratorAccess
```

Bootstrap creates: S3 staging bucket, ECR repo, IAM roles (`cdk-*`).

## Escape Hatches to CloudFormation

```typescript
// Override a property L2 doesn't expose
const cfnBucket = bucket.node.defaultChild as s3.CfnBucket;
cfnBucket.addPropertyOverride('NotificationConfiguration.EventBridgeConfiguration.EventBridgeEnabled', true);

// Add a CloudFormation condition
const isProd = new cdk.CfnCondition(this, 'IsProd', {
  expression: cdk.Fn.conditionEquals(this.node.tryGetContext('env'), 'prod'),
});
cfnBucket.cfnOptions.condition = isProd;

// Add a deletion policy override
cfnBucket.cfnOptions.deletionPolicy = cdk.CfnDeletionPolicy.RETAIN;
```
