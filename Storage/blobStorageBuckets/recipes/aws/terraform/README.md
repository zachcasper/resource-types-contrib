# AWS S3 Blob Storage Bucket Recipe

## Recipe Description

This Terraform recipe deploys an AWS S3 bucket with appropriate access controls, IAM users, and storage class configurations based on the `blobStorageBuckets` resource type properties.

## Features

- **Automatic bucket naming**: Generates a unique, globally-valid S3 bucket name
- **Storage class support**: Maps `hot`, `cool`, and `cold` to S3 storage classes (STANDARD, STANDARD_IA, GLACIER)
- **Access control**: Configures bucket permissions based on application, group, and public access settings
- **IAM user creation**: Creates a dedicated IAM user with access keys for S3 access
- **Versioning**: Enables S3 bucket versioning for data protection
- **Public access blocking**: Configures public access settings based on the `accessControl.public` property

## Usage Instructions

### Prerequisites

- AWS account with appropriate permissions to create S3 buckets and IAM users
- Terraform >= 1.5
- AWS provider >= 5.0

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
- `awsAccessKeyId`: The IAM access key ID (secret)
- `awsSecretAccessKey`: The IAM secret access key (secret)

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
- IAM access keys are stored as secrets and can be accessed via environment variables in connected containers
- Bucket versioning is enabled by default for data protection
- Storage class transitions are applied immediately (day 0) for `cool` and `cold` classes
