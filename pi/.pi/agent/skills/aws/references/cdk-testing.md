# CDK Testing

CDK uses the `aws-cdk-lib/assertions` module. Tests run with Jest (or Vitest).

## Setup

```bash
npm install -D aws-cdk-lib constructs jest @types/jest ts-jest
```

```json
// jest.config.js
module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  testMatch: ['**/*.test.ts'],
  transform: { '^.+\\.tsx?$': 'ts-jest' }
};
```

## Template Basics

```typescript
import * as cdk from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import { MyStack } from '../lib/my-stack';

describe('MyStack', () => {
  let template: Template;

  beforeEach(() => {
    const app = new cdk.App();
    const stack = new MyStack(app, 'TestStack');
    template = Template.fromStack(stack);
  });

  // ...tests
});
```

## Fine-Grained Assertions

### hasResourceProperties — assert specific properties exist

```typescript
// Check a DynamoDB table has PAY_PER_REQUEST billing
template.hasResourceProperties('AWS::DynamoDB::Table', {
  BillingMode: 'PAY_PER_REQUEST',
});

// Check a Lambda has correct runtime and env var
template.hasResourceProperties('AWS::Lambda::Function', {
  Runtime: 'nodejs22.x',
  Environment: {
    Variables: {
      TABLE_NAME: Match.anyValue(),   // token — value unknown at synth time
    },
  },
});

// Nested partial match
template.hasResourceProperties('AWS::Lambda::Function', {
  VpcConfig: Match.objectLike({
    SubnetIds: Match.arrayWith([Match.anyValue()]),
  }),
});
```

### resourceCountIs — assert number of resources

```typescript
template.resourceCountIs('AWS::Lambda::Function', 3);
template.resourceCountIs('AWS::DynamoDB::Table', 1);
template.resourceCountIs('AWS::SQS::Queue', 2);  // includes DLQ
```

### hasOutput / hasParameter

```typescript
template.hasOutput('ApiUrl', {
  Value: Match.objectLike({ 'Fn::GetAtt': Match.anyValue() }),
});
```

### findResources — return matching resources for further assertions

```typescript
const functions = template.findResources('AWS::Lambda::Function', {
  Properties: { Runtime: 'nodejs22.x' },
});
expect(Object.keys(functions)).toHaveLength(2);
```

## Match Helpers

| Helper | Description |
|--------|-------------|
| `Match.anyValue()` | Any non-null/undefined value (useful for tokens) |
| `Match.absent()` | Property must NOT be present |
| `Match.objectLike(pattern)` | Object contains at least these keys (partial) |
| `Match.objectEquals(pattern)` | Object matches exactly |
| `Match.arrayWith([...])` | Array contains at least these items |
| `Match.arrayEquals([...])` | Array matches exactly |
| `Match.stringLikeRegexp(pattern)` | String matches regex |
| `Match.serializedJson(pattern)` | JSON string, parsed then matched |
| `Match.not(pattern)` | Negates a matcher |

```typescript
// Absent — ensure no public access
template.hasResourceProperties('AWS::S3::Bucket', {
  PublicAccessBlockConfiguration: {
    BlockPublicAcls: true,
    BlockPublicPolicy: true,
    IgnorePublicAcls: true,
    RestrictPublicBuckets: true,
  },
  WebsiteConfiguration: Match.absent(),   // not a website bucket
});

// stringLikeRegexp
template.hasResourceProperties('AWS::IAM::Role', {
  AssumeRolePolicyDocument: Match.objectLike({
    Statement: Match.arrayWith([
      Match.objectLike({
        Principal: { Service: Match.stringLikeRegexp('lambda') },
      }),
    ]),
  }),
});
```

## Snapshot Tests

Catch unintended changes — run once to establish baseline, then on every PR:

```typescript
it('matches snapshot', () => {
  expect(template.toJSON()).toMatchSnapshot();
});
```

**Update snapshots** after intentional changes:
```bash
npx jest --updateSnapshot
```

