# import tohil

# tcl=tohil.import_tcl()
import subprocess

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
    try:
        result1 = subprocess.run(["docker", "info"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # get the output and check if it contains "Server Version"
        result = result1.stdout.decode().strip()
        return result
    except (subprocess.CalledProcessError, FileNotFoundError):
        return -1
    return -1    

# is docker running any container for an image
def isDockerRunningContainer(image_name, external_port=-1):   
    try:
        result = subprocess.run(["docker", "ps", "--filter", f"ancestor={image_name}", "--filter", f"publish={external_port}" if external_port != -1 else "", "--format", "{{.ID}}"],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        container_ids = result.stdout.decode().strip().split('\n')
        # tcl.W(container_ids)
        if container_ids == ['']:
            return 0
        # tcl.W(len(container_ids))
        return len(container_ids) 
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False
    return False

def killContainersFromImage(image_name, external_port=-1):
    try:
        result = subprocess.run(
            ["docker", "ps", "-q", "--filter", f"ancestor={image_name}", "--filter", f"publish={external_port}" if external_port != -1 else "", "--format", "{{.ID}}"],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        container_ids = result.stdout.strip().splitlines()

        if not container_ids:
            return 0

        result = subprocess.run(["docker", "rm", "-f"] + container_ids, check=True)
        return len(container_ids)

    except subprocess.CalledProcessError as e:
        return -1  # Error al ejecutar docker

def startContainerForImage(image_name, external_port, internal_port, modelname):
    try:
        result = subprocess.run(
            ["docker", "run", "-d", "-p", f"{external_port}:{internal_port}", "-v", f"{modelname}:/model", image_name],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        container_id = result.stdout.strip()
        return container_id 

    except subprocess.CalledProcessError as e:
        return -1  # Error al ejecutar docker

# -np- GiD_Python_Source C:/Users/jgarate/Desktop/CODE/Other/GiDInterface/kratos.gid/exec/check_docker.py
# check_docker.check_docker()
# -np- GiD_Python_Exec check_docker.check_docker()

# -np- GiD_Python_Import_File C:/Users/jgarate/Desktop/CODE/Other/GiDInterface/kratos.gid/exec/check_docker.py
# -np- GiD_Python_Exec check_docker.check_docker()

# print(isDockerAvailable())
# print(isDockerRunning())
# print(isDockerRunningContainer("flowgraph"))
# print(killContainersFromImage("flowgraph"))
# print(killContainersFromImage("flowgraph", 8080))
# print(startContainerForImage("flowgraph", 8080, 80, "C:\\Users\\jgarate\\Desktop\\bbb.gid"))  # Adjust the model path as needed