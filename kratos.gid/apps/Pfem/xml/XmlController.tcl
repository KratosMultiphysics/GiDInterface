namespace eval Pfem::xml {
    variable dir
    variable bodyNodalCondition
    variable body_UN
    variable Elements
}

proc Pfem::xml::Init { } {
    variable bodyNodalCondition
    set bodyNodalCondition [list ]

    variable body_UN
    set body_UN "PFEM_Bodies"
    
    variable dir
    Model::InitVariables dir $Pfem::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getConstitutiveLaws "../../Pfem/xml/ConstitutiveLaws.xml"
    Model::getConstitutiveLaws "../../Solid/xml/ConstitutiveLaws.xml"
    Model::getProcesses "../../Solid/xml/Processes.xml"
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getNodalConditions "../../Solid/xml/NodalConditions.xml"
    Model::getMaterials Materials.xml
    Model::getConditions "../../Solid/xml/Conditions.xml"
    Model::getSolvers "../../Pfem/xml/Solvers.xml"

    Model::ForgetNodalCondition "CONTACT"
}

proc Pfem::xml::getUniqueName {name} {
    return PFEM_$name
}

proc Pfem::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames SL PFEM_
    }
}

proc Pfem::xml::CustomTree { args } {

    #HOW TO USE THIS FUNCTION:
    #spdAux::SetValueOnTreeItem arg1 arg2 arg3 (arg4)
    #arg1: attribute_to_modify
    #arg2: value_of_the_attribute
    #arg3: unique_name_of_the_node  ('unique name is defined by the attribute un=)
    #arg4 (optional): name_of_the_child_we_want_to_modify  ('name'is defined by the attribute n=)

    #set icon data as default
    foreach node [[customlib::GetBaseRoot] getElementsByTagName value ] { $node setAttribute icon data }

    #problem settings
    foreach node [[customlib::GetBaseRoot] getElementsByTagName container ] { if {[$node hasAttribute solstratname]} {$node setAttribute icon folder } }
    #TODO: (for JG) the previous icons should be changed automatically looking at the strategies.xml


    #intervals
    spdAux::SetValueOnTreeItem icon timeIntervals Intervals
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute Intervals]/blockdata"] {
        $node setAttribute icon select
    }

    #conditions
    #spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEM_NodalConditions VELOCITY
    #spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEM_NodalConditions PRESSURE

    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute PFEM_NodalConditions]/condition" ] {
        $node setAttribute icon select
	    $node setAttribute groups_icon groupCreated
    }

    #loads
    spdAux::SetValueOnTreeItem icon setLoad PFEM_Loads
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute PFEM_Loads]/condition" ] {
        $node setAttribute icon select
	    $node setAttribute groups_icon groupCreated
    }

    #materials
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute PFEM_Materials]/blockdata" ] {
        $node setAttribute icon select
    }

    #solver settings
    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute PFEM_Solution]/container\[@n = 'linear_solver_settings'\]" ] {
        $node setAttribute icon solvers
    }

    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute PFEM_Solution]/container\[@n = 'velocity_linear_solver_settings'\]" ] {
        $node setAttribute icon solvers
    }

    foreach node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute PFEM_Solution]/container\[@n = 'pressure_linear_solver_settings'\]" ] {
        $node setAttribute icon solvers
    }


    #units
    [[customlib::GetBaseRoot] selectNodes "/Kratos_data/blockdata\[@n = 'units'\]"] setAttribute icon setUnits

    #results
    set problemtype [write::getValue PFEM_DomainType]
    if {$problemtype eq "Fluid"} {        
	    spdAux::SetValueOnTreeItem v Yes NodalResults VELOCITY
	    spdAux::SetValueOnTreeItem v Yes NodalResults PRESSURE
	    spdAux::SetValueOnTreeItem v No NodalResults DISPLACEMENT
    }
    spdAux::SetValueOnTreeItem v No NodalResults VELOCITY_REACTION

    foreach result [list INLET SPRING_2D BALLAST_2D AXIAL_TURN_2D AXIAL_VELOCITY_TURN_2D AXIAL_ACCELERATION_TURN_2D SPRING_3D BALLAST_3D AXIAL_TURN_3D AXIAL_VELOCITY_TURN_3D AXIAL_ACCELERATION_TURN_3D] {
        set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = '$result'\]"]
	if { $result_node ne "" } {$result_node delete}
    }

    #restart
    spdAux::SetValueOnTreeItem icon doRestart Restart
    spdAux::SetValueOnTreeItem icon select Restart RestartOptions


}

