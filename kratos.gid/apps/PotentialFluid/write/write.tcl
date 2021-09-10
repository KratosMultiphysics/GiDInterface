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
    SetAttribute main_launch_file "KratosPotentialFluid.py"
    SetAttribute model_part_name "FluidModelPart"
    SetAttribute materials_file "FluidMaterials.json"
    SetAttribute properties_location json
    SetAttribute output_model_part_name "fluid_computational_model_part"
}

# Events
proc PotentialFluid::write::writeModelPartEvent { } {
    # Add the PotentialFluid to the Fluid valid applications list
    Fluid::write::AddValidApps "PotentialFluid"
    Fluid::write::writeModelPartEvent
}

proc PotentialFluid::write::writeCustomFilesEvent { } {
    # Write the fluid materials json file
    set materials_model_part_name [GetAttribute model_part_name]
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] False $materials_model_part_name
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
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
