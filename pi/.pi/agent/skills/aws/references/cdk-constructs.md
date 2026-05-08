# CDK Constructs by Service

## Lambda

```typescript
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import * as path from 'path';

// Preferred: NodejsFunction (auto-bundles with esbuild)
const fn = new NodejsFunction(this, 'Handler', {
  entry: path.join(__dirname, '../lambda/handler.ts'),
  handler: 'handler',
  runtime: lambda.Runtime.NODEJS_22_X,
  architecture: lambda.Architecture.ARM_64,     // cheaper + faster for most workloads
  memorySize: 512,
  timeout: cdk.Duration.seconds(30),
  environment: {
    TABLE_NAME: table.tableName,
    BUCKET_NAME: bucket.bucketName,
  },
  bundling: {
    minify: true,
    sourceMap: true,
    externalModules: ['@aws-sdk/*'],            // excluded from bundle (available in runtime)
  },
  logRetention: logs.RetentionDays.ONE_MONTH,
  tracing: lambda.Tracing.ACTIVE,              // X-Ray
});

// Generic Function (zip from local asset)
const fn2 = new lambda.Function(this, 'Handler2', {
  runtime: lambda.Runtime.PYTHON_3_13,
  code: lambda.Code.fromAsset('lambda'),
  handler: 'index.handler',
});

// Docker image Lambda
const fn3 = new lambda.DockerImageFunction(this, 'DockerHandler', {
  code: lambda.DockerImageCode.fromImageAsset('./src'),
});

// Lambda URL (no API Gateway needed for simple cases)
const url = fn.addFunctionUrl({
  authType: lambda.FunctionUrlAuthType.AWS_IAM,
  cors: { allowedOrigins: ['*'] },
});

// Versioning & Aliases (required for traffic shifting)
const version = fn.currentVersion;
const alias = new lambda.Alias(this, 'Live', {
  aliasName: 'live',
  version,
});

// Event Source Mappings
fn.addEventSource(new lambdaEventSources.SqsEventSource(queue, {
  batchSize: 10,
  maxBatchingWindow: cdk.Duration.seconds(5),
  reportBatchItemFailures: true,
}));
fn.addEventSource(new lambdaEventSources.DynamoEventSource(table, {
  startingPosition: lambda.StartingPosition.TRIM_HORIZON,
  bisectBatchOnError: true,
}));
```

## S3

```typescript
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';

const bucket = new s3.Bucket(this, 'MyBucket', {
  bucketName: 'my-unique-bucket-name',          // omit to auto-generate
  versioned: true,
  encryption: s3.BucketEncryption.S3_MANAGED,   // or KMS_MANAGED / KMS with encryptionKey
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  enforceSSL: true,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
  lifecycleRules: [{
    id: 'ArchiveOldVersions',
    noncurrentVersionTransitions: [{
      storageClass: s3.StorageClass.GLACIER,
      transitionAfter: cdk.Duration.days(90),
    }],
    noncurrentVersionExpiration: cdk.Duration.days(365),
  }],
  cors: [{
    allowedMethods: [s3.HttpMethods.GET],
    allowedOrigins: ['https://example.com'],
    allowedHeaders: ['*'],
  }],
  serverAccessLogsBucket: logBucket,
});

// Grants (always prefer over manual policies)
bucket.grantRead(lambdaFn);
bucket.grantWrite(lambdaFn);
bucket.grantReadWrite(lambdaFn);
bucket.grantPut(lambdaFn);
bucket.grantDelete(lambdaFn);

// Event notifications
bucket.addEventNotification(
  s3.EventType.OBJECT_CREATED,
  new s3n.LambdaDestination(lambdaFn),
  { prefix: 'uploads/', suffix: '.csv' },
);

// Deploy static assets
new s3deploy.BucketDeployment(this, 'Deploy', {
  sources: [s3deploy.Source.asset('./dist')],
  destinationBucket: bucket,
  cacheControl: [s3deploy.CacheControl.maxAge(cdk.Duration.days(1))],
});

// Import existing bucket (read-only reference, no modifications)
const existing = s3.Bucket.fromBucketName(this, 'Existing', 'my-existing-bucket');
```

## DynamoDB

