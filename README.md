# KratosMultiphysics <-> GiD Interface

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/36d3d305c87e4bb398bc87ea2e3b890e)](https://www.codacy.com/gh/KratosMultiphysics/GiDInterface/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=KratosMultiphysics/GiDInterface&amp;utm_campaign=Badge_Grade)

The user interface of Kratos with [GiD](http://www.gidhome.com).

If you need the latest stable release, launch your GiD, navigate to Data > Problemtype > Internet retrieve and download Kratos there.
Available for Linux. Windows, and macOS.

If you need the developer version, you are on the right place.

## First steps
* 1- Clone this repository, or install a stable [release](https://github.com/KratosMultiphysics/GiDInterface/releases)
* 2- Install the latest GiD developer version -> [Developer version](http://www.gidhome.com/download/developer-versions)
* 3- Navigate to GiD's problemtype folder and delete any previous kratos.gid
    * Create there a link to our [kratos.gid](./kratos.gid/) downloaded in step 1
        * Windows: Simple shortcut to kratos.gid folder
* 4- Navigate to kratos.gid/exec/
    * Create there a symbolic link to the kratos installation folder (where runkratos is located)
        * Unix : `ln -s ~/Kratos Kratos` or maybe `ln -s ~/Kratos/bin/Release Kratos` if that's the destination folder
        * Windows : `mklink /J Kratos C:\kratos\bin\Release` (choose actual Kratos installation folder)

### Step by step video
https://www.youtube.com/watch?v=zZq7ypDdudo

## Launch modea
In Kratos preferences, select the execution mode:
* Pip packages: Kratos will be installed via `pip install`
* local compiled: If you are a developer and build your applications, use this one

## Usage
* Run GiD
* Go to: Data / Problem type / kratos
* kratos top menu / Developer mode (recommended)

### Examples
* [Fluid dynamics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#3-set-a-fluid-dynamics-problem)
* [Structural mechanics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#4-set-a-structural-mechanics-problem)
* [Fluid-Structure interaction example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#5-set-a-fluid-structure-interaction-problem)

## Warnings
* This repository is in Beta version. This means that everything can change.

## Want to develop?
* Ask for access -> contact fjgarate@cimne.upc.edu

