
proc PfemFluid::write::writeParametersEvent { } {
    write::WriteJSON [getNewParametersDict]
    write::SetParallelismConfiguration
}

# Project Parameters
proc PfemFluid::write::getNewParametersDict { } {
    PfemFluid::write::CalculateMyVariables
    set projectParametersDict [dict create]

    ##### Problem data #####
    # Create section
    set problemDataDict [GetPFEM_ProblemDataDict]
    # Add section to document
    dict set projectParametersDict problem_data $problemDataDict

    ##### solver_settings #####
    set solverSettingsDict [GetPFEM_SolverSettingsDict]
    dict set projectParametersDict solver_settings $solverSettingsDict

    ##### problem_process_list
    set problemProcessList [GetPFEM_ProblemProcessList "[]" "[]"]
    dict set projectParametersDict problem_process_list $problemProcessList

    set processList [GetPFEM_ProcessList]
    dict set projectParametersDict processes $processList

    ##### Restart
    # set output_process_list [GetPFEM_OutputProcessList]
    # dict set projectParametersDict output_process_list $output_process_list

    ##### output_configuration
    # dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]
    set xpath [spdAux::getRoute Results]
    dict set projectParametersDict output_configuration [write::GetDefaultOutputGiDDict PfemFluid $xpath]
    dict set projectParametersDict output_configuration result_file_configuration nodal_results [write::GetResultsByXPathList [spdAux::getRoute NodalResults]]
    dict set projectParametersDict output_configuration result_file_configuration gauss_point_results [write::GetResultsList ElementResults]


    return $projectParametersDict
}

proc PfemFluid::write::GetPFEM_ProblemDataDict { } {
    set problemDataDict [dict create]
    dict set problemDataDict problem_name [Kratos::GetModelName]

   # Time Parameters
    set time_params [PfemFluid::write::GetTimeSettings]
    dict set problemDataDict start_time [dict get $time_params start_time]
    dict set problemDataDict end_time [dict get $time_params end_time]
    dict set problemDataDict echo_level [write::getValue Results EchoLevel]

    # Parallelization
    # dict set problemDataDict "parallel_type" "OpenMP"
    dict set problemDataDict parallel_type [write::getValue Parallelization ParallelSolutionType]

    dict set problemDataDict threads [write::getValue Parallelization OpenMPNumberOfThreads]
    dict set problemDataDict gravity_vector [PfemFluid::write::GetGravity]

    return $problemDataDict
}

proc PfemFluid::write::GetTimeSettings { } {
    set result [dict create]
    dict set result time_step [write::getValue PFEMFLUID_TimeParameters DeltaTime]
    dict set result start_time [write::getValue PFEMFLUID_TimeParameters StartTime]
    dict set result end_time [write::getValue PFEMFLUID_TimeParameters EndTime]
    return $result
}

