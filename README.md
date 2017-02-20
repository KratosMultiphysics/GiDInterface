# GiDInterface
The interface of Kratos with GiD

## First steps
* Install GiD -> [Developer version](http://www.gidhome.com/download/developer-versions)
* Navigate to GiD's problemtype folder and delete kratos.gid
* Create there a link to our [kratos.gid](./kratos.gid/)
* Navigate to kratos.gid/exec/
* Create there a symbolic link to the kratos installation folder (where runkratos is located)
  * Unix : ln -s Kratos /home/Kratos (Kratos installation folder)
  * Windows : mklink /J Kratos C:/kratos (Kratos installation folder)

## Usage
* Run GiD
* Go to: Data / Problem type / kratos
* kratos top menu / Developer mode (recommended)

## Want to develop?
* Ask for access -> contact fjgarate@cimne.upc.edu