proc Pfem::xml::ProcCheckNodalConditionStatePFEM {domNode args} {
    set domain_type [write::getValue PFEM_DomainType]
    set fluid_exclusive_conditions [list "VELOCITY" "INLET" "PRESSURE"]
    set current_condition [$domNode @n]
    if {$domain_type eq "Fluid"} {
        if {$current_condition ni $fluid_exclusive_conditions} {              
            return hidden
        }
    } elseif {$domain_type eq "Solid"} {        
        if {$current_condition eq "INLET"} {
            return hidden
        }        
    }
    return [Pfem::xml::ProcCheckNodalConditionStateSolid $domNode {*}$args]
}

proc Pfem::xml::CheckElementOutputState { domNode args } {
    set elemsactive [list ]
    set parts_path [spdAux::getRoute [Pfem::write::GetAttribute parts_un]]
    set xp1 "$parts_path/group/value\[@n='Element'\]"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        lappend elemsactive [get_domnode_attribute $gNode v]
    }
    
    set paramName [$domNode @n]
    return [::Model::CheckElementOutputState $elemsactive $paramName]
}

proc Pfem::xml::ProcGetElements {domNode args} {
    set cumplen [list ]
    set domain_type_un PFEM_DomainType
    set domain_type_route [spdAux::getRoute $domain_type_un]
    set equation_type_un PFEM_EquationType
    set equation_type_route [spdAux::getRoute $equation_type_un]

    if {$domain_type_route ne ""} {
        set domain_type_node [$domNode selectNodes $domain_type_route]
        set domain_type_value [get_domnode_attribute $domain_type_node v]

        set equation_type_node [$domNode selectNodes $equation_type_route]
        set equation_type_value [get_domnode_attribute $equation_type_node v]

        set filter [list ]
        lappend filter "EquationType" $equation_type_value
        if {$domain_type_value ne "Coupled"} {
            lappend filter "ElementType" $domain_type_value
            set cumplen [Model::GetElements $filter]    
            set filter [list "ElementType" "Rigid"]
            lappend filter "EquationType" $equation_type_value
            lappend cumplen {*}[Model::GetElements $filter]
        } else {
            set cumplen [Model::GetElements $filter]
        }        
    }
    set names [list ]
    set pnames [list ]
    foreach elem $cumplen {
        lappend names [$elem getName]
        lappend pnames [$elem getName]
        lappend pnames [$elem getPublicName]
    }
    set diction [join $pnames ","]
    set values [join $names ","]
    $domNode setAttribute values $values
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}

    return $diction
}

proc Pfem::xml::FindMyBlocknode {domNode} {
    set top 10
    set ret ""
    for {set i 0} {$i < $top} {incr i} {
        if {[$domNode nodeName] eq "blockdata"} {
            set ret $domNode
            break
        } else {
            set domNode [$domNode parent]
        }
    }
    return $ret
}

proc Pfem::xml::ProcGetMeshingDomains {domNode args} {
    set basepath [spdAux::getRoute "PFEM_meshing_domains"]
    set values [list ]
    foreach meshing_domain [[$domNode selectNodes $basepath] childNodes] {
        lappend values [get_domnode_attribute $meshing_domain name]
    }
    if {[get_domnode_attribute $domNode v] eq "" || [get_domnode_attribute $domNode v] ni $values} {
        $domNode setAttribute v [lindex $values 0]
    }
    return [join $values ,]
}

