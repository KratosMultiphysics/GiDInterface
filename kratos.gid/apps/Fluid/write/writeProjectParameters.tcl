# Project Parameters
proc ::Fluid::write::getParametersDict { {stage ""} } {
    set projectParametersDict [dict create]

    # Analysis stage field
    dict set projectParametersDict analysis_stage "KratosMultiphysics.FluidDynamicsApplication.fluid_dynamics_analysis"

    # Problem data
    dict set projectParametersDict problem_data [::Fluid::write::GetProblemData_Dict]

    # output configuration
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict [::Fluid::GetAttribute id]]

    # Solver settings
    dict set projectParametersDict solver_settings [Fluid::write::getSolverSettingsDict]

    # Boundary conditions processes
    dict set projectParametersDict processes [Fluid::write::GetProcesses_Dict]

    return $projectParametersDict
}

proc ::Fluid::write::GetProblemData_Dict { } {
    return [write::GetDefaultProblemDataDict [::Fluid::GetAttribute id]]
}

proc ::Fluid::write::GetProcesses_Dict { } {
    set processesDict [dict create]
    dict set processesDict initial_conditions_process_list [write::getConditionsParametersDict [::Fluid::GetUniqueName nodal_conditions] "Nodal"]
    set boundary_conditions_process_list [process_special_conditions [write::getConditionsParametersDict [::Fluid::GetUniqueName conditions]]]
    dict set processesDict boundary_conditions_process_list $boundary_conditions_process_list
    dict set processesDict gravity [list [getGravityProcessDict] ]
    dict set processesDict auxiliar_process_list [getAuxiliarProcessList]
    return $processesDict
}

proc ::Fluid::write::process_special_conditions { list_of_processes } {
    set new_list [list ]
    foreach process $list_of_processes {
        # Wall law has nested parameters
        if {[dict get $process process_name] eq "ApplyWallLawProcess" } {
            if {[dict get $process Parameters wall_model_name] eq "navier_slip"} {
                dict set process Parameters wall_model_settings slip_length [dict get $process Parameters slip_length]
            }
            if {[dict get $process Parameters wall_model_name] eq "linear_log"} {
                dict set process Parameters wall_model_settings y_wall [dict get $process Parameters y_wall]
            }
            dict unset process Parameters y_wall
            dict unset process Parameters slip_length
        }
        lappend new_list $process
    }
    return $new_list
    
}

proc ::Fluid::write::getParametersMultistageDict { } {
    # At this moment we can only fake stages, so we'll have only one stage
    # Get the base dictionary for the project parameters
    set project_parameters_dict [dict create]

    # Get the stages
    set stages_list [list "stage_1"]
    set stages_names [list "stage_1"]

    # Set the orchestrator
    dict set project_parameters_dict orchestrator [::write::GetOrchestratorDict $stages_names]

    # Set the stages
    set stages [dict create]

    set i 0
    foreach stage $stages_list {
        set stage_name [lindex $stages_names 0]
        set stage_content [::Fluid::write::getParametersDict]
        # In first iteration we add the mdpa importer
        if {$i == 0} {
            set parameters_modeler [dict create input_filename [Kratos::GetModelName] model_part_name [write::GetConfigurationAttribute model_part_name]]
            dict set stages $stage_name stage_preprocess [::write::getPreprocessForStage $stage $parameters_modeler]
        } else {
            dict set stages $stage_name stage_preprocess [::write::getPreprocessForStage $stage]
        }
        if {[dict exists $stage_content solver_settings model_import_settings]} {dict unset stage_content solver_settings model_import_settings}
        dict set stages $stage_name stage_settings $stage_content
        
        dict set stages $stage_name stage_postprocess [::write::getPostprocessForStage $stage]
        incr i
    }

    dict set project_parameters_dict "stages" $stages
    
    return $project_parameters_dict
}

