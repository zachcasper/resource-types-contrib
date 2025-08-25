# Radius Resource Types and Recipes Contributions

## Overview

This repository contains Radius Resource Type definitions and Recipes for deploying those resource types. It includes:

- **Resource Type Defintions**: Schema definitions for resource types available for developers to use while defining their application
- **Recipes**: Platform-specific Infrastructure as Code used to deploy the associated resource type
- **Recipe Packs**: Bundled collections of Recipes organized compute platform or deployment scenario

## What are Resource Types?

Resource types are abstractions that define the schema for resources in the Radius. They provide a consistent interface that enables developers to define their application's resources that is separated from the platform engineer's implementation.

## What are Recipes?

Recipes define how the Resource types are provisioned on different compute platforms and cloud environments. Recipes provide the implementation of the interface defined in the resource type definition. To learn more about Recipes, please visit [Recipes overview](https://docs.radapp.io/guides/recipes/overview/) in the Radius documentation.

## What are Recipe Packs?

Recipe Packs are collections of Recipes that are grouped together to provide a complete solution for a specific compute platform or deployment scenario. Recipe Packs enable platform engineers to easily add an entire collection of Recipes to a Radius Environment. The Recipe Packs feature is currently under development.

## Repository Structure

```
resource-types-contrib/
├── <resource_type_namespace>/          # Namespace excluding Radius; the namespace Radius.Data is in the Data directory
│   ├── <resource_type_name>/           # e.g., redisCaches/
│   │   ├── README.MD                   # Documentation for platform engineers
│   │   ├── <resource_type_name>.yaml/  # e.g., redisCaches.yaml
│   │   ├── recipes/                    # Recipes for this type
│   │   │       ├── <platform-service>  # e.g., azure-cache/
│   │   │       │       ├── bicep
│   │   │       │       │       ├── azure-cache.bicep
│   │   │       │       │       └── azure-cache.params
│   │   │       │       └── terraform
│   │   │       │               ├── main.tf
│   │   │       │               └── var.tf
│   │   │       ├── <platform-service>  # e.g., aws-memorydb/
│   │   │       │       ├── bicep
│   │   │       │       │       ├── aws-memorydb.bicep
│   │   │       │       │       └── aws-memorydb.params
│   │   │       │       └── terraform
│   │   │       │               ├── main.tf
│   │   │       │               └── var.tf
│   │   │       └── <platform-service>  # e.g., kubernetes/
│   │                   ├── bicep
│   │                   │       ├── kubernetes-redis.bicep
│   │                   │       └── kubernetes-redis.params
│   │                   └── terraform
│   │                           ├── main.tf
│   │                           └── var.tf
├── recipe-packs/
│   ├── azure-aci/                      # Azure Container Instances Recipes
│   ├── kubernetes/                     # Kubernetes platform Recipes
│   └── ...


```

## Contributing

Community members can contribute new Resource Types, Recipes and Recipe Packs to this repository. Follow the [Contribution.md](CONTRIBUTING.MD) guidelines for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Code of Conduct

Please refer to our [Radius Community Code of Conduct](https://github.com/radius-project/radius/blob/main/CODE_OF_CONDUCT.md)