proc Pfem::xml::ProcGetContactDomains {domNode args} {
    set basepath [spdAux::getRoute "PFEM_contacts"]
    set values [list "No contact strategy"]
    foreach contact_domain [[$domNode selectNodes $basepath] childNodes] {
        lappend values [get_domnode_attribute $contact_domain name]
    }

    if {[get_domnode_attribute $domNode v] eq "" || [get_domnode_attribute $domNode v] ni $values} {
        $domNode setAttribute v [lindex $values 0]
    }
    return [join $values ,]
}

proc Pfem::xml::ProcCheckNodalConditionStateSolid {domNode args} {
    # Overwritten the base function to add Solution Type restrictions
    set elemsactive [list ]
    set parts_path [spdAux::getRoute [Pfem::write::GetAttribute parts_un]]
    set xp1 "$parts_path/group/value\[@n='Element'\]"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        lappend elemsactive [get_domnode_attribute $gNode v]
    }
    if {$elemsactive eq ""} {return "hidden"}
    set elemsactive [lsort -unique $elemsactive]
    set conditionId [$domNode @n]
    set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute PFEM_SolutionType]] v]
    set params [list analysis_type $solutionType]
    if {[::Model::CheckElementsNodalCondition $conditionId $elemsactive $params]} {return "normal"} else {return "hidden"}
}



proc Pfem::xml::ProcSolutionTypeState {domNode args} {
    set domain_type_un PFEM_DomainType
    set domain_type_route [spdAux::getRoute $domain_type_un]
    set state normal
    if {$domain_type_route ne ""} {
        set domain_type_node [$domNode selectNodes $domain_type_route]
        set domain_type_value [get_domnode_attribute $domain_type_node v]

        if {$domain_type_value ne "Solid"} {
            $domNode setAttribute values Dynamic
            $domNode setAttribute v Dynamic
            set state disabled
        } {
            $domNode setAttribute values "Static,Quasi-static,Dynamic"
            set state normal
        }
    }
    return $state
}

proc Pfem::xml::ProcEquationTypeState {domNode args} {
    set domain_type_un PFEM_DomainType
    set domain_type_route [spdAux::getRoute $domain_type_un]
    set state normal
    if {$domain_type_route ne ""} {
        set domain_type_node [$domNode selectNodes $domain_type_route]
        set domain_type_value [get_domnode_attribute $domain_type_node v]

        if {$domain_type_value ne "Solid"} {
            $domNode setAttribute values Segregated
            $domNode setAttribute v Segregated
            set state disabled
        } elseif {$domain_type_value eq "Solid"} {
            $domNode setAttribute values Monolithic
            $domNode setAttribute v Monolithic
            set state disabled
        } else {
            $domNode setAttribute values "Monolithic,Segregated"
            set state normal
        }
    }
    return $state
}

proc Pfem::xml::ProcStrategyTypeState {domNode args} {
    set domain_type_un PFEM_DomainType
    set domain_type_route [spdAux::getRoute $domain_type_un]
    set state normal
    if {$domain_type_route ne ""} {
        set domain_type_node [$domNode selectNodes $domain_type_route]
        set domain_type_value [get_domnode_attribute $domain_type_node v]

        if {$domain_type_value ne "Solid"} {
            $domNode setAttribute values Implicit
            $domNode setAttribute v Implicit
            set state disabled
        } {
            set solution_type_un PFEM_SolutionType
            set solution_type_route [spdAux::getRoute $solution_type_un]
            set state normal
            if {$solution_type_route ne ""} {
                set solution_type_node [$domNode selectNodes $solution_type_route]
                set solution_type_value [get_domnode_attribute $solution_type_node v]
                if {$solution_type_value eq "Static"} {
                    $domNode setAttribute values Static
                    $domNode setAttribute v Static
                    set state disabled
                } elseif {$solution_type_value eq "Quasi-static"} {
                    $domNode setAttribute values Quasi-static
                    $domNode setAttribute v Quasi-static
                    set state disabled
                }
            }
        }
    }
    return $state
}

