# AWS S3 Blob Storage Bucket Recipe

## Recipe Description

This Terraform recipe deploys an AWS S3 bucket with IAM role-based access controls, storage class configurations, and appropriate security settings based on the `blobStorageBuckets` resource type properties.

## Features

- **Automatic bucket naming**: Generates a unique, globally-valid S3 bucket name
- **Storage class support**: Maps `hot`, `cool`, and `cold` to S3 storage classes (STANDARD, STANDARD_IA, GLACIER)
- **Access control**: Configures bucket permissions based on application, group, and public access settings
- **IAM role-based access**: Creates an IAM role that can be assumed by EC2, ECS, or other AWS services
- **IAM user with assume-role permissions**: Creates a user with credentials that can assume the role for non-AWS environments
- **Versioning**: Enables S3 bucket versioning for data protection
- **Public access blocking**: Configures public access settings based on the `accessControl.public` property

## Usage Instructions

### Prerequisites

- AWS account with appropriate permissions to create:
  - S3 buckets and bucket configurations
  - IAM roles, users, access keys, and policies
- Terraform >= 1.5
- AWS provider >= 5.0

**Required IAM Permissions:**

Your AWS credentials must have the following permissions:

- `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutLifecycleConfiguration`, `s3:PutBucketPublicAccessBlock`, `s3:PutBucketPolicy`
- `iam:CreateRole`, `iam:CreateUser`, `iam:CreateAccessKey`, `iam:PutRolePolicy`, `iam:PutUserPolicy`, `iam:TagRole`, `iam:TagUser`
- `sts:GetCallerIdentity` (for determining AWS account ID)

If you don't have these permissions, contact your AWS administrator.

### Recipe Registration

Register this recipe in your Radius environment:

```bash
rad recipe register aws-s3 \
  --environment <environment-name> \
  --resource-type Radius.Storage/blobStorageBuckets \
  --template-kind terraform \
  --template-path git::https://github.com/<your-org>/<your-repo>.git//types/blobStorageBuckets/recipes/aws/terraform
```

### Properties Mapping

| Radius Property | AWS Resource | Description |
|---|---|---|
| `class: hot` | S3 STANDARD storage class | Frequently accessed data |
| `class: cool` | S3 STANDARD_IA storage class | Infrequently accessed data |
| `class: cold` | S3 GLACIER storage class | Archived data |
| `accessControl.application: ReadWrite` | IAM policy with Get, Put, Delete, List | Full access for the application |
| `accessControl.application: Read` | IAM policy with Get, List only | Read-only access |
| `accessControl.application: None` | No IAM permissions | No access |
| `accessControl.public: Read` | S3 bucket policy for public read | Public read access |
| `accessControl.public: None` | Block all public access | Private bucket (default) |

### Output Properties

The recipe sets the following read-only properties in the resource:

- `uniqueName`: The globally unique S3 bucket name
- `region`: The AWS region where the bucket is deployed
- `endpointUrl`: The S3 API endpoint URL
- `roleArn`: The ARN of the IAM role for S3 access (can be used with AssumeRole)
- `awsAccessKeyId`: The IAM access key ID (secret) - for use with AssumeRole
- `awsSecretAccessKey`: The IAM secret access key (secret) - for use with AssumeRole

## Authentication Methods

This recipe provides two authentication methods:

### Method 1: IAM Role (Recommended for AWS Services)

For applications running on AWS services (EC2, ECS, EKS), use the IAM role directly:

- The role ARN is available in `roleArn` output
- Configure your application to assume this role using AWS SDK
- No credentials need to be stored in your application

### Method 2: Access Keys with AssumeRole (For Non-AWS Environments)

For applications running outside AWS or in Kubernetes:

- Use the provided `awsAccessKeyId` and `awsSecretAccessKey`
- These credentials have permission to assume the role
- Your application should use STS AssumeRole to get temporary credentials
- The role ARN is provided in the `roleArn` output

## Example Application

```bicep
extension radius
extension blobStorageBuckets

param environment string

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'myapp'
  properties: {
    environment: environment
  }
}

resource bucket 'Radius.Storage/blobStorageBuckets@2025-08-01-preview' = {
  name: 'mydata'
  properties: {
    environment: environment
    application: app.id
    class: 'cool'
    accessControl: {
      application: 'ReadWrite'
      public: 'None'
    }
  }
}
```

## Notes

- The recipe generates unique bucket names by appending a random 8-character suffix
- **IAM Role-Based Access**: The recipe creates an IAM role with S3 permissions that can be assumed by:
  - EC2 instances
  - ECS tasks
  - Any principal in the same AWS account (can be further restricted)
- **IAM User for External Access**: A user is created with permissions to assume the role, providing credentials for non-AWS environments
- Bucket versioning is enabled by default for data protection
- Storage class transitions follow AWS minimum requirements:
  - `cool` (STANDARD_IA): Objects transition after 30 days
  - `cold` (GLACIER): Objects transition after 90 days
  - `hot` (STANDARD): No lifecycle transitions applied

## Security Best Practices

1. **Use IAM roles** when running on AWS services (EC2, ECS, EKS)
2. **Use AssumeRole** with temporary credentials instead of long-lived access keys when possible
3. The user credentials only have permission to assume the role, not direct S3 access
4. Consider adding additional trust policy conditions to restrict role assumption
5. Regularly rotate access keys if using Method 2
