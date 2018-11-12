
# Project Parameters
proc Pfem::write::getParametersDict { } {
    Pfem::write::CalculateMyVariables
    set projectParametersDict [dict create]

    ##### Problem data #####
    # Create section
    set problemDataDict [GetPFEM_ProblemDataDict]
    dict set projectParametersDict problem_data $problemDataDict

    ##### model_data #####
    set modelDataDict [GetPFEM_ModelDataDict]
    dict set projectParametersDict model_settings $modelDataDict

    ##### Time settings #####
    set timeDataDict [dict create]
    dict set timeDataDict time_step [write::getValue PFEM_TimeParameters DeltaTime]
    dict set timeDataDict end_time [write::getValue PFEM_TimeParameters EndTime]
    dict set projectParametersDict time_settings $timeDataDict

    ##### solver_settings #####
    set solverSettingsDict [GetPFEM_SolverSettingsDict]
    dict set projectParametersDict solver_settings $solverSettingsDict

    ##### problem_process_list
    set problemProcessList [GetPFEM_ProblemProcessList]
    dict set projectParametersDict problem_process_list $problemProcessList

    ##### constraints_process_list
    set group_constraints [Pfem::write::getConditionsParametersDict PFEM_NodalConditions "Nodal"]
    set body_constraints [Pfem::write::getBodyConditionsParametersDict PFEM_NodalConditions "Nodal"]
    dict set projectParametersDict constraints_process_list [concat $group_constraints $body_constraints]

    ##### loads_process_list
    dict set projectParametersDict loads_process_list [Pfem::write::GetConditionsParametersDictWithGravity]
    
    ##### Restart
    set output_process_list [GetPFEM_OutputProcessList]
    dict set projectParametersDict output_process_list $output_process_list

    ##### output_configuration
    dict set projectParametersDict output_configuration [Pfem::write::GetDefaultOutputDict]

    return $projectParametersDict
}

proc Pfem::write::GetConditionsParametersDictWithGravity { } {
    set loads_list [Pfem::write::getConditionsParametersDict PFEM_Loads]
    set problemtype [write::getValue PFEM_DomainType]
    if {$problemtype ne "Solid"} {

        set cx [write::getValue FLGravity Cx]
        set cy [write::getValue FLGravity Cy]
        set cz [write::getValue FLGravity Cz]
        
        set fluid_bodies_list [Pfem::write::GetFluidBodies]

        foreach body $fluid_bodies_list {

            set processDict [dict create]
            set parametersDict [dict create]
                
            dict set parametersDict "model_part_name" $body	    
            dict set parametersDict "variable_name" "VOLUME_ACCELERATION"
            dict set parametersDict "value" [list $cx $cy $cz]
            dict set parametersDict "constrained" false

            dict set processDict python_module "assign_vector_components_to_nodes_process"
            dict set processDict kratos_module "KratosMultiphysics.SolidMechanicsApplication"
            dict set processDict Parameters $parametersDict
            
            lappend loads_list $processDict
        }
    }
    return $loads_list
}
proc Pfem::write::GetPFEM_ProblemDataDict { } {
    set problemDataDict [dict create]
    dict set problemDataDict problem_name [file tail [GiD_Info Project ModelName]]

    dict set problemDataDict echo_level [write::getValue Results EchoLevel]
    
    #dict set problemDataDict threads [write::getValue Parallelization OpenMPNumberOfThreads]
    
    #set problemtype [write::getValue PFEM_DomainType]
    #if {$problemtype ne "Solid"} {
    #	set cx [write::getValue FLGravity Cx]
    #	set cy [write::getValue FLGravity Cy]
    #	set cz [write::getValue FLGravity Cz]
    #	dict set problemDataDict gravity_vector [list $cx $cy $cz]
    #}

    return $problemDataDict
}