proc Pfem::xml::ProcGetBodyTypeValues {domNode args} {
    set domain_type_un PFEM_DomainType
    set domain_type_route [spdAux::getRoute $domain_type_un]
    set values [list Fluid Solid Rigid]
    if {$domain_type_route ne ""} {
        set domain_type_node [$domNode selectNodes $domain_type_route]
        set domain_type_value [get_domnode_attribute $domain_type_node v]

        if {$domain_type_value eq "Fluid"} {
            set values [list Fluid Rigid]
        }
        if {$domain_type_value eq "Coupled"} {
            set values [list Fluid Solid Rigid]
        }
        if {$domain_type_value eq "Solid"} {
            set values [list Solid Rigid]
        }
    }
    if {[get_domnode_attribute $domNode v] eq "" || [get_domnode_attribute $domNode v] ni $values} {
        $domNode setAttribute v [lindex $values 0]
    }
    gid_groups_conds::check_node_dependencies $domNode
    return [join $values ,]
}

proc Pfem::xml::ProcGetSolutionStrategiesPFEM {domNode args} {
    set names ""
    set pnames ""
    set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute PFEM_SolutionType]] v]
    set Sols [::Model::GetSolutionStrategies [list "SolutionType" $solutionType] ]
    set ids [list ]
    set domainType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute PFEM_DomainType]] v]
    set filter [list Solid Pfem]
    if {$domainType eq "Solid"} {set filter "Solid"}
    if {$domainType eq "Fluid"} {set filter "Pfem"}
    if {$domainType eq "Coupled"} {set filter "Pfem"}

    foreach ss $Sols {
        if {[$ss getAttribute "App"] in $filter} {
            lappend names [$ss getName]
            lappend pnames [$ss getName]
            lappend pnames [$ss getPublicName]
        }
    }

    $domNode setAttribute values [join $names ","]
    set dv [lindex $names 0]
    #W "dv $dv"
    if {[$domNode getAttribute v] eq ""} {$domNode setAttribute v $dv; spdAux::RequestRefresh}
    if {[$domNode getAttribute v] ni $names} {$domNode setAttribute v $dv; spdAux::RequestRefresh}

    return [join $pnames ","]
}


proc Pfem::xml::ProcPartsOverWhat {domNode args} {
    set names [list ]
    set blockNode [Pfem::xml::FindMyBlocknode $domNode]
    set BodyType [get_domnode_attribute [$blockNode selectNodes "value\[@n='BodyType'\]"] v]
    if {$BodyType eq "Fluid" || $BodyType eq "Solid"} {
        if {$::Model::SpatialDimension eq "3D"} {
            return "volume"
        } else {
            return "surface"
        }
    } elseif { $BodyType eq "Rigid"} {
        if {$::Model::SpatialDimension eq "3D"} {
            return "surface,volume"
        } else {
            return "line,surface"
        }
    } else {
        return "point,line,surface,volume"
    }
}

proc Pfem::xml::ProcActiveIfAnyPartState {domNode args} {
    set parts ""
    set parts_un "PFEM_Parts"
    catch {
        set parts [$domNode selectNodes "[spdAux::getRoute $parts_un]/group"]
    }
    if {$parts ne ""} {return "normal"} else {return "hidden"}
}

proc Pfem::xml::ProcGetBodiesValues {domNode args} {
    customlib::UpdateDocument
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
    set bodies [list ]
    foreach body_node [$root selectNodes $xp1] {
        lappend bodies [$body_node @name]
    }
    if {[get_domnode_attribute $domNode v] ni $bodies} {$domNode setAttribute v [lindex $bodies 0]}
    return [join $bodies ","]
}

