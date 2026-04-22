# KratosMultiphysics <-> GiD Interface

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/36d3d305c87e4bb398bc87ea2e3b890e)](https://www.codacy.com/gh/KratosMultiphysics/GiDInterface/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=KratosMultiphysics/GiDInterface&amp;utm_campaign=Badge_Grade)
[![Tester](https://github.com/KratosMultiphysics/GiDInterface/actions/workflows/tester.yml/badge.svg)](https://github.com/KratosMultiphysics/GiDInterface/actions/workflows/tester.yml)

User interface and problemtype integration to run KratosMultiphysics models from [GiD](http://www.gidsimulation.com).

If you only need a stable package, open GiD and install from:

1. Data -> Problem type -> Internet retrieve
2. Search for Kratos

If you want to develop or test the latest changes, this repository is the right place.

## Compatibility

- Kratos interface version: 10.3.0
- Minimum GiD version: 16.1.10d
- Maximum GiD version tested in metadata: 17.99.99d
- Supported platforms: Linux, Windows, macOS

## Quick Start (Developer Version)

1. Clone this repository.
2. Install/update GiD developer build from the [official downloads page](https://www.gidsimulation.com/gid-for-science/downloads/).
3. Go to your GiD problemtypes folder and remove older kratos.gid installations.
4. Create a link to this repository's [kratos.gid](./kratos.gid/) folder:
    - Windows: create a shortcut to the folder.
    - Linux/macOS: create a symbolic link.
5. Open GiD and select Data -> Problem type -> kratos.
6. Open Kratos -> Preferences and select the launch configuration you want.

## Launch Configurations

The interface currently exposes these launch configurations in Preferences:

1. Default
    - Uses GiD embedded Python.
    - Good for first use and minimal setup.
    - Missing packages can be installed from GiD command line.
2. External python
    - Uses your own Python executable.
    - Configure Python path in Preferences.
3. Your compiled Kratos
    - For developers running a local compiled Kratos build.
    - Configure both Python path and Kratos bin path.
4. Docker
    - Runs with Docker image configured in Preferences.
    - Useful to avoid local dependency setup.
    - Required fallback option for macOS users without local compatible setup.

## Python and Package Setup

If you use an external Python environment, recommended versions are 3.8 to 3.12.

Install Kratos pip packages with:

- Linux:

```bash
python3 -m pip install --upgrade --force-reinstall --no-cache-dir KratosMultiphysics-all==10.3.0
```

- Windows:

```bat
python -m pip install --upgrade --force-reinstall --no-cache-dir KratosMultiphysics-all==10.3.0
```

From GiD command line, required packages can also be installed with:

```tcl
-np- W [GiD_Python_PipInstall [list $::Kratos::pip_packages_required ] 1 ]
```

## Typical Workflow

1. Open GiD.
2. Select Data -> Problem type -> kratos.
3. Set project preferences from Kratos -> Preferences.
4. Prepare geometry/mesh, assign conditions, and run.
5. Inspect output logs (.info/.err) and postprocess in GiD.

## Repository Layout

- [kratos.gid/](./kratos.gid/): GiD problemtype (apps, scripts, launchers, xml descriptors).
- [kratos.gid/apps/](./kratos.gid/apps/): Kratos applications integrated into GiD.
- [kratos.gid/scripts/](./kratos.gid/scripts/): TCL logic for UI, launch, writing, and utilities.
- [kratos.gid/exec/](./kratos.gid/exec/): launch scripts for default/python/compiled/docker execution.
- [dockers/](./dockers/): release/build support for containerized packaging.
- [tools/](./tools/): release preparation utilities.

## Examples

- [Fluid dynamics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#3-set-a-fluid-dynamics-problem)
- [Structural mechanics example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#4-set-a-structural-mechanics-problem)
- [Fluid-Structure interaction example](https://github.com/KratosMultiphysics/Kratos/wiki/Running-an-example-from-GiD#5-set-a-fluid-structure-interaction-problem)

## Troubleshooting

1. Kratos does not appear in GiD
    - Verify the link/shortcut points to the repository [kratos.gid](./kratos.gid/) folder.
    - Remove duplicated kratos.gid folders from GiD problemtypes path.
2. Docker mode fails
    - Check Docker daemon is running.
    - Verify the configured image name in Preferences.
3. Python mode fails
    - Confirm Python executable path is valid.
    - Reinstall Kratos packages in the selected environment.
4. Run produced only .err output
    - Open generated .info/.err files in project directory for stack trace and missing dependency hints.

## Notes for Contributors

- CI checks are available in the repository Actions tab.
- Release and packaging helpers are under [dockers/](./dockers/) and [tools/](./tools/).
- Main maintainers are reachable through the Kratos organization channels.

## Warning

This repository is under active development. Internal APIs, launch behavior, and app integrations may evolve between releases.

