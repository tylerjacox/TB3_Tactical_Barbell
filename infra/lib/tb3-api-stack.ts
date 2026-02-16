import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaNodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as apigateway from 'aws-cdk-lib/aws-apigatewayv2';
import * as apiIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as apiAuthorizers from 'aws-cdk-lib/aws-apigatewayv2-authorizers';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as path from 'path';
import { Construct } from 'constructs';

interface Tb3ApiStackProps extends cdk.StackProps {
  userPool: cognito.UserPool;
}

export class Tb3ApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: Tb3ApiStackProps) {
    super(scope, id, props);

    // DynamoDB table — single-table design
    // PK: USER#{cognitoUserId}, SK: entity type + ID
    // PAY_PER_REQUEST billing (cheapest for low traffic)
    const table = new dynamodb.Table(this, 'Tb3Data', {
      tableName: 'tb3-data',
      partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
    });

    // Lambda function — sync endpoint, bundled with esbuild
    const syncFunction = new lambdaNodejs.NodejsFunction(this, 'SyncFunction', {
      entry: path.join(__dirname, '../lambda/sync.ts'),
      handler: 'handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      environment: {
        TABLE_NAME: table.tableName,
      },
      timeout: cdk.Duration.seconds(10),
      memorySize: 256,
      bundling: {
        minify: true,
        sourceMap: true,
        externalModules: ['@aws-sdk/*'],
      },
    });

    table.grantReadWriteData(syncFunction);

    // HTTP API with Cognito JWT authorizer
    const httpApi = new apigateway.HttpApi(this, 'HttpApi', {
      apiName: 'tb3-api',
      corsPreflight: {
        allowOrigins: ['*'],
        allowMethods: [apigateway.CorsHttpMethod.POST, apigateway.CorsHttpMethod.OPTIONS],
        allowHeaders: ['Content-Type', 'Authorization'],
        maxAge: cdk.Duration.days(1),
      },
    });

    const authorizer = new apiAuthorizers.HttpUserPoolAuthorizer(
      'CognitoAuthorizer',
      props.userPool,
    );

    httpApi.addRoutes({
      path: '/sync',
      methods: [apigateway.HttpMethod.POST],
      integration: new apiIntegrations.HttpLambdaIntegration('SyncIntegration', syncFunction),
      authorizer,
    });

    // Stack outputs
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: httpApi.apiEndpoint,
      exportName: 'Tb3ApiUrl',
    });

    new cdk.CfnOutput(this, 'TableName', {
      value: table.tableName,
      exportName: 'Tb3TableName',
    });
  }
}
