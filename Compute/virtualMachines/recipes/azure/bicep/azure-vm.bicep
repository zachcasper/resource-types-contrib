// Azure Virtual Machine Bicep Template
// This template creates a virtual machine on Azure based on the Radius.Compute/virtualMachines schema

@description('Radius recipe context containing resource configuration and metadata')
param context object

@description('Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Virtual Network ID (if not provided, a new VNet will be created)')
param existingVnetId string?

@description('Subnet name to use when an existing VNet is provided')
param existingSubnetName string?

@description('Windows admin password from context - Radius will populate this from context.resource.properties.windowsAdminPassword.secretKeyRef.key for Windows VMs')
@secure()
param adminPassword string = ''

@description('VM size mapping based on CPU and kind')
var vmSizeMap = {
  Burst: ['Standard_B1ms', 'Standard_B2s', 'Standard_B4ms', 'Standard_B8ms', 'Standard_B16ms', 'Standard_B32ms']
  Standard: ['Standard_A1_v2', 'Standard_A2_v2', 'Standard_A4_v2', 'Standard_A8_v2', 'Standard_D16s_v3', 'Standard_D32s_v3']
  ComputeOptimized: ['Standard_F1s', 'Standard_F2s_v2', 'Standard_F4s_v2', 'Standard_F8s_v2', 'Standard_F16s_v2', 'Standard_F32s_v2']
  MemoryOptimized: ['Standard_E2s_v3', 'Standard_E2s_v3', 'Standard_E4s_v3', 'Standard_E8s_v3', 'Standard_E16s_v3', 'Standard_E32s_v3']
}

@description('CPU values to array index mapping')
var cpuToIndex = {
  '1': 0
  '2': 1
  '4': 2
  '8': 3
  '16': 4
  '32': 5
}

// Extract values from Radius context
var environment = context.environment.name
var application = context.application.name
var resourceName = context.resource.name
var resourceConfig = context.resource.properties

// Extract VM configuration from context
var vmName = resourceName
var kind = resourceConfig.kind ?? 'Burst'
var cpu = int(resourceConfig.cpu ?? 1)
var operatingSystem = resourceConfig.operatingSystem
var publiclyAccessible = resourceConfig.publiclyAccessible ?? false

// Extract authentication and startup configuration from context
// SSH key is required for Linux VMs, Windows admin password is required for Windows VMs
var sshPublicKey = operatingSystem == 'Linux' ? resourceConfig.sshKey.secretKeyRef.key : ''
var startupScriptContent = resourceConfig.startupScript != null ? resourceConfig.startupScript.content : null

@description('Selected VM size based on CPU count and kind')
var selectedVmSize = vmSizeMap[kind][cpuToIndex[string(cpu)]]

@description('Generate a unique name suffix')
var uniqueSuffix = substring(uniqueString(resourceGroup().id, vmName), 0, 8)

@description('Common tags for all resources')
var commonTags = {
  'radapp.io/resource': resourceName
  'radapp.io/resource-type': 'Applications.Compute/virtualMachines'
  'radapp.io/application': application
  'radapp.io/environment': environment
  'radapp.io/resource-group': resourceGroup().name
}

@description('Check if we should use an existing VNet')
var useExistingVnet = existingVnetId != null

@description('VNet name')
var vnetName = 'vnet-${vmName}-${uniqueSuffix}'

@description('Subnet name for the VM')
var vmSubnetName = useExistingVnet ? existingSubnetName! : 'subnet-radius'

// Virtual Network (only created if vnetId is not provided)
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = if (!useExistingVnet) {
  name: vnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: vmSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${vmName}-${uniqueSuffix}'
  location: location
  tags: commonTags
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'RDP'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'  
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Public IP
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (publiclyAccessible) {
  name: 'pip-${vmName}-${uniqueSuffix}'
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${vmName}-${uniqueSuffix}'
    }
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${vmName}-${uniqueSuffix}'
  location: location
  tags: commonTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: publiclyAccessible ? {
            id: publicIp.id
          } : null
          subnet: {
            id: useExistingVnet ? '${existingVnetId}/subnets/${vmSubnetName}' : '${vnet.id}/subnets/${vmSubnetName}'
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: commonTags
  properties: {
    hardwareProfile: {
      vmSize: selectedVmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: operatingSystem == 'Linux' ? 'azureuser' : 'azureadmin'
      adminPassword: operatingSystem == 'Windows' ? adminPassword : null
      customData: startupScriptContent != null ? base64(startupScriptContent!) : null
      linuxConfiguration: operatingSystem == 'Linux' ? {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      } : null
      windowsConfiguration: operatingSystem == 'Windows' ? {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      } : null
    }
    storageProfile: {
      imageReference: operatingSystem == 'Linux' ? {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      } : {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-g2'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-${vmName}-${uniqueSuffix}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Outputs
@description('Result object containing all computed readonly properties')
output result object = {
  resources: [
    vm.id
  ]
  values: {
    publicIpAddress: publiclyAccessible ? publicIp.properties.ipAddress : null
    privateIpAddress: nic.properties.ipConfigurations[0].properties.privateIPAddress
    fqdn: publiclyAccessible ? publicIp.properties.dnsSettings.fqdn : null
  }
}
