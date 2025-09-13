import tohil

tcl=tohil.import_tcl()

if __name__ == "__main__":
    # debug stand alone to find meshio in the plugin path, instead site-packages
    import os
    plugin_site_packages=os.path.join(os.path.dirname(os.path.abspath(__file__)), "site-packages","src")
    import sys
    sys.path.append(plugin_site_packages)

def myfunction():
    return "65"

def isDockerAvailable():
    # if docker is installed and available
    import subprocess
    try:
        # execute "docker --version" and return the output
        result1 = subprocess.run(["docker", "--version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        result = result1.stdout.decode().strip()
        return result
    except (subprocess.CalledProcessError, FileNotFoundError):
        return -1
    return -1

def isDockerRunning():
    # if docker is running
    import subprocess
    try:
        result1 = subprocess.run(["docker", "info"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # get the output and check if it contains "Server Version"
        result = result1.stdout.decode().strip()
        return result
    except (subprocess.CalledProcessError, FileNotFoundError):
        return -1
    return -1    

# is docker running any container for an image
def isDockerRunningContainer(image_name):   
    import subprocess
    try:
        result = subprocess.run(["docker", "ps", "--filter", f"ancestor={image_name}", "--format", "{{.ID}}"],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        container_ids = result.stdout.decode().strip().split('\n')
        tcl.W(container_ids)
        if container_ids == ['']:
            return 0
        tcl.W(len(container_ids))
        return len(container_ids) 
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False
    return False

def killContainersFromImage(image_name):
    try:
        # Obtener los IDs de contenedores que usan la imagen
        result = subprocess.run(
            ["docker", "ps", "-q", "--filter", f"ancestor={image_name}", "--format", "{{.ID}}"],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        container_ids = result.stdout.strip().splitlines()

        if not container_ids:
            return 0  # No hay contenedores para esa imagen

        # Matar todos los contenedores encontrados
        subprocess.run(["docker", "rm", "-f"] + container_ids, check=True)
        return len(container_ids)

    except subprocess.CalledProcessError as e:
        return -1  # Error al ejecutar docker


# -np- GiD_Python_Source C:/Users/jgarate/Desktop/CODE/Other/GiDInterface/kratos.gid/exec/check_docker.py
# check_docker.check_docker()
# -np- GiD_Python_Exec check_docker.check_docker()

# -np- GiD_Python_Import_File C:/Users/jgarate/Desktop/CODE/Other/GiDInterface/kratos.gid/exec/check_docker.py
# -np- GiD_Python_Exec check_docker.check_docker()

# print(isDockerAvailable())
# print(isDockerRunning())
print(isDockerRunningContainer("flowgraph"))
