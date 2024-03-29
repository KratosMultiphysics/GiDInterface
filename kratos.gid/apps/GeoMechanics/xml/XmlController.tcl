namespace eval ::GeoMechanics::xml {
    namespace path ::GeoMechanics
    Kratos::AddNamespace [namespace current]

    variable is_drawing_stage
}

proc ::GeoMechanics::xml::Init { } {
    Model::InitVariables dir $::GeoMechanics::dir

    Model::ForgetElements
    Model::getElements Elements.xml
    
    Model::getProcesses Processes.xml

    # Set Water to false on all conditions coming from Structural Application
    foreach condition [Model::GetConditions] {
        $condition setAttribute Water False
    }
    Model::getConditions Conditions.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml

    Model::ForgetMaterials
    Model::getMaterials Materials.xml

    Model::getNodalConditions NodalConditions.xml


    # Structural strategies and schemes filter elements by ImplementedInApplication StructuralMechanicsApplication
    # In order to add our elements, we need to tell the schemes to accept GeoMechanicsApplication
    foreach strategy $::Model::SolutionStrategies {
        foreach scheme [$strategy getSchemes] {
            $scheme addElementFilter ImplementedInApplication StructuralMechanicsApplication,GeoMechanicsApplication
        }
    }

    
    variable is_drawing_stage
    set is_drawing_stage 0
}

proc ::GeoMechanics::xml::getUniqueName {name} {
    return [::GeoMechanics::GetAttribute prefix]$name
}

proc ::GeoMechanics::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames ST GEOM
    }
}

proc ::GeoMechanics::xml::CustomTree { args } {
    spdAux::SetValueOnTreeItem state hidden STResults CutPlanes
    spdAux::SetValueOnTreeItem v SingleFile GiDOptions GiDMultiFileFlag
    spdAux::SetValueOnTreeItem v 1 GiDOptions EchoLevel

    set nodal_results_node [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute NodalResults]]

    set result_node [$nodal_results_node selectNodes "./value\[@n = 'CONDENSED_DOF_LIST_2D'\]"]
    if {$result_node ne "" } {$result_node delete}
    set result_node [$nodal_results_node selectNodes "./value\[@n = 'CONDENSED_DOF_LIST'\]"]
    if {$result_node ne "" } {$result_node delete}
    set result_node [$nodal_results_node selectNodes "./value\[@n = 'CONTACT'\]"]
    if {$result_node ne "" } {$result_node delete}
    set result_node [$nodal_results_node selectNodes "./value\[@n = 'CONTACT_SLAVE'\]"]
    if {$result_node ne "" } {$result_node delete}
    set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute STNodalConditions]/condition\[@n = 'VOLUMETRIC_STRAIN'\]"]
    if {$result_node ne "" } {$result_node delete}

    set xpath "[spdAux::getRoute STResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    if {[[customlib::GetBaseRoot] selectNodes "$xpath/value\[@n='print_prestress'\]"] eq ""} {
        gid_groups_conds::addF $xpath value [list n print_prestress pn "Print prestress" values "true,false" v true state "\[checkStateByUniqueName STSoluType formfinding\]"]
    }
    if {[[customlib::GetBaseRoot] selectNodes "$xpath/value\[@n='print_mdpa'\]"] eq ""} {
        gid_groups_conds::addF $xpath value [list n print_mdpa pn "Print modelpart" values "true,false" v true state "\[checkStateByUniqueName STSoluType formfinding\]"]
    }

    spdAux::SetValueOnTreeItem state {[HideIfUniqueName STAnalysisType linear]} STStratSection use_old_stiffness_in_first_iteration

    # Stress test
    # for {set index 0} {$index < 200} {incr index} {::snit::RT.CallInstance ::boundary_conds::Snit_inst1 copy_block_data}
    set xpath [spdAux::getRoute GEOMSoluType]
    set solution_type_node [[customlib::GetBaseRoot] selectNodes $xpath]
    $solution_type_node setAttribute values "Static,Quasi-static,Dynamic"

    set xpath "[spdAux::getRoute STStratSection]/container\[@n='ParallelType'\]"
    set old_parallel [[customlib::GetBaseRoot] selectNodes $xpath]
    $old_parallel delete

    ::GeoMechanics::WarnActiveStage
}

proc ::GeoMechanics::xml::ProcCheckGeometryGeoMechanics {domNode args} {
    set ret "line,surface"
    if {$::Model::SpatialDimension eq "3D"} {
        set ret "line,surface,volume"
    }
    return $ret
}