# Update the modelers information
proc ::Fluid::write::UpdateModelers { projectParametersDict {stage ""} } {
    set modelerts_list [list ]
    # Move the import to the modelers
    # set modelers [dict get $projectParametersDict solver_settings model_import_settings]
    dict unset projectParametersDict solver_settings model_import_settings 
    dict set projectParametersDict solver_settings model_import_settings input_type use_input_model_part
    set importer_modeler [dict create name "KratosMultiphysics.modelers.import_mdpa_modeler.ImportMDPAModeler"]  
    dict set importer_modeler "parameters" [dict create input_filename [Kratos::GetModelName] model_part_name [write::GetConfigurationAttribute model_part_name]]  
    lappend modelerts_list $importer_modeler

    # Add the entities creation modeler
    set entities_modeler [dict create name "KratosMultiphysics.CreateEntitiesFromGeometriesModeler"]
    dict set entities_modeler "parameters" elements_list [Fluid::write::GetMatchSubModelPart element $stage]
    dict set entities_modeler "parameters" conditions_list [Fluid::write::GetMatchSubModelPart condition $stage]
    lappend modelerts_list $entities_modeler
    dict set projectParametersDict "modelers" $modelerts_list

    return $projectParametersDict
}

# what can be element, condition
proc Fluid::write::GetMatchSubModelPart { what {stage ""} } {
    set model_part_basename [write::GetConfigurationAttribute model_part_name]
    set entity_name element_name
    if {$what == "condition"} {set entity_name condition_name}
   
    set elements_list [list ]
    set processed_groups_list [list ]
    set groups [::Fluid::xml::GetListOfSubModelParts $stage]
    foreach group $groups {
        # get the group and submodelpart name
        set group_name [$group @n]
        
        set group_name [write::GetWriteGroupName $group_name]
        if {$group_name ni $processed_groups_list} {lappend processed_groups_list $group_name} {continue}
        if {$what == "condition"} {set cid [[$group parent] @n]} {
            set element_node [$group selectNodes "./value\[@n='Element']"]
            if {[llength $element_node] == 0} {continue}
            set cid [write::getValueByNode $element_node]
        }
        if {$cid eq ""} {continue}
        if {$what == "condition"} {set entity [::Model::getCondition $cid]} {set entity [::Model::getElement $cid]}
        if {$entity eq ""} {continue}
        set good_name [write::transformGroupName $group_name]
        # Get the entity (element or condition)
        if {[$group hasAttribute ov]} {set ov [get_domnode_attribute $group ov]} {set ov [get_domnode_attribute [$group parent] ov]}

        lassign [write::getEtype $ov $group_name] etype nnodes

        set kname [$entity getTopologyKratosName $etype $nnodes]
        set pair [ dict create model_part_name $model_part_basename.$good_name $entity_name $kname]
        lappend elements_list $pair
        
    }
    return $elements_list
}