proc Pfem::write::GetPFEM_ModelDataDict { } {
    variable bodies_list
    set modelDataDict [dict create]
    dict set modelDataDict model_name [file tail [GiD_Info Project ModelName]]

    set nDim $::Model::SpatialDimension
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set modelDataDict dimension $nDim

    # model import settings
    set modelDict [dict create]
    #dict set modelDict type "mdpa"
    dict set modelDict name [file tail [GiD_Info Project ModelName]]
    #dict set modelDict label 0
    dict set modelDataDict input_file_settings $modelDict

    set bodies_parts_list [list ]
    foreach body $bodies_list {
        set body_parts [dict get $body parts_list]
        foreach part $body_parts {
            lappend bodies_parts_list $part
        }
    }

    dict set modelDataDict bodies_list $bodies_list
    dict set modelDataDict domain_parts_list $bodies_parts_list
    dict set modelDataDict processes_parts_list [write::getSubModelPartNames "PFEM_NodalConditions" "PFEM_Loads"]
    
    return $modelDataDict
}

proc Pfem::write::GetPFEM_SolverSettingsDict { } {

    set equationType [write::getValue PFEM_EquationType]
    set solverSettingsDict [dict create]        
    set strategyId [write::getValue PFEM_SolStrat]
    set strategy_write_name [[::Model::GetSolutionStrategy $strategyId] getAttribute "python_module"] 
    
    if {$equationType eq "Monolithic"} {
        return [GetPFEM_MonolithicSolverSettingsDict strategy_write_name [DofsInElements]]
    } else {

        # Solver type  
        dict set solverSettingsDict solver_type $strategy_write_name
        # Solver parameters
        set solverParametersDict [dict create]
        set solver_name "solid_mechanics_implicit_dynamic_solver"

        set solversList [list ]
        foreach dof [DofsInElements] {
            lappend solversList [GetPFEM_MonolithicSolverSettingsDict $solver_name $dof]
        }
        
        dict set solverParametersDict solvers $solversList

        # Set parameters to solver settings
        dict set solverSettingsDict Parameters $solverParametersDict

        return $solverSettingsDict
    }
}

proc Pfem::write::GetPFEM_MonolithicSolverSettingsDict { solver_name dofs } {

    set solverSettingsDict [dict create]

    dict set solverSettingsDict solver_type $solver_name

    # Solver parameters
    set solverParametersDict [dict create]

    # Time integration settings
    set integrationDataDict [dict create]

    dict set integrationDataDict solution_type [write::getValue PFEM_SolutionType]

    set solutiontype [write::getValue PFEM_SolutionType]
        
    if {$solutiontype ne "Dynamic"} {
        dict set integrationDataDict integration_method "Implicit"
        dict set integrationDataDict analysis_type [write::getValue PFEM_AnalysisType]
    } else {
        dict set integrationDataDict time_integration "Implicit"
        dict set integrationDataDict integration_method [write::getValue PFEM_Scheme]
    }

    # Solving strategy settings
    set strategyDataDict [dict create]
    
    # Solution strategy parameters and Solvers   
    set strategyDataDict [dict merge $strategyDataDict [write::getSolutionStrategyParametersDict] ]

    # Get integration order as term for the integration settings
    set exist_time_integration [dict exists $strategyDataDict time_integration_order]
    if {$exist_time_integration eq 1} {
        dict set integrationDataDict time_integration_order [dict get $strategyDataDict time_integration_order]
        dict unset strategyDataDict time_integration_order
    }   
    
    dict set solverParametersDict time_integration_settings $integrationDataDict

    # Get convergence criterion settings
    set convergenceDataDict [dict create]
    set exist_convergence_criterion [dict exists $strategyDataDict convergence_criterion]
    if {$exist_convergence_criterion eq 1} {
	dict set convergenceDataDict convergence_criterion [dict get $strategyDataDict convergence_criterion]
	dict unset strategyDataDict convergence_criterion
	set exist_variable_tolerances [dict exists $strategyDataDict variable_relative_tolerance]
	if {$exist_variable_tolerances eq 1} {
	    dict set convergenceDataDict variable_relative_tolerance [dict get $strategyDataDict variable_relative_tolerance]
	    dict set convergenceDataDict variable_absolute_tolerance [dict get $strategyDataDict variable_absolute_tolerance]
	    dict unset strategyDataDict variable_relative_tolerance
	    dict unset strategyDataDict variable_absolute_tolerance
	}
	set exist_residual_tolerances [dict exists $strategyDataDict residual_relative_tolerance]
	if {$exist_residual_tolerances eq 1} {
	    dict set convergenceDataDict residual_relative_tolerance [dict get $strategyDataDict residual_relative_tolerance]
	    dict set convergenceDataDict residual_absolute_tolerance [dict get $strategyDataDict residual_absolute_tolerance]
	    dict unset strategyDataDict residual_relative_tolerance
	    dict unset strategyDataDict residual_absolute_tolerance	    
	}
    }
    
    dict set solverParametersDict convergence_criterion_settings $convergenceDataDict

    set reform_dofs true        
    dict set strategyDataDict reform_dofs_at_each_step [expr $reform_dofs]

    set strategy_data_size [dict size $strategyDataDict]
    if { $strategy_data_size ne 0 } {
        dict set solverParametersDict solving_strategy_settings $strategyDataDict
    }
    
    # Linear solver settings
    set solverParametersDict [dict merge $solverParametersDict [write::getSolversParametersDict Pfem] ]

    # Add Dofs
    # dict set solverParametersDict dofs [list {*}[DofsInElements] ]
    dict set solverParametersDict dofs [list {*}$dofs ]
    
    dict set solverSettingsDict Parameters $solverParametersDict


    return $solverSettingsDict
}

