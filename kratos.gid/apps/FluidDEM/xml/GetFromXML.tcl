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

    set inlet_cnd [Model::getCondition "Inlet"]
    set inlet_process [Model::GetProcess [$inlet_cnd getProcessName]]
    set parameter [::Model::Parameter new "hydrodynamic_law" "Hydrodynamic law" "combo" "" "" "" "Select a hydrodynamic law" "uno" ""]
    $inlet_process addInputDone $parameter

    set element [::Model::getElement "SphericPartDEMElement3D"]
    $element addInputDone $parameter
}

proc FluidDEM::xml::getUniqueName {name} {
    return ${::FluidDEM::prefix}${name}
}

proc FluidDEM::xml::CustomTree { args } {
    DEM::xml::CustomTree
    Fluid::xml::CustomTree
    spdAux::parseRoutes
    set root [customlib::GetBaseRoot]

    # Remove Fluid things to move them to Common
    set result_node [$root selectNodes "[spdAux::getRoute FLSolutionParameters]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute FLSolutionParameters]/container\[@n = 'Gravity'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute FLSolutionParameters]/container\[@n = 'TimeParameters'\]"]
	if { $result_node ne "" } {$result_node delete}

    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'DEMGravity'\]"]
	if { $result_node ne "" } {$result_node delete}

    set dem_inlet_hydrodynamic_law_node [$root selectNodes "[spdAux::getRoute "DEMConditions"]/condition\[@n = 'Inlet'\]/value\[@n = 'hydrodynamic_law'\]"]
    $dem_inlet_hydrodynamic_law_node setAttribute values "\[GetHydrodynamicLaws\]"
    
}

proc FluidDEM::xml::ProcGetHydrodynamicLaws {domNode args} {
    set names [list ]
    set dem_inlet_hydrodynamic_law_nodes [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute "DEMFluidHydrodynamicLaw"]/blockdata"]
    foreach hydro_law $dem_inlet_hydrodynamic_law_nodes {
        lappend names [$hydro_law @name]
    }
    
    set values [join $names ","]
    #W "[get_domnode_attribute $domNode v] $names"
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
    #spdAux::RequestRefresh
    return $values
}

FluidDEM::xml::Init