proc ::Fluid::write::writeParametersEvent { } {
    set write_parameters_mode 0
    if {$write_parameters_mode == 0} {
        set projectParametersDict [getParametersDict]
        set projectParametersDict [Fluid::write::UpdateModelers $projectParametersDict]
    } else {
        set projectParametersDict [getParametersMultistageDict]
    }
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

proc ::Fluid::write::getAuxiliarProcessList {} {
    set process_list [list ]

    foreach process [getDragProcessList] {lappend process_list $process}

    return $process_list
}

proc ::Fluid::write::getDragProcessList {} {
    set root [customlib::GetBaseRoot]

    set process_list [list ]
    set xp1 "[spdAux::getRoute [::Fluid::GetUniqueName drag]]/group"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set write_output [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='write_drag_output_file'\]"]]]
        set print_screen [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='print_drag_to_screen'\]"]]]
        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "compute_body_fitted_drag_process"
        dict set pdict "kratos_module" "KratosMultiphysics.FluidDynamicsApplication"
        dict set pdict "process_name" "ComputeBodyFittedDragProcess"
        set params [dict create]
        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        dict set params "write_drag_output_file" $write_output
        dict set params "print_drag_to_screen" $print_screen
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    return $process_list
}

# Gravity SubModelParts and Process collection
proc ::Fluid::write::getGravityProcessDict {} {
    set root [customlib::GetBaseRoot]

    set value [write::getValue FLGravity GravityValue]
    set cx [write::getValue FLGravity Cx]
    set cy [write::getValue FLGravity Cy]
    set cz [write::getValue FLGravity Cz]
    #W "Gravity $value on \[$cx , $cy , $cz\]"
    set pdict [dict create]
    dict set pdict "python_module" "assign_vector_by_direction_process"
    dict set pdict "kratos_module" "KratosMultiphysics"
    dict set pdict "process_name" "AssignVectorByDirectionProcess"
    set params [dict create]
    set partgroup [write::getPartsSubModelPartId]
    dict set params "model_part_name" [write::GetModelPartNameWithParent [concat [lindex $partgroup 0]]]
    dict set params "variable_name" "BODY_FORCE"
    dict set params "modulus" $value
    dict set params "constrained" false
    dict set params "direction" [list $cx $cy $cz]
    dict set pdict "Parameters" $params

    return $pdict
}

# Skin SubModelParts ids
proc ::Fluid::write::getBoundaryConditionMeshId {} {
    set root [customlib::GetBaseRoot]
    set listOfBCGroups [list ]
    set xp1 "[spdAux::getRoute [::Fluid::GetUniqueName conditions]]/condition/group"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set cond [Model::getCondition $cid]
        if {[$cond getAttribute "SkinConditions"] eq "True"} {
            if {[GetAttribute mdpa_mode] eq "geometries"} {
                    if {$groupName ni $listOfBCGroups} {lappend listOfBCGroups $groupName}
            } else {
                if {[[::Model::getCondition $cid] getGroupBy] eq "Condition"} {
                    # Grouped conditions have its own submodelpart
                    if {$cid ni $listOfBCGroups} {
                        lappend listOfBCGroups $cid
                    }
                } else {
                    set gname [::write::getSubModelPartId $cid $groupName]
                    if {$gname ni $listOfBCGroups} {lappend listOfBCGroups $gname}
                }
            }
        }
    }
    return $listOfBCGroups
}

# No-skin SubModelParts ids
proc ::Fluid::write::getNoSkinConditionMeshId {} {
    set root [customlib::GetBaseRoot]
    set listOfNoSkinGroups [list ]

    # Append drag processes model parts names
    set xp1 "[spdAux::getRoute [::Fluid::GetUniqueName drag]]/group"
    set dragGroups [$root selectNodes $xp1]
    foreach dragGroup $dragGroups {
        set groupName [$dragGroup @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$dragGroup parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]
        if {$submodelpart ni $listOfNoSkinGroups} {lappend listOfNoSkinGroups $submodelpart}
    }

    # Append no skin conditions model parts names
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set cond [Model::getCondition $cid]
        if {[$cond getAttribute "SkinConditions"] eq "False"} {
            set gname [::write::getSubModelPartId $cid $groupName]
            if {$gname ni $listOfNoSkinGroups} {lappend listOfNoSkinGroups $gname}
        }
    }

    return $listOfNoSkinGroups
}