```typescript
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';

const table = new dynamodb.Table(this, 'Table', {
  tableName: 'MyTable',                           // omit to auto-generate
  partitionKey: { name: 'pk', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'sk', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,  // or PROVISIONED
  encryption: dynamodb.TableEncryption.AWS_MANAGED,
  pointInTimeRecovery: true,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
  stream: dynamodb.StreamViewType.NEW_AND_OLD_IMAGES,  // for DynamoDB Streams
  timeToLiveAttribute: 'ttl',
});

// GSI
table.addGlobalSecondaryIndex({
  indexName: 'gsi1',
  partitionKey: { name: 'gsi1pk', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'gsi1sk', type: dynamodb.AttributeType.STRING },
  projectionType: dynamodb.ProjectionType.ALL,
});

// LSI (must be added at table creation — can't add later)
// Only with PROVISIONED billing mode

// Grants
table.grantReadData(lambdaFn);
table.grantWriteData(lambdaFn);
table.grantReadWriteData(lambdaFn);
table.grantFullAccess(lambdaFn);

// Import existing
const existing = dynamodb.Table.fromTableName(this, 'Existing', 'MyTable');
```

## API Gateway (REST)

```typescript
import * as apigateway from 'aws-cdk-lib/aws-apigateway';

const api = new apigateway.RestApi(this, 'Api', {
  restApiName: 'MyApi',
  description: 'My REST API',
  deployOptions: {
    stageName: 'prod',
    tracingEnabled: true,
    loggingLevel: apigateway.MethodLoggingLevel.INFO,
    metricsEnabled: true,
    throttlingBurstLimit: 100,
    throttlingRateLimit: 50,
  },
  defaultCorsPreflightOptions: {
    allowOrigins: apigateway.Cors.ALL_ORIGINS,
    allowMethods: apigateway.Cors.ALL_METHODS,
    allowHeaders: ['Content-Type', 'Authorization'],
  },
});

const items = api.root.addResource('items');
items.addMethod('GET', new apigateway.LambdaIntegration(listFn));
items.addMethod('POST', new apigateway.LambdaIntegration(createFn));

const item = items.addResource('{id}');
item.addMethod('GET', new apigateway.LambdaIntegration(getFn));
item.addMethod('PUT', new apigateway.LambdaIntegration(updateFn));
item.addMethod('DELETE', new apigateway.LambdaIntegration(deleteFn));

// Cognito authorizer
const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'Auth', {
  cognitoUserPools: [userPool],
});
item.addMethod('DELETE', new apigateway.LambdaIntegration(deleteFn), {
  authorizer,
  authorizationType: apigateway.AuthorizationType.COGNITO,
});
```

## API Gateway HTTP API (v2 — preferred for Lambda + lower cost)

```typescript
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import { HttpLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import { HttpJwtAuthorizer } from 'aws-cdk-lib/aws-apigatewayv2-authorizers';

const api = new apigwv2.HttpApi(this, 'Api', {
  apiName: 'MyHttpApi',
  corsPreflight: {
    allowOrigins: ['*'],
    allowMethods: [apigwv2.CorsHttpMethod.ANY],
    allowHeaders: ['Authorization', 'Content-Type'],
  },
});

api.addRoutes({
  path: '/items',
  methods: [apigwv2.HttpMethod.GET],
  integration: new HttpLambdaIntegration('ListItems', listFn),
});
api.addRoutes({
  path: '/items/{id}',
  methods: [apigwv2.HttpMethod.GET, apigwv2.HttpMethod.PUT, apigwv2.HttpMethod.DELETE],
  integration: new HttpLambdaIntegration('ItemHandler', itemFn),
});
```

## IAM

```typescript
import * as iam from 'aws-cdk-lib/aws-iam';

// Role
const role = new iam.Role(this, 'Role', {
  assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
  managedPolicies: [
    iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
  ],
});

// Inline policy
role.addToPolicy(new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['s3:GetObject', 's3:PutObject'],
  resources: [bucket.arnForObjects('*')],
}));

// Grant patterns (preferred over manual policies)
bucket.grantReadWrite(role);
table.grantReadWriteData(role);
queue.grantSendMessages(role);
topic.grantPublish(role);
secret.grantRead(role);

// Policy document
const policy = new iam.ManagedPolicy(this, 'Policy', {
  document: new iam.PolicyDocument({
    statements: [
      new iam.PolicyStatement({
        actions: ['logs:CreateLogGroup', 'logs:CreateLogStream', 'logs:PutLogEvents'],
        resources: ['*'],
      }),
    ],
  }),
});

// Import existing role
const existingRole = iam.Role.fromRoleArn(this, 'Existing', 'arn:aws:iam::123456789012:role/MyRole');
```

## VPC & Networking