proc Pfem::write::GetPFEM_OutputProcessList { } {
    set resultList [list]
    lappend resultList [write::GetRestartProcess Restart]
    return $resultList
}
proc Pfem::write::GetPFEM_ProblemProcessList { } {
    set resultList [list ]
    set problemtype [write::getValue PFEM_DomainType]
    if {$problemtype ne "Solid"} {
        lappend resultList [GetPFEM_FluidRemeshDict]
    } else {
        set root [customlib::GetBaseRoot]
        set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
        set remesh_list [list ]
        foreach body_node [$root selectNodes $xp1] {
            set remesh [get_domnode_attribute [$body_node selectNodes ".//value\[@n='MeshingStrategy'\]"] v]
            if {$remesh ne "No remesh" && $remesh ne ""} {lappend remesh_list $remesh}
        }
        if {[llength $remesh_list]} {
            lappend resultList [GetPFEM_RemeshDict]
        }
    }
    set contactDict [GetPFEM_ContactDict]
    if {[dict size $contactDict]} {lappend resultList $contactDict}
    return $resultList
}

proc Pfem::write::GetPFEM_ContactDict { } {
    set contact_dict [dict create]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
    set contact_list [list ]
    foreach body_node [$root selectNodes $xp1] {
        set contact [get_domnode_attribute [$body_node selectNodes ".//value\[@n='ContactStrategy'\]"] v]
        if {$contact ne "No" && $contact ne "" && $contact ni $contact_list} {lappend contact_list $contact}
    }
    #W $contact_list
    set contact_domains [list ]
    foreach contact $contact_list {
        lappend contact_domains [Pfem::write::GetPfem_ContactProcessDict $contact]
    }
    if {[llength $contact_list]} {
        dict set contact_dict "python_module" "contact_domain_process"
        dict set contact_dict "kratos_module" "KratosMultiphysics.ContactMechanicsApplication"
        dict set contact_dict "help"          "This process applies contact domain search by remeshing outer boundaries"
        dict set contact_dict "process_name"  "ContactDomainProcess"
        set params [dict create]
	set model_name [file tail [GiD_Info Project ModelName]]
        dict set params "model_part_name"       $model_name
        dict set params "meshing_control_type"  "step"
	set frequency [Pfem::write::GetContactProperty "Solid-Solid" "Frequency"]
        dict set params "meshing_frequency"     [expr $frequency]
        dict set params "meshing_before_output" true
        dict set params "meshing_domains"       $contact_domains
        dict set contact_dict "Parameters"      $params
    }
    return $contact_dict
}

