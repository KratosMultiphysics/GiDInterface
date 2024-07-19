namespace eval ::BasicFlow::write {
    namespace path ::BasicFlow
    Kratos::AddNamespace [namespace current]
    
}

proc ::BasicFlow::write::Init { } {
    # Namespace variables inicialization
    SetAttribute parts_un [::BasicFlow::GetUniqueName parts]
    SetAttribute conditions_un [::BasicFlow::GetUniqueName conditions]
}

# MDPA write event
proc ::BasicFlow::write::writeModelPartEvent { } {

    # Get the list of groups in the spd
    set lista [::spdAux::GetListOfSubModelParts]
    
    # Write the geometries
    set ret [::write::writeGeometryConnectivities $lista]

    # Write the submodelparts
    foreach group $lista {
        write::writeGroupSubModelPartAsGeometry [$group @n]
    }
    
}

proc ::BasicFlow::write::writeCustomFilesEvent { } {
    # Write the BasicFlow materials json file

}

proc ::BasicFlow::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::BasicFlow::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::BasicFlow::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::BasicFlow::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ::BasicFlow::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::BasicFlow::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc ::BasicFlow::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}


