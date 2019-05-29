namespace eval PotentialFluid::write {
    variable writeAttributes
    variable FluidConditionMap
}

proc PotentialFluid::write::Init { } {
    # Namespace variables inicialization
    SetAttribute parts_un FLParts
    SetAttribute nodal_conditions_un FLNodalConditions
    SetAttribute conditions_un FLBC
    SetAttribute materials_un PTFLMaterials
    SetAttribute results_un Results
    SetAttribute drag_un FLDrags
    SetAttribute time_parameters_un FLTimeParameters
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "Fluid" "PotentialFluid"]
    SetAttribute main_script_file "KratosPotentialFluid.py"
    SetAttribute materials_file "FluidMaterials.json"
    SetAttribute output_model_part_name "fluid_computational_model_part"
}

# Events
proc PotentialFluid::write::writeModelPartEvent { } {
    Fluid::write::AddValidApps "PotentialFluid"
    set err [Fluid::write::Validate]
    if {$err ne ""} {error $err}
    write::initWriteConfiguration [GetAttributes]
    write::writeModelPartData
    Fluid::write::writeProperties
    write::writeMaterials [::Fluid::GetAttribute validApps]
    write::writeNodalCoordinatesOnParts
    write::writeElementConnectivities
    Fluid::write::InitConditionsMap
    Fluid::write::writeConditions
    Fluid::write::writeMeshes
}
proc PotentialFluid::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosPotentialFluid.py"
    write::RenameFileInModel "KratosPotentialFluid.py" "MainKratos.py"
}


proc PotentialFluid::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc PotentialFluid::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc PotentialFluid::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc PotentialFluid::write::AddAttribute {att val} {
    variable writeAttributes
    dict append writeAttributes $att $val]
}

proc PotentialFluid::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}


PotentialFluid::write::Init