proc Pfem::write::GetPfem_ContactProcessDict {contact_name} {
    set cont_dict [dict create]
    dict set cont_dict "python_module" "contact_domain"
    set mesh_strat [dict create]
    dict set mesh_strat "python_module" "contact_meshing_strategy"
    set contact_parameters [dict create]

    set penalty_method [Pfem::write::GetContactProperty "Solid-Solid" "Penalty"]
    set nDim $::Model::SpatialDimension
    if {$nDim eq "3D"} {
	if {$penalty_method eq "true"} {
	    dict set contact_parameters "contact_condition_type" "ContactDomainPenaltyCondition3D4N"
	} else {
	    dict set contact_parameters "contact_condition_type" "ContactDomainLMCondition3D4N"
	}
    } else {
	if {$penalty_method eq "true"} {
	    dict set contact_parameters "contact_condition_type" "ContactDomainPenaltyCondition2D3N"
	} else {
	    dict set contact_parameters "contact_condition_type" "ContactDomainLMCondition2D3N"
	}
    }

    dict set contact_parameters "friction_law_type" "FrictionLaw"
    dict set contact_parameters "kratos_module" "KratosMultiphysics.ContactMechanicsApplication"
    set properties_dict [dict create]

    set prop_list [list ]
    if {$penalty_method eq "true"} {
	lappend prop_list "PENALTY_PARAMETER"
    } else {
	lappend prop_list "TAU_STAB"
    }

    set friction_active [Pfem::write::GetContactProperty "Solid-Solid" "FRICTION_ACTIVE"]
    if {$friction_active eq "true"} {
	lappend prop_list "FRICTION_ACTIVE"
	lappend prop_list "MU_STATIC"
	lappend prop_list "MU_DYNAMIC"
	if {$penalty_method eq "true"} {
	    lappend prop_list "TANGENTIAL_PENALTY_RATIO"
	}
    } else {
	lappend prop_list "FRICTION_ACTIVE"
    }

    foreach prop $prop_list {
	set prop_value [Pfem::write::GetContactProperty "Solid-Solid" $prop]
	set prop_value [expr $prop_value]
        dict set properties_dict $prop $prop_value
    }

    dict set contact_parameters "variables_of_properties" $properties_dict
    dict set mesh_strat "contact_parameters" $contact_parameters
    dict set cont_dict "elemental_variables_to_transfer" [list "CAUCHY_STRESS_VECTOR" "DEFORMATION_GRADIENT" ]
    dict set cont_dict "contact_bodies_list" [Pfem::write::GetSolidBodiesWithContact]
    dict set cont_dict "meshing_strategy" $mesh_strat
    return $cont_dict
}

proc Pfem::write::GetFluidBodies { } {
    set bodies_list [list ]
    # Locate the node pointing to the bodies
    set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
    foreach body_node [[customlib::GetBaseRoot] selectNodes $xp1] {
        # If the body is Fluid
        set body_type_path ".//value\[@n='BodyType'\]"
        set body_type [get_domnode_attribute [$body_node selectNodes $body_type_path] v]
        # Append to the return list
	    if {$body_type eq "Fluid"} {lappend bodies_list [get_domnode_attribute $body_node name]}
    }

    return $bodies_list
}

proc Pfem::write::GetSolidBodiesWithContact { } {
    set bodies_list [list ]
    set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
    foreach body_node [[customlib::GetBaseRoot] selectNodes $xp1] {
        set contact [get_domnode_attribute [$body_node selectNodes ".//value\[@n='ContactStrategy'\]"] v]
        if {$contact eq "Yes"} {lappend bodies_list [get_domnode_attribute $body_node name]}
    }
    return $bodies_list
}

