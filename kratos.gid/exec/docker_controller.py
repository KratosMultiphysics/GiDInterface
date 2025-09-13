import subprocess

if __name__ == "__main__":
    # debug stand alone to find meshio in the plugin path, instead site-packages
    import os
    plugin_site_packages=os.path.join(os.path.dirname(os.path.abspath(__file__)), "site-packages","src")
    import sys
    sys.path.append(plugin_site_packages)

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
        args = ["docker", "ps", "-q", "--filter", f"ancestor={image_name}"]
        if external_port != -1:
            args.extend(["--filter", f"publish={external_port}"])
        args.extend(["--format", "{{.ID}}"])
        result = subprocess.run(
            args,
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        container_ids = result.stdout.decode().strip().split('\n')
        if container_ids == ['']:
            return 0
        return len(container_ids) 
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False
    return False

def killContainersFromImage(image_name, external_port=-1):
    try:
        args = ["docker", "ps", "-q", "--filter", f"ancestor={image_name}"]
        if external_port != -1:
            args.extend(["--filter", f"publish={external_port}"])
        args.extend(["--format", "{{.ID}}"])
        result = subprocess.run(
            args,
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        container_ids = result.stdout.strip().splitlines()

        if not container_ids:
            return 0

        result = subprocess.run(["docker", "rm", "-f"] + container_ids, check=True)
        return len(container_ids)

    except subprocess.CalledProcessError as e:
        return -1

def startContainerForImage(image_name, external_port, internal_port, modelname):
    try:
        result = subprocess.run(
            ["docker", "run", "-d", "-p", f"{external_port}:{internal_port}", "-v", f"{modelname}:/model", image_name],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        container_id = result.stdout.strip()
        return container_id 

    except subprocess.CalledProcessError as e:
        return -1
