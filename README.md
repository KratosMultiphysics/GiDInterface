# KratosMultiphysics <-> GiD Interface

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/36d3d305c87e4bb398bc87ea2e3b890e)](https://www.codacy.com/gh/KratosMultiphysics/GiDInterface/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=KratosMultiphysics/GiDInterface&amp;utm_campaign=Badge_Grade)
[![Tester](https://github.com/KratosMultiphysics/GiDInterface/actions/workflows/tester.yml/badge.svg)](https://github.com/KratosMultiphysics/GiDInterface/actions/workflows/tester.yml)

The user interface of Kratos with [GiD](http://www.gidsimulation.com).

If you need the latest stable release, launch your GiD, navigate to Data > Problemtype > Internet retrieve and download Kratos there.
Available for Linux. Windows, and macOS.

If you need the developer version, you are on the right place.

## First steps
* 1- Clone this repository, or install a stable [release](https://github.com/KratosMultiphysics/GiDInterface/releases)
* 2- Install the latest GiD developer version **(minimum 16.1.4d)** -> [Developer version](https://www.gidsimulation.com/gid-for-science/downloads/)
* 3- Navigate to GiD's problemtype folder and delete any previous kratos.gid
    * Create there a link to our [kratos.gid](./kratos.gid/) downloaded in step 1
        * Windows: Simple shortcut to kratos.gid folder
* 4- Choose your execution mode:
    * 4.1- **Default execution mode.** Use GiD's python:
        * You don't need to install python. The program will detect if you have any pending package to install.
        * If there's any missing package, use the GiD command line and execute:
        
            `-np- W [GiD_Python_PipInstallMissingPackages [list $Kratos::pip_packages_required ] ]`
    * 4.1- To execute Kratos using the standard pip packages:
        * Python version recommended: 3.8, 3.9, 3.10, 3.11
        * Open a terminal and run
            - Linux: `python3 -m pip install --upgrade --force-reinstall --no-cache-dir KratosMultiphysics-all==9.3.2`
            - Windows: `python -m pip install --upgrade --force-reinstall --no-cache-dir KratosMultiphysics-all==9.3.2`
    * 4.2- To execute Kratos using your compiled binaries:
        * Fill the Kratos preferences windows with
            - Path to the python folder
            - Path to the kratos build folder
        * Step by step video: https://www.youtube.com/watch?v=zZq7ypDdudo
    * 4.3- To execute Kratos using docker, just install docker.
        * Note: This is the ONLY option if you are a **macOS** user at this moment

### Launch modes
In Kratos preferences, select the execution mode:
* GiD's python: Use the GiD internal python to run. It will help you install the pip packages
* Pip packages: Kratos will be installed via `pip install`
* local compiled: If you are a developer and build your applications, use this one
* docker: If you do not want to install any dependency, just run via docker!
    * The default image is [fjgarate/kratos-run](https://hub.docker.com/repository/docker/fjgarate/kratos-run)

### Usage
* Run GiD
* Go to top menu: Data / Problem type / kratos
* Go to top menu: kratos / Preferences / Developer mode (recommended)

### Examples
* [Fluid dynamics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#3-set-a-fluid-dynamics-problem)
* [Structural mechanics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#4-set-a-structural-mechanics-problem)
* [Fluid-Structure interaction example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#5-set-a-fluid-structure-interaction-problem)

## Warnings
* This repository is in Beta version. This means that everything can change.

## Want to develop?
* Ask for access -> contact fjgarate@cimne.upc.edu