proc PfemFluid::write::GetPFEM_SolverSettingsDict { } {
    variable bodies_list

    set solverSettingsDict [dict create]
    set currentStrategyId [write::getValue PFEMFLUID_SolStrat]
    set strategy_write_name [[::Model::GetSolutionStrategy $currentStrategyId] getAttribute "python_module"]
    dict set solverSettingsDict solver_type $strategy_write_name

    set problemtype [write::getValue PFEMFLUID_DomainType]

    dict set solverSettingsDict model_part_name [GetAttribute model_part_name]
    if {$problemtype eq "Fluids"} {
        dict set solverSettingsDict physics_type "fluid"
    }
    if {$problemtype eq "FSI"} {
        dict set solverSettingsDict physics_type "fsi"
    }
    set nDim $::Model::SpatialDimension
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set solverSettingsDict domain_size $nDim


    # Time stepping settings
    set timeSteppingDict [dict create]

    set automaticDeltaTime [write::getValue PFEMFLUID_TimeParameters UseAutomaticDeltaTime]
    if {$automaticDeltaTime eq "Yes"} {
        dict set timeSteppingDict automatic_time_step "true"
     } else {
        dict set timeSteppingDict automatic_time_step "false"
    }

    dict set timeSteppingDict time_step [write::getValue PFEMFLUID_TimeParameters [dict get $::PfemFluid::write::Names DeltaTime]]

    # set time_params [PfemFluid::write::GetTimeSettings]
    # dict set timeSteppingDict "time_step" [dict get $time_params time_step]

    dict set solverSettingsDict time_stepping $timeSteppingDict

    # dict set problemDataDict time_step [dict get $time_params time_step]


    # model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename [Kratos::GetModelName]
    # dict set modelDict input_file_label 0
    dict set solverSettingsDict model_import_settings $modelDict

    # Solution strategy parameters and Solvers
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict PFEMFLUID_SolStrat PFEMFLUID_Scheme PFEMFLUID_StratParams] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict PfemFluid] ]
	
	# Body parts list
    set bodies_parts_list [list ]
    foreach body $bodies_list {
        set body_parts [dict get $body parts_list]
        foreach part $body_parts {
            lappend bodies_parts_list $part
        }
    }
	
	# Constitutive laws
	set constitutive_list [list]
    foreach parts_un [PfemFluid::write::GetPartsUN] {
        set parts_path [spdAux::getRoute $parts_un]
        set xp1 "$parts_path/group/value\[@n='ConstitutiveLaw'\]"
        foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
            lappend constitutive_list [get_domnode_attribute $gNode v]
        }
    }
	
    dict set solverSettingsDict bodies_list $bodies_list
    dict set solverSettingsDict problem_domain_sub_model_part_list $bodies_parts_list
	dict set solverSettingsDict constitutive_laws_list $constitutive_list
    dict set solverSettingsDict processes_sub_model_part_list [write::getSubModelPartNames [GetAttribute nodal_conditions_un] "PFEMFLUID_Loads"]

    set materialsDict [dict create]
    dict set materialsDict materials_filename [GetAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    return $solverSettingsDict
}

proc PfemFluid::write::GetPFEM_OutputProcessList { } {
    set resultList [list]
    # lappend resultList [write::GetRestartProcess Restart]
    return $resultList
}
proc PfemFluid::write::GetPFEM_ProblemProcessList { free_surface_heat_flux free_surface_thermal_face } {
    set resultList [list ]
    set problemtype [write::getValue PFEMFLUID_DomainType]
    lappend resultList [GetPFEM_FluidRemeshDict $free_surface_heat_flux $free_surface_thermal_face]
    return $resultList
}

proc PfemFluid::write::GetPFEM_ProcessList { } {
    set resultList [list ]

    set group_constraints [write::getConditionsParametersDict PFEMFLUID_NodalConditions "Nodal"]
    set body_constraints [PfemFluid::write::getBodyConditionsParametersDict PFEMFLUID_NodalConditions "Nodal"]
    dict set resultList constraints_process_list [concat $group_constraints $body_constraints]

    ##### loads_process_list
    dict set resultList loads_process_list [write::getConditionsParametersDict PFEMFLUID_Loads]

    dict set resultList auxiliar_process_list []

    return $resultList
}

proc PfemFluid::write::GetBodiesWithContactList {contact_name} {
    set bodies_list [list ]
    set xp1 "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata"
    foreach body_node [[customlib::GetBaseRoot] selectNodes $xp1] {
        if {[get_domnode_attribute $body_node state] ne "hidden"} {
            set contact [get_domnode_attribute [$body_node selectNodes ".//value\[@n='ContactStrategy'\]"] v]
            if {$contact eq $contact_name} {lappend bodies_list [get_domnode_attribute $body_node name]}
        }
    }
    return $bodies_list
}


proc PfemFluid::write::GetContactProperty { contact_name property } {
    set ret ""
    set root [customlib::GetBaseRoot]
    set ret [get_domnode_attribute [$root selectNodes "[spdAux::getRoute PFEMFLUID_contacts]/blockdata\[@name='$contact_name'\]/value\[@n='$property'\]"] v]
    if {$ret eq ""} {set ret null}
    return $ret
}

