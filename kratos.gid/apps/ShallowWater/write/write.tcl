namespace eval ::ShallowWater::write {
    namespace path ::ShallowWater
    Kratos::AddNamespace [namespace current]

    variable ConditionsDictGroupIterators
    variable writeAttributes
}

proc ::ShallowWater::write::Init { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [dict create ]
    variable writeAttributes
    set writeAttributes [dict create]

    SetAttribute parts_un [GetUniqueName parts]
    SetAttribute materials_un [GetUniqueName materials]
    SetAttribute initial_conditions_un [GetUniqueName initial_conditions]
    SetAttribute topography_data_un [GetUniqueName topography_data]
    SetAttribute conditions_un [GetUniqueName conditions]

    SetAttribute main_launch_file [ShallowWater::GetAttribute main_launch_file]
    SetAttribute properties_location [GetWriteProperty properties_location]
    SetAttribute materials_file [GetWriteProperty materials_file]
    SetAttribute model_part_name [GetWriteProperty model_part_name]
    SetAttribute write_mdpa_mode [GetWriteProperty write_mdpa_mode]
}

proc ::ShallowWater::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    # Init data
    ::write::initWriteConfiguration [GetAttributes]

    # Nodal Coordinates
    ::write::writeNodalCoordinates

    # Get the list of groups in the spd
    set lista [spdAux::GetListOfSubModelParts]

    # Write the geometries
    set ret [::write::writeGeometryConnectivities $lista]

    foreach group $lista {
        write::writeGroupSubModelPartAsGeometry [$group @n]
    }
}

proc ::ShallowWater::write::Validate {} {
    set err ""
    return $err
}

proc ::ShallowWater::write::writeCustomFilesEvent { } {
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] false [GetAttribute model_part_name]
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}

proc ::ShallowWater::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::ShallowWater::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::ShallowWater::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::ShallowWater::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ::ShallowWater::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}
