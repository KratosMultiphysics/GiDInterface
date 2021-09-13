namespace eval ::FluidDEM::xml {
    # Namespace variables declaration
    namespace path ::FluidDEM
    Kratos::AddNamespace [namespace current]
    variable dir
}

proc ::FluidDEM::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $::FluidDEM::dir

    Model::ForgetElements
    Model::ForgetSolutionStrategies
    Model::getSolutionStrategies [file join ".." ".." DEM xml "Strategies.xml"]
    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml

    # Get the inlet condition
    set inlet_cnd [Model::getCondition "Inlet"]
    # Get the process assigned to the inlet condition
    set inlet_process [Model::GetProcess [$inlet_cnd getProcessName]]
    # Add the hydrodynamic law parameter
    set parameter [::Model::Parameter new "hydrodynamic_law" "Hydrodynamic law" "combo" "" "" "" "Select a hydrodynamic law" "uno" ""]
    $inlet_process addInputDone $parameter

    # Change the inlet injector element type
    set inlet_element_type_param [$inlet_process getInputPn InletElementType]
    if {$inlet_element_type_param ne ""} {
        $inlet_element_type_param setValues "SphericSwimmingParticle3D"
        $inlet_element_type_param setPValues "Spheres"
        $inlet_element_type_param setDv "SphericSwimmingParticle3D"
    }

    set element [::Model::getElement "SphericPartDEMElement3D"]
    $element addInputDone $parameter
    spdAux::parseRoutes
}

proc ::FluidDEM::xml::getUniqueName {name} {
    return ${::FluidDEM::prefix}${name}
}

proc ::FluidDEM::xml::CustomTree { args } {
    ::DEM::xml::CustomTree
    ::Fluid::xml::CustomTree
    spdAux::parseRoutes
    set root [customlib::GetBaseRoot]

    # Remove DEM things to move them to Common
    set dem_gravity_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'Gravity'\]"]
	if { $dem_gravity_node ne "" } {$dem_gravity_node delete}
    set dem_inlet_hydrodynamic_law_node [$root selectNodes "[spdAux::getRoute "DEMConditions"]/condition\[@n = 'Inlet'\]/value\[@n = 'hydrodynamic_law'\]"]
    $dem_inlet_hydrodynamic_law_node setAttribute values "\[GetHydrodynamicLaws\]"
    set dem_parts_hydrodynamic_law_node [$root selectNodes "[spdAux::getRoute "DEMParts"]/value\[@n = 'hydrodynamic_law'\]"]
    $dem_parts_hydrodynamic_law_node setAttribute values "\[GetHydrodynamicLaws\]"
    set result_node [$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}

    spdAux::SetValueOnTreeItem state hidden DEMPreferences
    spdAux::SetValueOnTreeItem state hidden DEMStratSection TimeParameters


    spdAux::SetValueOnTreeItem state hidden DEMResults

    spdAux::SetValueOnTreeItem state normal FLParts Element
    spdAux::SetValueOnTreeItem dict {[GetElements ElementType "Fluid"]} FLParts Element

    # Remove Fluid things to move them to Common
    set result_node [$root selectNodes "[spdAux::getRoute FLSolutionParameters]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute FLSolutionParameters]/container\[@n = 'Gravity'\]"]
	if { $result_node ne "" } {$result_node delete}
    set result_node [$root selectNodes "[spdAux::getRoute FLSolutionParameters]/container\[@n = 'TimeParameters'\]"]
	if { $result_node ne "" } {$result_node delete}

    # set result_node [$root selectNodes "[spdAux::getRoute FLResults]/container\[@n = 'GiDOptions'\]"]
	# if { $result_node ne "" } {$result_node delete}
    spdAux::SetValueOnTreeItem state disabled FLScheme
    spdAux::SetValueOnTreeItem state hidden FLResults FileLabel
    spdAux::SetValueOnTreeItem state hidden FLResults OutputControlType
    spdAux::SetValueOnTreeItem state hidden FLResults OutputDeltaTime
    spdAux::SetValueOnTreeItem state hidden FLResults OnNodes
    spdAux::SetValueOnTreeItem state hidden FLResults GiDOptions
    spdAux::SetValueOnTreeItem v MultipleFiles FLResults GiDMultiFileFlag

    spdAux::parseRoutes

}

proc ::FluidDEM::xml::ProcGetHydrodynamicLaws {domNode args} {
    set names [list ]
    set dem_hydrodynamic_law_nodes [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute "DEMFluidHydrodynamicLaw"]/blockdata"]
    foreach hydro_law $dem_hydrodynamic_law_nodes {
	lappend names [$hydro_law @name]
    }

    set values [join $names ","]
    #W "[get_domnode_attribute $domNode v] $names"
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
    return $values
}