proc PfemFluid::write::GetPFEM_RemeshDict { } {
    variable bodies_list
    set resultDict [dict create ]
    dict set resultDict "help" "This process applies meshing to the problem domains"
    dict set resultDict "kratos_module" "KratosMultiphysics.PfemFluidDynamicsApplication"
    dict set resultDict "python_module" "remesh_domains_process"
    dict set resultDict "process_name" "RemeshDomainsProcess"

    set paramsDict [dict create]
    dict set paramsDict "model_part_name" [GetAttribute model_part_name]
    dict set paramsDict "meshing_control_type" "step"
    dict set paramsDict "meshing_frequency" 1.0
    dict set paramsDict "meshing_before_output" true
    set meshing_domains_list [list ]
    foreach body $bodies_list {
        set bodyDict [dict create ]
        set body_name [dict get $body body_name]
        dict set bodyDict "python_module" "meshing_domain"
        dict set bodyDict "model_part_name" $body_name
        dict set bodyDict "alpha_shape" 2.4
        set remesh [write::getStringBinaryFromValue [PfemFluid::write::GetRemeshProperty $body_name "Remesh"]]
        set refine [write::getStringBinaryFromValue [PfemFluid::write::GetRemeshProperty $body_name "Refine"]]
        set meshing_strategyDict [dict create ]
        dict set meshing_strategyDict "python_module" "meshing_strategy"
        dict set meshing_strategyDict "remesh" $remesh
        dict set meshing_strategyDict "refine" $refine
        dict set meshing_strategyDict "transfer" false
        set nDim $::Model::SpatialDimension
        if {$nDim eq "3D"} {
            dict set meshing_strategyDict "reference_element_type" "Element3D4N"
            dict set meshing_strategyDict "reference_condition_type" "CompositeCondition3D3N"
        } else {
            dict set meshing_strategyDict "reference_element_type" "Element2D3N"
            dict set meshing_strategyDict "reference_condition_type" "CompositeCondition2D2N"
        }
        dict set bodyDict meshing_strategy $meshing_strategyDict

        set spatial_bounding_boxDict [dict create ]
        dict set spatial_bounding_boxDict "use_bounding_box" [write::getValue PFEMFLUID_BoundingBox UseBoundingBox]
        dict set spatial_bounding_boxDict "initial_time"     [write::getValue PFEMFLUID_BoundingBox StartTime]
        dict set spatial_bounding_boxDict "final_time"       [write::getValue PFEMFLUID_BoundingBox StopTime]
        dict set spatial_bounding_boxDict "upper_point"      [PfemFluid::write::GetUpperPointBoundingBox]
        dict set spatial_bounding_boxDict "lower_point"      [PfemFluid::write::GetLowerPointBoundingBox]
        dict set bodyDict spatial_bounding_box $spatial_bounding_boxDict

        set spatial_refining_boxDict [dict create ]
        dict set spatial_refining_boxDict "mesh_size"        [write::getValue PFEMFLUID_RefiningBox RefinedMeshSize]
        dict set spatial_refining_boxDict "use_refining_box" [write::getValue PFEMFLUID_RefiningBox UseRefiningBox]
        dict set spatial_refining_boxDict "initial_time"     [write::getValue PFEMFLUID_RefiningBox StartTime]
        dict set spatial_refining_boxDict "final_time"       [write::getValue PFEMFLUID_RefiningBox StopTime]
        dict set spatial_refining_boxDict "upper_point"      [PfemFluid::write::GetUpperPointRefiningBox]
        dict set spatial_refining_boxDict "lower_point"      [PfemFluid::write::GetLowerPointRefiningBox]
        dict set bodyDict spatial_refining_box $spatial_refining_boxDict

        lappend meshing_domains_list $bodyDict
    }
    dict set paramsDict meshing_domains $meshing_domains_list
    dict set resultDict Parameters $paramsDict
    return $resultDict
}