proc ::GeoMechanics::xml::ProcGetSolutionStrategiesGeoMechanics { domNode args } {
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

proc ::GeoMechanics::xml::ProcCheckNodalConditionStateGeoMechanics {domNode args} {
    # Overwritten the base function to add Solution Type restrictions
    set parts_un STParts
    if {[spdAux::getRoute $parts_un] ne ""} {
        set conditionId [$domNode @n]
        set condition [Model::getNodalConditionbyId $conditionId]
        set cnd_dim [$condition getAttribute WorkingSpaceDimension]
        if {$cnd_dim ne ""} {
            if {$cnd_dim ne $Model::SpatialDimension} {return "hidden"}
        }
        set elems [$domNode selectNodes "[spdAux::getRoute $parts_un]/condition/group/value\[@n='Element'\]"]
        set elemnames [list ]
        foreach elem $elems { lappend elemnames [$elem @v]}
        set elemnames [lsort -unique $elemnames]

        set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute STSoluType]] v]
        set params [list analysis_type $solutionType]
        if {[::Model::CheckElementsNodalCondition $conditionId $elemnames $params]} {return "normal"} else {return "hidden"}
    } {return "normal"}
}

proc ::GeoMechanics::xml::ProcCheckGeometryGeoMechanics {domNode args} {
    set ret "surface"
    if {$::Model::SpatialDimension eq "3D"} {
        set ret "surface,volume"
    }
    return $ret
}


proc ::GeoMechanics::xml::UpdateParts {domNode args} {
    set current [lindex [$domNode selectNodes "./group"] end]
    set element_name [get_domnode_attribute [$current selectNodes "./value\[@n = 'Element'\]"] v]
    set element [Model::getElement $element_name]
    set LocalAxesAutomaticFunction [$element getAttribute "LocalAxesAutomaticFunction"]
    if {$LocalAxesAutomaticFunction ne ""} {
        $LocalAxesAutomaticFunction $current
    }
}

proc ::GeoMechanics::xml::AddLocalAxesToBeamElement { current } {
    # set y_axis_deviation [get_domnode_attribute [$current selectNodes "./value\[@n = 'LOCAL_AXIS_ROTATION'\]"] v]
    # W $y_axis_deviation
    set group [get_domnode_attribute $current n]
    if {[GiD_EntitiesGroups get $group lines -count]} {
        foreach line [GiD_EntitiesGroups get $group lines] {
            GiD_Process MEscape Data Conditions AssignCond line_Local_axes change -Automatic- $line escape escape
            #set raw [lindex [lindex [GiD_Info conditions -localaxesmat line_Local_axes mesh $line] 0] 3]
        }
    }
}


############# procs #################
proc ::GeoMechanics::xml::ProcGetElementsGeoMechanics { domNode args } {
    set nodeApp [spdAux::GetAppIdFromNode $domNode]
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

    set solution_type [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute STSoluType]] v]; # This filters between Static, Quasi-static, Dynamic, formfinding, ...
    set analysis_type [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute STAnalysisType]] v]; # This filters between linear and non-linear
    set params [list AnalysisType $analysis_type]

    set names [list ]
    set pnames [list ]
    foreach elem $elems {
        if {[$elem cumple {*}$args]} {
            # Get the available analysis type for the current element
            set available_analysis_type {*}[split [$elem getAttribute AnalysisType] {,}]
            # Get the available solution type for the current element
            if {[$elem hasAttribute SolutionType]} {
                set available_solution_type {*}[split [$elem getAttribute SolutionType] {,}]
            } else {
                set available_solution_type [list]
            }
            # Filter according to analysis type and solution type
            # Note that if the element does not define solution type, all solution types are valid
            set number_available_solution_types [llength $available_solution_type]
            if {$analysis_type in $available_analysis_type && ($number_available_solution_types eq 0 || $solution_type in $available_solution_type)} {
                lappend names [$elem getName]
                lappend pnames [$elem getName]
                lappend pnames [$elem getPublicName]
            }
        }
    }
    set diction [join $pnames ","]
    set values [join $names ","]
    #W "[get_domnode_attribute $domNode v] $names"
    $domNode setAttribute values $values
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {
        ::GidUtils::SetWarnLine "Warning. [get_domnode_attribute $domNode v] not available for the current settings. Changed to [lindex $names 0]."
        $domNode setAttribute v [lindex $names 0]
        spdAux::RequestRefresh
    }
    #spdAux::RequestRefresh
    return $diction
}