```typescript
import * as ec2 from 'aws-cdk-lib/aws-ec2';

// New VPC (creates subnets, NAT gateways, IGW automatically)
const vpc = new ec2.Vpc(this, 'Vpc', {
  maxAzs: 2,
  natGateways: 1,                       // set to 0 for dev to save cost
  subnetConfiguration: [
    { name: 'Public', subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 },
    { name: 'Private', subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS, cidrMask: 24 },
    { name: 'Isolated', subnetType: ec2.SubnetType.PRIVATE_ISOLATED, cidrMask: 28 },
  ],
});

// Lookup existing VPC (requires environment-specific stack)
const existingVpc = ec2.Vpc.fromLookup(this, 'Vpc', { vpcId: 'vpc-12345' });

// Security Group
const sg = new ec2.SecurityGroup(this, 'SG', {
  vpc,
  description: 'My SG',
  allowAllOutbound: true,
});
sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'HTTPS');
sg.addIngressRule(ec2.Peer.securityGroupId(otherSg.securityGroupId), ec2.Port.tcp(5432), 'Postgres from app');

// VPC Endpoints (avoid NAT costs for AWS services)
vpc.addGatewayEndpoint('S3Endpoint', { service: ec2.GatewayVpcEndpointAwsService.S3 });
vpc.addGatewayEndpoint('DynamoEndpoint', { service: ec2.GatewayVpcEndpointAwsService.DYNAMODB });
vpc.addInterfaceEndpoint('SecretsManagerEndpoint', {
  service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
});
```

## ECS & Fargate

```typescript
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';

const cluster = new ecs.Cluster(this, 'Cluster', { vpc, containerInsights: true });

// Fargate service behind ALB (L3 pattern)
const service = new ecsPatterns.ApplicationLoadBalancedFargateService(this, 'Service', {
  cluster,
  cpu: 512,
  memoryLimitMiB: 1024,
  desiredCount: 2,
  taskImageOptions: {
    image: ecs.ContainerImage.fromAsset('./src'),
    containerPort: 3000,
    environment: { NODE_ENV: 'production' },
    secrets: {
      DB_PASSWORD: ecs.Secret.fromSecretsManager(dbSecret, 'password'),
    },
  },
  publicLoadBalancer: true,
  assignPublicIp: false,
});

// Auto scaling
const scaling = service.service.autoScaleTaskCount({ maxCapacity: 10 });
scaling.scaleOnCpuUtilization('CpuScaling', { targetUtilizationPercent: 70 });
scaling.scaleOnRequestCount('RequestScaling', {
  requestsPerTarget: 1000,
  targetGroup: service.targetGroup,
});

// Task definition (manual, lower-level)
const taskDef = new ecs.FargateTaskDefinition(this, 'TaskDef', { cpu: 256, memoryLimitMiB: 512 });
taskDef.addContainer('App', {
  image: ecs.ContainerImage.fromRegistry('nginx:latest'),
  portMappings: [{ containerPort: 80 }],
  logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'app' }),
});
```

## SNS & SQS

```typescript
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';

// SQS Queue
const queue = new sqs.Queue(this, 'Queue', {
  queueName: 'my-queue',
  visibilityTimeout: cdk.Duration.seconds(300),
  retentionPeriod: cdk.Duration.days(14),
  encryption: sqs.QueueEncryption.SQS_MANAGED,
  deadLetterQueue: {
    queue: new sqs.Queue(this, 'DLQ', { retentionPeriod: cdk.Duration.days(14) }),
    maxReceiveCount: 3,
  },
});

// FIFO queue
const fifoQueue = new sqs.Queue(this, 'Fifo', {
  fifo: true,
  contentBasedDeduplication: true,
  queueName: 'my-queue.fifo',          // must end in .fifo
});

// SNS Topic
const topic = new sns.Topic(this, 'Topic', {
  topicName: 'my-topic',
  displayName: 'My Topic',
});

// Subscribe
topic.addSubscription(new subscriptions.SqsSubscription(queue, { rawMessageDelivery: true }));
topic.addSubscription(new subscriptions.LambdaSubscription(lambdaFn));
topic.addSubscription(new subscriptions.EmailSubscription('ops@example.com'));
topic.addSubscription(new subscriptions.UrlSubscription('https://example.com/hook', {
  protocol: sns.SubscriptionProtocol.HTTPS,
}));

// Grants
queue.grantSendMessages(lambdaFn);
queue.grantConsumeMessages(lambdaFn);
topic.grantPublish(lambdaFn);
```

