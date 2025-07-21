# read the file kratos.spd, and parse it as xml
# then extract the version number 

import xml.etree.ElementTree as ET
import sys

def get_version_number(file_name):
    tree = ET.parse(file_name)
    root = tree.getroot()
    version = root.attrib['version']
    return version

if __name__ == "__main__":

    # Open kratos.xml and set Production to 1
    file_name = "../kratos.gid/kratos.xml"
    tree = ET.parse(file_name)
    root = tree.getroot()
    production = root.find('Production')
    if production is not None:
        production.text = '1'
    else:
        production = ET.SubElement(root, 'Production')
        production.text = '1'
    
    file_name = "../kratos.gid/kratos.spd"
    version = get_version_number(file_name)
    print(version)

    # Get all the applications whose tag is appLink
    tree = ET.parse(file_name)
    root = tree.getroot()
    applications = root.findall('.//appLink')
    # create a list of applications, reading the field 'n'

    app_list = ['Common', 'Examples']
    for app in applications:
        # check if the app has the attribute 'production=1'
        if 'production' in app.attrib and app.attrib['production'] == '1':
            # add the app to the list
            if 'n' in app.attrib:
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

    