proc Pfem::xml::ProcGetRigidBodiesValues {domNode args} {
    customlib::UpdateDocument
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
    set bodies [list ]
    foreach body_node [$root selectNodes $xp1] {
        foreach subnode [$body_node childNodes] {
            if { [$subnode getAttribute n] eq "BodyType" } {
                if { [$subnode getAttribute v] eq "Rigid" } {
                    lappend bodies [$body_node @name]
                    break
                }
            }
        }
    }
    if {[get_domnode_attribute $domNode v] ni $bodies} {$domNode setAttribute v [lindex $bodies 0]}
    return [join $bodies ","]
}

proc Pfem::xml::StartSortingWindow { } {
    package require SorterWindow
    set data_dict [dict create]
    set conds [Pfem::xml::GetConditionsAndGroups PFEM_Loads]
    set nodalconds [Pfem::xml::GetConditionsAndGroups PFEM_NodalConditions]
    if {[dict size $conds]} {dict set data_dict Loads $conds}
    if {[dict size $nodalconds]} {dict set data_dict Constraints $nodalconds}
    SorterWindow::SorterWindow $data_dict "Pfem::xml::GetDataFromSortingWindow"
}
proc Pfem::xml::GetDataFromSortingWindow { data_dict } {
    W $data_dict
}
proc Pfem::xml::GetConditionsAndGroups { cnd_UN } {
    customlib::UpdateDocument
    set data_dict [dict create]
    set root [customlib::GetBaseRoot]
    foreach {cond_type cond_item cond_item_name} {container blockdata name condition group n} {
        set xp1 "[spdAux::getRoute $cnd_UN]/$cond_type"
        foreach cnd_cont_node [$root selectNodes $xp1] {
            set cnd_cont_name [$cnd_cont_node @n]
            set xp2 "./$cond_item"
            foreach cnd_node [$cnd_cont_node selectNodes $xp2] {
                set cnd_name [$cnd_node getAttribute $cond_item_name]
                set num 0
                if {[$cnd_node hasAttribute order]} {set num [$cnd_node @order]}
                dict set data_dict $cnd_cont_name $cnd_name $num
            }
        }
    }
    return $data_dict
}

proc Pfem::xml::getBodyNodalConditionById { id } {
    variable bodyNodalCondition

    foreach cnd $bodyNodalCondition {
        if {[$cnd getName] eq $id} {
            return $cnd
        }
    }
    return ""
}
proc Pfem::xml::getBodyNodalConditions { filename } {
    variable bodyNodalCondition
    dom parse [tDOM::xmlReadFile [file join $Pfem::dir xml $filename]] doc

    set NCList [$doc getElementsByTagName NodalConditionItem]
    foreach Node $NCList {
        lappend bodyNodalCondition [::Model::ParseNodalConditionsNode $Node]
    }
}
proc Pfem::xml::injectBodyNodalConditions { basenode args} {
    variable bodyNodalCondition
    Pfem::xml::_injectCondsToTree $basenode $bodyNodalCondition nodal
    $basenode delete
}