## EventBridge

```typescript
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';

// Default event bus rule (custom events)
const rule = new events.Rule(this, 'Rule', {
  eventBus: events.EventBus.fromEventBusName(this, 'DefaultBus', 'default'),
  eventPattern: {
    source: ['com.myapp.orders'],
    detailType: ['OrderPlaced'],
    detail: { status: ['PENDING'] },
  },
  targets: [
    new targets.LambdaFunction(processFn, { retryAttempts: 2 }),
    new targets.SqsQueue(queue),
  ],
});

// Scheduled rule (cron)
new events.Rule(this, 'Cron', {
  schedule: events.Schedule.cron({ minute: '0', hour: '2' }),
  targets: [new targets.LambdaFunction(cleanupFn)],
});

// Scheduled rule (rate)
new events.Rule(this, 'Heartbeat', {
  schedule: events.Schedule.rate(cdk.Duration.minutes(5)),
  targets: [new targets.LambdaFunction(healthFn)],
});

// Custom event bus
const bus = new events.EventBus(this, 'Bus', { eventBusName: 'my-bus' });
```

## Secrets Manager & SSM Parameter Store

```typescript
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as ssm from 'aws-cdk-lib/aws-ssm';

// Create secret
const secret = new secretsmanager.Secret(this, 'Secret', {
  secretName: '/myapp/db/credentials',
  generateSecretString: {
    secretStringTemplate: JSON.stringify({ username: 'admin' }),
    generateStringKey: 'password',
    excludeCharacters: '"@/\\',
  },
});
secret.grantRead(lambdaFn);

// Import existing secret
const existing = secretsmanager.Secret.fromSecretNameV2(this, 'Existing', '/myapp/api-key');

// Pass to Lambda
const fn = new NodejsFunction(this, 'Fn', {
  environment: {
    SECRET_ARN: secret.secretArn,           // reference ARN, fetch at runtime
  },
});

// SSM Parameter
const param = new ssm.StringParameter(this, 'Param', {
  parameterName: '/myapp/config/endpoint',
  stringValue: 'https://api.example.com',
  tier: ssm.ParameterTier.STANDARD,
});
param.grantRead(lambdaFn);

// SecureString (managed externally — CDK can't create SecureString)
const secureParam = ssm.StringParameter.fromSecureStringParameterAttributes(this, 'Secure', {
  parameterName: '/myapp/api-key',
});
```

## RDS

```typescript
import * as rds from 'aws-cdk-lib/aws-rds';

// Aurora Serverless v2 (recommended for most new projects)
const cluster = new rds.DatabaseCluster(this, 'Cluster', {
  engine: rds.DatabaseClusterEngine.auroraPostgres({
    version: rds.AuroraPostgresEngineVersion.VER_16_4,
  }),
  serverlessV2MinCapacity: 0.5,
  serverlessV2MaxCapacity: 8,
  writer: rds.ClusterInstance.serverlessV2('writer'),
  readers: [rds.ClusterInstance.serverlessV2('reader', { scaleWithWriter: true })],
  vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
  credentials: rds.Credentials.fromGeneratedSecret('postgres'),
  removalPolicy: cdk.RemovalPolicy.RETAIN,
  backup: { retention: cdk.Duration.days(7) },
});

// RDS Proxy (recommended when Lambda connects to RDS — manages connection pooling)
const proxy = cluster.addProxy('Proxy', {
  secrets: [cluster.secret!],
  vpc,
  requireTLS: true,
  idleClientTimeout: cdk.Duration.minutes(5),
});
proxy.grantConnect(lambdaFn, 'postgres');

// Standard RDS instance
const instance = new rds.DatabaseInstance(this, 'DB', {
  engine: rds.DatabaseInstanceEngine.postgres({ version: rds.PostgresEngineVersion.VER_16 }),
  instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MEDIUM),
  vpc,
  credentials: rds.Credentials.fromGeneratedSecret('postgres'),
  multiAz: true,
  storageEncrypted: true,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});
```

## CloudFront

