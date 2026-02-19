import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaNodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as apigateway from 'aws-cdk-lib/aws-apigatewayv2';
import * as apiIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as apiAuthorizers from 'aws-cdk-lib/aws-apigatewayv2-authorizers';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as path from 'path';
import { Construct } from 'constructs';

interface Tb3ApiStackProps extends cdk.StackProps {
  userPool: cognito.UserPool;
  userPoolClient: cognito.UserPoolClient;
}

export class Tb3ApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: Tb3ApiStackProps) {
    super(scope, id, props);

    // Look up the user pool and client by hardcoded IDs to avoid cross-stack
    // export drift. CDK version changes caused the cross-stack export logical
    // IDs to change (UserPoolAuthorizerClient → AppClient), which blocks
    // deployment. Using hardcoded IDs avoids the cross-stack export entirely.
    const userPool = cognito.UserPool.fromUserPoolId(
      this, 'ImportedUserPool', 'us-west-2_JwSNJXX9t',
    );
    const userPoolClient = cognito.UserPoolClient.fromUserPoolClientId(
      this, 'ImportedUserPoolClient', '7ebq8hk7m52uqp636n31s7ussb',
    );

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
      userPool,
      { userPoolClients: [userPoolClient] },
    );

    httpApi.addRoutes({
      path: '/sync',
      methods: [apigateway.HttpMethod.POST],
      integration: new apiIntegrations.HttpLambdaIntegration('SyncIntegration', syncFunction),
      authorizer,
    });

    // Strava token exchange proxy — keeps client_secret server-side
    const stravaSecret = secretsmanager.Secret.fromSecretNameV2(
      this, 'StravaOAuthSecret', 'tb3/strava-oauth',
    );

    const stravaTokenFunction = new lambdaNodejs.NodejsFunction(this, 'StravaTokenFunction', {
      entry: path.join(__dirname, '../lambda/strava-token.ts'),
      handler: 'handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      environment: {
        STRAVA_SECRET_NAME: stravaSecret.secretName,
      },
      timeout: cdk.Duration.seconds(10),
      memorySize: 256,
      bundling: {
        minify: true,
        sourceMap: true,
        externalModules: ['@aws-sdk/*'],
      },
    });

    stravaSecret.grantRead(stravaTokenFunction);

    // No auth required — the OAuth code is single-use
    httpApi.addRoutes({
      path: '/strava/token',
      methods: [apigateway.HttpMethod.POST],
      integration: new apiIntegrations.HttpLambdaIntegration('StravaTokenIntegration', stravaTokenFunction),
    });

    // Spotify token exchange proxy — keeps client_secret server-side
    const spotifySecret = secretsmanager.Secret.fromSecretNameV2(
      this, 'SpotifyOAuthSecret', 'tb3/spotify',
    );

    const spotifyTokenFunction = new lambdaNodejs.NodejsFunction(this, 'SpotifyTokenFunction', {
      entry: path.join(__dirname, '../lambda/spotify-token.ts'),
      handler: 'handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      environment: {
        SPOTIFY_SECRET_NAME: spotifySecret.secretName,
      },
      timeout: cdk.Duration.seconds(10),
      memorySize: 256,
      bundling: {
        minify: true,
        sourceMap: true,
        externalModules: ['@aws-sdk/*'],
      },
    });

    spotifySecret.grantRead(spotifyTokenFunction);

    httpApi.addRoutes({
      path: '/spotify/token',
      methods: [apigateway.HttpMethod.POST],
      integration: new apiIntegrations.HttpLambdaIntegration('SpotifyTokenIntegration', spotifyTokenFunction),
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
