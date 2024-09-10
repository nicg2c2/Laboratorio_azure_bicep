import subprocess  # Permite ejecutar comandos del sistema operativo desde Python, como si los escribieras en una terminal.
import sys         # Proporciona acceso a variables y funciones que interactúan con el intérprete de Python, como la salida del programa.

def run_playbook(playbook_path):
    try:  # Bloque para manejar posibles excepciones que puedan ocurrir durante la ejecución del código.
        result = subprocess.run(  # Ejecuta el comando del sistema "ansible-playbook" con el argumento de la ruta del playbook.
            ["ansible-playbook", playbook_path],  # Lista que contiene el comando y el playbook que se quiere ejecutar.
            stdout=subprocess.PIPE,  # Redirige la salida estándar del comando (lo que normalmente verías en la terminal) a una variable.
            stderr=subprocess.PIPE,  # Redirige la salida de errores del comando a una variable.
            text=True  # Convierte la salida de `stdout` y `stderr` a cadenas de texto en lugar de bytes.
        )
        print(f"Output: {playbook_path}:")  # Muestra un mensaje que indica qué playbook se está ejecutando.
        print(result.stdout)  # Imprime la salida generada por el comando "ansible-playbook".
    except subprocess.CalledProcessError as e:  # Captura la excepción si el comando "ansible-playbook" falla.
        print(f"Error: {playbook_path}:")  # Muestra un mensaje de error indicando en qué playbook ocurrió el fallo.
        print(e.stderr)  # Imprime el mensaje de error que generó el comando "ansible-playbook".
        sys.exit(1)  # Termina el programa con un código de error 1 (indica que ocurrió un fallo).


def main():
    # Path of the playbook in the current directory
    playbooks = [
        '/home/Nicolas/Laboratorios/Periferia/Laboratorio_azure_bicep/system-setup/ansible/v1/playbooks/app1/main.yml',
        '/home/Nicolas/Laboratorios/Periferia/Laboratorio_azure_bicep/system-setup/ansible/v1/playbooks/app1/config_main.yml'
    ]

    #Execute first playbook
    print("Running the main playbook, creating the VM wait a few seconds....")
    run_playbook(playbooks[0])
    
    print("Running the config_main playbook for your VM, wait a few seconds....")
    #Execute second playbook
    run_playbook(playbooks[1])

if __name__ == "__main__":
    main()  