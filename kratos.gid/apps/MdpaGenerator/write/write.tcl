namespace eval ::MdpaGenerator::write {
    namespace path ::MdpaGenerator
    Kratos::AddNamespace [namespace current]

    # Namespace variables declaration
    variable writeCoordinatesByGroups
    variable writeAttributes
    variable ConditionMap
    # after regular conditions are written, we need this number in order to print the custom submodelpart conditions
    # only if are applied over things that are not in the skin
    variable last_condition_iterator
}

proc ::MdpaGenerator::write::Init { } {
    # Namespace variables inicialization

    variable last_condition_iterator
    set last_condition_iterator 0

    variable writeAttributes
    set writeAttributes [dict create ]
    
    SetAttribute parts_un [::MdpaGenerator::GetUniqueName parts]
    SetAttribute write_mdpa_mode [::MdpaGenerator::GetWriteProperty write_mdpa_mode]
}

# MDPA write event
proc ::MdpaGenerator::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    # Init data
    write::initWriteConfiguration [GetAttributes]

    InitConditionsMap
    writeProperties

    # Headers
    write::writeModelPartData

    # Nodal coordinates
    write::writeNodalCoordinates

    set write_mode [::MdpaGenerator::xml::GetCurrentWriteMode]
    if {$write_mode eq "geometries"} {
        MdpaGenerator::write::writeGeometries
    } else {
        
        # Custom SubmodelParts
        set conditions_mode [write::getValue SMP_write_options condition_write_mode]
        variable last_condition_iterator
        set last_condition_iterator [expr [write::getValue SMP_write_options conditions_start_id] -1]
        switch $conditions_mode {
            "unique" {write::writeBasicSubmodelPartsByUniqueId $MdpaGenerator::write::ConditionMap $last_condition_iterator}
            "norepeat" {write::writeBasicSubmodelParts $last_condition_iterator}
            default {}
        }
    }

    # Clean
    unset ::MdpaGenerator::write::ConditionMap
}

proc ::MdpaGenerator::write::writeCustomFilesEvent { } {
}

proc ::MdpaGenerator::write::Validate {} {
    set err ""

    return $err
}

proc ::MdpaGenerator::write::writeGeometries { } {
    # Get the list of groups in the spd
    set lista [::MdpaGenerator::xml::GetListOfSubModelParts]

    # Write the geometries
    set ret [::write::writeGeometryConnectivities $lista]

    # Write the submodelparts
    set what "nodal"
    append what "&Geometries"
    
    foreach group $lista {
        ::write::writeGroupSubModelPart "GENERIC" [$group @n] $what
    }
    
}

# MDPA Blocks
proc ::MdpaGenerator::write::writeProperties { } {
    # Begin Properties
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc ::MdpaGenerator::write::InitConditionsMap { {map "" } } {

    variable ConditionMap
    if {$map eq ""} {
        set ConditionMap [objarray new intarray [expr [GiD_Info Mesh MaxNumElements] +1] 0]
    } {
        set ConditionMap $map
    }
}
proc ::MdpaGenerator::write::FreeConditionsMap { } {

    variable ConditionMap
    unset ConditionMap
}

proc ::MdpaGenerator::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::MdpaGenerator::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::MdpaGenerator::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::MdpaGenerator::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ::MdpaGenerator::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::MdpaGenerator::write::writeParametersEvent { } {

}