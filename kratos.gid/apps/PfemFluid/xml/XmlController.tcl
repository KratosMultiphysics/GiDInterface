namespace eval ::PfemFluid::xml {
    namespace path ::PfemFluid
    Kratos::AddNamespace [namespace current]

    variable bodyNodalCondition
}

proc PfemFluid::xml::Init { } {
    variable bodyNodalCondition

    set bodyNodalCondition [list ]

    Model::InitVariables dir $::PfemFluid::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getSolvers Solvers.xml

    Model::ForgetNodalCondition "CONTACT"
}

proc PfemFluid::xml::getUniqueName {name} {
    return PFEMFLUID_$name
}

proc PfemFluid::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames SL PFEMFLUID_
    }
}

proc PfemFluid::xml::CustomTree { args } {
    #HOW TO USE THIS FUNCTION:
    #spdAux::SetValueOnTreeItem arg1 arg2 arg3 (arg4)
    #arg1: attribute_to_modify
    #arg2: value_of_the_attribute
    #arg3: unique_name_of_the_node  ('unique name is defined by the attribute un=)
    #arg4 (optional): name_of_the_child_we_want_to_modify  ('name'is defined by the attribute n=)

    set app_root [customlib::GetBaseRoot]
    foreach node [$app_root getElementsByTagName container ] { if {[$node hasAttribute prefix] && [$node getAttribute prefix] eq "PFEMFLUID_"} {set app_root $node; break } }

    #set icon data as default
    foreach node [$app_root getElementsByTagName value ] { $node setAttribute icon data }

    #problem settings
    foreach node [$app_root getElementsByTagName container ] { if {[$node hasAttribute solstratname]} {$node setAttribute icon folder } }
    #TODO: (for JG) the previous icons should be changed automatically looking at the strategies.xml

    #intervals
    spdAux::SetValueOnTreeItem icon sheets Intervals
    foreach node [[$app_root parent] selectNodes "[spdAux::getRoute Intervals]/blockdata"] {
        $node setAttribute icon select
    }

    #conditions
    spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEMFLUID_NodalConditions VELOCITY
    spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEMFLUID_NodalConditions PRESSURE

    foreach node [[$app_root parent] selectNodes "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition" ] {
        $node setAttribute icon select
	    $node setAttribute groups_icon groupCreated
    }

    #loads
    if {[spdAux::getRoute PFEMFLUID_Loads] ne ""} {
        spdAux::SetValueOnTreeItem icon setLoad PFEMFLUID_Loads
        foreach node [[$app_root parent] selectNodes "[spdAux::getRoute PFEMFLUID_Loads]/condition" ] {
            $node setAttribute icon select
            $node setAttribute groups_icon groupCreated
        }
    }

    #materials
    foreach node [[$app_root parent] selectNodes "[spdAux::getRoute PFEMFLUID_Materials]/blockdata" ] {
        $node setAttribute icon select
    }

    #solver settings
    foreach node [[$app_root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'linear_solver_settings'\]" ] {
        $node setAttribute icon select
    }

    foreach node [[$app_root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'velocity_linear_solver_settings'\]" ] {
        $node setAttribute icon select
    }

    foreach node [[$app_root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'pressure_linear_solver_settings'\]" ] {
        $node setAttribute icon select
    }


    #units
    [[$app_root parent] selectNodes "/Kratos_data/blockdata\[@n = 'units'\]"] setAttribute icon setUnits

    #results
    spdAux::SetValueOnTreeItem v Yes NodalResults VELOCITY
    spdAux::SetValueOnTreeItem v Yes NodalResults PRESSURE
    spdAux::SetValueOnTreeItem v No NodalResults DISPLACEMENT
    spdAux::SetValueOnTreeItem v No NodalResults VELOCITY_REACTION
    spdAux::SetValueOnTreeItem v No NodalResults DISPLACEMENT_REACTION

    set lagrangian_rotation_process_result_node [[$app_root parent] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'ANGULAR_VELOCITY'\]"]
    if {$lagrangian_rotation_process_result_node ne "" } {$lagrangian_rotation_process_result_node delete}

    set inlet_result_node [[$app_root parent] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'INLET'\]"]
    if {$inlet_result_node ne "" } {$inlet_result_node delete}

    #restart
    # spdAux::SetValueOnTreeItem icon doRestart Restart
    # spdAux::SetValueOnTreeItem icon select Restart RestartOptions

    # 3D gravity
    if {$Model::SpatialDimension eq "3D"} {
        catch {
            spdAux::SetValueOnTreeItem v -9.81 PFEMFLUID_Gravity Cy
            spdAux::SetValueOnTreeItem v 0.0 PFEMFLUID_Gravity Cz
        }
    }

}

