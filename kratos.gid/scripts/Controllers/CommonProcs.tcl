
############# procs #################
proc spdAux::ProcGetElements { domNode args } {
    set nodeApp [GetAppIdFromNode $domNode]
    set sol_stratUN [apps::getAppUniqueName $nodeApp SolStrat]
    set schemeUN [apps::getAppUniqueName $nodeApp Scheme]
    if {[get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $sol_stratUN]] v] eq ""} {
        get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $sol_stratUN]] dict
    }
    if {[get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $schemeUN]] v] eq ""} {
        get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $schemeUN]] dict
    }

    #W "solStrat $sol_stratUN sch $schemeUN"
    set solStratName [::write::getValue $sol_stratUN]
    set schemeName [write::getValue $schemeUN]
    #W "$solStratName $schemeName"
    #W "************************************************************************"
    #W "$nodeApp $solStratName $schemeName"
    set elems [::Model::GetAvailableElements $solStratName $schemeName]
    #W "************************************************************************"
    set names [list ]
    set pnames [list ]
    foreach elem $elems {
        if {[$elem cumple {*}$args]} {
            lappend names [$elem getName]
            lappend pnames [$elem getName]
            lappend pnames [$elem getPublicName]
        }
    }
    set diction [join $pnames ","]
    set values [join $names ","]
    #W "[get_domnode_attribute $domNode v] $names"
    $domNode setAttribute values $values
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
    #spdAux::RequestRefresh
    return $diction
}

proc spdAux::ProcGetElementsValues { domNode args } {
    set nodeApp [GetAppIdFromNode $domNode]
    set sol_stratUN [apps::getAppUniqueName $nodeApp SolStrat]
    set schemeUN [apps::getAppUniqueName $nodeApp Scheme]
    if {[get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $sol_stratUN]] v] eq ""} {
        get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $sol_stratUN]] dict
    }
    if {[get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $schemeUN]] v] eq ""} {
        get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $schemeUN]] dict
    }

    set solStratName [::write::getValue $sol_stratUN]
    set schemeName [write::getValue $schemeUN]
    set elems [::Model::GetAvailableElements $solStratName $schemeName]

    set names [list ]
    foreach elem $elems {
        if {[$elem cumple {*}$args]} {
            lappend names [$elem getName]
        }
    }
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
    set values [join $names ","]
    return $values
}

proc spdAux::ProcGetElementsDict { domNode args } {
    set elems [Model::GetElements]
    set pnames [list ]
    foreach elem $elems {
        lappend pnames [$elem getName]
        lappend pnames [$elem getPublicName]
    }
    set diction [join $pnames ","]
    return $diction
}

proc spdAux::ProcGetSolutionStrategies {domNode args} {
    set names [list ]
    set pnames [list ]
    #W $args
    set Sols [::Model::GetSolutionStrategies {*}$args]
    #W $Sols
    foreach ss $Sols {
        lappend names [$ss getName]
        lappend pnames [$ss getName]
        lappend pnames [$ss getPublicName]
    }

    $domNode setAttribute values [join $names ","]
    set dv [lindex $names 0]
    #W "dv $dv"
    if {[$domNode getAttribute v] eq ""} {$domNode setAttribute v $dv; spdAux::RequestRefresh}
    if {[$domNode getAttribute v] ni $names} {$domNode setAttribute v $dv; spdAux::RequestRefresh}

    return [join $pnames ","]
}

proc spdAux::ProcGetSchemes {domNode args} {
    set nodeApp [GetAppIdFromNode $domNode]
    #W $nodeApp
    set sol_stratUN [apps::getAppUniqueName $nodeApp SolStrat]
    set sol_stat_path [spdAux::getRoute $sol_stratUN]

    if {[get_domnode_attribute [$domNode selectNodes $sol_stat_path] v] eq ""} {
        #W "entra"
        get_domnode_attribute [$domNode selectNodes $sol_stat_path] dict
        get_domnode_attribute [$domNode selectNodes $sol_stat_path] values
    }
    set solStratName [::write::getValue $sol_stratUN]
    #W "Unique name: $sol_stratUN - Nombre $solStratName"
    set schemes [::Model::GetAvailableSchemes $solStratName {*}$args]

    set ids [list ]
    if {[llength $schemes] == 0} {
        if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v "None";$domNode setAttribute values "None"}
        return "None,None"
    }
    set names [list ]
    set pnames [list ]
    foreach cl $schemes {
        lappend names [$cl getName]
        lappend pnames [$cl getName]
        lappend pnames [$cl getPublicName]
    }

    $domNode setAttribute values [join $names ","]

    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]}
    spdAux::RequestRefresh
    return [join $pnames ","]
}

