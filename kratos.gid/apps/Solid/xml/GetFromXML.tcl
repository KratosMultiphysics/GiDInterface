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
    
}

proc Solid::xml::getUniqueName {name} {
    return SL$name
}

proc Solid::xml::CustomTree { args } {
    # Hide Results Cut plane
    spdAux::SetValueOnTreeItem state hidden Results CutPlanes
    spdAux::SetValueOnTreeItem v MultipleFiles GiDOptions GiDMultiFileFlag

    #intervals
    spdAux::SetValueOnTreeItem icon timeIntervals Intervals
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute Intervals]/blockdata"] {
        $node setAttribute icon select
    }

    #conditions
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute SLNodalConditions]/condition" ] { 
        $node setAttribute icon select
	$node setAttribute groups_icon groupCreated
    }

    #loads
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute SLLoads]/condition" ] { 
        $node setAttribute icon select
	$node setAttribute groups_icon groupCreated
    }
    
    #materials
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute SLMaterials]/Material" ] { 
        $node setAttribute icon select
    }
    
    #units
    [[customlib::GetBaseRoot] selectNodes "/Kratos_data/blockdata\[@n = 'units'\]"] setAttribute icon setUnits
    
}

Solid::xml::Init

proc Solid::xml::ProcGetSolutionStrategiesSolid { domNode args } {
     set names ""
     set pnames ""
     set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute SLSoluType]] v]
     set Sols [::Model::GetSolutionStrategies [list "SolutionType" $solutionType] ]
     set ids [list ]
     foreach ss $Sols {
          lappend ids [$ss getName]
          append names [$ss getName] ","
          append pnames [$ss getName] "," [$ss getPublicName] ","
     }
     set names [string range $names 0 end-1]
     set pnames [string range $pnames 0 end-1]
     
     $domNode setAttribute values $names
     set dv [lindex $ids 0]
     if {[$domNode getAttribute v] eq ""} {$domNode setAttribute v $dv}
     if {[$domNode getAttribute v] ni $ids} {$domNode setAttribute v $dv}
     #spdAux::RequestRefresh
     return $pnames
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

proc Solid::xml::injectMaterials { basenode args } {
    set base [$basenode parent]
    set materials [Model::GetMaterials {*}$args]
    foreach mat $materials {
        set matname [$mat getName]
        set mathelp [$mat getAttribute help]
        set inputs [$mat getInputs]
        set matnode "<blockdata n='material' name='$matname' sequence='1' editable_name='unique' icon='select' help='Material definition'>"
        foreach {inName in} $inputs {
            set node [spdAux::GetParameterValueString $in [list base $mat state [$in getAttribute state]]]
            append matnode $node
        }
        append matnode "</blockdata> \n"
        $base appendXML $matnode
    }
    $basenode delete
} 


proc Solid::xml::injectSolvers {basenode args} {
    
    # Get all solvers params
    set paramspuestos [list ]
    set paramsnodes ""
    set params [::Model::GetAllSolversParams]
    foreach {parname par} $params {
        if {$parname ni $paramspuestos} {
            lappend paramspuestos $parname
            set pn [$par getPublicName]
            set type [$par getType]
            set dv [$par getDv]
            if {$dv ni [list "1" "0"]} {
                if {[write::isBooleanFalse $dv]} {set dv No}
                if {[write::isBooleanTrue $dv]} {set dv Yes}  
            }
            append paramsnodes "<value n='$parname' pn='$pn' state='\[SolverParamState\]' v='$dv' "
            if {$type eq "bool"} {
                append paramsnodes " values='Yes,No' "
            }
            if {$type eq "combo"} {
                append paramsnodes " values='\[GetSolverParameterValues\]' "
                append paramsnodes " dict='\[GetSolverParameterDict\]' "
            }
            
            append paramsnodes "/>"
        }
    }
    set contnode [$basenode parent]
    
    # Get All SolversEntry
    set ses [list ]
    foreach st [::Model::GetSolutionStrategies {*}$args] {
        lappend ses $st [$st getSolversEntries]
    }
    
    # One container per solverEntry 
    foreach {st ss} $ses {
        foreach se $ss {
            set stn [$st getName]
            set n [$se getName]
            set pn [$se getPublicName]
            set help [$se getHelp]
            set appid [spdAux::GetAppIdFromNode [$basenode parent]]
            set un [apps::getAppUniqueName $appid "$stn$n"]
            set container "<container help='$help' n='$n' pn='$pn' un='$un' state='\[SolverEntryState\]' solstratname='$stn' open_window='0' icon='linear_solver'>"
            set defsolver [lindex [$se getDefaultSolvers] 0]
            append container "<value n='Solver' pn='Solver' v='$defsolver' values='\[GetSolversValues\]' dict='\[GetSolvers\]' actualize='1' update_proc='UpdateTree'/>"
            #append container "<dependencies node='../value' actualize='1'/>"
            #append container "</value>"
            append container $paramsnodes
            append container "</container>"
            $contnode appendXML $container
        }
    }
    $basenode delete
}