proc PfemFluid::xml::ProcCheckNodalConditionStatePFEM {domNode args} {
    set domain_type [write::getValue PFEMFLUID_DomainType]
    set fluid_exclusive_conditions [list "VELOCITY" "INLET" "ANGULAR_VELOCITY" "PRESSURE"]
    set current_condition [$domNode @n]
    if {$domain_type eq "Fluids" && $current_condition ni $fluid_exclusive_conditions} {
        return hidden
    }
    return normal
}

proc PfemFluid::xml::CheckElementOutputState { domNode args } {
    set elemsactive [list ]
    foreach parts_un [PfemFluid::write::GetPartsUN] {
        set parts_path [spdAux::getRoute $parts_un]
        set xp1 "$parts_path/group/value\[@n='Element'\]"
        foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
            lappend elemsactive [get_domnode_attribute $gNode v]
        }
    }
    set paramName [$domNode @n]
    return [::Model::CheckElementOutputState $elemsactive $paramName]
}

proc PfemFluid::xml::ProcGetElementsDict {domNode args} {
    set names [list ]
    set blockNode [PfemFluid::xml::FindMyBlocknode $domNode]
    set BodyType [get_domnode_attribute [$blockNode selectNodes "value\[@n='BodyType'\]"] v]
    set argums [list ElementType $BodyType]
    set elems [PfemFluid::xml::GetElements $domNode $args]
    set pnames ""
    foreach elem $elems {
        if {[$elem cumple $argums]} {
            lappend pnames [$elem getName]
            lappend pnames [$elem getPublicName]
        }
    }
    set diction [join $pnames ","]
    if {$diction eq ""} {W "No available elements - Check Solution strategy & scheme - Check Kratos mode (developer)"}
    return $diction
}
proc PfemFluid::xml::ProcGetElementsValues {domNode args} {
    set names [list ]
    set blockNode [PfemFluid::xml::FindMyBlocknode $domNode]
    set BodyType [get_domnode_attribute [$blockNode selectNodes "value\[@n='BodyType'\]"] v]

    set argums [list ElementType $BodyType]
    set elems [PfemFluid::xml::GetElements $domNode $args]
    foreach elem $elems {
        if {[$elem cumple $argums]} {
            lappend names [$elem getName]
        }
    }
    set values [join $names ","]

    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]}

    return $values
}

proc PfemFluid::xml::ProcGetConstitutiveLaws {domNode args} {
    set Elementname [$domNode selectNodes {string(../value[@n='Element']/@v)}]
    set Claws [::Model::GetAvailableConstitutiveLaws $Elementname]

    if {[llength $Claws] == 0} {
        set names [list "None"]
    } {
        set names [list ]
        foreach cl $Claws {
		    lappend names [$cl getName]
        }
    }

    set values [join $names ","]

    if {[get_domnode_attribute $domNode v] eq "" || [get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}

    return $values
}

proc PfemFluid::xml::GetElements {domNode args} {

    set nodeApp [spdAux::GetAppIdFromNode $domNode]
    set sol_stratUN [apps::getAppUniqueName $nodeApp SolStrat]
    set schemeUN [apps::getAppUniqueName $nodeApp Scheme]

    get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $sol_stratUN]] dict
    get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $schemeUN]] dict

    set solStratName [::write::getValue $sol_stratUN]
    set schemeName [write::getValue $schemeUN]
    set elems [::Model::GetAvailableElements $solStratName $schemeName]

    return $elems
}