proc spdAux::SetNoneValue {domNode} {
    $domNode setAttribute v "None"
    #$domNode setAttribute values "None"
    #spdAux::RequestRefresh
    return "None,None"
}

#This should go to values
proc spdAux::ProcGetConstitutiveLaws { domNode args } {
    set Elementname [$domNode selectNodes {string(../value[@n='Element']/@v)}]
    set Claws [::Model::GetAvailableConstitutiveLaws $Elementname]
    #W "Const Laws que han pasado la criba: $Claws"
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
    #spdAux::RequestRefresh

    return $values
}
#This should go to dict
proc spdAux::ProcGetAllConstitutiveLaws { domNode args } {
    set Claws [Model::GetConstitutiveLaws]
    if {[llength $Claws] == 0} { return [SetNoneValue $domNode] }
    set pnames [list ]
    foreach cl $Claws {
        lappend pnames [$cl getName]
        lappend pnames [$cl getPublicName]
    }
    set diction [join $pnames ","]
    #spdAux::RequestRefresh

    return $diction
}
proc spdAux::ProcGetSolvers { domNode args } {

    set solStrat [get_domnode_attribute [$domNode parent] solstratname]
    set solverEntryId [get_domnode_attribute [$domNode parent] n]

    set solvers [Model::GetAvailableSolvers $solStrat $solverEntryId]

    set pnames [list ]
    foreach slvr $solvers {
        lappend pnames [$slvr getName]
        lappend pnames [$slvr getPublicName]
    }
    return [join $pnames ","]

}

proc spdAux::ProcGetSolverParameterDict { domNode args } {
    set param_name [get_domnode_attribute $domNode n]
    set pnames [list ]
    foreach solver [Model::GetAllSolvers] {
        foreach param [dict values [$solver getInputs]] {
            foreach value [$param getValues] pvalue [$param getPValues] {
                if {$value ni $pnames} {
                    lappend pnames $value
                    lappend pnames $pvalue
                }
            }
        }
    }
    return [join $pnames ","]
}
proc spdAux::ProcGetSolverParameterValues { domNode args } {

    set solver_node [[$domNode parent] selectNodes "./value\[@n='Solver'\]"]
    get_domnode_attribute $solver_node values
    set solver_name [get_domnode_attribute $solver_node v]
    if {$solver_name ne "Automatic"} {
        set solver [Model::GetSolver $solver_name]
        set param_name [get_domnode_attribute $domNode n]
        set param [$solver getInputPn $param_name]
        if {$param ne ""} {
            set values [$param getValues]
            set v [get_domnode_attribute $domNode v]
            if {$v eq "" || $v ni $values} {
                set v [$param getDv]
                if {$v eq "" || $v ni $values} {
                    set v [lindex $values 0]
                }
                $domNode setAttribute v $v
            }
            if {$param ne ""} {return [join $values ","]}
        }
    }
    return ""
}
proc spdAux::ProcGetSolversValues { domNode args } {

    set solStrat [get_domnode_attribute [$domNode parent] solstratname]
    set solverEntryId [get_domnode_attribute [$domNode parent] n]

    set solvers [Model::GetAvailableSolvers $solStrat $solverEntryId]

    set curr_parallel_system OpenMP
    catch {set curr_parallel_system [write::getValue ParallelType]}

    set names [list ]
    set pnames [list ]
    foreach slvr $solvers {
        if {$curr_parallel_system in [$slvr getParallelism] } {
            lappend names [$slvr getName]
        }
    }
    #$domNode setAttribute values [join $names ","]
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    return [join $names ","]

}

proc spdAux::ProcConditionState { domNode args } {

    set resp [::Model::CheckConditionState $domNode]
    if {$resp} {return "normal"} else {return "hidden"}
}

