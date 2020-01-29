# GiDInterface

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/07a116949d2a437eb99b1423a18ecdb6)](https://app.codacy.com/app/jginternational/GiDInterface?utm_source=github.com&utm_medium=referral&utm_content=KratosMultiphysics/GiDInterface&utm_campaign=badger)

The interface of Kratos with [GiD](http://www.gidhome.com). 

If you need the latest release, launch your GiD, navigate to Data > Problemtype > Internet retrieve and download Kratos there. If you need the developer version, you are on the right place

## First steps
* Install GiD -> [Developer version](http://www.gidhome.com/download/developer-versions)
* Navigate to GiD's problemtype folder and delete kratos.gid
* Create there a link to our [kratos.gid](./kratos.gid/)
* Navigate to kratos.gid/exec/
* Create there a symbolic link to the kratos installation folder (where runkratos is located)
  * Unix : `ln -s ~/Kratos Kratos` or maybe `ln -s ~/Kratos/bin/Release Kratos` if that's the destination folder
  * Windows : `mklink /J Kratos C:\kratos` or maybe `mklink /J Kratos C:\kratos\bin\Release` (choose actual Kratos installation folder)

## Usage
* Run GiD
* Go to: Data / Problem type / kratos
* kratos top menu / Developer mode (recommended)
* [Fluid dynamics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#3-set-a-fluid-dynamics-problem)
* [Structural mechanics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#4-set-a-structural-mechanics-problem)
* [Fluid-Structure interaction example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#5-set-a-fluid-structure-interaction-problem)

## Warnings
* This repository is in Beta version. This means that everything can change.

## Want to develop?
* Ask for access -> contact fjgarate@cimne.upc.edu

