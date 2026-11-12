# AGENTS.md

Guidance for AI coding agents (and humans) working on the Kratos ↔ GiD interface.
For installation and user-facing docs see [README.md](./README.md).

## What this repo is

A GiD *problemtype* (`kratos.gid/`) that lets users build Kratos Multiphysics models in GiD. It writes the Kratos input files (`.mdpa`, `ProjectParameters.json`, materials `.json`) and launches Kratos.

- **Language:** Tcl/Tk on top of GiD's *customlib* framework. Data trees are XML (`.xml`, `.spd`).
- **Python** is used only in `kratos.gid/exec/MainKratos.py`, `scripts/Custom/python_writer.py` and the release tools.
- There is **no standalone build or test command**: the code runs inside GiD.

## Layout

| Path | Purpose |
|---|---|
| `kratos.gid/kratos.tcl` | Entry point: registers GiD events (`GiD_RegisterEvent`, e.g. `GiD_Event_LoadModelSPD`), version checks, model upgrade. |
| `kratos.gid/kratos.xml` | Problemtype metadata: version, `MinimumGiDVersion`, required pip packages. |
| `kratos.gid/kratos.spd` | Root data tree; `<Kratos_data version=…>` and one `appLink` per application. |
| `kratos.gid/kratos.transform` | Rules applied when opening a model saved with a different `.spd` version. |
| `kratos.gid/apps/<App>/` | One folder per application (see below). |
| `kratos.gid/apps/Common/xml/` | Shared definitions (processes, solvers, results, intervals…) reused by apps. |
| `kratos.gid/scripts/Model/` | In-memory model: Element, Condition, Material, Process, Solver… |
| `kratos.gid/scripts/Writing/` | Generic writers for mdpa, submodelparts, materials, ProjectParameters, stages. |
| `kratos.gid/scripts/Controllers/` | Windows: preferences, application market, examples, tree injections. |
| `kratos.gid/scripts/Launch.tcl` | Execution modes (GiD python, pip, local compiled, docker) and dependency checks. |
| `kratos.gid/exec/` | Per-mode, per-OS launch scripts (`*.win.bat`, `*.unix.bat`) and `MainKratos.py`. |
| `kratos.gid/libs/` | Third-party Tcl libs — do not modify. |
| `tools/`, `dockers/` | Release packaging. |
| `dist/` | Release output (git-ignored) — never edit. |

## Anatomy of an application (`apps/<App>/`)

```
app.json                 id, prefix, kratos_name, python_packages, script_files, start_script,
                         requirements (apps, minimum_gid_version), permissions, unique_names, write
start.tcl                namespace ::<App>; Init stores the app object and calls xml::Init / write::Init
xml/Main.spd             Tree for this app (plus Parts.spd, Materials.spd, … included from it)
xml/*.xml                Catalogues: Elements, Conditions, Materials, ConstitutiveLaws, Processes, Solvers, Strategies
xml/XmlController.tcl    ::<App>::xml — loads catalogues via Model::get*, CustomTree tweaks
write/write.tcl          ::<App>::write — mdpa writing (Init sets attributes from app.json)
write/writeProjectParameters.tcl   ProjectParameters.json
examples/examples.xml    Example list; each <Example cmd=…> points to a proc in examples/*.tcl
images/                  Icons and example thumbnails
```

Conventions:
- Every namespace registers itself with `Kratos::AddNamespace [namespace current]`.
- Sub-namespaces use `namespace path ::<App>` to reach the app's helpers (`GetAttribute`, `GetUniqueName`, `GetWriteProperty`).
- Tree node names are prefixed with the app `prefix` (e.g. `STParts`, `FLBC`); use `unique_names` from `app.json` instead of hard-coding them.
- Any new `.tcl` file must be listed in `script_files` of `app.json`, otherwise it is not sourced.
- Reuse `apps/Common/xml/*` and the generic writers in `scripts/Writing/` before adding app-specific code.
- Launcher apps (`FluidLauncher`, `PfemLauncher`, `DEMLauncher`, `ThermicLauncher`) only route to other apps.

### Adding a new application
1. Copy the structure of a similar app (e.g. `Fluid` or `Structural`) to `apps/<NewApp>/`.
2. Choose a unique `prefix` and update `id`, `kratos_name`, `python_packages`, `unique_names`, `start_script`.
3. Add an `appLink` to `kratos.spd` (`public="1"` to show it in the market, `production="1"` to ship it in releases).
4. Add tests in the tester repo (see below).

## Versioning — read before touching versions

The Kratos version (currently `10.4.3`) is hard-coded in several places that must stay in sync:

- `kratos.gid/kratos.xml` — `<Version>` and `<Package … Version=…>`
- `kratos.gid/kratos.spd` — `<Kratos_data version=…>`
- `kratos.gid/kratos.tcl` — `pip_packages_required`
- `README.md` — pip install commands
- `tools/create-release.bat`, `dockers/deploy.bat`, `dockers/create-release.sh`

Search for the old version string across the repo when bumping it.

**Model compatibility:** when a saved model's `.spd` version differs from `kratos.spd`, GiD runs the upgrade defined by `kratos.transform`. If you rename or remove tree nodes, values or conditions, add the corresponding rule to `kratos.transform`. Otherwise existing user models lose data.

The minimum GiD version is `MinimumGiDVersion` in `kratos.xml`. Some `app.json` files declare older values; the global one is the effective minimum.

## Testing

- No unit tests in this repo. Integration tests live in [kratos-gid-tester](https://github.com/jginternational/kratos-gid-tester): it runs GiD batch files (`batchs/<App>/*.bch`) that build each example, write the Kratos input and, for `*_calculate` cases, run the simulation.
- CI: `.github/workflows/tester.yml`, image `fjgarate/kratos-tester`, self-hosted runner. It runs on push to `master` and on PRs labelled `safe-to-test`.
- Manual check: link `kratos.gid` into GiD's `problemtypes`, load the problemtype, open the relevant example, *Calculate*, and inspect the generated files in the model folder.
- Without GiD you can only review syntax and logic. Say so when reporting results instead of claiming the change was tested.

## Rules

- Do not edit `dist/`, `libs/`, or generated/ignored files (`exec/Kratos*`, `__pycache__`).
- `*.unix.bat` and `*.sh` must keep **LF** line endings; `*.win.bat` CRLF.
- Keep XML files UTF-8 and preserve each file's existing indentation (some use tabs, others spaces).
- Do not rename tree nodes, `n=` attributes or unique names without a `kratos.transform` rule.
- Use `Kratos::Log` for debug output rather than `W` in committed code.
- Release scripts (`tools/create-release.bat`) create and force-push tags: do not run them unless asked.