proc Pfem::xml::_injectCondsToTree {basenode cond_list {cond_type "normal"} } {
    set conds [$basenode parent]
    set AppUsesIntervals [::Pfem::GetAttribute UseIntervals]
    if {$AppUsesIntervals eq ""} {set AppUsesIntervals 0}

    foreach cnd $cond_list {
        set n [$cnd getName]
        set pn [$cnd getPublicName]
        set help [$cnd getHelp]
        set units [$cnd getAttribute "units"]
        set um [$cnd getAttribute "unit_magnitude"]
        set process [::Model::GetProcess [$cnd getProcessName]]
        set check [$process getAttribute "check"]
        if {$check eq ""} {set check "UpdateTree"}
        set state "ConditionState"
        if {$cond_type eq "nodal"} {
            set state [$cnd getAttribute state]
            if {$state eq ""} {set state "CheckNodalConditionState"}
        }
        set contNode [gid_groups_conds::addF [$conds toXPath] container [list n $n pn ${pn}s help $help]]
        set blockNode [gid_groups_conds::addF [$contNode toXPath] blockdata [list n $n pn $pn help $help icon shells16 update_proc $check name "$pn 1" sequence 1 editable_name unique sequence_type non_void_disabled]]
        set block_path [$blockNode toXPath]
        set inputs [$process getInputs]
        foreach {inName in} $inputs {
            set pn [$in getPublicName]
            set type [$in getType]
            set v [$in getDv]
            set help [$in getHelp]
            set state [$in getAttribute "state"]
            if {$state eq ""} {set state "normal"}
            foreach key [$cnd getDefaults $inName] {
                set $key [$cnd getDefault $inName $key]
            }

            set has_units [$in getAttribute "has_units"]
            if {$has_units ne ""} { set has_units "units='$units'  unit_magnitude='$um'"}
            if {$type eq "vector"} {
                set vector_type [$in getAttribute "vectorType"]
                lassign [split $v ","] v1 v2 v3
                if {$vector_type eq "bool"} {
                    gid_groups_conds::addF $block_path value [list n ${inName}X wn [concat $n "_X"] pn "X ${pn}" values "1,0"]
                    gid_groups_conds::addF $block_path value [list n ${inName}Y wn [concat $n "_Y"] pn "Y ${pn}" values "1,0"]
                    gid_groups_conds::addF $block_path value [list n ${inName}Z wn [concat $n "_Z"] pn "Z ${pn}" values "1,0" state {[CheckDimension 3D]}]
                } {
                    foreach i [list "X" "Y" "Z"] {
                        set nodev "../value\[@n='${inName}$i'\]"
                        set zstate ""
                        if {$i eq "Z"} { set zstate "state {\[CheckDimension 3D\]}"}
                        if {[$in getAttribute "enabled"] in [list "1" "0"]} {
                            set val [expr [$in getAttribute "enabled"] ? "Yes" : "No"]
                            if {$i eq "Z"} { set val "No" }
                            set valNode [gid_groups_conds::addF $block_path value [list n Enabled_$i pn "$i component" v No values "Yes,No" help "Enables the $i ${inName}" actualize_tree 1 {*}$zstate]]

                            gid_groups_conds::addF [$valNode toXPath] dependencies [list value No node $nodev att1 state v1 hidden]
                            gid_groups_conds::addF [$valNode toXPath] dependencies [list value Yes node $nodev att1 state v1 normal]
                            if {[$in getAttribute "function"] eq "1"} {
                                set fname "${i}function_$inName"
                                set nodef "../value\[@n='$fname'\]"
                                set nodeb "../value\[@n='ByFunction$i'\]"
                                gid_groups_conds::addF [$valNode toXPath] dependencies [list value No node $nodef att1 state v1 hidden]
                                gid_groups_conds::addF [$valNode toXPath] dependencies [list value No node $nodeb att1 state v1 hidden]
                                gid_groups_conds::addF [$valNode toXPath] dependencies [list value Yes node $nodeb att1 state v1 normal att2 v v2 No]
                            }
                        }
                        if {[$in getAttribute "function"] eq "1"} {
                            set fname "${i}function_$inName"
                            set valNode [gid_groups_conds::addF $block_path value [list n ByFunction$i pn "by function -> f(x,y,z,t)" v No values "Yes,No" actualize_tree 1 state hidden]]
                            gid_groups_conds::addF [$valNode toXPath] dependencies [list value No node $nodev att1 state v1 normal]
                            gid_groups_conds::addF [$valNode toXPath] dependencies [list value Yes node $nodev att1 state v1 hidden]
                            gid_groups_conds::addF [$valNode toXPath] dependencies [list value No node $nodef att1 state v1 hidden]
                            gid_groups_conds::addF [$valNode toXPath] dependencies [list value Yes node $nodef att1 state v1 normal]
                            gid_groups_conds::addF $block_path value [list n $fname pn "$i function" state hidden]
                        }
                        gid_groups_conds::addF $block_path value [list n ${inName}$i wn [concat $n "_$i"] pn "$i ${pn}" v $v1 state hidden]
                    }
                }

            } elseif { $type eq "combo" } {
                set values [join [$in getValues] ","]
                gid_groups_conds::addF $block_path value [list n $inName pn $pn v $v1 values $values state $state help $help]
            } elseif { $type eq "bool" } {
                set values "1,0"
                gid_groups_conds::addF $block_path value [list n $inName pn $pn v $v1 values $values state $state help $help]
            } elseif { $type eq "file" || $type eq "tablefile" } {
                gid_groups_conds::addF $block_path value [list n $inName pn $pn v $v1 values {[GetFilesValues]} update_proc AddFile type $type state $state help $help]
            } else {
                if {[$in getAttribute "function"] eq "1"} {
                    set fname "function_$inName"
                    set nodev "../value\[@n='$inName'\]"
                    set nodef "../value\[@n='$fname'\]"

                    set valNode [gid_groups_conds::addF $block_path value [list n ByFunction pn "by function -> f(x,y,z,t)" v No values "Yes,No" actualize_tree 1]]
                    gid_groups_conds::addF [$valNode toXPath] dependencies [list value No node $nodev att1 state v1 normal]
                    gid_groups_conds::addF [$valNode toXPath] dependencies [list value Yes node $nodev att1 state v1 hidden]
                    gid_groups_conds::addF [$valNode toXPath] dependencies [list value No node $nodef att1 state v1 hidden]
                    gid_groups_conds::addF [$valNode toXPath] dependencies [list value Yes node $nodef att1 state v1 normal]
                    gid_groups_conds::addF $block_path value [list n $fname pn "Function"]
                }
                append node "<value n='$inName' pn='$pn' v='$v'  units='$units'  unit_magnitude='$um'  help='$help'/>"
                gid_groups_conds::addF $block_path value [list n $inName pn $pn v $v units $units unit_magnitude $um help $help]
            }
        }

        set CondUsesIntervals [$cnd getAttribute "Interval"]
        if {$AppUsesIntervals && $CondUsesIntervals ne "False"} {
            gid_groups_conds::addF $block_path value [list n Interval pn "Time interval" v $CondUsesIntervals values {[getIntervals]} help $help]
        }
        gid_groups_conds::addF $block_path value [list n Body pn Body v - values {[GetRigidBodiesValues]} help $help]
    }
}