proc PfemFluid::xml::FindMyBlocknode {domNode} {
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

proc PfemFluid::xml::ProcGetMeshingDomains {domNode args} {
    set basepath [spdAux::getRoute "PFEMFLUID_meshing_domains"]
    set values [list ]
    foreach meshing_domain [[$domNode selectNodes $basepath] childNodes] {
        lappend values [get_domnode_attribute $meshing_domain name]
    }
    if {[get_domnode_attribute $domNode v] eq ""} {
        $domNode setAttribute v [lindex $values 0]
    }
    return [join $values ,]
}

proc PfemFluid::xml::ProcGetContactDomains {domNode args} {
    set basepath [spdAux::getRoute "PFEMFLUID_contacts"]
    set values [list "No contact strategy"]
    foreach contact_domain [[$domNode selectNodes $basepath] childNodes] {
        lappend values [get_domnode_attribute $contact_domain name]
    }

    if {[get_domnode_attribute $domNode v] eq "" || [get_domnode_attribute $domNode v] ni $values} {
        $domNode setAttribute v [lindex $values 0]
    }
    return [join $values ,]
}

proc PfemFluid::xml::ProcSolutionTypeState {domNode args} {
    set domain_type_un PFEMFLUID_DomainType
    set domain_type_route [spdAux::getRoute $domain_type_un]
    set state normal
    if {$domain_type_route ne ""} {
        set domain_type_node [$domNode selectNodes $domain_type_route]
        set domain_type_value [get_domnode_attribute $domain_type_node v]

        $domNode setAttribute values Dynamic
        $domNode setAttribute v Dynamic
        set state disabled

    }
    return $state
}

proc PfemFluid::xml::ProcGetBodyTypeValues {domNode args} {
    set domain_type_un PFEMFLUID_DomainType
    set domain_type_route [spdAux::getRoute $domain_type_un]
    set values "Fluid,Solid,Rigid"
    if {$domain_type_route ne ""} {
        set domain_type_node [$domNode selectNodes $domain_type_route]
        set domain_type_value [get_domnode_attribute $domain_type_node v]

        if {$domain_type_value eq "Fluids"} {
            set values "Fluid,Rigid"
        }
        if {$domain_type_value eq "FSI"} {
            set values "Fluid,Solid,Rigid,Interface"
        }
        if {$domain_type_value eq "Solids"} {
            set values "Solid,Rigid"
        }
    }
    return $values
}

proc PfemFluid::xml::ProcGetSolutionStrategiesPFEM {domNode args} {
    set names ""
    set pnames ""
    set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute PFEMFLUID_SolutionType]] v]
    set Sols [::Model::GetSolutionStrategies [list "SolutionType" $solutionType] ]
    set ids [list ]
    set domainType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute PFEMFLUID_DomainType]] v]
    set filter [list Solid Pfem]
    if {$domainType eq "Solids"} {set filter "Solid"}
    if {$domainType eq "Fluids"} {set filter "Pfem"}
    if {$domainType eq "FSI"} {set filter "Pfem"}

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

proc PfemFluid::xml::ProcGetPartUN {domNode args} {
    customlib::UpdateDocument
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata/condition"
    set i 0
    foreach part_node [$root selectNodes $xp1] {
        if {$part_node eq $domNode} {
            break
        } {incr i}
    }
    set un "PFEMFLUID_Part$i"
    spdAux::setRoute $un [$part_node toXPath]
    #$domNode setAttribute curr_un $un
    return $un
}

proc PfemFluid::xml::ProcPartsOverWhat {domNode args} {
    set names [list ]
    set blockNode [PfemFluid::xml::FindMyBlocknode $domNode]
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
    } elseif { $BodyType eq "Interface"} {
        if {$::Model::SpatialDimension eq "3D"} {
            return "surface"
        } else {
            return "line"
        }
    } else {
        return "point,line,surface,volume"
    }
}

