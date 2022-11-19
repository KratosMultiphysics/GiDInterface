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
}

# MDPA write event
proc ::MdpaGenerator::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    InitConditionsMap
    writeProperties

    # Init data
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData

    # Nodal coordinates
    write::writeNodalCoordinates

    # Custom SubmodelParts
    set conditions_mode [write::getValue SMP_write_options condition_write_mode]
    variable last_condition_iterator
    set last_condition_iterator [expr [write::getValue SMP_write_options conditions_start_id] -1]
    switch $conditions_mode {
        "unique" {write::writeBasicSubmodelPartsByUniqueId $MdpaGenerator::write::ConditionMap $last_condition_iterator}
        "norepeat" {write::writeBasicSubmodelParts $last_condition_iterator}
        "gid-id" {}
        default {}
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