# Get stages list
proc ::GeoMechanics::xml::GetStages { {what "nodes"} } {
    set stages [list ]
    set root [customlib::GetBaseRoot]
    set stages [$root selectNodes ".//container\[@n='stages'\]/blockdata"]
    if {$what eq "names"} {
        set names [list ]
        foreach stage $stages {
            lappend names [$stage getAttribute name]
        }
        set stages $names
    }
    return $stages
}

# Close all stages
proc ::GeoMechanics::xml::CloseStages { } {
    set stages [::GeoMechanics::xml::GetStages]
    foreach stage $stages {
        $stage setAttribute tree_state "closed"
    }
}
# Open stage by name
proc ::GeoMechanics::xml::OpenStage { stage_name } {
    set root [customlib::GetBaseRoot]
    set stage [$root selectNodes ".//container\[@n='stages'\]/blockdata\[@name='$stage_name'\]"]

    $stage setAttribute tree_state "open"

    # We should not use this, but it is the only way to open the stage
    set w .gid.central.boundaryconds
    set wbc [gid_groups_conds::open_conditions_window -force_open $w]
    $wbc select_domNode $stage

    variable is_drawing_stage
    if {$is_drawing_stage} {
        ::GeoMechanics::xml::EndDrawStage
        ::GeoMechanics::xml::DrawStage $stage_name
    }
}

# Draw stage by id
proc ::GeoMechanics::xml::DrawStage {stage_name} {
    
    variable is_drawing_stage

    if {$is_drawing_stage} {
        ::GeoMechanics::xml::EndDrawStage
    } else {
        set root [customlib::GetBaseRoot]
        set stage [$root selectNodes ".//container\[@n='stages'\]/blockdata\[@name='$stage_name'\]"]
        
        set groups_raw [$stage selectNodes ".//group"]
        set groups [list ]
        foreach group $groups_raw {
            set n [get_domnode_attribute $group n]
            lappend groups $n
        }
        if {[llength $groups] ne 0} {
            GiD_Groups draw $groups
            set is_drawing_stage 1
        }

    }
    
    GiD_Process 'Redraw
}

proc ::GeoMechanics::xml::EndDrawStage { } {
    variable is_drawing_stage
    set is_drawing_stage 0
    GiD_Groups end_draw
}

proc ::GeoMechanics::xml::NewStage { stage_name } {
    set root [customlib::GetBaseRoot]
    set stages [$root selectNodes ".//container\[@n='stages'\]/blockdata"]
    set newstage [[lindex $stages end] cloneNode -deep]
    $newstage setAttribute name $stage_name
    $newstage setAttribute tree_state "open"
    [$root selectNodes ".//container\[@n='stages'\]"] appendChild $newstage
    spdAux::RequestRefresh
}

proc ::GeoMechanics::xml::GetListOfSubModelParts { {stage ""} } {
    set root [customlib::GetBaseRoot]
    if {$stage ne ""} {set root $stage}
    set all_raw [$root selectNodes ".//condition/group"]
    return $all_raw
}

proc ::GeoMechanics::xml::GetPhreaticPoints {stage} {
    set root [customlib::GetBaseRoot]
    if {$stage ne ""} {set root $stage}
    set all_raw [$root selectNodes ".//container\[@n='PhreaticPoints'\]/value"]

    set result [list ]  
    foreach point $all_raw {
        lappend result [write::getValueByNode $point]
    }
    return $result
}
proc ::GeoMechanics::xml::DeletePhreaticPoints {stage} {
    set root [customlib::GetBaseRoot]
    if {$stage ne ""} {set root $stage}
    set all_raw [$root selectNodes ".//container\[@n='PhreaticPoints'\]/value"]

    foreach point $all_raw {
        $point delete
    }
}

proc ::GeoMechanics::xml::AddPhreaticPoint {stage x1 y1 z1} {
    set root [customlib::GetBaseRoot]
    if {$stage ne ""} {set root $stage}
    set base [$root selectNodes ".//container\[@n='PhreaticPoints'\]"]
    
    set all_raw [$base selectNodes "./value"]
    set num [llength $all_raw]
    set v "$x1,$y1"
    set node "<value n='p_$num' pn='P $num' v='$v' fieldtype='vector' dimensions='2' />"
    $base appendXML $node
    set result [$base selectNodes "./value\[@n=p_$num\]"]
    return $result
}