proc Pfem::write::GetContactProperty { contact_name property } {
    set ret ""
    set root [customlib::GetBaseRoot]
    set ret [get_domnode_attribute [$root selectNodes "[spdAux::getRoute "PFEM_contacts"]/container\[@n='$contact_name'\]/value\[@n='$property'\]"] v]

    if {$ret eq ""} {set ret null}
    return $ret
}

proc Pfem::write::GetPFEM_RemeshDict { } {
    variable bodies_list
    set resultDict [dict create ]
    dict set resultDict "help" "This process applies meshing to the problem domains"
    dict set resultDict "kratos_module" "KratosMultiphysics.PfemApplication"
    dict set resultDict "python_module" "remesh_domains_process"
    dict set resultDict "process_name" "RemeshDomainsProcess"

    set paramsDict [dict create]
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set paramsDict "model_part_name" $model_name
    dict set paramsDict "meshing_control_type" "step"
    dict set paramsDict "meshing_frequency" 1.0
    dict set paramsDict "meshing_before_output" true
    set meshing_domains_list [list ]
    foreach body $bodies_list {
        set bodyDict [dict create ]
        set body_name [dict get $body body_name]
        set remesh [write::getStringBinaryFromValue [Pfem::write::GetRemeshProperty $body_name "Remesh"]]
        if { $remesh eq "true" } {
            dict set bodyDict "python_module" "meshing_domain"
            dict set bodyDict "model_part_name" $body_name
            dict set bodyDict "alpha_shape" 2.4
            dict set bodyDict "offset_factor" 0.0        
            set refine [write::getStringBinaryFromValue [Pfem::write::GetRemeshProperty $body_name "Refine"]]
            set meshing_strategyDict [dict create ]
            dict set meshing_strategyDict "python_module" "meshing_strategy"
            dict set meshing_strategyDict "meshing_frequency" 0
            dict set meshing_strategyDict "remesh" $remesh
            dict set meshing_strategyDict "refine" $refine
            dict set meshing_strategyDict "reconnect" false
            dict set meshing_strategyDict "transfer" false
            dict set meshing_strategyDict "constrained" false
            dict set meshing_strategyDict "mesh_smoothing" false
            dict set meshing_strategyDict "variables_smoothing" false
            dict set meshing_strategyDict "elemental_variables_to_smooth" [list "DETERMINANT_F" ]
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
            set upX [expr 0.0]; set upY [expr 0.0]; set upZ [expr 0.0]
            dict set spatial_bounding_boxDict "upper_point" [list $upX $upY $upZ]
            set lpX [expr 0.0]; set lpY [expr 0.0]; set lpZ [expr 0.0]
            dict set spatial_bounding_boxDict "lower_point" [list $lpX $lpY $lpZ]
            set vlX [expr 0.0]; set vlY [expr 0.0]; set vlZ [expr 0.0]
            dict set spatial_bounding_boxDict "velocity" [list $vlX $vlY $vlZ]
            dict set bodyDict spatial_bounding_box $spatial_bounding_boxDict

            set refining_parametersDict [dict create ]
            dict set refining_parametersDict "critical_size" 0.0
            dict set refining_parametersDict "threshold_variable" "PLASTIC_STRAIN"
            dict set refining_parametersDict "reference_threshold" 0.0
            dict set refining_parametersDict "error_variable" "NORM_ISOCHORIC_STRESS"
            dict set refining_parametersDict "reference_error" 0.0
            dict set refining_parametersDict "add_nodes" true
            dict set refining_parametersDict "insert_nodes" false

            set remove_nodesDict [dict create]
            dict set remove_nodesDict "apply_removal" false
            dict set remove_nodesDict "on_distance" false
            dict set remove_nodesDict "on_threshold" false
            dict set remove_nodesDict "on_error" false
            dict set refining_parametersDict remove_nodes $remove_nodesDict

            set remove_boundaryDict [dict create]
            dict set remove_boundaryDict "apply_removal" false
            dict set remove_boundaryDict "on_distance" false
            dict set remove_boundaryDict "on_threshold" false
            dict set remove_boundaryDict "on_error" false
            dict set refining_parametersDict remove_boundary $remove_boundaryDict

            set refine_elementsDict [dict create]
            dict set refine_elementsDict "apply_refinement" false
            dict set refine_elementsDict "on_distance" false
            dict set refine_elementsDict "on_threshold" false
            dict set refine_elementsDict "on_error" false
            dict set refining_parametersDict refine_elements $refine_elementsDict

            set refine_boundaryDict [dict create]
            dict set refine_boundaryDict "apply_refinement" false
            dict set refine_boundaryDict "on_distance" false
            dict set refine_boundaryDict "on_threshold" false
            dict set refine_boundaryDict "on_error" false
            dict set refining_parametersDict refine_boundary $refine_boundaryDict

            set refining_boxDict [dict create]
            dict set refining_boxDict "refine_in_box_only" false
            set upX [expr 0.0]; set upY [expr 0.0]; set upZ [expr 0.0]
            dict set refining_boxDict "upper_point" [list $upX $upY $upZ]
            set lpX [expr 0.0]; set lpY [expr 0.0]; set lpZ [expr 0.0]
            dict set refining_boxDict "lower_point" [list $lpX $lpY $lpZ]
            set vlX [expr 0.0]; set vlY [expr 0.0]; set vlZ [expr 0.0]
            dict set refining_boxDict "velocity" [list $vlX $vlY $vlZ]
            dict set refining_parametersDict refining_box $refining_boxDict

            dict set bodyDict refining_parameters $refining_parametersDict

            dict set bodyDict "elemental_variables_to_transfer" [list "CAUCHY_STRESS_VECTOR" "DEFORMATION_GRADIENT"]
            lappend meshing_domains_list $bodyDict
        }
    }
    dict set paramsDict meshing_domains $meshing_domains_list
    dict set resultDict Parameters $paramsDict
    return $resultDict
}

