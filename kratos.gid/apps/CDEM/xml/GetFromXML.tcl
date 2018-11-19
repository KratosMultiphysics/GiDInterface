namespace eval CDEM::xml {
    # Namespace variables declaration
    variable dir
}

proc CDEM::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $CDEM::dir

    Model::ForgetElement SphericPartDEMElement3D
    Model::getElements Elements.xml
}

proc CDEM::xml::getUniqueName {name} {
    return ${::CDEM::prefix}${name}
}

proc CDEM::xml::CustomTree { args } {
    DEM::xml::CustomTree
    #spdAux::SetValueOnTreeItem values Fluid PFEMFLUID_DomainType

    set root [customlib::GetBaseRoot]

    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'DEMGravity'\]"]
	if { $result_node ne "" } {$result_node delete}

}

CDEM::xml::Init
