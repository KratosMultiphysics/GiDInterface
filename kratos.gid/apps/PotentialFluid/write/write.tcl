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
    SetAttribute properties_location json
    SetAttribute output_model_part_name "fluid_computational_model_part"
}

# Events
proc PotentialFluid::write::writeModelPartEvent { } {
    # Add the PotentialFluid to the Fluid valid applications list
    Fluid::write::AddValidApps "PotentialFluid"

    # Validation
    Fluid::write::InitConditionsMap

    set err [Fluid::write::Validate]
    if {$err ne ""} {error $err}

    # Init data
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData
    Fluid::write::writeProperties

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (groups in FLParts)
    write::writeElementConnectivities

    # Nodal conditions and conditions
    Fluid::write::writeConditions

    # SubmodelParts
    Fluid::write::writeMeshes
}

proc PotentialFluid::write::writeCustomFilesEvent { } {
    # Write the fluid materials json file
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] False

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