proc PfemFluid::write::GetPFEM_FluidRemeshDict { free_surface_heat_flux free_surface_thermal_face } {
    variable bodies_list
    set resultDict [dict create ]
    dict set resultDict "help" "This process applies meshing to the problem domains"
    dict set resultDict "kratos_module" "KratosMultiphysics.PfemFluidDynamicsApplication"
    set problemtype [write::getValue PFEMFLUID_DomainType]

    dict set resultDict "python_module" "remesh_fluid_domains_process"
    dict set resultDict "process_name" "RemeshFluidDomainsProcess"

    set paramsDict [dict create]
    dict set paramsDict "model_part_name" [GetAttribute model_part_name]
    dict set paramsDict "meshing_control_type" "step"
    dict set paramsDict "meshing_frequency" 1.0
    dict set paramsDict "meshing_before_output" true
    dict set paramsDict update_conditions_on_free_surface [PfemFluid::write::GetUpdateConditionsOnFreeSurface $free_surface_heat_flux $free_surface_thermal_face]
	
    set meshing_domains_list [list ]
    foreach body $bodies_list {
        set bodyDict [dict create ]
        set body_name [dict get $body body_name]
        dict set bodyDict "model_part_name" $body_name
        dict set bodyDict "python_module" "fluid_meshing_domain"
        set nDim $::Model::SpatialDimension
        if {$nDim eq "3D"} {
            dict set bodyDict "alpha_shape" 1.3
        } else {
            dict set bodyDict "alpha_shape" 1.25
        }
        set remesh [write::getStringBinaryFromValue [PfemFluid::write::GetRemeshProperty $body_name "Remesh"]]
        set refine [write::getStringBinaryFromValue [PfemFluid::write::GetRemeshProperty $body_name "Refine"]]
        set meshing_strategyDict [dict create ]
        dict set meshing_strategyDict "python_module" "fluid_meshing_strategy"
        dict set meshing_strategyDict "remesh" $remesh
        dict set meshing_strategyDict "refine" $refine
        dict set meshing_strategyDict "transfer" false
        if {$nDim eq "3D"} {
            dict set meshing_strategyDict "reference_element_type" "TwoStepUpdatedLagrangianVPFluidElement3D"
            dict set meshing_strategyDict "reference_condition_type" "CompositeCondition3D3N"
        } else {
            dict set meshing_strategyDict "reference_element_type" "TwoStepUpdatedLagrangianVPFluidElement2D"
            dict set meshing_strategyDict "reference_condition_type" "CompositeCondition2D2N"
        }
        dict set bodyDict meshing_strategy $meshing_strategyDict

        if {[spdAux::getRoute PFEMFLUID_BoundingBox] ne ""} {
            set spatial_bounding_boxDict [dict create ]
            dict set spatial_bounding_boxDict "use_bounding_box" [write::getValue PFEMFLUID_BoundingBox UseBoundingBox]
            dict set spatial_bounding_boxDict "initial_time"     [write::getValue PFEMFLUID_BoundingBox StartTime]
            dict set spatial_bounding_boxDict "final_time"       [write::getValue PFEMFLUID_BoundingBox StopTime]
            dict set spatial_bounding_boxDict "upper_point"      [PfemFluid::write::GetUpperPointBoundingBox]
            dict set spatial_bounding_boxDict "lower_point"      [PfemFluid::write::GetLowerPointBoundingBox]
            dict set bodyDict spatial_bounding_box $spatial_bounding_boxDict
        }

        set spatial_refining_boxDict [dict create ]
        dict set spatial_refining_boxDict "use_refining_box" [write::getValue PFEMFLUID_RefiningBox UseRefiningBox]
        dict set spatial_refining_boxDict "mesh_size"        [write::getValue PFEMFLUID_RefiningBox RefinedMeshSize]
        dict set spatial_refining_boxDict "initial_time"     [write::getValue PFEMFLUID_RefiningBox StartTime]
        dict set spatial_refining_boxDict "final_time"       [write::getValue PFEMFLUID_RefiningBox StopTime]
        dict set spatial_refining_boxDict "upper_point"      [PfemFluid::write::GetUpperPointRefiningBox]
        dict set spatial_refining_boxDict "lower_point"      [PfemFluid::write::GetLowerPointRefiningBox]
        dict set bodyDict spatial_refining_box $spatial_refining_boxDict

        lappend meshing_domains_list $bodyDict
    }
    dict set paramsDict meshing_domains $meshing_domains_list
    dict set resultDict Parameters $paramsDict
    return $resultDict
}

