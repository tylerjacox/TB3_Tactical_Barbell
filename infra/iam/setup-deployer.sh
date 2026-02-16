#!/bin/bash
# Run this with an admin/root AWS account to create the tb3-deployer IAM user.
# Usage: bash infra/iam/setup-deployer.sh
set -euo pipefail

USER_NAME="tb3-deployer"
POLICY_NAME="Tb3DeployerPolicy"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Creating IAM user: $USER_NAME"
aws iam create-user --user-name "$USER_NAME"

echo "Creating IAM policy: $POLICY_NAME"
POLICY_ARN=$(aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document "file://${SCRIPT_DIR}/tb3-deployer-policy.json" \
  --query 'Policy.Arn' --output text)

echo "Attaching policy to user..."
aws iam attach-user-policy --user-name "$USER_NAME" --policy-arn "$POLICY_ARN"

echo "Creating access key..."
aws iam create-access-key --user-name "$USER_NAME"

echo ""
echo "Done! Save the AccessKeyId and SecretAccessKey above."
echo "Configure with: aws configure --profile tb3-deployer"
