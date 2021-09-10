namespace eval ::PotentialFluid::write {
    namespace path ::PotentialFluid
    variable writeAttributes
    variable FluidConditionMap
}

proc ::PotentialFluid::write::Init { } {
    # Namespace variables inicialization
    variable writeAttributes
    set writeAttributes [::Fluid::write::GetAttributes]
    SetAttribute validApps [list "Fluid" "PotentialFluid"]
}

# Events
proc PotentialFluid::write::writeModelPartEvent { } {
    # Add the PotentialFluid to the Fluid valid applications list
    Fluid::write::AddValidApps "PotentialFluid"
    Fluid::write::writeModelPartEvent
}

proc PotentialFluid::write::writeCustomFilesEvent { } {
    # Write the fluid materials json file
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] False [GetAttribute model_part_name]
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
