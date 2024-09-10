# 🗃️🧱 Construccion por IaC de una VM en Azure 🧱🗃️

# 📋 Requerimiento

1. Construir con BICEP de AZ una plantilla que desplieguen una Virtual Mchine Linux con ip y acceso por SSH.

2.  Deplegar toda la infraestructura con Ansible y a su ves que instale Docker, Nginx y haga el build de una imagen Sonarqube.

# ⛅ Azure Cloud

1. Logearse en Azure Cloud con:

    `az login`

2. Seleccionar una Suscripción de Azure, Si tienes varias suscripciones, puedes seleccionar una específica usando:

    `az account set --subscription "Nombre o ID de la Suscripción"`

3. Crear un Grupo de Recursos , Un grupo de recursos es un contenedor lógico para recursos de Azure:

    `az group create --name MiGrupoDeRecursos --location eastus`

4. Crear una carpeta de modulos para AZ con bicep, para este caso se crea un modulo "sshKey.bicep" el cual contiene la key SSH publica con la cual nos podremos conectar a la VM.

5. Crear plantilla del despligue de la VM en AZ con BICEP, aplicando todo lo necesario como la clave SSH, las subnets, red virtual, IP publica, grupo de seguridad (NSG), Interfaz de red (NIC) y por ultimo la Virtual Machine.

6. Validar que la plantilla de BICEP se pueda desplegar correctamente

    `az deployment group create --resource-group MiGrupoDeRecursos --template-file deployVM.bicep`

  - Revisar en Azure Portal: 
  
    Ve a portal.azure.com, inicia sesión, y busca el grupo de recursos que creaste. Asegúrate de que la VM y otros recursos se hayan creado correctamente.

  - Verificar con Azure CLI: Puedes listar los recursos en tu grupo de recursos:

    `az resource list --resource-group MiGrupoDeRecursos`

  - Conectar por SSH: Intenta conectarte a la VM usando SSH con la IP pública que se te     proporcionó.

    `ssh -i /home/<user>/.ssh/id_rsa <User_AZ>@<PublicIP>`

7. Mantenimiento y Limpieza

    Eliminar los recursos que se crearon , ya que estos son una prueba para validar que todo haya quedado bien a su ves evitando costos innecesarios en el cloud provider:

      `az group delete --name MiGrupoDeRecursos --yes --no-wait`

## Funcionamientos Plantilla bicep:

1. El usuario genera una clave SSH en su máquina local:
   └── Comando: `ssh-keygen -t rsa -b 2048 -C "<comentario>"`
       └── Resultado:
           ├── Clave privada: `/home/<user>/.ssh/id_rsa`
           └── Clave pública: `/home/<user>/.ssh/id_rsa.pub`

2. La plantilla Bicep incluye un módulo para la clave SSH:
   └── Código en Bicep:
       └── module sshKeyModule 'az_modules/sshKey.bicep'
           └── Exporta `sshPublicKey` (la clave pública)

3. La clave pública SSH se utiliza en la configuración de la máquina virtual:
   └── En la sección `osProfile` de la máquina virtual en la plantilla Bicep:
       ├── `disablePasswordAuthentication: true` (solo se permite SSH)
       └── `ssh:`
           └── `publicKeys:`
               └── `keyData: sshKeyModule.outputs.sshPublicKey`
                   └── La clave pública se coloca en `/home/<User_AZ>/.ssh/authorized_keys` dentro de la VM

4. El acceso SSH a la máquina virtual está habilitado por el grupo de seguridad de red (NSG):
   └── Sección `networkSecurityGroup` en la plantilla Bicep:
       ├── `securityRules:`
           └── `allow-ssh` (permite tráfico en el puerto 22)
               ├── `protocol: 'Tcp'`
               ├── `access: 'Allow'`
               ├── `direction: 'Inbound'`
               └── `destinationPortRange: '22'`

5. El usuario se conecta a la VM a través de SSH:
   └── Comando: `ssh -i /home/<user>/.ssh/id_rsa <User_AZ>@<PublicIP>`
       └── Se establece una conexión segura entre la máquina local y la VM en Azure
           └── La autenticación se realiza utilizando la clave privada local y la clave pública en la VM
               └── Si las claves coinciden, se otorga acceso a la VM

