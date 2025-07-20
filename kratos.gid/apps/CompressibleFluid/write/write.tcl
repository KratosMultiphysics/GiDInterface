namespace eval ::CompressibleFluid::write {
    namespace path ::CompressibleFluid
    Kratos::AddNamespace [namespace current]

    # Namespace variables declaration
    variable writeCoordinatesByGroups
    variable writeAttributes
}

proc ::CompressibleFluid::write::Init { } {
    # Namespace variables inicialization
    ::Fluid::write::Init
    # Fluid has implemented the geometry mode, but we do not use it yet in inherited apps
    ::Fluid::write::SetAttribute write_mdpa_mode [::CompressibleFluid::GetWriteProperty write_mdpa_mode]

    SetAttribute parts_un            [::Fluid::GetUniqueName parts]
    SetAttribute nodal_conditions_un [::CompressibleFluid::GetUniqueName nodal_conditions]
    SetAttribute conditions_un       [::CompressibleFluid::GetUniqueName conditions]
    SetAttribute materials_un        [::CompressibleFluid::GetUniqueName materials]
    SetAttribute results_un          [::CompressibleFluid::GetUniqueName results]
    SetAttribute drag_un             [::CompressibleFluid::GetUniqueName drag]
    SetAttribute time_parameters_un  [::Fluid::GetUniqueName time_parameters]

    SetAttribute writeCoordinatesByGroups [::CompressibleFluid::GetWriteProperty coordinates]
    SetAttribute validApps [list "CompressibleFluid"]

    SetAttribute main_launch_file       [::CompressibleFluid::GetAttribute main_launch_file]
    SetAttribute materials_file         [::CompressibleFluid::GetWriteProperty materials_file]
    SetAttribute properties_location    [::CompressibleFluid::GetWriteProperty properties_location]
    SetAttribute model_part_name        [::CompressibleFluid::GetWriteProperty model_part_name]
    SetAttribute output_model_part_name [::CompressibleFluid::GetWriteProperty output_model_part_name]

    variable last_condition_iterator
    set last_condition_iterator 0
}

# MDPA write event
proc ::CompressibleFluid::write::writeModelPartEvent { } {
    ::Fluid::write::writeModelPartEvent
}

proc ::CompressibleFluid::write::writeCustomFilesEvent { } {
    # Write the fluid materials json file
    ::CompressibleFluid::write::WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}

# Custom files
proc ::CompressibleFluid::write::WriteMaterialsFile { {write_const_law True} {include_modelpart_name True} } {
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetAttribute model_part_name]}
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] $write_const_law $model_part_name
}

proc ::CompressibleFluid::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::CompressibleFluid::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::CompressibleFluid::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::CompressibleFluid::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ::CompressibleFluid::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::CompressibleFluid::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc ::CompressibleFluid::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}
