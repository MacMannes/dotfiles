# CDK Patterns & Architecture

## Custom Construct

Encapsulate repeatable infrastructure into reusable constructs:

```typescript
import { Construct } from 'constructs';
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';

export interface LambdaWithTableProps {
  entry: string;
  tableProps?: Partial<dynamodb.TableProps>;
  functionProps?: Partial<lambda.FunctionProps>;
}

export class LambdaWithTable extends Construct {
  public readonly table: dynamodb.Table;
  public readonly handler: lambda.Function;

  constructor(scope: Construct, id: string, props: LambdaWithTableProps) {
    super(scope, id);

    this.table = new dynamodb.Table(this, 'Table', {
      partitionKey: { name: 'pk', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      ...props.tableProps,
    });

    this.handler = new NodejsFunction(this, 'Handler', {
      entry: props.entry,
      environment: { TABLE_NAME: this.table.tableName },
      ...props.functionProps,
    });

    this.table.grantReadWriteData(this.handler);
  }
}

// Usage
const orders = new LambdaWithTable(this, 'Orders', {
  entry: 'lambda/orders/handler.ts',
});
```

## Multi-Stack Application

```
bin/app.ts
├── NetworkStack        — VPC, subnets, security groups
├── DataStack           — RDS, DynamoDB, S3 (depends on NetworkStack)
├── ServiceStack        — ECS / Lambda (depends on DataStack)
└── MonitoringStack     — CloudWatch dashboards & alarms (depends on ServiceStack)
```

```typescript
// bin/app.ts
const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

const network = new NetworkStack(app, 'Network', { env });
const data = new DataStack(app, 'Data', { env, vpc: network.vpc });
const service = new ServiceStack(app, 'Service', { env, vpc: network.vpc, table: data.table });
new MonitoringStack(app, 'Monitoring', { env, service: service.fargateService });
```

Pass constructs through props (not ARNs) to keep references strongly typed and to avoid CloudFormation export/import coupling.

## Stage-based Environments

```typescript
// lib/pipeline-stage.ts
export class AppStage extends cdk.Stage {
  constructor(scope: Construct, id: string, props: cdk.StageProps) {
    super(scope, id, props);
    const network = new NetworkStack(this, 'Network');
    new AppStack(this, 'App', { vpc: network.vpc });
  }
}

// bin/app.ts
new AppStage(app, 'Dev', {
  env: { account: '111111111111', region: 'us-east-1' },
});
new AppStage(app, 'Prod', {
  env: { account: '222222222222', region: 'us-east-1' },
});
```

## CDK Pipelines (CI/CD)

```typescript
import * as pipelines from 'aws-cdk-lib/pipelines';

const pipeline = new pipelines.CodePipeline(this, 'Pipeline', {
  pipelineName: 'MyAppPipeline',
  synth: new pipelines.ShellStep('Synth', {
    input: pipelines.CodePipelineSource.connection('org/repo', 'main', {
      connectionArn: 'arn:aws:codestar-connections:...',
    }),
    commands: [
      'npm ci',
      'npm run build',
      'npx cdk synth',
    ],
  }),
  dockerEnabledForSynth: true,
  crossAccountKeys: true,           // required for cross-account deployments
});

pipeline.addStage(new AppStage(this, 'Dev', {
  env: { account: '111111111111', region: 'us-east-1' },
}));

pipeline.addStage(new AppStage(this, 'Prod', {
  env: { account: '222222222222', region: 'us-east-1' },
}), {
  pre: [new pipelines.ManualApprovalStep('PromoteToProd')],
  post: [
    new pipelines.ShellStep('SmokeTest', {
      commands: ['curl -f https://api.example.com/health'],
    }),
  ],
});
```

## Serverless Event-Driven Pattern

```typescript
// Pattern: S3 → EventBridge → Lambda → DynamoDB
const bucket = new s3.Bucket(this, 'Uploads', {
  eventBridgeEnabled: true,           // emit all S3 events to EventBridge
});

const processUpload = new NodejsFunction(this, 'ProcessUpload', {
  entry: 'lambda/process-upload/index.ts',
  environment: { TABLE_NAME: table.tableName },
});
table.grantWriteData(processUpload);
bucket.grantRead(processUpload);

new events.Rule(this, 'OnUpload', {
  eventPattern: {
    source: ['aws.s3'],
    detailType: ['Object Created'],
    detail: {
      bucket: { name: [bucket.bucketName] },
      object: { key: [{ prefix: 'uploads/' }] },
    },
  },
  targets: [new targets.LambdaFunction(processUpload)],
});
```

## Serverless API Pattern

