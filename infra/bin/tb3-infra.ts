#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { Tb3Stack } from '../lib/tb3-stack';
import { Tb3ApiStack } from '../lib/tb3-api-stack';

const app = new cdk.App();

const hostingStack = new Tb3Stack(app, 'Tb3Stack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
});

const apiStack = new Tb3ApiStack(app, 'Tb3ApiStack', {
  userPool: hostingStack.userPool,
  userPoolClient: hostingStack.userPoolClient,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
});

apiStack.addDependency(hostingStack);