## 🦾🦿 Comandos utiles Azure Cloud:

```shell
az account set --subscription "Azure subscription 1"
```

```shell
az configure --defaults group="learn-62f5f226-f048-4a3d-916d-076ae3f6925f"
```

```shell
az account set --subscription f646a8d5-6d52-426f-ad92-4e9bc1bf56e7
```

```shell
az account show
```

```shell
az network vnet list --resource-group <your-resource-group> --query "[].name" --output tsv
```

```shell
az group list --query "[].name" --output ts
```

```shell
az vm list-skus --location eastus --size Standard_A --all --output table
```

```shell
az vm image list-skus --publisher Canonical --offer UbuntuServer --location eastus --output table
```

```shell
az group create --name LabVirtualMachine --location eastus
```

```shell
az deployment group validate --resource-group LabVirtualMachine --template-file main.bicep
```

```shell
az deployment group create --resource-group LabVirtualMachine --template-file main.bicep 
```

# 🤖 Ansible IaC

1. Crear toda la estructura necesaria de ansible

2. Configurar el ansible.cfg para que tome correctamente los inventarios, roles y demas configuraciones necesarias.

3. Definir en requirements.yml que collection de ansible galaxy vamos a necesitar en la arquitectura de ansible.

    ***Para utilizar la collection ansible galaxy de azure.azcollection adicional a la instalacion se tiene que configurar***

    1. Instalar todos los requerimientos que da AZ collections, ejecutar alguna de las dos opciones:

        `pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt`

        `pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt`

4. Configurar los inventarios, para este caso como es en un cloud provider se realizan inventarios dinamicos, de igual forma asignar las variables que vamos a necesitar para todas las aplicaciones si son varias (all) o varibles especificas para una sola aplicacion (app1).

    ***Para crear inventarios Dinamicos es conveniente mirar primero como obtener la IP Pública asociada a la Interfaz de red (NIC) en nuestra VM***

    1. Obtener la ID de la NIC Asociada a la VM:

        Utiliza el comando az vm show para obtener la **<NIC_ID>** desde la configuración de red de la VM.

          `az vm show --resource-group <ResourceGroup> --name <VMName> --query "networkProfile.networkInterfaces[0].id" --output tsv`

    2. Obtener la IP Pública desde la NIC:

        Utiliza la **<NIC_ID>** para obtener la **<PUBLIC_IP_ID>** asociada.

        `az network nic show --ids <NIC_ID> --query 'ipConfigurations[0].publicIPAddress.id' --output tsv`

    3. Obtener la IP Pública Real:

        Usa la **<PUBLIC_IP_ID>** obtenida en el paso anterior para recuperar la dirección IP pública real.

        `az network public-ip show --ids <PUBLIC_IP_ID> --query 'ipAddress' --output tsv`

5. Crear los roles necesarios para la infraestructura necesaria en la VM, para este caso:

- Docker:

  1. Para Docker se tiene que tener presente que version se necesita segun la maquina VM que se esta creando.

  2. Tener presente si es necesario instalar el containerd.io o si ya viene incluido en la version de docker.

- Nginx:

  1. Verificar el estado del servicio de Nginx:

      `sudo systemctl status nginx`

  2. Verificar si el paquete de Nginx está instalado:

      `dpkg -l | grep nginx`

  3. Verificar la versión de Nginx:

      `nginx -v`

  4. Podemos verificar si Nginx está escuchando en los puertos estándar (80 para HTTP, 443 para HTTPS):

      `sudo lsof -i -P -n | grep LISTEN | grep nginx`

- Sonarqube:

  1. Cuando se instale es conveniente dejarle un Network Bridge definida para que pueda hablarse con otras herramientas que se necesiten mas adelante.

  2. Habilitar los puertos necesarios en la instalacion de Sonar a si como en la VM los output para que pueda eschuchar desde el navegador

6. Configurar la carpeta de playbook, creando dos playbook uno como **main.yml** la cual lo que hara sera crear la VM en AZ y el segundo **config_main.yml** configurara todas las herramientas necesaria en la VM segun el requerimiento.

7. Crear un archivo .py como **execute_playbook.py** el cual ejecutara de forma ordenada los playbook garantizando que la informacion de los inventarios este disponible antes de ejecutar el playbook de configuracion.

