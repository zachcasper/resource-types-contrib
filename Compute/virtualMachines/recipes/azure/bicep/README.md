# Azure Virtual Machine Bicep Template

This Bicep template creates an Azure Virtual Machine based on the Radius.Compute/virtualMachines schema parameters.

## Features

- **Flexible VM Sizing**: Automatically selects appropriate Azure VM SKUs based on CPU count and workload type (Burst, Standard, ComputeOptimized, MemoryOptimized)
- **OS Support**: Supports both Linux (Ubuntu 22.04) and Windows Server 2022
- **Network Configuration**: Can use existing VNet or create a new one with proper subnet configuration
- **Security**: Includes Network Security Group with SSH/RDP access rules
- **Authentication**: Supports SSH key authentication for Linux and password authentication for Windows
- **Startup Scripts**: Supports custom startup script execution via cloud-init/custom data
- **Resource Tagging**: Applies Radius environment and application tags to all resources

## Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `context` | object | Radius recipe context containing resource configuration and metadata |

The `context` object contains:
- `context.environment.name` - The Radius Environment name
- `context.application.name` - The Radius Application name  
- `context.resource.name` - The name of the virtual machine resource
- `context.resource.properties.operatingSystem` - Operating system: 'Linux' or 'Windows'
- `context.resource.properties.cpu` - Number of vCPUs as string: '1', '2', '4', '8', '16', or '32'
- `context.resource.properties.kind` - VM type: 'Burst', 'Standard', 'ComputeOptimized', 'MemoryOptimized' (optional, defaults to 'Standard')
- `context.resource.properties.memoryInMib` - Memory in MiB (optional, auto-calculated if not specified)
- `context.resource.properties.sshKey` - SSH key configuration for Linux VMs (optional)
- `context.resource.properties.windowsAdminPassword` - Windows admin password configuration (optional)
- `context.resource.properties.startupScript` - Startup script configuration (optional)

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | resourceGroup().location | Azure region |
| `adminPasswordOverride` | string (secure) | auto-generated | Administrator password for Windows VMs |
| `vnetId` | string | null | Existing VNet resource ID (creates new VNet if not provided) |
| `subnetName` | string | 'default' | Subnet name when using existing VNet |

## VM Size Mapping

The template automatically selects Azure VM SKUs based on the `cpu` and `kind` parameters:

### Burst VMs (for variable workloads)
- 1 CPU: Standard_B1ms
- 2 CPU: Standard_B2s
- 4 CPU: Standard_B4ms
- 8 CPU: Standard_B8ms
- 16 CPU: Standard_B16ms
- 32 CPU: Standard_B32ms

### Standard VMs (balanced compute and memory)
- 1 CPU: Standard_A1_v2
- 2 CPU: Standard_A2_v2
- 4 CPU: Standard_A4_v2
- 8 CPU: Standard_A8_v2
- 16 CPU: Standard_D16s_v3
- 32 CPU: Standard_D32s_v3

### ComputeOptimized VMs (high CPU-to-memory ratio)
- 1 CPU: Standard_F1s
- 2 CPU: Standard_F2s_v2
- 4 CPU: Standard_F4s_v2
- 8 CPU: Standard_F8s_v2
- 16 CPU: Standard_F16s_v2
- 32 CPU: Standard_F32s_v2

### MemoryOptimized VMs (high memory-to-CPU ratio)
- 1 CPU: Standard_E2s_v3
- 2 CPU: Standard_E2s_v3
- 4 CPU: Standard_E4s_v3
- 8 CPU: Standard_E8s_v3
- 16 CPU: Standard_E16s_v3
- 32 CPU: Standard_E32s_v3

## Memory Calculation

If `memoryInMib` is not specified, memory is automatically calculated based on the VM kind:
- **Burst/Standard/ComputeOptimized**: 2 GB per vCPU
- **MemoryOptimized**: 4 GB per vCPU

## Usage Examples

### Linux VM with existing VNet
```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azure-vm.bicep \
  --parameters \
    context='{"environment":{"name":"prod"},"application":{"name":"webapp"},"resource":{"name":"web-server-01","properties":{"operatingSystem":"Linux","cpu":"4","kind":"Standard","sshKey":{"secretKeyRef":{"key":"ssh-rsa AAAAB3NzaC1yc2EAAAA..."}}}}}' \
    vnetId="/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/my-vnet" \
    subnetName="web-subnet"
```

### Windows VM with new VNet
```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azure-vm.bicep \
  --parameters \
    context='{"environment":{"name":"dev"},"application":{"name":"testapp"},"resource":{"name":"windows-vm-01","properties":{"operatingSystem":"Windows","cpu":"2","kind":"Burst"}}}'
```

### Using Parameters File
```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azure-vm.bicep \
  --parameters @parameters.json
```

Note: In a Radius recipe deployment, the `context` object is automatically provided by the Radius platform and contains the resource configuration from the virtualMachines.yaml schema.

## Outputs

The template provides the following outputs:

- `vmName`: Name of the created VM
- `vmId`: Resource ID of the VM
- `publicIpAddress`: Public IP address
- `fqdn`: Fully qualified domain name
- `privateIpAddress`: Private IP address
- `vmSize`: Selected Azure VM SKU
- `calculatedMemoryMiB`: Calculated memory in MiB
- `sshConnectionString`: SSH connection command (Linux VMs)
- `rdpConnectionString`: RDP connection command (Windows VMs)

## Security Considerations

- SSH key authentication is recommended for Linux VMs
- Strong passwords are required for Windows VMs
- Network Security Group allows SSH (port 22) and RDP (port 3389) from any source - consider restricting source IP ranges in production
- All resources are tagged with Radius environment and application identifiers for governance

## Prerequisites

- Azure CLI or Azure PowerShell
- Bicep CLI (if deploying with `az deployment group create` using Bicep files)
- Appropriate Azure permissions to create virtual machines and networking resources