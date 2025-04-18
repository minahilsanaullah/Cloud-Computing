@secure()
param adminPassword string

param location string = resourceGroup().location

// First VNET configuration (Alpha)
param vnetAlphaName string = 'vnetAlpha'
param vnetAlphaAddressPrefix string = '10.100.0.0/16'
param vnetAlphaInfraSubnetPrefix string = '10.100.1.0/24'
param vnetAlphaStorageSubnetPrefix string = '10.100.2.0/24'

// Second VNET configuration (Beta)
param vnetBetaName string = 'vnetBeta'
param vnetBetaAddressPrefix string = '10.200.0.0/16'
param vnetBetaInfraSubnetPrefix string = '10.200.1.0/24'
param vnetBetaStorageSubnetPrefix string = '10.200.2.0/24'

// Deploy first VNET
module vnetAlpha './data/vnet.bicep' = {
  name: 'vnetAlphaDeployment'
  params: {
    vnetName: vnetAlphaName
    location: location
    vnetAddressPrefix: vnetAlphaAddressPrefix
    infraSubnetPrefix: vnetAlphaInfraSubnetPrefix
    storageSubnetPrefix: vnetAlphaStorageSubnetPrefix
  }
}

// Deploy second VNET
module vnetBeta './data/vnet.bicep' = {
  name: 'vnetBetaDeployment'
  params: {
    vnetName: vnetBetaName
    location: location
    vnetAddressPrefix: vnetBetaAddressPrefix
    infraSubnetPrefix: vnetBetaInfraSubnetPrefix
    storageSubnetPrefix: vnetBetaStorageSubnetPrefix
  }
}

// Create peering from vnetAlpha to vnetBeta
module alphaToBetaPeering './data/vnet-peering.bicep' = {
  name: 'peeringAlphaToBeta'
  params: {
    sourceVnetName: vnetAlphaName
    targetVnetId: vnetBeta.outputs.vnetId
    peeringName: 'peering-to-vnetBeta'
  }
  dependsOn: [
    vnetAlpha
  ]
}

// Create peering from vnetBeta to vnetAlpha
module betaToAlphaPeering './data/vnet-peering.bicep' = {
  name: 'peeringBetaToAlpha'
  params: {
    sourceVnetName: vnetBetaName
    targetVnetId: vnetAlpha.outputs.vnetId
    peeringName: 'peering-to-vnetAlpha'
  }
  dependsOn: [
    vnetBeta
  ]
}

// Deploy VM in vnetAlpha
module vmAlpha './data/vm.bicep' = {
  name: 'vmAlphaDeployment'
  params: {
    vmName: 'vmAlpha'
    location: location
    subnetId: vnetAlpha.outputs.infraSubnetId
    adminPassword: adminPassword
  }
}

// Deploy VM in vnetBeta
module vmBeta './data/vm.bicep' = {
  name: 'vmBetaDeployment'
  params: {
    vmName: 'vmBeta'
    location: location
    subnetId: vnetBeta.outputs.infraSubnetId
    adminPassword: adminPassword
  }
}

// Storage Account 1
module storageAlpha './data/storage.bicep' = {
  name: 'storageAlphaDeployment'
  params: {
    storageAccountName: 'st${uniqueString(resourceGroup().id)}alpha'
    location: location
  }
}

// Storage Account 2
module storageBeta './data/storage.bicep' = {
  name: 'storageBetaDeployment'
  params: {
    storageAccountName: 'st${uniqueString(resourceGroup().id)}beta'
    location: location
  }
}

// Monitoring
module monitor './data/monitor.bicep' = {
  name: 'monitorAlphaDeployment'
  params: {
    location: location
  }
}