proc spdAux::ProcCheckNodalConditionState { domNode args } {

    set nodeApp [GetAppIdFromNode $domNode]
    set parts_un [apps::getAppUniqueName $nodeApp Parts]
    #W $parts_un
    if {[spdAux::getRoute $parts_un] ne ""} {
        set conditionId [$domNode @n]
        set elems [$domNode selectNodes "[spdAux::getRoute $parts_un]/group/value\[@n='Element'\]"]
        set elemnames [list ]
        foreach elem $elems {
            set elemName [$elem @v]
            if {$elemName eq ""} {get_domnode_attribute $elem dict; get_domnode_attribute $elem values; set elemName [$elem @v]}
            lappend elemnames $elemName
        }
        set elemnames [lsort -unique $elemnames]
        if {$elemnames eq ""} {return "hidden"}
        if {[::Model::CheckElementsNodalCondition $conditionId $elemnames]} {return "normal"} else {return "hidden"}
    } {return "normal"}
}
proc spdAux::ProcCheckNodalConditionOutputState { domNode args } {

    set nodeApp [GetAppIdFromNode $domNode]
    set NC_un [apps::getAppUniqueName $nodeApp NodalConditions]
    if {[spdAux::getRoute $NC_un] ne ""} {
        set ncs [$domNode selectNodes "[spdAux::getRoute $NC_un]/condition/group"]
        set ncslist [list ]
        foreach nc $ncs { lappend ncslist [[$nc parent] @n]}
        set ncslist [lsort -unique $ncslist]
        set conditionId [lindex $args 0]
        if {$conditionId ni $ncslist} {return "hidden"} {return "normal"}
        set outputId [$domNode @n]
        if {[::Model::CheckNodalConditionOutputState $conditionId $outputId]} {return "normal"} else {return "hidden"}
    } {return "normal"}
}
proc spdAux::ProcRefreshTree { domNode args } {
    spdAux::RequestRefresh
}