```typescript
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';

// S3 + CloudFront (static site / SPA)
const distribution = new cloudfront.Distribution(this, 'Distribution', {
  defaultBehavior: {
    origin: new origins.S3StaticWebsiteOrigin(bucket),  // or S3BucketOrigin.withOriginAccessControl
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
    allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
  },
  additionalBehaviors: {
    '/api/*': {
      origin: new origins.HttpOrigin('api.example.com'),
      viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
      allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
      originRequestPolicy: cloudfront.OriginRequestPolicy.ALL_VIEWER_EXCEPT_HOST_HEADER,
    },
  },
  domainNames: ['example.com'],
  certificate: acmCertificate,
  defaultRootObject: 'index.html',
  errorResponses: [
    { httpStatus: 403, responseHttpStatus: 200, responsePagePath: '/index.html' },
    { httpStatus: 404, responseHttpStatus: 200, responsePagePath: '/index.html' },
  ],
});
```

## Step Functions

```typescript
import * as sfn from 'aws-cdk-lib/aws-stepfunctions';
import * as tasks from 'aws-cdk-lib/aws-stepfunctions-tasks';

const processItem = new tasks.LambdaInvoke(this, 'ProcessItem', {
  lambdaFunction: processItemFn,
  outputPath: '$.Payload',
});

const waitForApproval = new sfn.Wait(this, 'Wait', {
  time: sfn.WaitTime.duration(cdk.Duration.hours(24)),
});

const success = new sfn.Succeed(this, 'Success');
const fail = new sfn.Fail(this, 'Fail', { error: 'ProcessingFailed' });

const definition = processItem
  .next(new sfn.Choice(this, 'Approved?')
    .when(sfn.Condition.stringEquals('$.status', 'APPROVED'), success)
    .when(sfn.Condition.stringEquals('$.status', 'REJECTED'), fail)
    .otherwise(waitForApproval.next(processItem)));

const stateMachine = new sfn.StateMachine(this, 'StateMachine', {
  definition,
  timeout: cdk.Duration.hours(48),
  tracingEnabled: true,
  stateMachineType: sfn.StateMachineType.STANDARD,  // or EXPRESS for high-volume
});
```

## CloudWatch

```typescript
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as logs from 'aws-cdk-lib/aws-logs';

// Metric alarm
const alarm = new cloudwatch.Alarm(this, 'ErrorAlarm', {
  metric: lambdaFn.metricErrors({ period: cdk.Duration.minutes(5) }),
  threshold: 5,
  evaluationPeriods: 2,
  comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
  alarmDescription: 'Lambda error rate too high',
  treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
});
alarm.addAlarmAction(new cloudwatchActions.SnsAction(alertTopic));

// Dashboard
const dashboard = new cloudwatch.Dashboard(this, 'Dashboard', { dashboardName: 'MyApp' });
dashboard.addWidgets(
  new cloudwatch.GraphWidget({
    title: 'Lambda Errors',
    left: [lambdaFn.metricErrors()],
    right: [lambdaFn.metricInvocations()],
  }),
);

// Log group
const logGroup = new logs.LogGroup(this, 'Logs', {
  logGroupName: `/myapp/${props.stage}/app`,
  retention: logs.RetentionDays.ONE_MONTH,
  removalPolicy: cdk.RemovalPolicy.DESTROY,
});

// Metric filter from logs
const errorMetric = new logs.MetricFilter(this, 'ErrorFilter', {
  logGroup,
  metricNamespace: 'MyApp',
  metricName: 'Errors',
  filterPattern: logs.FilterPattern.literal('[timestamp, level="ERROR", ...]'),
  metricValue: '1',
});
```

## Cognito

```typescript
import * as cognito from 'aws-cdk-lib/aws-cognito';

const userPool = new cognito.UserPool(this, 'UserPool', {
  userPoolName: 'myapp-users',
  selfSignUpEnabled: true,
  signInAliases: { email: true },
  autoVerify: { email: true },
  standardAttributes: {
    email: { required: true, mutable: true },
    fullname: { required: false, mutable: true },
  },
  passwordPolicy: {
    minLength: 12,
    requireLowercase: true,
    requireUppercase: true,
    requireDigits: true,
    requireSymbols: true,
  },
  accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});

const client = userPool.addClient('WebClient', {
  authFlows: {
    userPassword: true,
    userSrp: true,
  },
  oAuth: {
    flows: { authorizationCodeGrant: true },
    scopes: [cognito.OAuthScope.EMAIL, cognito.OAuthScope.OPENID],
    callbackUrls: ['https://example.com/callback'],
  },
});

const identityPool = new cognito.CfnIdentityPool(this, 'IdentityPool', {
  allowUnauthenticatedIdentities: false,
  cognitoIdentityProviders: [{
    clientId: client.userPoolClientId,
    providerName: userPool.userPoolProviderName,
  }],
});
```
