namespace eval Structural::xml {
     variable dir
}

proc Structural::xml::Init { } {
     variable dir
     Model::InitVariables dir $Structural::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getMaterials Materials.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses DeprecatedProcesses.xml
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc Structural::xml::getUniqueName {name} {
    return ST$name
}

proc ::Structural::xml::MultiAppEvent {args} {

}

proc Structural::xml::CustomTree { args } {
    spdAux::SetValueOnTreeItem state hidden Results CutPlanes
    spdAux::SetValueOnTreeItem v SingleFile GiDOptions GiDMultiFileFlag
    
    set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'CONTACT'\]"]
    if {$result_node ne "" } {$result_node delete}
}

proc Structural::xml::ProcCheckGeometryStructural {domNode args} {
    set ret "line,surface"
    if {$::Model::SpatialDimension eq "3D"} {
        set ret "line,surface,volume"
    }
    return $ret
}


proc Structural::xml::ProcGetSolutionStrategiesSolid { domNode args } {
    set names ""
    set pnames ""
    set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute STSoluType]] v]
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

proc Structural::xml::ProcCheckNodalConditionStateSolid {domNode args} {
    # Overwritten the base function to add Solution Type restrictions
    set parts_un STParts
    if {[spdAux::getRoute $parts_un] ne ""} {
        set conditionId [$domNode @n]
        set elems [$domNode selectNodes "[spdAux::getRoute $parts_un]/group/value\[@n='Element'\]"]
        set elemnames [list ]
        foreach elem $elems { lappend elemnames [$elem @v]}
        set elemnames [lsort -unique $elemnames]
        
        set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute STSoluType]] v]
        set params [list analysis_type $solutionType]
        if {[::Model::CheckElementsNodalCondition $conditionId $elemnames $params]} {return "normal"} else {return "hidden"}
    } {return "normal"}
}

proc Structural::xml::ProcCheckGeometrySolid {domNode args} {
    set ret "surface"
    if {$::Model::SpatialDimension eq "3D"} {
        set ret "surface,volume"
    }
    return $ret
}


Structural::xml::Init
