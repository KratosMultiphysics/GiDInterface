# TODO — Auditoría de código (2026-11-12)

Resultado de una revisión de solo lectura de `kratos.gid/` (Tcl, XML/SPD, `exec/`, `tools/`, `dockers/`).
Nada de esto se ha probado en GiD. Rutas relativas a `kratos.gid/` salvo que se indique.

Leyenda: **[V]** = comprobado leyendo el código · **[A]** = reportado por la auditoría, pendiente de confirmar al corregir.
Severidad: 🔴 alta · 🟠 media · 🟢 baja.

Antes de cada corrección: identificar el test de kratos-gid-tester que la cubre (o añadir uno).

---

## Fase 1 — Bugs confirmados (arreglos pequeños, un commit por bug)

### Lanzamiento / ejecución
- [ ] 🔴 [V] `scripts/Launch.tcl:103` — `GetMissingPipPackages` compara `KratosMultiphysics[all]` con `pip list --format=freeze`, que nunca incluye `[all]` → el modo *External python* siempre da `MISSING_PIP_PACKAGES` y `kratos.tcl:548` cancela el cálculo. Fix: `regsub {\[.*\]} $name ""` antes de comparar (como en la variante GiD's python).
- [ ] 🔴 [V] `exec/pip.unix.bat:12-16` — `export PYTHONPATH=%python_home%` (sintaxis Windows en bash) → Python no arranca; además ejecuta `$python_home/python3` en vez de `$python_path`. Fix: no exportar PYTHONHOME/PYTHONPATH y ejecutar `"$python_path" MainKratos.py`.
- [ ] 🔴 [V] `exec/compiled.unix.bat:34-35` — `export PATH=$kratos_bin_path\libs;$PATH` rompe PATH; `PYTHONHOME=$python_home` usa `dirname(python)` (p.ej. `/usr/bin`). Fix: `export PATH="$kratos_bin_path/libs:$PATH"`, no fijar PYTHONHOME en Unix.
- [ ] 🔴 [A] `exec/pip_gids_python.win.bat:18-19` — `set PYTHONPATH=""` deja el literal `""`. Fix: `set "PYTHONPATH="` / `set "PYTHONHOME="`.
- [ ] 🟠 [V] `exec/*.unix.bat:5-7` (compiled, pip, pip_gids_python, docker) — `rm -f "$2/$1*.post.bin"`: el `*` entrecomillado no expande. Fix: `rm -f "$2/$1"*.post.bin`.
- [ ] 🟠 [A] Rutas con espacios sin comillas: `compiled.unix.bat:41`, `pip_gids_python.unix.bat:16`, `compiled.win.bat:28`, `pip_gids_python.win.bat:20`, `pip.win.bat:21`.
- [ ] 🟠 [A] `exec/compiled.win.bat:18-19` — `DEL "%2\gid_output"` sobre un directorio pide confirmación. Fix: `rmdir /s /q`.
- [ ] 🟠 [A] `exec/docker.*.bat` — `--name "$1"` falla con nombres de modelo con espacios; sin `--user` en Linux los resultados quedan como root. `Launch.tcl:351` depende del nombre.
- [ ] 🟠 [A] `scripts/Launch.tcl:305-310` + `kratos.tcl:557` — modo inexistente → `dict get` falla, `catch` lo silencia y GiD recibe un bat vacío sin aviso. Fix: comprobar `$mode ne ""` y mostrar `$error_msg`.
- [ ] 🟠 [A] `scripts/Launch.tcl:98,115` — `exec ... pip list` sin `catch`. `Launch.tcl:232` llama a `pipVersion` sin el `python_path` configurado.

### Núcleo (`scripts/`, `kratos.tcl`)
- [ ] 🔴 [V] `scripts/Writing/Writing.tcl:724-725` — `CopyMainScriptFile`: rama de error usa `$errName`/`$wevent` inexistentes y `return errcode 1` inválido.
- [ ] 🟠 [V] `scripts/Writing/Writing.tcl:379` — prisma cuadrático escrito con 1 nodo (debe ser 15).
- [ ] 🟠 [V] `scripts/Controllers/TreeInjections.tcl:376` — `v='$vfX'` dentro del bucle X/Y/Z → Y y Z reciben la función de X. Fix: `[set vf$i]`.
- [ ] 🟠 [V] `scripts/Controllers/CommonProcs.tcl:292` — `if {...} {return hidden} {return normal}` hace inalcanzables las líneas 293-294. Fix: `if {$conditionId ni $ncslist} {return hidden}`.
- [ ] 🟠 [V] `scripts/spdAuxiliar.tcl:278-280` — `GetAppIdFromNode` asigna `prevDomNode` pero compara `prevDomNodeName` (nunca cambia) → puede subir hasta el documento y fallar. >30 usos.
- [ ] 🟠 [V] `kratos.tcl:448` — se pasa el literal `n_elems` en vez de `$n_elems` a `MeshProgress`.
- [ ] 🟠 [A] `kratos.tcl:598` — usa `$inittime`; la variable es `ini_time` (latente: solo con `time_monitor`).
- [ ] 🟠 [A] `scripts/Writing/WriteProjectParameters.tcl:700-707` — `GetMatchSubModelPart`: comprueba `$pair_join` pero añade `$pair` (no deduplica); L700 pasa literal `stage`; L701 sobrescribe `model_part_basename`.
- [ ] 🟠 [V] `scripts/Logs.tcl:54` — `return ""` al inicio de `FlushLog` → `kratos_private(Log)` crece sin límite. `Logs.tcl:98` condición invertida (desactiva logs cuando `SaveGidDefaults`=1).
- [ ] 🟠 [A] `scripts/Writing/Writing.tcl:514-519` — MPI genera `MPILauncher.sh` que apunta a `exec/Kratos/runkratos` y `python35.zip` (ya no existen).
- [ ] 🟠 [A] `scripts/Controllers/TreeInjections.tcl:700` vs `:737` — `is_historical`: una usa `isBooleanFalse`, otra `ne "False"` (latente).
- [ ] 🟢 [A] `scripts/spdAuxiliar.tcl:479-480` — `RenameIntervalGroup`: `join [list $newname $child] //` con `$child` lista. Fix: `{*}$child`.
- [ ] 🟢 [A] `scripts/Controllers/ApplicationMarketWindow.tcl:310` — `set must_open_init_window 0` sin `variable` (sin efecto); L138 usa `$root` posiblemente indefinido. Mismo patrón con `initwind` en `CreateLauncherWindow`/`CreateDimensionWindow`.
- [ ] 🟢 [A] `scripts/Writing/WriteConditions.tcl:38` — `ne $groups` en vez de `ni` (no deduplica; lo usa MPM).
- [ ] 🟢 [A] `scripts/Controllers/MdpaImportMesh.tcl:127` — `if {$id in [dict exists ...]} {next}` → `if {[dict exists ...]} {continue}`; cerrar `$fp` y `EndWaitState` con `try/finally`.
- [ ] 🟢 [A] Errores de una línea: `ConstitutiveLaw.tcl:398` (`set $cl`), `ConstitutiveLaw.tcl:351`, `Writing.tcl:61` (`configutation`), `Writing.tcl:90` (`]` suelto), `WriteProjectParameters.tcl:142` (ignora `cut_planes_UN`), `TreeInjections.tcl:988`, `TreeInjections.tcl:962` (`get_materials_list_simple` vs `ProcGet_materials_list_simple`).
- [ ] 🟢 [A] `scripts/Model/Entity.tcl:61-74` — `addInput/addOutput` pasan argumentos desplazados al constructor de `Parameter` (latente).

### Apps
- [ ] 🔴 [V] `apps/PfemThermic/xml/NodalConditions.xml:72` — `INLET` usa `AssignInletProcess` (renombrado a `AssignLagrangianInletProcess` solo en PfemFluid, commit `48f4290ef`) → `TreeInjections.tcl:231` lanza error.
- [ ] 🔴 [V] `apps/GeoMechanics/app.json:37-45` — `unique_names` (`GEOMParts`, `GEOMNodalConditions`, `GEOMBC`, `GEOMResults`, `GEOMTimeParameters`) no existen; el árbol usa `STParts`, `STNodalConditions`, `STLoads,GEOMLoads`, `STResults`.
- [ ] 🔴 [V] `apps/GeoMechanics/write/write.tcl:64` — llama a `write::writeModelPartFileOld`; el proc es `::GeoMechanics::write::writeModelPartFileOld` (L125).
- [ ] 🔴 [V] `apps/DEMPFEM/xml/XmlController.tcl:16` y `apps/FluidDEM/xml/XmlController.tcl:43` — leen `${::DEMPFEM::prefix}` / `${::FluidDEM::prefix}`, que no existen. Fix: `[::X::GetAttribute prefix]$name`.
- [ ] 🔴 [V] `apps/DEMPFEM/start.tcl:14-22` — `Init` no hace `set _app $app`.
- [ ] 🟠 [A] `apps/ConjugateHeatTransfer/write/writeProjectParameters.tcl:192` — `lappend` en vez de `concat`; L225-232 `new_condition` sin rama por defecto.
- [ ] 🟠 [V] `apps/StenosisWizard/app.json:14` — lista `wizard/wizard_steps.tcl`, el archivo es `Wizard_Steps.tcl` (falla en Linux/macOS).
- [ ] 🟠 [V] `apps/StenosisWizard/start.tcl:33` — `after 600 [::StenosisWizard::StartWizardWindow]` ejecuta al instante. Fix: sin corchetes. L22 variable local sin uso.
- [ ] 🟠 [A] `apps/ShallowWater/examples/examples.xml:9` — "Waves" llama a `DamBreak::Init`; `examples/Waves.tcl` no está en `script_files`.
- [ ] 🟠 [A] `apps/Structural/xml/XmlController.tcl:56` y `:109` — `ProcCheckGeometryStructural` definido dos veces; `Stent/xml/XmlController.tcl:26` lo redefine globalmente.
- [ ] 🟠 [A] `apps/FreeSurface/write/write.tcl:2` y `apps/Buoyancy/write/write.tcl:2` — `namespace path` a sí mismos; `AddValidApps` llama a `AddAttribute` inexistente.
- [ ] 🟠 [A] `apps/CompressibleFluid/xml/XmlController.tcl:77` — llama a `CompressibleFluid::write::GetUsedElements` (no existe; usar `::Fluid::write::GetUsedElements`).
- [ ] 🟠 [A] `apps/PotentialFluid/xml/XmlController.tcl:49` — redefine globalmente `spdAux::injectConditions` sin `processDynamicNodes`; afecta a apps cargadas después.
- [ ] 🟠 [A] IDs duplicados en el mismo catálogo (getElement/GetProcess devuelven el primero): `PfemFluid/xml/Elements.xml:504/673` y `:587/714`, `Dam/xml/Processes.xml:166/175` y `:184/194`, `MPM/xml/Elements.xml:157/176`.
- [ ] 🟢 [A] `AddAttribute` con `dict append ... ]` en `Structural/write/write.tcl:495`, `DEM/write/write.tcl:125`, `GeoMechanics/write/write.tcl:252`, `PotentialFluid/write/write.tcl:48`. `validApps` no lo lee nadie → eliminar `AddValidApps`.
- [ ] 🟢 [A] `apps/FluidDEM/start.tcl:30` — `::DEM::AfterMeshGeneration fail` (literal en vez de `$fail`).
- [ ] 🟢 [A] `apps/Stent/start.tcl:52` — `catch {::Structural::BeforeMeshGeneration ...}` proc inexistente; L6 `variable app_id` en vez de `_app`.
- [ ] 🟢 [A] `apps/CompressibleFluid/app.json` — `unique_names` `materials`/`time_parameters` no coinciden con el árbol; falta `drag`.
- [ ] 🟢 [A] IDs de ejemplo duplicados en el mismo grupo: `FluidDEM/examples/examples.xml:7,15`; `FSI/examples/examples.xml:27,41`.

---

## Fase 2 — Procesos, compatibilidad y decisiones

- [ ] 🔴 [A] `tools/create-release.bat:18-23` + `tools/prepare-release-files.py:38-55` — borra apps no `production` del working tree y hace `git commit -am` en la rama actual, luego `tag -f` + `push --force` (ya pasó: `bfde2884`, revertido en `153ec864`). Fix: generar `dist/` desde `git archive`/`git worktree`, sin commit, abortar en error.
- [ ] 🟠 [A] Finales de línea: no hay `.gitattributes`; con `core.autocrlf=true` los `*.unix.bat` y `*.sh` quedan en CRLF en el working tree; `dockers/create-release.sh:5` solo hace `dos2unix` a `*.unix.bat`. Fix: `.gitattributes` (`*.unix.bat`/`*.sh` `eol=lf`, `*.win.bat` `eol=crlf`) y `dos2unix` también para `*.sh`. Revisar la regla de AGENTS.md.
- [ ] 🟠 [A] `apps/Structural/xml/ConstitutiveLaws.xml:177` — `BeamConstitutiveLaw2D` → `TimoshenkoBeamConstitutiveLaw2D` (commit `38b8bb93`) sin regla en `kratos.transform`; `kratos.spd` sigue en 10.4.3 así que el transform no se dispara. Fix: subir versión del `.spd` y añadir regla.
- [ ] 🟠 [A] `kratos.transform` — solo reglas 6.0 → 9.3.2. Añadir sección por versión y documentar el procedimiento en AGENTS.md.
- [ ] 🟠 [A] `exec/launch.json:5,11` — contiene `10.4.3` (no está en la lista de AGENTS.md); `pip_packages` no se usa. `Launch.tcl:273` / `LoadLaunchModes` — revisar si se copia/sobrescribe `~/.kratos_multiphysics/launch_configuration.json` (los dos informes discrepan).
- [ ] 🔴 [A] **Decidir:** `scripts/Writing/WriteProjectParameters.tcl:21` — `tcl2json` elige número/string según la representación interna de Tcl → salida no determinista. Cambia el JSON de todas las apps.
- [ ] 🔴 [V] **Decidir:** `expr` sin llaves sobre valores de usuario: `Writing.tcl:571` (`getFormattedValue`), `WriteProjectParameters.tcl:391-392`, `WriteMaterials.tcl:99`. Riesgo de inyección y conversiones no deseadas (`2*3`, `sin(1)`).
- [ ] 🟠 [A] `scripts/Controllers/TreeInjections.tcl` (L64, 93, 118, 243, 268, 331…) — XML generado con `help='$help'` sin escapar; un apóstrofo rompe `appendXML`. Añadir helper `xml_escape`.
- [ ] 🟢 [A] `minimum_gid_version` en los `app.json` (`15.1.3d`, `15.1.4d`, `16.1.4d`) por debajo del efectivo `16.1.10d`. Quitar el campo o alinearlo.
- [ ] 🟢 [A] `exec/install_python_and_dependencies.unix.sh:2` — `2>1` (debe ser `2>&1`); `python3-distutils` no existe en Ubuntu 24.04.
- [ ] 🟢 [A] `tools/prepare-release-files.py:24` — `ET.SubElement(root, 'Program', 'Production')` pasa str como attrib; `tree.write` sin declaración/encoding.

---

## Fase 3 — Limpieza de bajo riesgo

### Código y archivos muertos
- [ ] `.tcl` no listados en `script_files` (borrar o registrar): `CompressibleFluid/examples/examples.tcl`, `Fluid/write/writeByGiDId.tcl`, `GeoMechanics/controllers/Fase.tcl`, `GeoMechanics/controllers/SplashWindow.tcl`, `GeoMechanics/examples/FirstExample.tcl`.
- [ ] Procs sin uso (verificar de nuevo con grep, incluido kratos-gid-tester, antes de borrar):
  - Launch: `InstallAllPythonDependencies` (y `exec/install_python.win.bat`, `exec/global_pip.win.bat`), `InstallPip`, `GetMissingPipPackagesGiDsPython_old`, `CreateModeCombo`, `CheckDependenciesLocalPipMode`.
  - Utils: `SetMeshCriteria`/`ResetMeshCriteria`, `GetExecVersion`, `proc ?`.
  - Model: `GetAllCLInputs`, `GetAllCondInputs`, `GetAllCondOutputs`, `GetAllElemInputs`, `GetAllSchemeParams`, `GetAllSolStratParams`, `GetAvailableConditions`, `CheckCondOutputState`, `DeleteRepeatedConditions`, `getAllProcs`, `Element::getNodalCondition`.
  - apps/spdAux: `apps::ClearActiveApp`, `spdAux::ExploreAllRoutes`, `ForceExtremeLoad`, `insertDependenciesSoft`, `InsertMaterialsSimple`; `Proc*` sin referencia: `ProcRefreshTree`, `ProcgetStateFromXPathValue2`, `ProcCambioMat`, `ProcEdit_database_list`, `ProcGetIntervals`, `ProcGet_materials_list_simple`, `ProcPartParamValue`, `ProcShowInMode` (ojo: `.spd` de usuario antiguos).
  - write: `AddConfigurationAttribute`, `GetDataType`, `GetNodesFromElementFace`, `GetRestartProcess`, `json2dict_former`. Examples: `getExampleById`.
  - **No borrar:** `Kratos::Quicktest` (lo usa kratos-gid-tester), eventos legacy `EndGIDProject`/`AfterWriteCalcFileGIDProject`.
- [ ] GeoMechanics `xml/XmlController.tcl`: `ProcCheckGeometryGeoMechanics` (x2), `ProcGetSolutionStrategiesGeoMechanics`, `ProcCheckNodalConditionStateGeoMechanics`, `ProcGetElementsGeoMechanics` (~120 líneas sin uso).
- [ ] `apps/Buoyancy/write/write.tcl:71` `writeSubModelParts` sin uso.
- [ ] `scripts/Custom/python_writer.py` — no lo referencia nadie y está a medias.
- [ ] Catálogos rotos/no cargados: `FluidDEM/xml/NodalConditions.xml:11` (XML inválido), `DEM/xml/NodalConditions.xml:3`, `MPM/xml/NodalConditions.xml:5`.
- [ ] Includes a `apps/Structural/xml/Processes.spd` (inexistente, `active="0"`) en Structural, MPM y GeoMechanics `Main.spd`.
- [ ] Ramas para GiD < 16: `kratos.tcl:24-28` (`DeprecatedEvents.tcl`, `ModifyPreferencesWindowOld`), `Deprecated.tcl:84-105`, comprobaciones 14.x en `kratos.tcl:297,374`, `Menus.tcl:167`, `ApplicationMarketWindow.tcl:105`.
- [ ] Código tras `return`: `CommonProcs.tcl:390`, `:586`; `Launch.tcl:47` (`if {true}`); `SolutionStrategy.tcl:377,399`.

### Coherencia
- [ ] `prefix` de los `appLink` en `kratos.spd` no coincide con `app.json` (no se usa: `App::getPrefix` sin llamadas). Eliminar o alinear.
- [ ] `id`/`kratos_name` de `app.json` inconsistentes (`DAM`, `* Launcher`, `Buoyancyapplication`…).
- [ ] Nombres únicos escritos a mano (usar `GetUniqueName`): `MPM/xml/XmlController.tcl:66`, `GeoMechanics/xml/XmlController.tcl:126`, `FSI/write/writeProjectParameters.tcl:80,81,90,168,169`, `FluidDEM/xml/XmlController.tcl:68-69`, `FluidDEM/write/writeProjectParameters.tcl:272`, `ConjugateHeatTransfer/xml/XmlController.tcl:36-44`, `ConjugateHeatTransfer/write/writeProjectParameters.tcl:64-65,150-162`, `PfemFluid/xml/XmlController.tcl:415`; prefijos a mano en `xml::getUniqueName` de Dam, MPM, PfemFluid.
- [ ] `Launch.tcl:179-180` recomienda Python 3.9; el resto exige ≥ 3.10.8.
- [ ] Plataforma: `PreferencesWindow.tcl:45` (ruta por defecto solo Windows), `ImportFiles.tcl:104` (`start` solo Windows), `ApplicationMarketWindow.tcl:182` (`string trimleft` como prefijo).

### Depuración
- [ ] 82 `W` activas y 104 comentadas en `kratos.tcl` + `scripts/`; pasar las de depuración a `Kratos::Log`: `spdAuxiliar.tcl:177,267,270,369`, `Element.tcl:439`, `Mesh.tcl:32`, `CommonProcs.tcl:309,505,878`, `Writing.tcl:210`, `kratos.tcl:374`. En apps: `PfemFluid/xml/XmlController.tcl:422`, `GeoMechanics/controllers/Python.tcl:5,15`, `FluidDEM/examples/CylinderInFlow.tcl:262`.
- [ ] `scripts/Controllers/ExamplesWindow.tcl:244-252` — canal abierto si falla el parse de un enlace.

---

## Fase 4 — Refactors de duplicación (requieren kratos-gid-tester)

| # | Clúster | Líneas aprox. | Destino propuesto |
|---|---|---|---|
| 1 | Plantilla de `Init` en 49 `examples/*.tcl` (`IsModelEmpty`, `ResetModel`, redraw/zoom) | ~700 | `Examples::RunExample {ns}` en `scripts/Controllers/ExamplesWindow.tcl` (comprobar si el tester llama a los `Init` directamente) |
| 2 | Ejemplos 2D/3D casi iguales (Dam ThermoMechaDam, FreeSurface Box, MPM CantileverBeam, PfemThermic Sloshing, PotentialFluid NACA) | ~650 | Un archivo parametrizado por dimensión |
| 3 | Ejemplos copiados entre apps (CylinderInFlow, HeatedSquare, SpheresDrop/CirclesDrop, DamBreakFSI) | ~650 | Llamar al proc de la app padre (como `FSI/examples/HighRiseBuilding.tcl:26-29`) |
| 4 | Accesores de atributos del writer en 19 apps (116 procs) | ~550 | Almacén común en `scripts/Writing/Writing.tcl` |
| 5 | Cabecera de `start.tcl` en 24 apps | ~450 | Generada en `apps::LoadAppProperties` |
| 6 | GeoMechanics copia de Structural (`XmlController.tcl`, `write.tcl`) | ~225 | Usar `Structural::xml::*` |
| 7 | `Procs.spd` copiados (Fluid = EmbeddedFluid = PotentialFluid; PfemThermic ≈ PfemFluid) | ~160 | `include` del de la app padre |
| 8 | Tres escritores de SubModelPart (`WriteSubModelPart.tcl:3`, `WriteConditionsByGiDId.tcl:74`, `WriteConditionsByUniqueId.tcl:159`) | ~120 | `write::_writeSMPBlock` con callback de condiciones |
| 9 | `inject*Inputs` (`TreeInjections.tcl:542,565,588`) + `injectNodalConditionsOutputs_do`/`_Nonhistorical_do` | ~120 | Un proc parametrizado |
| 10 | `ErasePreviousIntervals` en 12 `examples.tcl` | ~80 | `spdAux::` junto a `CreateInterval` |
| 11 | `PlaceMDPAImports`/`ModelersPrefix` (FSI, CHT) | ~50 | Helper junto a `write::GetModelersDict` |
| 12 | `writeParametersEvent` idéntico en 7 apps | — | `write::DefaultWriteParametersEvent ns` |
| 13 | Lista de booleanos copiada 5 veces (`Writing.tcl:578-596`, `TreeInjections.tcl:765`) | — | Una sola variable `write::true_values` |
| 14 | Envoltorios `Proc*State` en `CommonProcs.tcl:257-486` | — | `spdAux::BoolToState` |
| 15 | Parseo de `pip list` x3 en `Launch.tcl` | — | `Kratos::_pipFreezeDict` |

### XML
- [ ] Elementos de `apps/Stent/xml/Elements.xml:3-171` copiados de Structural (Stent ya depende de Structural).
- [ ] Cargas `SelfWeight`/`PointLoad`/`LineLoad`/`SurfaceLoad`/`PointMoment` en Dam, MPM y Structural → `Common/xml/Conditions.xml`.
- [ ] `Dam/xml/Solvers.xml` repite 6 de los 9 solvers de `Common/xml/Solvers.xml`.
- [ ] Materiales `Water`, `Air` (5 apps) y `Steel` (3 apps).

### Diseño
- [ ] Apps hijas que redefinen procs de la padre o del core (`EmbeddedFluid` → `Fluid::write::writeCustomBlocks`, `Stent` → `ProcCheckGeometryStructural`, `MdpaGenerator` → `write::GetWriteMode`, `PotentialFluid` → `spdAux::injectConditions`) → hooks explícitos.
- [ ] Herencia del writer de Fluid distinta en cada app hija → un único mecanismo (`write::InheritAttributes`).
- [ ] CHT y Buoyancy mutan atributos de `ConvectionDiffusion::write` y los restauran a mano → pasar `un` como parámetros.
- [ ] Capas mezcladas: `apps::setActiveApp` → ventanas; `Model::*State` depende del DOM; `Model::GetSolutionStrategy` devuelve `""` con `W`.
- [ ] `Kratos::ManagePreferences` escribe en disco y refresca el árbol incluso en `GetValue`.
- [ ] `spdAux::TryRefreshTree` con `update` en temporizador y `catch` (reentrada).
- [ ] Procs grandes: `spdAux::GetParameterValueString`, `Kratos::ReadPre`, `write::processMaterials`, `write::writeEvent`, `ProcGetMaterialsList` (define procs globales en cada llamada).
- [ ] Fugas: `Model::DestroyEverything` no destruye objetos TclOO; documentos tDOM sin borrar (`Model.tcl:55-95`, `kratos.tcl:247`, `TreeInjections.tcl:793`, `ExamplesWindow.tcl:97`).