```typescript
// Pattern: API Gateway → Lambda → DynamoDB
const table = new dynamodb.Table(this, 'Items', {
  partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
});

const commonEnv = { TABLE_NAME: table.tableName };
const commonFnProps = { runtime: lambda.Runtime.NODEJS_22_X, architecture: lambda.Architecture.ARM_64 };

const listFn = new NodejsFunction(this, 'List', { ...commonFnProps, entry: 'lambda/items/list.ts', environment: commonEnv });
const getFn = new NodejsFunction(this, 'Get', { ...commonFnProps, entry: 'lambda/items/get.ts', environment: commonEnv });
const createFn = new NodejsFunction(this, 'Create', { ...commonFnProps, entry: 'lambda/items/create.ts', environment: commonEnv });

[listFn, getFn].forEach(fn => table.grantReadData(fn));
table.grantWriteData(createFn);

const api = new apigwv2.HttpApi(this, 'Api');
api.addRoutes({ path: '/items', methods: [apigwv2.HttpMethod.GET], integration: new HttpLambdaIntegration('List', listFn) });
api.addRoutes({ path: '/items/{id}', methods: [apigwv2.HttpMethod.GET], integration: new HttpLambdaIntegration('Get', getFn) });
api.addRoutes({ path: '/items', methods: [apigwv2.HttpMethod.POST], integration: new HttpLambdaIntegration('Create', createFn) });

new cdk.CfnOutput(this, 'ApiUrl', { value: api.apiEndpoint });
```

## Fan-out Pattern (SNS → SQS → Lambda)

```typescript
const topic = new sns.Topic(this, 'Events');

const queues = ['processing', 'analytics', 'audit'].map(name => {
  const dlq = new sqs.Queue(this, `${name}DLQ`);
  const queue = new sqs.Queue(this, `${name}Queue`, {
    deadLetterQueue: { queue: dlq, maxReceiveCount: 3 },
    visibilityTimeout: cdk.Duration.minutes(5),
  });
  topic.addSubscription(new subscriptions.SqsSubscription(queue, { rawMessageDelivery: true }));
  return queue;
});

const [processingQueue, analyticsQueue, auditQueue] = queues;

const processingFn = new NodejsFunction(this, 'Processing', { entry: 'lambda/processing.ts' });
processingFn.addEventSource(new lambdaEventSources.SqsEventSource(processingQueue, {
  batchSize: 10,
  reportBatchItemFailures: true,
}));
```

## Shared Config / Props Pattern

Avoid prop drilling by defining a shared interface:

```typescript
// lib/shared-props.ts
export interface SharedProps extends cdk.StackProps {
  stage: 'dev' | 'staging' | 'prod';
  isProd: boolean;
  domainName: string;
}

// lib/my-stack.ts — use isProd to vary behaviour
new s3.Bucket(this, 'Data', {
  removalPolicy: props.isProd ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
  versioned: props.isProd,
});
```

## Asset Bundling (Lambda + Docker)

```typescript
// Lambda with custom bundling commands
const fn = new NodejsFunction(this, 'Fn', {
  entry: 'lambda/handler.ts',
  bundling: {
    nodeModules: ['sharp'],           // modules that need native binaries (bundled, not external)
    forceDockerBundling: true,        // build in Lambda-compatible Docker container
    commandHooks: {
      beforeBundling: () => [],
      afterBundling: (input, output) => [
        `cp ${input}/config.json ${output}/`,
      ],
      beforeInstall: () => [],
    },
  },
});

// Docker image from local Dockerfile
const fn2 = new lambda.DockerImageFunction(this, 'DockerFn', {
  code: lambda.DockerImageCode.fromImageAsset('./docker', {
    platform: Platform.LINUX_ARM64,
    buildArgs: { NODE_ENV: 'production' },
  }),
});
```

## Custom Resource (Lambda-backed)

Use when you need to perform actions during deployment that CloudFormation doesn't support natively:

```typescript
import * as cr from 'aws-cdk-lib/custom-resources';

const provider = new cr.Provider(this, 'Provider', {
  onEventHandler: new NodejsFunction(this, 'OnEvent', {
    entry: 'lambda/custom-resource/index.ts',
  }),
  isCompleteHandler: new NodejsFunction(this, 'IsComplete', {  // optional, for async
    entry: 'lambda/custom-resource/is-complete.ts',
  }),
});

const resource = new cdk.CustomResource(this, 'Resource', {
  serviceToken: provider.serviceToken,
  properties: {
    BucketName: bucket.bucketName,
    Config: JSON.stringify({ ... }),
  },
});

// Get return value from custom resource
const value = resource.getAttString('OutputKey');
```

## SSM Parameter Store for Cross-Stack (alternative to cross-stack references)

```typescript
// Producing stack
new ssm.StringParameter(this, 'VpcIdParam', {
  parameterName: '/myapp/prod/vpc-id',
  stringValue: vpc.vpcId,
});

// Consuming stack (different deploy cycle, no CloudFormation dependency)
const vpcId = ssm.StringParameter.valueFromLookup(this, '/myapp/prod/vpc-id');
const vpc = ec2.Vpc.fromLookup(this, 'Vpc', { vpcId });
```

Use `valueFromLookup` (resolved at synth) when you need the value to configure the construct tree. Use `valueForStringParameter` (Token, resolved at deploy) when you just need to pass a value to a resource property.
