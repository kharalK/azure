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