proc Pfem::xml::GetPartsGroups { } {
    set parts [list ]
    set parts_path [spdAux::getRoute "PFEM_Parts"]
    # set xp1 "$parts_path/group/value\[@n='Element'\]"
    set xp1 "$parts_path/group"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        lappend parts [get_domnode_attribute $gNode n]
    }
    return $parts
}

proc Pfem::xml::GetBodiesInformation { } {
    variable body_UN
    set bodies [list ]
    set bodies_path [spdAux::getRoute $body_UN]
    foreach body_node [[customlib::GetBaseRoot] selectNodes "$bodies_path/blockdata"] {
        set body [dict create]
        dict set body name [get_domnode_attribute $body_node name]
        dict set body type [get_domnode_attribute [$body_node selectNodes "./value\[@n='BodyType'\]"] v]
        dict set body mesh [get_domnode_attribute [$body_node selectNodes "./value\[@n='MeshingStrategy'\]"] v]
        dict set body cont [get_domnode_attribute [$body_node selectNodes "./value\[@n='ContactStrategy'\]"] v]
        set parts [list ]
        foreach gNode [$body_node selectNodes "./container\[@n='Groups'\]/blockdata\[@n='Group'\]"] {
            lappend parts [$gNode @name]
        }
        dict set body parts $parts
        lappend bodies $body
    }
    
    return $bodies
}

