# Radius.Storage/blobStorageBuckets

## Overview

The **Radius.Storage/blobStorageBuckets** resource type represents an S3 API-compatible storage bucket. It allows developers to easily integrate blob storage into their Radius applications using a consistent interface across multiple cloud platforms (AWS, Azure, Kubernetes).

Developer documentation is embedded in the resource type definition YAML file, and it is accessible via the `rad resource-type show Radius.Storage/blobStorageBuckets` command.

## Recipes

A list of available Recipes for this resource type, including links to the Terraform templates:

|Platform| IaC Language| Recipe Name | Stage |
|---|---|---|---|
| AWS | Terraform | [recipes/aws/terraform/main.tf](recipes/aws/terraform/main.tf) | Alpha |
| Azure | Terraform | recipes/azure/terraform/main.tf | Planned |
| Kubernetes | Terraform | recipes/kubernetes/terraform/main.tf | Planned |

## Recipe Input Properties

Properties for the **Radius.Storage/blobStorageBuckets** resource type are provided via the [Recipe Context](https://docs.radapp.io/reference/context-schema/) object. These properties include:

- `context.properties.class` (string, optional): The storage class - `hot`, `cool`, or `cold`. If not specified, Recipes should assume `hot`.
  - `hot`: Frequently accessed data (AWS: S3 STANDARD, Azure: Hot tier)
  - `cool`: Infrequently accessed data (AWS: S3 STANDARD_IA, Azure: Cool tier)
  - `cold`: Archived data (AWS: S3 GLACIER, Azure: Archive tier)

- `context.properties.accessControl` (object, optional): Access control settings for the bucket
  - `context.properties.accessControl.application` (string, optional): Application access level - `None`, `Read`, or `ReadWrite`. If not specified, Recipes should assume `ReadWrite`.
  - `context.properties.accessControl.group` (string, optional): Resource group access level - `None`, `Read`, or `ReadWrite`. If not specified, Recipes should assume `ReadWrite`.
  - `context.properties.accessControl.public` (string, optional): Public access level - `None` or `Read`. If not specified, Recipes should assume `None`.

## Recipe Output Properties

The **Radius.Storage/blobStorageBuckets** resource type expects the following output properties to be set in the result object by the Recipe:

### Required Values

- `values.uniqueName` (string): The globally unique name of the storage bucket
- `values.region` (string): The region/location of the storage bucket
- `values.endpointUrl` (string): The S3-compatible API endpoint URL

### Required Secrets

- `secrets.awsAccessKeyId` (string): The access key ID for S3 API authentication
- `secrets.awsSecretAccessKey` (string): The secret access key for S3 API authentication

## Custom Recipe Requirements

When authoring a custom Recipe for this resource type, ensure:

1. **Unique naming**: Generate globally unique bucket names (S3 bucket names are globally unique)
2. **Storage class mapping**: Map the `class` property to platform-specific storage tiers
3. **Access control**: Implement proper IAM/RBAC policies based on `accessControl` properties
4. **Credentials**: Provide S3-compatible access credentials in the secrets output
5. **Endpoint URL**: Return the correct S3 API endpoint for the platform
6. **Idempotency**: Ensure the Recipe can be run multiple times without errors

## Connection Environment Variables

When a container connects to a blobStorageBucket resource, the following environment variables are automatically created:

- `CONNECTION_<RESOURCE_NAME>_UNIQUENAME`: The bucket's unique name
- `CONNECTION_<RESOURCE_NAME>_REGION`: The bucket's region
- `CONNECTION_<RESOURCE_NAME>_ENDPOINTURL`: The S3 API endpoint
- `CONNECTION_<RESOURCE_NAME>_AWSACCESSKEYID`: The access key ID
- `CONNECTION_<RESOURCE_NAME>_AWSSECRETACCESSKEY`: The secret access key

Replace `<RESOURCE_NAME>` with your resource name in uppercase (e.g., `MYBUCKET`).
