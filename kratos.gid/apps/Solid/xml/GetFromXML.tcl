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

    #results
    spdAux::SetValueOnTreeItem icon seeResults Results 
    spdAux::SetValueOnTreeItem icon select Results OnElement 
    spdAux::SetValueOnTreeItem icon select Results OnNodes 
    spdAux::SetValueOnTreeItem icon select Results GiDOptions 

    spdAux::SetValueOnTreeItem icon boundaryConditions SLNodalConditions
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute SLNodalConditions]/condition" ] { 
        $node setAttribute icon folder
    }
    
    #loads
    spdAux::SetValueOnTreeItem icon setLoad SLLoads
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute SLLoads]/condition" ] { 
        $node setAttribute icon folder
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

 