proc Pfem::write::GetPFEM_FluidRemeshDict { } {
    variable bodies_list
    set resultDict [dict create ]
    dict set resultDict "help" "This process applies meshing to the problem domains"
    dict set resultDict "kratos_module" "KratosMultiphysics.PfemApplication"
    set problemtype [write::getValue PFEM_DomainType]

    dict set resultDict "python_module" "remesh_fluid_domains_process"
    dict set resultDict "process_name" "RemeshFluidDomainsProcess"

    set paramsDict [dict create]
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set paramsDict "model_part_name" $model_name
    dict set paramsDict "meshing_control_type" "step"
    dict set paramsDict "meshing_frequency" 1.0
    dict set paramsDict "meshing_before_output" true
    set meshing_domains_list [list ]
    foreach body $bodies_list {
        set bodyDict [dict create ]
        set body_name [dict get $body body_name]
        set remesh [write::getStringBinaryFromValue [Pfem::write::GetRemeshProperty $body_name "Remesh"]]
        if { $remesh eq "true" } {
            dict set bodyDict "model_part_name" $body_name
            dict set bodyDict "python_module" "meshing_domain"
            set nDim $::Model::SpatialDimension
            if {$nDim eq "3D"} {
                dict set bodyDict "alpha_shape" 1.3
            } else {
                dict set bodyDict "alpha_shape" 1.25
            }
            dict set bodyDict "offset_factor" 0.0        
            set refine [write::getStringBinaryFromValue [Pfem::write::GetRemeshProperty $body_name "Refine"]]
            set meshing_strategyDict [dict create ]
            dict set meshing_strategyDict "python_module" "fluid_meshing_strategy"
            dict set meshing_strategyDict "meshing_frequency" 0
            dict set meshing_strategyDict "remesh" $remesh
            dict set meshing_strategyDict "refine" $refine
            dict set meshing_strategyDict "reconnect" false
            dict set meshing_strategyDict "transfer" false
            dict set meshing_strategyDict "constrained" false
            dict set meshing_strategyDict "mesh_smoothing" false
            dict set meshing_strategyDict "variables_smoothing" false
            dict set meshing_strategyDict "elemental_variables_to_smooth" [list "DETERMINANT_F" ]
            if {$nDim eq "3D"} {
                dict set meshing_strategyDict "reference_element_type" "UpdatedLagrangianSegregatedFluidElement3D4N"
                dict set meshing_strategyDict "reference_condition_type" "CompositeCondition3D3N"
            } else {
                dict set meshing_strategyDict "reference_element_type" "UpdatedLagrangianSegregatedFluidElement2D3N"
                dict set meshing_strategyDict "reference_condition_type" "CompositeCondition2D2N"
            }
            dict set bodyDict meshing_strategy $meshing_strategyDict

            set spatial_bounding_boxDict [dict create ]
            set upX [expr 0.0]; set upY [expr 0.0]; set upZ [expr 0.0]
            dict set spatial_bounding_boxDict "upper_point" [list $upX $upY $upZ]
            set lpX [expr 0.0]; set lpY [expr 0.0]; set lpZ [expr 0.0]
            dict set spatial_bounding_boxDict "lower_point" [list $lpX $lpY $lpZ]
            set vlX [expr 0.0]; set vlY [expr 0.0]; set vlZ [expr 0.0]
            dict set spatial_bounding_boxDict "velocity" [list $vlX $vlY $vlZ]
            dict set bodyDict spatial_bounding_box $spatial_bounding_boxDict

            set refining_parametersDict [dict create ]
            dict set refining_parametersDict "critical_size" 0.0
            dict set refining_parametersDict "threshold_variable" "PLASTIC_STRAIN"
            dict set refining_parametersDict "reference_threshold" 0.0
            dict set refining_parametersDict "error_variable" "NORM_ISOCHORIC_STRESS"
            dict set refining_parametersDict "reference_error" 0.0
            dict set refining_parametersDict "add_nodes" false
            dict set refining_parametersDict "insert_nodes" true

            set remove_nodesDict [dict create]
            dict set remove_nodesDict "apply_removal" true
            dict set remove_nodesDict "on_distance" true
            dict set remove_nodesDict "on_threshold" false
            dict set remove_nodesDict "on_error" false
            dict set refining_parametersDict remove_nodes $remove_nodesDict

            set remove_boundaryDict [dict create]
            dict set remove_boundaryDict "apply_removal" false
            dict set remove_boundaryDict "on_distance" false
            dict set remove_boundaryDict "on_threshold" false
            dict set remove_boundaryDict "on_error" false
            dict set refining_parametersDict remove_boundary $remove_boundaryDict

            set refine_elementsDict [dict create]
            dict set refine_elementsDict "apply_refinement" true
            dict set refine_elementsDict "on_distance" true
            dict set refine_elementsDict "on_threshold" false
            dict set refine_elementsDict "on_error" false
            dict set refining_parametersDict refine_elements $refine_elementsDict

            set refine_boundaryDict [dict create]
            dict set refine_boundaryDict "apply_refinement" false
            dict set refine_boundaryDict "on_distance" false
            dict set refine_boundaryDict "on_threshold" false
            dict set refine_boundaryDict "on_error" false
            dict set refining_parametersDict refine_boundary $refine_boundaryDict

            set refining_boxDict [dict create]
            dict set refining_boxDict "refine_in_box_only" false
            set upX [expr 0.0]; set upY [expr 0.0]; set upZ [expr 0.0]
            dict set refining_boxDict "upper_point" [list $upX $upY $upZ]
            set lpX [expr 0.0]; set lpY [expr 0.0]; set lpZ [expr 0.0]
            dict set refining_boxDict "lower_point" [list $lpX $lpY $lpZ]
            set vlX [expr 0.0]; set vlY [expr 0.0]; set vlZ [expr 0.0]
            dict set refining_boxDict "velocity" [list $vlX $vlY $vlZ]
            dict set refining_parametersDict refining_box $refining_boxDict

            dict set bodyDict refining_parameters $refining_parametersDict

            dict set bodyDict "elemental_variables_to_transfer" [list "CAUCHY_STRESS_VECTOR" "DEFORMATION_GRADIENT"]
            lappend meshing_domains_list $bodyDict
        }
    }
    dict set paramsDict meshing_domains $meshing_domains_list
    dict set resultDict Parameters $paramsDict
    return $resultDict
}

