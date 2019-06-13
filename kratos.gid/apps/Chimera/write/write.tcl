namespace eval Chimera::write {
    variable writeAttributes
}

proc Chimera::write::Init { } {
    # Namespace variables inicialization
    SetAttribute parts_un FLParts
    SetAttribute nodal_conditions_un FLNodalConditions
    SetAttribute conditions_un FLBC
    SetAttribute materials_un FLMaterials
    SetAttribute results_un FLResults
    SetAttribute time_parameters_un FLTimeParameters
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "Fluid" "Chimera"]
    SetAttribute main_script_file "KratosFluid.py"
    SetAttribute model_part_name "FluidModelPart"
    SetAttribute materials_file "FluidMaterials.json"
}

# Events
proc Chimera::write::writeModelPartEvent { } {
    # Fluid::write::AddValidApps "Chimera"
    set err [Fluid::write::Validate]
    if {$err ne ""} {error $err}

    Fluid::write::InitConditionsMap
    write::initWriteConfiguration [GetAttributes]
    write::writeModelPartData
    Fluid::write::writeProperties
    write::writeMaterials [GetAttribute validApps]
    write::writeNodalCoordinatesOnParts
    write::writeElementConnectivities
    Fluid::write::writeConditions
    Fluid::write::writeMeshes
    Fluid::write::FreeConditionsMap
}
proc Chimera::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosFluid.py"
    write::RenameFileInModel "KratosFluid.py" "MainKratos.py"
}

proc Chimera::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Chimera::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Chimera::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

Chimera::write::Init
