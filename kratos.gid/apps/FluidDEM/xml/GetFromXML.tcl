namespace eval FluidDEM::xml {
    # Namespace variables declaration
    variable dir
}

proc FluidDEM::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $FluidDEM::dir

    Model::ForgetElement SphericPartDEMElement3D
    Model::getElements Elements.xml
}

proc FluidDEM::xml::getUniqueName {name} {
    return ${::FluidDEM::prefix}${name}
}

proc FluidDEM::xml::CustomTree { args } {
    DEM::xml::CustomTree
    #PfemFluid::xml::CustomTree
    #spdAux::SetValueOnTreeItem values Fluid PFEMFLUID_DomainType

    set root [customlib::GetBaseRoot]

    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'DEMGravity'\]"]
	if { $result_node ne "" } {$result_node delete}
    
}

FluidDEM::xml::Init