> Snapshot tests are brittle for large stacks. Prefer fine-grained assertions for critical security/config properties, use snapshots as a broad safety net.

## Testing IAM Policies

```typescript
// Check Lambda has permission to read from DynamoDB
template.hasResourceProperties('AWS::IAM::Policy', {
  PolicyDocument: {
    Statement: Match.arrayWith([
      Match.objectLike({
        Action: Match.arrayWith(['dynamodb:GetItem', 'dynamodb:Query']),
        Effect: 'Allow',
      }),
    ]),
  },
});

// Check NO wildcard resource permissions
const policies = template.findResources('AWS::IAM::Policy');
for (const policy of Object.values(policies)) {
  const statements = policy.Properties.PolicyDocument.Statement;
  for (const stmt of statements) {
    if (stmt.Effect === 'Allow') {
      const resources = Array.isArray(stmt.Resource) ? stmt.Resource : [stmt.Resource];
      expect(resources).not.toContain('*');
    }
  }
}
```

## Testing Custom Constructs

Test constructs in isolation by creating a minimal stack:

```typescript
import { LambdaWithTable } from '../lib/constructs/lambda-with-table';

describe('LambdaWithTable', () => {
  test('creates table and grants access', () => {
    const app = new cdk.App();
    const stack = new cdk.Stack(app, 'TestStack');

    new LambdaWithTable(stack, 'Construct', {
      entry: 'lambda/handler.ts',
    });

    const template = Template.fromStack(stack);
    template.resourceCountIs('AWS::DynamoDB::Table', 1);
    template.resourceCountIs('AWS::Lambda::Function', 1);
    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: {
        Statement: Match.arrayWith([
          Match.objectLike({ Action: Match.arrayWith(['dynamodb:PutItem']) }),
        ]),
      },
    });
  });
});
```

## CDK Nag (Security & Compliance)

[cdk-nag](https://github.com/cdklabs/cdk-nag) checks your stack against AWS security best practices:

```bash
npm install cdk-nag
```

```typescript
import { AwsSolutionsChecks, NagSuppressions } from 'cdk-nag';

// Apply in app or test
Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));

// Suppress a specific rule with justification
NagSuppressions.addResourceSuppressions(bucket, [
  {
    id: 'AwsSolutions-S1',
    reason: 'Server access logs disabled for cost savings in dev environment',
  },
]);

// Suppress by path (for generated resources like CDK BucketDeployment)
NagSuppressions.addStackSuppressions(stack, [
  { id: 'AwsSolutions-IAM4', reason: 'AWS managed policies used for CDK custom resources' },
]);
```

Common nag rules to know:
| Rule | Description |
|------|-------------|
| `AwsSolutions-S1` | S3 bucket server access logging |
| `AwsSolutions-S2` | S3 bucket no public access |
| `AwsSolutions-IAM4` | No AWS managed policies |
| `AwsSolutions-IAM5` | No wildcard permissions |
| `AwsSolutions-L1` | Lambda not using latest runtime |
| `AwsSolutions-DDB3` | DynamoDB PITR enabled |
| `AwsSolutions-SQS3` | SQS queue has DLQ |
| `AwsSolutions-SMG4` | Secrets Manager auto-rotation |

## Integration Tests (integ-tests-alpha)

```bash
npm install @aws-cdk/integ-tests-alpha
```

```typescript
// test/integ.my-api.ts
import { IntegTest } from '@aws-cdk/integ-tests-alpha';

const app = new cdk.App();
const stack = new MyApiStack(app, 'IntegStack', { env: { account: '...', region: 'us-east-1' } });

const integ = new IntegTest(app, 'IntegTest', {
  testCases: [stack],
});

// Assert against live resources after deploy
const response = integ.assertions.httpApiCall(`${stack.apiUrl}/items`);
response.expect(ExpectedResult.objectLike({ statusCode: 200 }));
```

```bash
# Run integration test (deploys real resources)
npx integ-runner test/integ.my-api.ts
# Clean up after
npx integ-runner test/integ.my-api.ts --clean
```
