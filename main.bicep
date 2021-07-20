// main.bicep
targetScope = 'subscription' // tenant', 'managementGroup', 'subscription', 'resourceGroup'

param vmPgsqlUsername string
param vmPgsqlPassword string
param resourceGroupName string = 'not-set'
param namePrefix string = 'not set'


module vnet_generic './vnets/vnet-generic.bicep' = {
  name: 'vnet'
  scope: resourceGroup(resourceGroupName)
  params: {
    namePrefix: '${namePrefix}-vnet'
  }
}


module vm_pgsql './virtual-machines/postgresql/vm-postgresql.bicep' = {
  name: 'vm-pgsql'
  scope: resourceGroup(resourceGroupName)
  params: {
    namePrefix: '${namePrefix}-vm'
    subnetId: vnet_generic.outputs.subnetId
    username: vmPgsqlUsername
    password: vmPgsqlPassword
  }
}
 

output vmName string = vm_pgsql.name
// vnets\vnet-generic.bicep
param namePrefix string = 'unique'
param location string = resourceGroup().location

var name = '${namePrefix}-${uniqueString(resourceGroup().id)}'
var subnetName = 'main-subnet'

resource vnet_generic 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}


output vnetId string = vnet_generic.id
output subnetId string = '${vnet_generic.id}/subnets/${subnetName}'
output subnetName string = subnetName
// virtual-machines\gneral\vm-small
param namePrefix string = 'unique'
param location string = resourceGroup().location
param subnetId string
param privateIPAddress string =  '10.0.0.4'

var vmName = '${namePrefix}${uniqueString(resourceGroup().id)}'

resource nic_pgsql 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: vmName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: privateIPAddress
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}


output nicId string = nic_pgsql.id
// virtual-machines\general\vm-small.bicep
param namePrefix string = 'unique'
param location string = resourceGroup().location
param subnetId string
param ubuntuOsVersion string = '18.04-LTS'
param osDiskType string = 'Standard_LRS'
param vmSize string = 'Standard_B1s'
param username string
param password string

var vmName = '${namePrefix}${uniqueString(resourceGroup().id)}'

// Bring in the nic
module nic './vm-small-nic.bicep' = {
  name: '${vmName}-nic'
  params: {
    namePrefix: '${vmName}-hdd'
    subnetId: subnetId
  }
}

// Create the vm
resource vm_small 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOsVersion
        version: 'latest'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: username
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.outputs.nicId
        }
      ]
    }
  }
}

output id string = vm_small.id

// virtual-machines/postgresql/vm-postgresql.bicep
param namePrefix string
param subnetId string
param username string
param password string

var name = '${namePrefix}-pgsql'

module vm_pgsql '../general/vm-small/vm-small.bicep' = {
  name: name
  params: {
    namePrefix: name
    location: resourceGroup().location
    subnetId: subnetId
    ubuntuOsVersion: '18.04-LTS'
    osDiskType: 'Standard_LRS'
    vmSize: 'Standard_B1s'
    username: username
    password: password    
  }
}

output vmId string = vm_pgsql.outputs.id
// parameters/parameters.prod.json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "resourceGroupName": {
            "value": "prod"
        },
        "namePrefix": {
            "value": "prod"
        },
        "vmPgsqlUsername": {
            "value": "test_username"
        },
        "vmPgsqlPassword": {
            "value": "$1test_password"
        }
    }
}