proc spdAux::ProccheckStateByUniqueName { domNode args } {
    set total 0
    foreach {un val} {*}$args {
        set xpath [spdAux::getRoute $un]
        if {$xpath ne ""} {
            spdAux::insertDependencies $domNode $un
            set node [$domNode selectNodes $xpath]
            set realval [get_domnode_attribute $node v]
            if {$realval eq ""} {W "Warning: Check unique name $un"}
            if {[lsearch $val $realval] != -1} {
                set total 1
                break
            }
        } else {W "Warning: Check unique name $un"}
    }
    if {$total} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcSolverParamState { domNode args } {


    set id [$domNode getAttribute n]
    set nodesolver [[$domNode parent] selectNodes "./value\[@n='Solver'\]"]
    get_domnode_attribute $nodesolver values
    set solverid [get_domnode_attribute $nodesolver v]

    if {$solverid eq ""} {set resp 0} {
        set resp [::Model::getSolverParamState $solverid $id]
    }

    #spdAux::RequestRefresh
    if {$resp} {return "normal"} else {return "hidden"}
}


proc spdAux::CheckPartParamValue {node material_name} {

    set root [customlib::GetBaseRoot]
    #W "Searching [get_domnode_attribute $node n] $material_name"
    if {[$node hasAttribute n] || $material_name ne ""} {
        set id [$node getAttribute n]
        set found 0
        set val 0.0

        # primero miramos si el material tiene ese campo
        if {$material_name ne ""} {
            set nodeApp [GetAppIdFromNode $node]
            set mats_un [apps::getAppUniqueName $nodeApp Materials]
            set xp3 [spdAux::getRoute $mats_un]
            append xp3 [format_xpath {/blockdata[@n="material" and @name=%s]/value} $material_name]
            foreach valueNode [$root selectNodes $xp3] {
                if {$id eq [$valueNode getAttribute n] } {set val [$valueNode getAttribute v]; set found 1; break}
            }
            #if {$found} {W "mat $material_name value $val"}
        }
        # si no está en el material, miramos en el elemento
        if {!$found} {
            set element_node [[$node parent] selectNodes "./value\[@n='Element'\]"]
            if {$element_node ne ""} {
                set element_name [get_domnode_attribute $element_node v]
                #set claw_name [.gid.central.boundaryconds.gg.data.f0.e1 get]
                set element [Model::getElement $element_name]
                if {$element ne ""} {
                    set val [$element getInputDv $id]
                    if {$val ne ""} {set found 1}
                }
                #if {$found} {W "element $element_name value $val"}
            }
        }
        # Si no está en el elemento, miramos en la ley constitutiva
        if {!$found} {
            set claw_node [[$node parent] selectNodes "./value\[@n='ConstitutiveLaw'\]"]
            if {$claw_node ne ""} {
                set claw_name [get_domnode_attribute $claw_node v]
                set claw [Model::getConstitutiveLaw $claw_name]
                if {$claw ne ""} {
                    set val [$claw getInputDv $id]
                    if {$val ne ""} {set found 1}
                }
                #if {$found} {W "claw $claw_name value $val"}
            }
        }
        #if {!$found} {W "Not found $val"}
        if {$val eq ""} {set val 0.0} {return $val}
    }
}

proc spdAux::ProcPartParamValue { domNode args } {
    #W [$domNode asXML]
    return [spdAux::CheckPartParamValue $domNode ""]
    if {[$domNode name] eq "value"} {
        set node [$domNode selectNode "../value\[@n='Material'\]" ]
        #W $node
        set matname [get_domnode_attribute $node v]
        #W $matname
        return [spdAux::CheckPartParamValue $domNode $matname]
    }
}
proc spdAux::ProcPartParamState { domNode args } {
    #W [get_domnode_attribute $domNode v]
    #W [$domNode @v]
    set resp [::Model::CheckElemParamState $domNode]
    if {$resp eq "0"} {
        set id [$domNode getAttribute n]
        set constLaw [get_domnode_attribute [[$domNode parent] selectNodes "./value\[@n='ConstitutiveLaw'\]"] v]
        if {$constLaw eq ""} {return hidden}
        set resp [Model::CheckConstLawParamState $constLaw $id]
    }

    #W "Calculando estado de [$domNode @pn] : $resp"
    if {$resp} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcSolverEntryState { domNode args } {

    set resp [spdAux::CheckSolverEntryState $domNode]
    if {$resp} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcCheckDimension { domNode args } {

    set checkdim [lindex $args 0]

    if {$checkdim eq $::Model::SpatialDimension} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcgetStateFromXPathValue2 { domNode args } {
    set args {*}$args
    set arglist [split $args " "]
    set xpath {*}[lindex $arglist 0]
    set checkvalue [lindex $arglist 1]
    set pst [$domNode selectNodes $xpath]
    #W "xpath $xpath checkvalue $checkvalue pst $pst"
    if {$pst == $checkvalue} { return "normal"} else {return "hidden"}
}

proc spdAux::ProcgetStateFromXPathValue { domNode args } {
    set args {*}$args
    set arglist [split $args " "]
    set xpath {*}[lindex $arglist 0]
    set checkvalue [split [lindex $arglist 1] ","]
    set pst [$domNode selectNodes $xpath]
    #W "xpath $xpath checkvalue $checkvalue pst $pst"
    if {$pst in $checkvalue} { return "normal"} else {return "hidden"}
}

proc spdAux::ProcgetStateFromXPathValueDisabled { domNode args } {
    set args {*}$args
    set arglist [split $args " "]
    set xpath {*}[lindex $arglist 0]
    set checkvalue [split [lindex $arglist 1] ","]
    set pst [$domNode selectNodes $xpath]
    #W "xpath $xpath checkvalue $checkvalue pst $pst"
    if {$pst in $checkvalue} { return "disabled"} else {return "hidden"}
}


proc spdAux::ProcSolStratParamState { domNode args } {

    set resp [::spdAux::SolStratParamState $domNode]
    if {$resp} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcSchemeParamState { domNode args } {

    set resp [::spdAux::SchemeParamState $domNode]
    if {$resp} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcConstLawOutputState { domNode args } {

    set resp [::spdAux::CheckConstLawOutputState $domNode]
    if {$resp} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcElementOutputState { domNode args } {

    set resp [::spdAux::CheckElementOutputState $domNode]
    if {$resp} {return "normal"} else {return "hidden"}
}

proc spdAux::ProcActiveIfAnyPartState { domNode args } {

    set resp [::spdAux::CheckAnyPartState $domNode]
    if {$resp} {return "normal"} else {return "hidden"}
}
proc spdAux::ProcActiveIfRestartAvailable { domNode args } {

    set active [apps::ExecuteOnApp [GetAppIdFromNode $domNode] GetAttribute UseRestart]
    if {$active ne "" && $active} {return "normal"} else {return "hidden"}
}

proc spdAux::ProcDisableIfUniqueName { domNode args } {
    return [ProcChangeStateIfUniqueName $domNode disabled {*}$args]
}
proc spdAux::ProcHideIfUniqueName { domNode args } {
    return [ProcChangeStateIfUniqueName $domNode hidden {*}$args]
}
proc spdAux::ProcChangeStateIfUniqueName { domNode newState args } {
    set total 1
    foreach {un val} {*}$args {
        set xpath [spdAux::getRoute $un]
        spdAux::insertDependencies $domNode $un
        set node [$domNode selectNodes $xpath]
        if {$node eq ""} {
            set total 0
            W "Warning: state of [$domNode @n]"
        } else {
            set realval [get_domnode_attribute $node v]
            if {$realval eq ""} {W "Warning: Check unique name $un"}
            if {[lsearch $val $realval] == -1} {
                set total 0
                break
            }
        }
    }
    if {!$total} {return "normal"} else {return $newState}
}
proc spdAux::ProcCheckGeometry { domNode args } {

    set level [lindex $args 0]
    #W $level
    if {$level eq 1} {
        if {$::Model::SpatialDimension eq "3D"} {return volume} {return surface}
    }
    if {$level eq 2} {
        if {$::Model::SpatialDimension eq "3D"} {return surface} {return line}
    }
}
proc spdAux::ProcDirectorVectorNonZero { domNode args } {

    set kw [lindex $args 0]
    set update 0
    foreach condgroupnode [$domNode getElementsByTagName group] {
        set valid 0
        foreach dirnode [$condgroupnode getElementsByTagName value] {
            if {[string first $kw [get_domnode_attribute $dirnode n]] eq 0 } {
                if { [get_domnode_attribute $dirnode v] != 0 } {set valid 1; break}
            }
        }
        if {!$valid} {
            $domNode removeChild $condgroupnode
            set update 1
        }
    }
    if {$update} {
        W "Director vector can't be null"
        gid_groups_conds::actualize_conditions_window
    }
}
proc spdAux::ProcShowInMode { domNode args } {
    set kw [lindex $args 0]
    if {$kw ni [list "Release" "Developer"]} {return "hidden"}
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        if {$kw eq "Developer"} {return "normal"} {return "hidden"}
    }
    if {$::Kratos::kratos_private(DevMode) eq "release"} {
        if {$kw eq "Developer"} {return "hidden"} {return "normal"}
    }
}

proc spdAux::ProcGetFilesValues { } {
    lappend listilla "- No file"
    lappend listilla {*}[FileSelector::GetAllFiles]
    lappend listilla "- Add new file"
    return [join $listilla ","]
}

proc spdAux::ProcGetIntervals {domNode args} {
    set lista [::spdAux::getIntervals]
    if {$lista eq ""} {$domNode setAttribute state "hidden"; spdAux::RequestRefresh}
    if {[$domNode @v] eq "" || [$domNode @v] ni $lista} {
        $domNode setAttribute v [lindex $lista 0]
    }
    set res [spdAux::ListToValues $lista]
    return $res
}

proc spdAux::PreChargeTree { } {
    return ""

    set root [customlib::GetBaseRoot]

    foreach field [list value condition container] {
        foreach cndNode [$root getElementsByTagName $field] {
            set a [get_domnode_attribute $cndNode dict]
            set a [get_domnode_attribute $cndNode values]
            set a [get_domnode_attribute $cndNode v]
            #W [get_domnode_attribute $cndNode n]
        }
    }
}

proc spdAux::ProcGive_materials_list {domNode args} {
    set optional {
        { -has_container container_name "" }
        { -icon icon_name material16 }
        { -types_icon types_icon_name ""}
        { -database database_name materials }
    }
    #W $args
    set compulsory ""
    parse_args $optional $compulsory $args
    set restList ""

    proc database_append_list { parentNode database_name level container_name icon_name types_icon_name filters} {
        set l ""
        # We guess the keywords of the levels of the database
        set level_names [give_levels_name $parentNode $database_name]
        set primary_level [lindex $level_names 0]
        set secondary_level [lindex $level_names 1]
        set materials [Model::GetMaterialsNames $filters]
        if {$secondary_level eq "" && $container_name ne "" && $level == "0"} {
            error [_ "The has_container flag is not available for the database %s (the different types of materials \
                    should be distributed in several containers)" $database_name]
        }

        foreach domNode [$parentNode childNodes] {
            set name [$domNode @name ""]
            if { $name eq "" } { set name [$domNode @name] }
            if { [$domNode @n] eq "$secondary_level" } {
                if {$name in $materials} {
                    set ret [database_append_list $domNode  $database_name [expr {$level+1}] $container_name $icon_name $types_icon_name $filters]
                    if { [llength $ret] } {
                        lappend l [list $level $name $name $types_icon_name 0]
                        eval lappend l $ret
                    }
                }
            } elseif {[$domNode @n] eq "$primary_level"} {
                set good 1
                if { $container_name ne "" } {
                    set xp [format_xpath {container[@n=%s]} $container_name]
                    if { [$domNode selectNodes $xp] eq "" } { set good 0 }
                }
                if { $good } {
                    lappend l [list $level $name $name $icon_name 1]
                }
            }
        }
        return $l
    }

    proc give_caption_name { domNode xp database_name } {
        set first_time 1
        foreach gNode [$domNode selectNodes $xp] {
            if {$first_time} {
                set caption_name [$gNode @n]
                set first_time 0
                continue
            }
            if {[$gNode @n] ne $caption_name} {
                error [_ "Please check the n attributes of the database %s" $database_name]
            }
        }
        return $caption_name
    }

    proc give_levels_name { domNode name } {
        set xp {container}
        if {[$domNode selectNodes $xp] eq ""} {
            # No seconday level exists
            set secondary_level ""
            set xp2 {blockdata}
            set primary_level [give_caption_name $domNode $xp2 $name]
        } else {
            set secondary_level [give_caption_name $domNode $xp $name]
            set xp3 {container/blockdata}
            set primary_level [give_caption_name $domNode $xp3 $name]
        }
        return [list $primary_level $secondary_level]
    }
    #W $database
    set appid [spdAux::GetAppIdFromNode $domNode]
    set mats_un [apps::getAppUniqueName $appid Materials]
    set xp3 [spdAux::getRoute $mats_un]
    set parentNode [$domNode selectNodes $xp3]
    set const_law_name [get_domnode_attribute [$domNode selectNodes "../value\[@n = 'ConstitutiveLaw'\]"] v]
    set filters [list ]
    if {$const_law_name != ""} {
        set const_law [Model::getConstitutiveLaw $const_law_name]
	if {$const_law != ""} {
	    set filters [$const_law getMaterialFilters]
	}
    }
    #W [$parentNode asXML]
    if {$parentNode eq ""} {
        error [_ "Database %s not found in the spd file" $database]
    }

    eval lappend resList [database_append_list $parentNode $database 0 $has_container $icon $types_icon $filters]

    set res_raw_list [list ]
    foreach m $resList {lappend res_raw_list [lindex $m 1]}
    set v [get_domnode_attribute [$domNode selectNodes "../value\[@n = 'Material'\]"] v]
    if {$v ni $res_raw_list} {[$domNode selectNodes "../value\[@n = 'Material'\]"] setAttribute v $v}
    return [join $resList ","]
}

proc spdAux::ProcEdit_database_list {domNode args} {
    set root [customlib::GetBaseRoot]
    set matname ""
    set xnode "[$domNode @n]:"
    # TODO: REMOVE THIS CHAPUZA
    set baseframe ".gid.central.boundaryconds.gg.data.f0"
    set things [winfo children $baseframe]
    foreach thing $things {
        if {[winfo class $thing] eq "TLabel"} {
            set lab [$thing cget -text]
            if {$lab eq $xnode} {
                set id [string range [lindex [split $thing "."] end] 1 end]
                set cbo ${baseframe}.e$id
                set matname [$cbo get]
                break
            }
        }
    }
    if {$matname ne ""} {
        foreach thing $things {
            set found 0
            #set id ""
            if {[winfo class $thing] eq "TPanedwindow"} {
                #set id [string range [lindex [split $thing "."] end] 1 end]
                set thing "${thing}.e"
            }
            if {[winfo class $thing] eq "TEntry"} {
                #if {$id eq "" } {set id [string range [lindex [split $thing "."] end] 1 end]}
                #set prop ${baseframe}.e$id
                set varname [$thing cget -textvariable]
                set propname [lindex [split [lindex [split [lindex [split $varname "::"] end] "("] end] ")"] 0]
                #W $propname
                set appid [spdAux::GetAppIdFromNode $domNode]
                set mats_un [apps::getAppUniqueName $appid Materials]
                set xp3 [spdAux::getRoute $mats_un]
                append xp3 [format_xpath {/blockdata[@n="material" and @name=%s]/value} $matname]

                foreach valueNode [$root selectNodes $xp3] {
                    if {$propname eq [$valueNode getAttribute n] } {
                        set val [$valueNode getAttribute v]
                        set $varname $val
                        #set found 1
                        break
                    }
                }
                #if {$found} {W "mat $matname value $val"}

            }
        }
    }
    return ""
}

proc spdAux::ProcCambioMat {domNode args} {
    set matname [get_domnode_attribute $domNode v]
    set exclusion [list "Element" "ConstitutiveLaw" "Material"]
    set nodes [$domNode selectNodes "../value"]
    foreach node $nodes {
        if {[$node @n] ni $exclusion} {
            #W "[$node @n] [CheckPartParamValue $node $matname]"
            $node setAttribute v [spdAux::CheckPartParamValue $node $matname]
        }
    }
    RequestRefresh
}

proc spdAux::ProcOkNewCondition {domNode args} {
    set cnd_id [$domNode @n]
    set condition [Model::getCondition $cnd_id]

    set group_node [$domNode lastChild]
    set interval [$group_node selectNodes "./value\[@n='Interval'\]"]
    if {$interval ne ""} {
        set group_id [$group_node @n]
        set interval_id [get_domnode_attribute $interval v]
        set new_group_id "$group_id//$interval_id"
        set i 0
        while {[GiD_Groups exists $new_group_id]} {
            set new_group_id "$group_id//$interval_id - $i"
            incr i
        }
        GiD_Groups create $new_group_id
        foreach ent [list points lines surfaces volumes nodes elements] {
            GiD_EntitiesGroups assign $new_group_id $ent [GiD_EntitiesGroups get $group_id $ent]
        }
        GiD_Groups edit state $new_group_id hidden
        $group_node setAttribute n $new_group_id
        AddIntervalGroup $group_id $new_group_id

        GiD_Groups window update
        RequestRefresh
    }
}

proc spdAux::ProcConditionParameterState {domNode args} {
    set param_name [get_domnode_attribute $domNode n]
    set cond_node [$domNode parent]
    if {[$cond_node nodeName] eq "group"} {set cond_node [$cond_node parent]}
    set cond_name [get_domnode_attribute $cond_node n]

    set cond [Model::getCondition $cond_name]
    if {$cond eq ""} {
        set cond [Model::getNodalConditionbyId $cond_name]
        if {$cond eq ""} {
            W "No condition found with name $cond_name" ; return normal
        }
    }
    set process_name [$cond getProcessName]
    set process [Model::GetProcess $process_name]
    set param [$process getInputPn $param_name]
    if {$param eq ""} {return normal}

    set depN [$param getDepN]
    if {$depN ne ""} {
        set depV [$param getDepV]
        set realV [get_domnode_attribute [$domNode selectNodes "../value\[@n='$depN'\]"] v]
        if {$depV ne $realV} {return hidden}
    }

    return normal
}

proc spdAux::ProcGetParts {domNode args} {
    set parts ""
    set nodeApp [GetAppIdFromNode $domNode]
    set parts_un [apps::getAppUniqueName $nodeApp Parts]
    set parts_path [spdAux::getRoute $parts_un]
    if {$parts_path ne ""} {
        foreach part [$domNode selectNodes "$parts_path/group"] {
            lappend parts [$part @n]
        }
    }
    if {[llength $parts]} { if {[$domNode @v] ni $parts} {$domNode setAttribute v [lindex $parts 0]}}
    return [join $parts ","]
}

proc spdAux::ProcUpdateParts {domNode args} {
    set current [lindex [$domNode selectNodes "./group"] end]
    # If a parameter type is file and the option selected is select file -> open it
    set file_params [$current selectNodes "./value\[@type = 'tablefile' and @v = '- Add new file'\]"]

    if {[llength $file_params] > 1} {
        W "Remember to load the files in:"
        foreach file $file_params {
            W "    [get_domnode_attribute $file pn]"
        }
    } elseif {[llength $file_params] == 1} {
        spdAux::AddFile $file_params
    }

    # Active app executexml
    set nodeApp [GetAppIdFromNode $domNode]
    apps::ExecuteOnAppXML $nodeApp UpdateParts $domNode
}