proc PfemFluid::write::GetUpdateConditionsOnFreeSurface { free_surface_heat_flux free_surface_thermal_face } {
	set updateConditionsDict [dict create]
	if {$free_surface_heat_flux eq "[]" && $free_surface_thermal_face eq "[]"} {
		dict set updateConditionsDict "update_conditions" false
	} else {
		set free_part_name_list [list ]
		set condition_type_list [list ]
		set nDim $::Model::SpatialDimension
		set nDim [expr [string range [write::getValue nDim] 0 0] ]
		if {$free_surface_heat_flux ne "[]"} {
			foreach part $free_surface_heat_flux {
				lappend free_part_name_list $part
			}
			if {$nDim == 2} {
				lappend condition_type_list "LineCondition2D2N"
			} else {
				lappend condition_type_list "SurfaceCondition3D3N"
			}
		}
		if {$free_surface_thermal_face ne "[]"} {
			foreach part $free_surface_thermal_face {
				lappend free_part_name_list $part
			}
			if {$nDim == 2} {
				lappend condition_type_list "LineCondition2D2N"
			} else {
				lappend condition_type_list "SurfaceCondition3D3N"
			}
		}
		dict set updateConditionsDict "update_conditions"        true
		dict set updateConditionsDict "sub_model_part_list"      $free_part_name_list
		dict set updateConditionsDict "reference_condition_list" $condition_type_list
    }
    return $updateConditionsDict
}

proc PfemFluid::write::GetRemeshProperty { body_name property } {
    set ret ""
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata"
    set remesh_name ""
    foreach body_node [$root selectNodes $xp1] {
        if {[$body_node @name] eq $body_name && [get_domnode_attribute $body_node state] ne "hidden"} {
            set remesh_name [get_domnode_attribute [$body_node selectNodes ".//value\[@n='MeshingStrategy'\]"] v]
            break
        }
    }
    if {$remesh_name ne ""} {
        variable remesh_domains_dict
        if {[dict exists $remesh_domains_dict ${remesh_name} $property]} {
            set ret [dict get $remesh_domains_dict ${remesh_name} $property]
        }
    }
    if {$ret eq ""} {set ret false}
    return $ret
}


proc PfemFluid::write::ProcessBodiesList { } {
    customlib::UpdateDocument
    set bodiesList [list ]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata"
    foreach body_node [$root selectNodes $xp1] {
        if {[get_domnode_attribute $body_node state] ne "hidden"} {
            set body [dict create]
            set name [$body_node @name]
            set body_type_path ".//value\[@n='BodyType'\]"
            set body_type [get_domnode_attribute [$body_node selectNodes $body_type_path] v]
            set parts [list ]
            foreach part_node [$body_node selectNodes "./condition/group"] {
                lappend parts [write::getSubModelPartId "Parts" [$part_node @n]]
            }
            dict set body "body_type" $body_type
            dict set body "body_name" $name
            dict set body "parts_list" $parts
            lappend bodiesList $body
        }
    }
    return $bodiesList
}

proc PfemFluid::write::GetNodalDataDict { } {
    set root [customlib::GetBaseRoot]
    set NodalData [list ]
    set parts [list "PFEMFLUID_Rigid2DParts" "PFEMFLUID_Rigid3DParts" "PFEMFLUID_Deformable2DParts" "PFEMFLUID_Deformable3DParts" "PFEMFLUID_Fluid2DParts" "PFEMFLUID_Fluid3DParts"]

    foreach part $parts {
        set xp1 "[spdAux::getRoute $part]/group"
        set groups [$root selectNodes $xp1]
        foreach group $groups {
            set partid [[$group parent] @n]
            set groupid [$group @n]
            set processDict [dict create]
            dict set processDict process_name "ApplyValuesToNodes"
            dict set processDict kratos_module "KratosMultiphysics.DelaunayMeshingApplication"

            set params [dict create]
            set xp2 "./value"
            set atts [$group selectNodes $xp2]
            #W "$group $groupid $atts"
            foreach att $atts {
                set state [get_domnode_attribute $att state]
                if {$state ne "hidden"} {
                    set paramName [$att @n]
                    set paramValue [get_domnode_attribute $att v]
                    if {$paramName eq "Material"} {
                        set matdict [::write::getAllMaterialParametersDict $paramValue]
                        dict set matdict Name $paramValue
                        dict set params $paramName $matdict
                    } {
                        if {[write::isBoolean $paramValue]} {set paramValue [expr $paramValue]}
                        dict set params $paramName $paramValue
                    }
                }
            }
            dict set params "model_part_name" [::write::getSubModelPartId $partid $groupid]
            dict set processDict "Parameters" $params
            lappend NodalData $processDict
        }
    }

    return $NodalData
}

