namespace eval ::GeoMechanics::write {
    namespace path ::GeoMechanics
    Kratos::AddNamespace [namespace current]

    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable writeAttributes
    variable ContactsDict
}

proc ::GeoMechanics::write::Init { } {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]

    variable ContactsDict
    set ContactsDict [dict create]

    variable writeAttributes
    set writeAttributes [dict create]
    
    SetAttribute validApps [list "GeoMechanics"]
    SetAttribute writeCoordinatesByGroups [::GeoMechanics::GetWriteProperty coordinates]
    SetAttribute properties_location [::GeoMechanics::GetWriteProperty properties_location]

    SetAttribute parts_un [::GeoMechanics::GetUniqueName parts]
    SetAttribute time_parameters_un [::GeoMechanics::GetUniqueName time_parameters]
    SetAttribute results_un [::GeoMechanics::GetUniqueName results]
    SetAttribute materials_un [::GeoMechanics::GetUniqueName materials]
    SetAttribute initial_conditions_un [::GeoMechanics::GetUniqueName initial_conditions]
    SetAttribute nodal_conditions_un [::GeoMechanics::GetUniqueName nodal_conditions]
    SetAttribute conditions_un [::GeoMechanics::GetUniqueName conditions]

    SetAttribute nodal_conditions_no_submodelpart [list CONDENSED_DOF_LIST CONDENSED_DOF_LIST_2D CONTACT CONTACT_SLAVE]
    SetAttribute materials_file [::GeoMechanics::GetWriteProperty materials_file]
    SetAttribute main_launch_file [::GeoMechanics::GetAttribute main_launch_file]
    SetAttribute model_part_name [::GeoMechanics::GetWriteProperty model_part_name]
    SetAttribute output_model_part_name [::GeoMechanics::GetWriteProperty output_model_part_name]
}

proc ::GeoMechanics::write::writeCustomFilesEvent { } {
    WriteMaterialsFile

    write::SetParallelismConfiguration
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]

}

proc ::GeoMechanics::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

proc ::GeoMechanics::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::GeoMechanics::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::GeoMechanics::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::GeoMechanics::write::AddAttribute {att val} {
    variable writeAttributes
    dict append writeAttributes $att $val]
}

proc ::GeoMechanics::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::GeoMechanics::write::AddValidApps {appList} {
    AddAttribute validApps $appList
}

proc ::GeoMechanics::write::ApplyConfiguration { } {
    variable writeAttributes
    write::SetConfigurationAttributes $writeAttributes
}