proc ::Fluid::write::GetUsedElements {} {
    set root [customlib::GetBaseRoot]

    # Get the fluid part
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set lista [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set g $gNode
        set name [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element']"] ]
        if {$name ni $lista} {lappend lista $name}
    }

    return $lista
}

proc ::Fluid::write::getSolverSettingsDict { } {
    set solverSettingsDict [dict create]
    dict set solverSettingsDict model_part_name [GetAttribute model_part_name]
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solverSettingsDict domain_size $nDim
    set currentStrategyId [write::getValue FLSolStrat "" force]
    set strategy [::Model::GetSolutionStrategy $currentStrategyId]
    set strategy_write_name [$strategy getAttribute "ImplementedInPythonFile"]
    set strategy_type [$strategy getAttribute "Type"]
    dict set solverSettingsDict solver_type $strategy_write_name

    # model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    set model_name [Fluid::write::getFluidModelPartFilename]
    dict set modelDict input_filename $model_name
    dict set solverSettingsDict model_import_settings $modelDict

    # material import settings
    set materialsDict [dict create]
    dict set materialsDict materials_filename [GetAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict FLSolStrat FLScheme FLStratParams] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Fluid] ]

    # Parts
    dict set solverSettingsDict volume_model_part_name {*}[write::getPartsSubModelPartId]

    # Skin parts
    dict set solverSettingsDict skin_parts [getBoundaryConditionMeshId]

    # No skin parts
    dict set solverSettingsDict no_skin_parts [getNoSkinConditionMeshId]

    # Time scheme settings
    if {$strategy_type eq "monolithic"} {
        dict set solverSettingsDict time_scheme [write::getValue FLScheme]
    }

    # Time stepping settings
    set timeSteppingDict [dict create]
    set automaticDeltaTime [write::getValue FLTimeParameters AutomaticDeltaTime]
    dict set timeSteppingDict automatic_time_step $automaticDeltaTime
    if {$automaticDeltaTime eq "Yes"} {
        dict set timeSteppingDict "CFL_number" [write::getValue FLTimeParameters CFLNumber]
        dict set timeSteppingDict "minimum_delta_time" [write::getValue FLTimeParameters MinimumDeltaTime]
        dict set timeSteppingDict "maximum_delta_time" [write::getValue FLTimeParameters MaximumDeltaTime]
    } else {
        dict set timeSteppingDict "time_step" [write::getValue FLTimeParameters DeltaTime]
    }
    dict set solverSettingsDict time_stepping $timeSteppingDict

    # For monolithic schemes, set the formulation settings
    if {$strategy_type eq "monolithic"} {
        # Create formulation dictionary
        set formulationSettingsDict [dict create]

        # Set formulation dictionary element type
        set elements [Fluid::write::GetUsedElements]
        if {[llength $elements] ne 1} {error "You must select 1 element"} {set element_name [lindex $elements 0]}
        set element_type [Fluid::write::GetMonolithicElementTypeFromElementName $element_name]
        dict set formulationSettingsDict element_type $element_type

        # Set OSS and remove oss_switch from the original dictionary
        # It is important to check that there is oss_switch, otherwise the derived apps (e.g. embedded) might crash
        if {[dict exists $solverSettingsDict oss_switch]} {
            # Set the oss_switch only in those elements that support it
            if {$element_type eq "qsvms" || $element_type eq "dvms"} {
                dict set formulationSettingsDict use_orthogonal_subscales [write::getStringBinaryFromValue [dict get $solverSettingsDict oss_switch]]
            }
            # Always remove the oss_switch from the original dictionary
            dict unset solverSettingsDict oss_switch
        }

        # Set dynamic tau and remove it from the original dictionary
        dict set formulationSettingsDict dynamic_tau [dict get $solverSettingsDict dynamic_tau]
        dict unset solverSettingsDict dynamic_tau

        # Include the formulation settings in the solver settings dict
        dict set solverSettingsDict formulation $formulationSettingsDict
    }
    dict set solverSettingsDict "reform_dofs_at_each_step" false
    return $solverSettingsDict
}

proc ::Fluid::write::GetMonolithicElementTypeFromElementName {element_name} {
    set element [Model::getElement $element_name]
    if {![$element hasAttribute FormulationElementType]} {error "Your monolithic element $element_name need to define the FormulationElementType field"}
    set formulation_element_type [$element getAttribute FormulationElementType]
    return {*}$formulation_element_type
}