proc PfemFluid::write::ProcessRemeshDomainsDict { } {
    customlib::UpdateDocument
    set domains_dict [dict create ]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEMFLUID_meshing_domains"]/blockdata"
    foreach domain_node [$root selectNodes $xp1] {
        set name [$domain_node @name]
        foreach part_node [$domain_node selectNodes "./value"] {
            dict set domains_dict $name [get_domnode_attribute $part_node n] [get_domnode_attribute $part_node v]
        }
    }
    return $domains_dict
}

proc PfemFluid::write::CalculateMyVariables { } {
    variable bodies_list
    set bodies_list [PfemFluid::write::ProcessBodiesList]
    variable remesh_domains_dict
    set remesh_domains_dict [PfemFluid::write::ProcessRemeshDomainsDict]
}



proc PfemFluid::write::getBodyConditionsParametersDict {un {condition_type "Condition"}} {
    set root [customlib::GetBaseRoot]
    return [list ]
    set bcCondsDict [list ]

    set xp1 "[spdAux::getRoute $un]/container/blockdata"
    set blocks [$root selectNodes $xp1]

    foreach block $blocks {
        set groupName [$block @name]
        set cid [[$block parent] @n]
        get_domnode_attribute [$block find n Body] values
        set bodyId [get_domnode_attribute [$block find n Body] v]

        if {$condition_type eq "Condition"} {
            error [= "Body conditions (not nodal) Not implemented yet."]
            #set condition [::Model::getCondition $cid]
        } {
            set condition [PfemFluid::xml::getBodyNodalConditionById $cid]
        }
        set processName [$condition getProcessName]
        #set processName [[$block parent] @processname]

        set process [::Model::GetProcess $processName]
        set processDict [dict create]
        set paramDict [dict create]
        dict set paramDict model_part_name $bodyId
        set vatiable_name [$condition getAttribute VariableName]
        dict set paramDict variable_name [lindex $vatiable_name 0]

        set process_attributes [$process getAttributes]
        set process_parameters [$process getInputs]

        dict set process_attributes process_name [dict get $process_attributes n]
        dict unset process_attributes n
        dict unset process_attributes pn

        set processDict [dict merge $processDict $process_attributes]

        foreach {inputName in_obj} $process_parameters {
            set in_type [$in_obj getType]
            if {$in_type eq "vector"} {
                if {[$in_obj getAttribute vectorType] eq "bool"} {
                    set ValX [expr [get_domnode_attribute [$block find n ${inputName}X] v] ? True : False]
                    set ValY [expr [get_domnode_attribute [$block find n ${inputName}Y] v] ? True : False]
                    set ValZ [expr False]
                    if {[$block find n ${inputName}Z] ne ""} {set ValZ [expr [get_domnode_attribute [$block find n ${inputName}Z] v] ? True : False]}
                    dict set paramDict $inputName [list $ValX $ValY $ValZ]
                } {
                    if {[$in_obj getAttribute "enabled"] in [list "1" "0"]} {
                        foreach i [list "X" "Y" "Z"] {
                            if {[expr [get_domnode_attribute [$block find n Enabled_$i] v] ] ne "Yes"} {
                                set Val$i null
                            } else {
                                set printed 0
                                if {[$in_obj getAttribute "function"] eq "1"} {
                                    if {[get_domnode_attribute [$block find n "ByFunction$i"] v]  eq "Yes"} {
                                        set funcinputName "${i}function_$inputName"
                                        set value [get_domnode_attribute [$block find n $funcinputName] v]
                                        set Val$i $value
                                        set printed 1
                                    }
                                }
                                if {!$printed} {
                                    set value [expr [get_domnode_attribute [$block find n ${inputName}$i] v] ]
                                    set Val$i $value
                                }
                            }
                        }
                    } else {
                        set ValX [expr [gid_groups_conds::convert_value_to_default [$block find n ${inputName}X]] ]
                        set ValY [expr [gid_groups_conds::convert_value_to_default [$block find n ${inputName}Y]] ]
                        set ValZ [expr 0.0]
                        if {[$block find n ${inputName}Z] ne ""} {set ValZ [expr [gid_groups_conds::convert_value_to_default [$block find n ${inputName}Z]]]}
                    }
                    dict set paramDict $inputName [list $ValX $ValY $ValZ]
                }
            } elseif {$in_type eq "double" || $in_type eq "integer"} {
                set printed 0
                if {[$in_obj getAttribute "function"] eq "1"} {
                    if {[get_domnode_attribute [$block find n "ByFunction"] v]  eq "Yes"} {
                        set funcinputName "function_$inputName"
                        set value [get_domnode_attribute [$block find n $funcinputName] v]
                        dict set paramDict $inputName $value
                        set printed 1
                    }
                }
                if {!$printed} {
                    set value [gid_groups_conds::convert_value_to_default [$block find n $inputName]]
                    dict set paramDict $inputName [expr $value]
                }
            } elseif {$in_type eq "bool"} {
                set value [get_domnode_attribute [$block find n $inputName] v]
                set value [expr $value ? True : False]
                dict set paramDict $inputName [expr $value]
            } elseif {$in_type eq "tablefile"} {
                set value [get_domnode_attribute [$block find n $inputName] v]
                dict set paramDict $inputName $value
            } else {
                if {[get_domnode_attribute [$block find n $inputName] state] ne "hidden" } {
                    set value [get_domnode_attribute [$block find n $inputName] v]
                    dict set paramDict $inputName $value
                }
            }
        }
        if {[$block find n Interval] ne ""} {dict set paramDict interval [write::getInterval  [get_domnode_attribute [$block find n Interval] v]] }
        dict set processDict Parameters $paramDict
        lappend bcCondsDict $processDict
    }
    return $bcCondsDict
}

