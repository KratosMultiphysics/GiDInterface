namespace eval CDEM::xml {
    # Namespace variables declaration
    variable dir
}

proc CDEM::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $CDEM::dir
    Model::ForgetElements
    Model::ForgetMaterials
    Model::ForgetConstitutiveLaws
    Model::ForgetElement SphericPartDEMElement3D
    Model::getElements ElementsC.xml
    Model::getConstitutiveLaws ConstitutiveLawsC.xml
    Model::getMaterials MaterialsC.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
}

proc CDEM::xml::getUniqueName {name} {
    return ${::CDEM::prefix}${name}
}

proc CDEM::xml::CustomTree { args } {
    spdAux::SetValueOnTreeItem values OpenMP ParallelType
    spdAux::SetValueOnTreeItem state hidden DEMTimeParameters StartTime

    set root [customlib::GetBaseRoot]
    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'DEMGravity'\]"]
	if { $result_node ne "" } {$result_node delete}

}

proc CDEM::xml::ProcGetElements { domNode args } {
    set elems [Model::GetElements]
    set names [list ]
    set pnames [list ]
    foreach elem $elems {
        if {[$elem cumple {*}$args]} {
            lappend names [$elem getName]
            lappend pnames [$elem getName]
            lappend pnames [$elem getPublicName]
        }
    }
    set diction [join $pnames ","]
    set values [join $names ","]
    $domNode setAttribute values $values
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}

    return $diction
}

CDEM::xml::Init
