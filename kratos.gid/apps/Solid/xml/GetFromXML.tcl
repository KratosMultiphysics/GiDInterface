namespace eval Solid::xml {
     variable dir
}

proc Solid::xml::Init { } {
     variable dir
     Model::InitVariables dir $Solid::dir

     Model::getSolutionStrategies Strategies.xml
     Model::getElements Elements.xml
     Model::getMaterials Materials.xml
     Model::getNodalConditions NodalConditions.xml
     Model::getConstitutiveLaws ConstitutiveLaws.xml
     Model::getProcesses DeprecatedProcesses.xml
     Model::getProcesses Processes.xml
     Model::getConditions Conditions.xml
     Model::getSolvers "../../Common/xml/Solvers.xml"
    
     # Model::ForgetElement SmallDisplacementBbarElement2D    
     # Model::ForgetElement SmallDisplacementBbarElement3D

     # This solver is not working in kratos June 01 2018
     Model::ForgetSolver GMRESSolver
}

proc Solid::xml::getUniqueName {name} {
    return SL$name
}

proc Solid::xml::CustomTree { args } {

    set root [customlib::GetBaseRoot]

    #set icon data as default
    foreach node [$root getElementsByTagName value ] { $node setAttribute icon data }

    #intervals
    spdAux::SetValueOnTreeItem icon timeIntervals Intervals
    foreach node [$root selectNodes "[spdAux::getRoute Intervals]/blockdata"] {
        $node setAttribute icon select
    }

    #conditions
    foreach node [$root selectNodes "[spdAux::getRoute SLNodalConditions]/condition" ] { 
        $node setAttribute icon select
	$node setAttribute groups_icon groupCreated
    }

    #loads
    foreach node [$root selectNodes "[spdAux::getRoute SLLoads]/condition" ] { 
        $node setAttribute icon select
	$node setAttribute groups_icon groupCreated
    }
    
    #materials
    foreach node [$root selectNodes "[spdAux::getRoute SLMaterials]/blockdata" ] { 
        $node setAttribute icon select
    }
    
    #solver settings
    foreach node [$root selectNodes "[spdAux::getRoute SLStratSection]/container\[@n = 'linear_solver_settings'\]" ] { 
        $node setAttribute icon solvers
    }

    #linear solver parameters
    spdAux::SetValueOnTreeItem v 2000 SLImplicitlinear_solver_settings max_iteration
    spdAux::SetValueOnTreeItem v 1e-6 SLImplicitlinear_solver_settings tolerance
    spdAux::SetValueOnTreeItem v cg SLImplicitlinear_solver_settings krylov_type

    #results
    foreach result [list SPRING_2D BALLAST_2D AXIAL_TURN_2D AXIAL_VELOCITY_TURN_2D AXIAL_ACCELERATION_TURN_2D SPRING_3D BALLAST_3D AXIAL_TURN_3D AXIAL_VELOCITY_TURN_3D AXIAL_ACCELERATION_TURN_3D] {
        set result_node [$root selectNodes "[spdAux::getRoute NodalResults]/value\[@n = '$result'\]"]
	if { $result_node ne "" } {$result_node delete}
    }
    
    #units
    [$root selectNodes "/Kratos_data/blockdata\[@n = 'units'\]"] setAttribute icon setUnits

    # Initial state for Strategy Parameters
    # set solutionType [get_domnode_attribute [$root selectNodes [spdAux::getRoute SLSoluType]] v]
    # if {$solutionType ne "Dynamic"} {
    #     [$root selectNodes [spdAux::getRoute SLStratParams]] setAttribute state hidden
    # }
}


proc Solid::xml::ProcGetSolutionStrategiesSolid { domNode args } {
    set names [list ]
    set pnames [list ]
    set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute SLSoluType]] v]
    set Sols [::Model::GetSolutionStrategies [list "SolutionType" $solutionType] ]
    set ids [list ]
    foreach ss $Sols {
        lappend names [$ss getName]
        lappend pnames [$ss getName]
        lappend pnames [$ss getPublicName] 
    }    
    $domNode setAttribute values [join $names ","]
    set dv [lindex $names 0]
    if {[$domNode getAttribute v] eq ""} {$domNode setAttribute v $dv; spdAux::RequestRefresh}
    if {[$domNode getAttribute v] ni $names} {$domNode setAttribute v $dv; spdAux::RequestRefresh}
    
    return [join $pnames ","]
}

proc Solid::xml::ProcCheckNodalConditionStateSolid {domNode args} {
     # Overwritten the base function to add Solution Type restrictions
     set parts_un SLParts
     if {[spdAux::getRoute $parts_un] ne ""} {
          set conditionId [$domNode @n]
          set elems [$domNode selectNodes "[spdAux::getRoute $parts_un]/group/value\[@n='Element'\]"]
          set elemnames [list ]
          foreach elem $elems { lappend elemnames [$elem @v]}
          set elemnames [lsort -unique $elemnames]
          
          set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute SLSoluType]] v]
          set params [list analysis_type $solutionType]
          if {[::Model::CheckElementsNodalCondition $conditionId $elemnames $params]} {return "normal"} else {return "hidden"}
     } {return "normal"}
}

proc Solid::xml::ProcCheckGeometrySolid {domNode args} {
     set ret "surface"
     if {$::Model::SpatialDimension eq "3D"} {
	    set ret "line,surface,volume"
     } elseif {$::Model::SpatialDimension eq "2D"} {
	    set ret "line,surface"
     } elseif {$::Model::SpatialDimension eq "1D"} {
	    set ret "line"
     }
     return $ret
}

proc Solid::xml::ProcCheckStratParamsState {domNode args} {
    set ret "normal"
    
    set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute SLSoluType]] v]
    set analysisType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute SLAnalysisType]] v]
    
    if {$solutionType ne "Dynamic"} {
        # If Static or Quasi-static
        if {$analysisType eq "Linear"} {
            # If linear -> hide
            set ret "hidden"
        }
    }
    
    return $ret
}


Solid::xml::Init