proc PfemFluid::write::GetGravity { } {
    set cx [write::getValue PFEMFLUID_Gravity Cx]
    set cy [write::getValue PFEMFLUID_Gravity Cy]
    set cz [write::getValue PFEMFLUID_Gravity Cz]
    return [list $cx $cy $cz]
}

proc PfemFluid::write::GetLowerPointBoundingBox { } {
    set minX [write::getValue PFEMFLUID_BoundingBox MinX]
    set minY [write::getValue PFEMFLUID_BoundingBox MinY]
    set minZ [write::getValue PFEMFLUID_BoundingBox MinZ]
    return [list $minX $minY $minZ]
}

proc PfemFluid::write::GetUpperPointBoundingBox { } {
    set maxX [write::getValue PFEMFLUID_BoundingBox MaxX]
    set maxY [write::getValue PFEMFLUID_BoundingBox MaxY]
    set maxZ [write::getValue PFEMFLUID_BoundingBox MaxZ]
    return [list $maxX $maxY $maxZ]
}

proc PfemFluid::write::GetLowerPointRefiningBox { } {
    set minX [write::getValue PFEMFLUID_RefiningBox MinX]
    set minY [write::getValue PFEMFLUID_RefiningBox MinY]
    set minZ [write::getValue PFEMFLUID_RefiningBox MinZ]
    return [list $minX $minY $minZ]
}

proc PfemFluid::write::GetUpperPointRefiningBox { } {
    set maxX [write::getValue PFEMFLUID_RefiningBox MaxX]
    set maxY [write::getValue PFEMFLUID_RefiningBox MaxY]
    set maxZ [write::getValue PFEMFLUID_RefiningBox MaxZ]
    return [list $maxX $maxY $maxZ]
}