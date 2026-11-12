# KratosMultiphysics <-> GiD Interface

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/36d3d305c87e4bb398bc87ea2e3b890e)](https://app.codacy.com/gh/KratosMultiphysics/GiDInterface/dashboard)
[![Tester](https://github.com/KratosMultiphysics/GiDInterface/actions/workflows/tester.yml/badge.svg)](https://github.com/KratosMultiphysics/GiDInterface/actions/workflows/tester.yml)

The graphical user interface of [Kratos Multiphysics](https://github.com/KratosMultiphysics/Kratos) for [GiD](https://www.gidsimulation.com), distributed as a GiD *problemtype* (`kratos.gid`).

- **Stable release:** open GiD, go to *Data > Problem type > Internet retrieve* and download Kratos. Available for Linux, Windows and macOS.
- **Developer version:** you are in the right place.

Current version: **Kratos 10.4.3** — requires **GiD 16.1.10d or newer** (developer version recommended).

## Installation (developer version)

1. Clone this repository, or download a [release](https://github.com/KratosMultiphysics/GiDInterface/releases).
2. Install the latest [GiD developer version](https://www.gidsimulation.com/gid-for-science/downloads/) (minimum **16.1.10d**).
3. Go to GiD's `problemtypes` folder and delete any previous `kratos.gid`.
4. Create there a link to the [`kratos.gid`](./kratos.gid/) folder of this repository:
   - Windows: a shortcut to the `kratos.gid` folder.
   - Linux / macOS: `ln -s /path/to/GiDInterface/kratos.gid /path/to/GiD/problemtypes/kratos.gid`
5. Choose an execution mode (see below).

## Execution modes

Select the mode in *Kratos > Preferences*.

| Mode | What you need | Notes |
|---|---|---|
| **GiD's python** (default) | Nothing | Uses the Python bundled with GiD. Missing packages are detected and can be installed from the interface. |
| **Pip packages** | Python + `KratosMultiphysics[all]` | Use a Python version supported by the [KratosMultiphysics 10.4.3 wheels](https://pypi.org/project/KratosMultiphysics/10.4.3/#files). |
| **Local compiled** | Your own Kratos build | For Kratos developers. |
| **Docker** | Docker | No other dependency. Currently the **only option on macOS**. Default image: [`fjgarate/kratos-run`](https://hub.docker.com/r/fjgarate/kratos-run). |

### GiD's python
If some package is missing, run this in the GiD command line:

```
-np- W [GiD_Python_PipInstall { $::Kratos::pip_packages_required } 1 ]
```

### Pip packages
```bash
# Linux
python3 -m pip install --upgrade --force-reinstall --no-cache-dir KratosMultiphysics[all]==10.4.3
# Windows
python -m pip install --upgrade --force-reinstall --no-cache-dir KratosMultiphysics[all]==10.4.3
```

### Local compiled
In *Kratos > Preferences* fill in:
- the path to the Python folder
- the path to the Kratos build folder

Step-by-step video: https://www.youtube.com/watch?v=zZq7ypDdudo

## Usage
1. Run GiD.
2. *Data > Problem type > kratos*.
3. *Kratos > Preferences > Developer mode* (recommended for developers).
4. Pick an application in the application market window.

### Examples
- [Fluid dynamics](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#3-set-a-fluid-dynamics-problem)
- [Structural mechanics](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#4-set-a-structural-mechanics-problem)
- [Fluid-structure interaction](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#5-set-a-fluid-structure-interaction-problem)

Many applications also ship ready-to-run examples (*Examples* tool inside the interface).

## Applications

Public applications (shown in the application market): Structural, Fluid, FSI, Dam, Thermic, Pfem, DEM, MPM, Shallow water, GeoMechanics, and the tools Stenosis Wizard, Stent, Mdpa Generator and Examples.

Others (CompressibleFluid, EmbeddedFluid, Buoyancy, ConjugateHeatTransfer, PfemFluid, CDEM, …) are reachable through the launchers or in developer mode. The full list lives in the `appLink` entries of [`kratos.gid/kratos.spd`](./kratos.gid/kratos.spd).

## Repository layout

```
kratos.gid/            The GiD problemtype
  kratos.tcl           Entry point (GiD events, init, version checks)
  kratos.xml           Problemtype metadata (version, min GiD version, pip packages)
  kratos.spd           Root of the data tree; lists the applications (appLink)
  kratos.transform     Rules to upgrade models saved with older versions
  apps/<App>/          One folder per application: app.json, start.tcl, xml/, write/, examples/
  apps/Common/         Shared XML/SPD definitions
  scripts/             Core: Model/ (entities), Writing/ (mdpa + json), Controllers/ (windows)
  exec/                Launch scripts per mode and OS, MainKratos.py
  libs/                Third-party Tcl libraries
tools/                 Release scripts
dockers/               Release / runner docker images
```

## Testing

CI runs the [kratos-gid-tester](https://github.com/jginternational/kratos-gid-tester) suite in the `fjgarate/kratos-tester` image on a self-hosted runner, on every push to `master`. Pull requests are tested only after a maintainer adds the `safe-to-test` label.

## Contributing

1. Fork the repository and create a branch from `master`.
2. Make your changes and test them in GiD (see [AGENTS.md](./AGENTS.md) for the code structure and conventions).
3. Open a pull request against `master`.

Questions: open an [issue](https://github.com/KratosMultiphysics/GiDInterface/issues).

## License

See [LICENSE.md](./LICENSE.md).
