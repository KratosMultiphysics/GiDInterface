# read the file kratos_default.spd, and parse it as xml
# then extract the version number 

import xml.etree.ElementTree as ET
import sys

def get_version_number(file_name):
    tree = ET.parse(file_name)
    root = tree.getroot()
    version = root.attrib['version']
    return version

if __name__ == "__main__":
    
    file_name = "../kratos.gid/kratos_default.spd"
    version = get_version_number(file_name)
    print(version)

    # Get all the applications whose tag is appLink
    tree = ET.parse(file_name)
    root = tree.getroot()
    applications = root.findall('.//appLink')
    # create a list of applications, reading the field 'n'

    app_list = []
    for app in applications:
        app_list.append(app.attrib['n'])

    print(app_list)
    # if there is a folder in the folder apps whose name is not in the list, delete it

    folder_name = "../kratos.gid/apps"
    import os
    for folder in os.listdir(folder_name):
        if folder not in app_list:
            print("Deleting folder: ", folder)
            import shutil
            shutil.rmtree(folder_name + "/" + folder)

    # Ready
    print("Ready to release version: ", version)

    