proc Pfem::write::GetRemeshProperty { body_name property } {
    set ret ""
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
    set remesh_name ""
    foreach body_node [$root selectNodes $xp1] {
        if {[$body_node @name] eq $body_name} {
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


proc Pfem::write::ProcessBodiesList { } {
    customlib::UpdateDocument
    set bodiesList [list ]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
    foreach body_node [$root selectNodes $xp1] {
        set body [dict create]
        set name [$body_node @name]
        set body_type_path ".//value\[@n='BodyType'\]"
        set body_type [get_domnode_attribute [$body_node selectNodes $body_type_path] v]
        set parts [list ]
        foreach part_node [$body_node selectNodes "./container\[@n = 'Groups'\]/blockdata\[@n='Group'\]"] {
            lappend parts [write::getSubModelPartId "Parts" [$part_node @name]]
        }
        dict set body "body_type" $body_type
        dict set body "body_name" $name
        dict set body "parts_list" $parts
        lappend bodiesList $body
    }
    return $bodiesList
}

proc Pfem::write::GetNodalDataDict { } {
    set root [customlib::GetBaseRoot]
    set NodalData [list ]
    set parts [list "PFEM_Rigid2DParts" "PFEM_Rigid3DParts" "PFEM_Deformable2DParts" "PFEM_Deformable3DParts" "PFEM_Fluid2DParts" "PFEM_Fluid3DParts"]

    foreach part $parts {
        set xp1 "[spdAux::getRoute $part]/group"
        set groups [$root selectNodes $xp1]
        foreach group $groups {
            set partid [[$group parent] @n]
            set groupid [$group @n]
            set processDict [dict create]
            dict set processDict process_name "ApplyValuesToNodes"
            dict set processDict kratos_module "KratosMultiphysics.PfemApplication"

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

proc Pfem::write::ProcessRemeshDomainsDict { } {
    customlib::UpdateDocument
    set domains_dict [dict create ]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEM_meshing_domains"]/blockdata"
    foreach domain_node [$root selectNodes $xp1] {
        set name [$domain_node @name]
        foreach part_node [$domain_node selectNodes "./value"] {
            dict set domains_dict $name [get_domnode_attribute $part_node n] [get_domnode_attribute $part_node v]
        }
    }
    return $domains_dict
}

proc Pfem::write::CalculateMyVariables { } {
    variable bodies_list
    set bodies_list [Pfem::write::ProcessBodiesList]
    variable remesh_domains_dict
    set remesh_domains_dict [Pfem::write::ProcessRemeshDomainsDict]
}



proc Pfem::write::getBodyConditionsParametersDict {un {condition_type "Condition"}} {
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
            set condition [Pfem::xml::getBodyNodalConditionById $cid]
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

proc Pfem::write::DofsInElements { } {
    set dofs [list ]
    set root [customlib::GetBaseRoot]
	set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group/value\[@n='Element'\]"
	set elements [$root selectNodes $xp1]
	foreach element_node $elements {
	    set elemid [$element_node @v]
	    set elem [Model::getElement $elemid]
	    foreach dof [split [$elem getAttribute "Dofs"] ","] {
		if {$dof ni $dofs} {lappend dofs $dof}
	    }
	}
    return {*}$dofs
}
