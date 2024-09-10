param VMname string = 'labvirtualmachine'
param location string = resourceGroup().location
param adminUsername string = 'nicg2c2'
param virtualNetName string = 'virtualNet'

module sshKeyModule 'az_modules/sshKey.bicep' = {
  name: 'sshKeyModule'
}

var subnets = [
  {
    name: 'Subnet-1'
    properties: {
      addressPrefix: '10.0.0.0/24'
    }
  }
  {
    name: 'Subnet-2'
    properties: {
      addressPrefix: '10.0.1.0/24'
    }
  }
]

// Definir la red virtual
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: subnets
  }
}

// Crear una IP pública
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'publicIP-${VMname}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Crear el grupo de seguridad de red (NSG)
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'securitygroup-${VMname}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          priority: 999
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'allow-sonarqube-http'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '9000'
        }
      }
      {
        name: 'allow-sonarqube-db'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '9092'
        }
      }
    ]
  }
}

// Crear la interfaz de red
resource networkInterface 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'nic-${VMname}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'// indica que la IP privada será asignada automáticamente de manera dinámica por Azure
          subnet: {
            id: virtualNetwork.properties.subnets[0].id // Referencia a la primera subred
          }
          publicIPAddress: {
            id: publicIp.id // Asocia la IP pública a la interfaz de red
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id // Asocia el NSG a la interfaz de red
    }
  }
}

resource VirtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: VMname
  location: location
  tags: {
    AnsibleGroup: 'app1'
    env: 'dev'
    owner: 'nicolas'
  }
  properties: { //Contiene la configuración detallada de la máquina virtual.
    hardwareProfile: {
      vmSize: 'Standard_B2ps_v2' // tamaño de la máquina virtual
    }
    osProfile: { // Configura el perfil del sistema operativo de la máquina virtual.
      computerName: VMname // Establece el nombre del equipo dentro de la máquina virtual.
      adminUsername: adminUsername
      linuxConfiguration: { // Configura la máquina virtual para que use Linux
        disablePasswordAuthentication: true // Desactiva la autenticación por contraseña y solo permite autenticación por clave SSH.
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys' // specifica la ruta en la máquina virtual donde se almacenarán las claves públicas autorizadas.
              keyData: sshKeyModule.outputs.sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [ // Define las interfaces de red conectadas a la máquina virtual.
        {
          id: networkInterface.id // Utiliza el identificador de la interfaz de red.
        }
      ]
    }
    storageProfile: { // Configura el perfil de almacenamiento de la máquina virtual
      imageReference: { // Imagen que se descarga desde Azure Marketplace o en sus repositorios oficiales para crear la máquina virtual
        publisher: 'Canonical' // El editor de la imagen.
        offer: 'UbuntuServer' // La oferta de imagen, en este caso, Ubuntu Server.
        sku: '18_04-lts-arm64' // La versión de la imagen (Ubuntu 18.04 LTS)
        version: 'latest' // Usa la última versión disponible de la imagen
      }
    }
  }
}