proc Pfem::xml::SaveBodiesInformation {data} {
    W "Unimplemented method Pfem::xml::SaveBodiesInformation"
}

proc Pfem::xml::AddNewBodyRaw { } {
    variable body_UN
    set bodies_path [spdAux::getRoute $body_UN]

    set bodies_name_list [list ]
    foreach body [Pfem::xml::GetBodiesInformation] {
        lappend bodies_name_list [dict get $body name]
    }
    set i 0
    while {"Body$i" in $bodies_name_list} {incr i}
    set body_name "Body$i"

    set str "<blockdata n='Body' name='$body_name' icon='select' editable='false' sequence='1' editable_name='unique' open_window='0' state='disabled'>"
    append str "<value n='BodyType' pn='Body type' icon='data' v='' values='\[GetBodyTypeValues\]' state='disabled'/>"
    append str "<value n='ContactStrategy' pn='Contacting' icon='data' v='No' values='Yes,No' state='\[getStateFromXPathValue {string(../value\[@n=BodyType\]/@v)} Solid\]'/>"
    append str "<value n='MeshingStrategy' pn='Meshing' icon='data' v='' values='\[GetMeshingDomains\]' state='\[getStateFromXPathValue {string(../value\[@n=BodyType\]/@v)} Fluid,Solid\]'/>"
    append str "<container n='Groups' pn='Groups' state='disabled' icon='parts'>"
    # append str "<blockdata n='Group' name='Auto Group 2' state='disabled' icon='groupCreated' />"
    append str "</container>"
    append str "</blockdata>"
    
    [[customlib::GetBaseRoot] selectNodes $bodies_path] appendXML $str

    return $body_name
}

proc Pfem::xml::DeleteBody {body_name} {
    variable body_UN
    set bodies_path [spdAux::getRoute $body_UN]
    [[customlib::GetBaseRoot] selectNodes "$bodies_path/blockdata\[@name = '$body_name'\]"] delete
}

proc Pfem::xml::AddPartToBody {body_name part_name} {
    variable body_UN
    set bodies_path [spdAux::getRoute $body_UN]
    # TODO: Check if part exists in parts availables for body
    foreach body [Pfem::xml::GetBodiesInformation] {
        if {[dict get $body name] eq $body_name} {
            if {$part_name ni [dict get $body parts]} {
                set str "<blockdata n='Group' name='${part_name}' state='disabled' icon='groupCreated' />"
                [[customlib::GetBaseRoot] selectNodes "$bodies_path/blockdata\[@name = '$body_name'\]/container\[@n = 'Groups'\]"] appendXML $str
            }
        }
    }
}

proc Pfem::xml::DeletePartInBody {body_name part_name} {
    variable body_UN
    set bodies_path [spdAux::getRoute $body_UN]
    [[customlib::GetBaseRoot] selectNodes "$bodies_path/blockdata\[@name = '$body_name'\]/container\[@n = 'Groups'\]/blockdata\[@name = '$part_name'\]"] delete
}

proc Pfem::xml::UpdateBody {body_name_old body_name body_type body_mesh body_cont} {
    
    variable body_UN
    set bodies_path [spdAux::getRoute $body_UN]
    # TODO: check if $body_name_old exists in parent
    set node [[customlib::GetBaseRoot] selectNodes "$bodies_path/blockdata\[@name = '$body_name_old'\]"]
    $node setAttribute name $body_name
    [$node selectNodes "./value\[@n = 'BodyType'\]"] setAttribute v $body_type
    [$node selectNodes "./value\[@n = 'MeshingStrategy'\]"] setAttribute v $body_mesh
    [$node selectNodes "./value\[@n = 'ContactStrategy'\]"] setAttribute v $body_cont
}


# TODO: Event After rename group for bodies associetion. Wait Event register system

# TODO: Event After delete group for bodies associetion. Wait Event register system

Pfem::xml::Init