proc PfemFluid::xml::ProcActiveIfAnyPartState {domNode args} {
    set parts ""
    set parts_un [PfemFluid::xml::ProcGetPartUN $domNode $args]
    catch {
        set parts [$domNode selectNodes "[spdAux::getRoute $parts_un]/group"]
    }
    if {$parts ne ""} {return "normal"} else {return "hidden"}
}

proc PfemFluid::xml::ProcGetBodiesValues {domNode args} {
    customlib::UpdateDocument
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata"
    set bodies [list ]
    foreach body_node [$root selectNodes $xp1] {
        lappend bodies [$body_node @name]
    }
    if {[get_domnode_attribute $domNode v] ni $bodies} {$domNode setAttribute v [lindex $bodies 0]}
    return [join $bodies ","]
}

proc PfemFluid::xml::ProcGetRigidBodiesValues {domNode args} {
    customlib::UpdateDocument
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata"
    set bodies [list ]
    foreach body_node [$root selectNodes $xp1] {
        foreach subnode [$body_node childNodes] {
            if { [$subnode getAttribute n] eq "BodyType" } {
                if { [$subnode getAttribute v] eq "Rigid"  || [$subnode getAttribute v] eq "Interface"} {
                    lappend bodies [$body_node @name]
                    break
                }
            }
        }
    }
    if {[get_domnode_attribute $domNode v] ni $bodies} {$domNode setAttribute v [lindex $bodies 0]}
    return [join $bodies ","]
}

proc PfemFluid::xml::StartSortingWindow { } {
    package require SorterWindow
    set data_dict [dict create]
    set conds [PfemFluid::xml::GetConditionsAndGroups PFEMFLUID_Loads]
    set nodalconds [PfemFluid::xml::GetConditionsAndGroups PFEMFLUID_NodalConditions]
    if {[dict size $conds]} {dict set data_dict Loads $conds}
    if {[dict size $nodalconds]} {dict set data_dict Constraints $nodalconds}
    SorterWindow::SorterWindow $data_dict "PfemFluid::xml::GetDataFromSortingWindow"
}
proc PfemFluid::xml::GetDataFromSortingWindow { data_dict } {
    W $data_dict
}
proc PfemFluid::xml::GetConditionsAndGroups { cnd_UN } {
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

proc PfemFluid::xml::getBodyNodalConditionById { id } {
    variable bodyNodalCondition

    foreach cnd $bodyNodalCondition {
        if {[$cnd getName] eq $id} {
            return $cnd
        }
    }
    return ""
}
proc PfemFluid::xml::getBodyNodalConditions { filename } {
    variable bodyNodalCondition
    dom parse [tDOM::xmlReadFile [file join $PfemFluid::dir xml $filename]] doc

    set NCList [$doc getElementsByTagName NodalConditionItem]
    foreach Node $NCList {
        lappend bodyNodalCondition [::Model::ParseNodalConditionsNode $Node]
    }
}
proc PfemFluid::xml::injectBodyNodalConditions { basenode args} {
    variable bodyNodalCondition
    PfemFluid::xml::_injectCondsToTree $basenode $bodyNodalCondition nodal
    $basenode delete
}


proc PfemFluid::xml::_injectCondsToTree {basenode cond_list {cond_type "normal"} } {
    set conds [$basenode parent]
    set AppUsesIntervals [::PfemFluid::GetAttribute UseIntervals]
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

proc PfemFluid::xml::ProcCheckStateBoundingBox3Dimension {domNode args} {
    set state 0
    set args {*}$args
    set arglist [split $args " "]
    set xpath {*}[lindex $arglist 0]
    set checkvalue [split [lindex $arglist 1] ","]
    set pst [$domNode selectNodes $xpath]
    #W "xpath $xpath checkvalue $checkvalue pst $pst"
    if {$pst in $checkvalue} { set state 1}
    if {$state} {

        set checkdim "3D"

        if {$checkdim eq $::Model::SpatialDimension} {set state 1} else {set state 0}
    }
    if {$state} {return "normal"} else {return "hidden"}
}
