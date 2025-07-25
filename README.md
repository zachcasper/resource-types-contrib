# Radius Resource Types and Recipes Contributions

This repository contains the core Radius and community-contributed Resource Types and Recipes for Radius Environments, enabling platform engineers to extend Radius capabilities to their Internal developer platforms

## Overview

Radius is a cloud-native application platform that enables developers and the platform engineers that support them to collaborate on delivering and managing cloud-native applications that follow organizational best practices for cost, operations and security, by default. Radius is designed to be extensible across different compute platforms and providers. This repository serves as the central hub for community contributions of:

- **Resource Types**: Schema definitions of the Radius core and community-contributed resources
- **Recipes**: Platform-specific provisioning templates using Bicep or Terraform
- **Recipe Packs**: Bundled collections of Recipes by compute platform or deployment scenario

## What are Resource Types?

Resource Types are simple abstractions that define the schema for different types of resources in the Radius ecosystem. They provide a consistent interface that enables developers to define and manage resources in their applications.

## What are Recipes?

Recipes define how the Resource types are provisioned on different compute platforms and cloud environments. Platform engineers or infrastructure operators define Recipes to provision the infrastructure in a secured way following the organization's best practices. Refer to the [Recipes overview page](https://docs.radapp.io/guides/recipes/overview/).

## What are Recipe Packs?

Recipe Packs are collections of Recipes that are grouped together to provide a complete solution for a specific compute platform or deployment scenario. They allow platform engineers to easily deploy and manage resources across different environments using pre-defined configurations.

## Repository Structure

```
resource-types-contrib/
├── README.md
├── <category of the resource type>/    #e.g., core/
│   ├── <name of the resource type>/   # e.g., containers/
│   │   ├── `<resourcetype>.yaml`/  # e.g., containers.yaml  
│   │   ├── recipes/     # Recipes for this type
│   │   │       ├── <provider1> # e.g., azure/
│   │   │       │       ├── bicep
│   │   │       │       │       ├── azure-aci.bicep
│   │   │       │       │       └── azure-aci.params
│   │   │       │       └── terraform
│   │   │       │               ├── main.tf
│   │   │       │               └── var.tf
│   │   │       ├── <provider2> # e.g., kubernetes/
│   │   │       │       ├── bicep
│   │   │       │       │       ├── kubernetes.bicep
│   │   │       │       │       └── kubernetes.params
│   │   │       │       └── terraform
│   │   │       │               ├── main.tf
│   │   │       │               └── var.tf
├── recipe-packs/
│   ├── azure-aci/         # Azure Container Instances Recipes
│   ├── kubernetes/        # Kubernetes platform Recipes
│   └── ...
```

## Contributing

Community members can contribute new Resource Types, Recipes and Recipe packs to this repository. Follow the [Contribution.md](CONTRIBUTING.md) guidelines for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Code of Conduct

Please refer to our [Radius Community Code of Conduct](https://github.com/radius-project/radius/blob/main/CODE_OF_CONDUCT.md)