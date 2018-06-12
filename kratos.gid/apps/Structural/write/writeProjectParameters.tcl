# Project Parameters

proc Structural::write::getOldParametersDict { } {
    set model_part_name "Structure"
    set projectParametersDict [dict create]

    # Problem data
    # Create section
    set problemDataDict [dict create]

    # Add items to section
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set problemDataDict problem_name $model_name
    dict set problemDataDict model_part_name $model_part_name
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set problemDataDict domain_size $nDim

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    dict set problemDataDict "parallel_type" $paralleltype
    if {$paralleltype eq "OpenMP"} {
        #set nthreads [write::getValue Parallelization OpenMPNumberOfThreads]
        #dict set problemDataDict NumberofThreads $nthreads
    } else {
        #set nthreads [write::getValue Parallelization MPINumberOfProcessors]
        #dict set problemDataDict NumberofProcessors $nthreads
    }
    set solutiontype [write::getValue STSoluType]
    # Time Parameters
    if {$solutiontype eq "Static"} {
        dict set problemDataDict time_step "1.1"
        dict set problemDataDict start_time "0.0"
        dict set problemDataDict end_time "1.0"

    } else {
        dict set problemDataDict time_step [write::getValue STTimeParameters DeltaTime]
        dict set problemDataDict start_time [write::getValue STTimeParameters StartTime]
        dict set problemDataDict end_time [write::getValue STTimeParameters EndTime]
    }
    if {$solutiontype eq "eigen_value"} {
        set eigen_process_dict [dict create]
        dict set eigen_process_dict python_module postprocess_eigenvalues_process
        dict set eigen_process_dict kratos_module KratosMultiphysics.StructuralMechanicsApplication
        dict set eigen_process_dict help "This process postprocces the eigen values for GiD"
        dict set eigen_process_dict process_name "PostProcessEigenvaluesProcess"
        set params [dict create]
        dict set params "result_file_name" $model_name
        dict set params "animation_steps" 20
        dict set params "label_type" "frequency"
        dict set eigen_process_dict "Parameters" $params
    }
    if {$solutiontype eq "formfinding"} {
        set formfinding_process_dict [dict create]
        dict set formfinding_process_dict python_module formfinding_IO_process
        dict set formfinding_process_dict kratos_module KratosMultiphysics.StructuralMechanicsApplication
        dict set formfinding_process_dict help "This process is for input and output of prestress data"
        dict set formfinding_process_dict process_name "FormfindingIOProcess"
        set params [dict create]
        dict set params "model_part_name" $model_part_name
        dict set params "print_mdpa" [write::getValue Results print_prestress]
        dict set params "print_prestress" [write::getValue Results print_mdpa]
        dict set params "read_prestress" [Structural::write::UsingFileInPrestressedMembrane]
        dict set formfinding_process_dict "Parameters" $params
    }
    set echo_level [write::getValue Results EchoLevel]
    dict set problemDataDict echo_level $echo_level
    # Add section to document
    dict set projectParametersDict problem_data $problemDataDict

    # Solution strategy
    set solverSettingsDict [dict create]
    set currentStrategyId [write::getValue STSolStrat]
    set currentStrategyId [write::getValue STSolStrat]
    # set strategy_write_name [[::Model::GetSolutionStrategy $currentStrategyId] getAttribute "n"]
    set solver_type_name $solutiontype
    if {$solutiontype eq "Quasi-static"} {set solver_type_name "Static"}
    dict set solverSettingsDict solver_type $solver_type_name
    #~ dict set solverSettingsDict domain_size [expr $nDim]
    dict set solverSettingsDict echo_level $echo_level
    dict set solverSettingsDict analysis_type [write::getValue STAnalysisType]

    if {$solutiontype eq "Dynamic"} {
        dict set solverSettingsDict time_integration_method [write::getValue STSolStrat]
        dict set solverSettingsDict scheme_type [write::getValue STScheme]
    }

    # Model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename $model_name
    dict set solverSettingsDict model_import_settings $modelDict

    set materialsDict [dict create]
    dict set materialsDict materials_filename [GetAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    # Solution strategy parameters and Solvers
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Structural] ]

    # Submodelpart lists

    # There are some Conditions and nodalConditions that dont generate a submodelpart
    # Add them to this list
    set special_nodal_conditions_dont_generate_submodelpart_names [GetAttribute nodal_conditions_no_submodelpart]
    set special_nodal_conditions [list ]
    foreach cnd_name $special_nodal_conditions_dont_generate_submodelpart_names {
        set cnd [Model::getNodalConditionbyId $cnd_name]
        if {$cnd ne ""} {
            lappend special_nodal_conditions $cnd
            Model::ForgetNodalCondition $cnd_name
        }
    }

    dict set solverSettingsDict problem_domain_sub_model_part_list [write::getSubModelPartNames [GetAttribute parts_un]]
    dict set solverSettingsDict processes_sub_model_part_list [write::getSubModelPartNames [GetAttribute nodal_conditions_un] [GetAttribute conditions_un] ]

    
    if {[usesContact]} {
        # Mirar type y ver si es Frictionless o Frictional
        dict set solverSettingsDict contact_settings mortar_type "ALMContactFrictionlessComponents"

        set convergence_criterion [dict get $solverSettingsDict convergence_criterion]
        dict set solverSettingsDict convergence_criterion "contact_$convergence_criterion"
    }

    dict set projectParametersDict solver_settings $solverSettingsDict

    # Lists of processes
    set nodal_conditions_dict [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    #lassign [ProcessContacts $nodal_conditions_dict] nodal_conditions_dict contact_conditions_dict
    dict set projectParametersDict constraints_process_list $nodal_conditions_dict
    if {[usesContact]} {
        set contact_conditions_dict [GetContactConditionsDict]
        dict set projectParametersDict contact_process_list $contact_conditions_dict
    }
    dict set projectParametersDict loads_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]

    # Recover the conditions and nodal conditions that we didn't want to print in submodelparts
    foreach cnd $special_nodal_conditions {
        lappend ::Model::NodalConditions $cnd
    }

    dict set projectParametersDict list_other_processes [list ]
    if {$solutiontype eq "eigen_value"} {
        dict lappend projectParametersDict list_other_processes $eigen_process_dict
    }    
    if {$solutiontype eq "formfinding"} {
        dict lappend projectParametersDict list_other_processes $formfinding_process_dict
    }

    # GiD output configuration
    dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]

    # # Restart options
    # set restartDict [dict create ]
    # dict set restartDict SaveRestart false
    # dict set restartDict RestartFrequency 0
    # dict set restartDict LoadRestart false
    # dict set restartDict Restart_Step 0
    # dict set projectParametersDict restart_options $restartDict

    # # Constraints data
    # set contraintsDict [dict create ]
    # dict set contraintsDict incremental_load false
    # dict set contraintsDict incremental_displacement false
    # dict set projectParametersDict constraints_data $contraintsDict

    set check_list [list "UpdatedLagrangianElementUP2D" "UpdatedLagrangianElementUPAxisym"]
    foreach elem $check_list {
        if {$elem in [Structural::write::GetUsedElements Name]} {
            dict set projectParametersDict pressure_dofs true
            break
        }
    }

    if {$solutiontype eq "eigen_value"} {
        dict unset projectParametersDict output_configuration
        dict unset projectParametersDict solver_settings analysis_type
    }

    # set materialsDict [dict create]
    # dict set materialsDict materials_filename [GetAttribute materials_file]
    # dict set projectParametersDict material_import_settings $materialsDict

    return $projectParametersDict
}

proc Structural::write::GetContactConditionsDict { } {
    set root [customlib::GetBaseRoot]
    
    # Prepare the xpaths
    set xp_master "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT'\]/group"
    set xp_slave  "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT_SLAVE'\]/group"

    # Get the groups
    set master_group [$root selectNodes $xp_master]
    set slave_group [$root selectNodes $xp_slave]
    
    if {[llength $master_group] > 1 || [llength $slave_group] > 1} {error "Max 1 group allowed in contact master and slave"}
    
    set contact_process_dict [dict create ]
    dict set contact_process_dict python_module alm_contact_process
    dict set contact_process_dict kratos_module "KratosMultiphysics.ContactStructuralMechanicsApplication"
    dict set contact_process_dict process_name ALMContactProcess

    set contact_parameters_dict [dict create]
    dict set contact_parameters_dict contact_model_part [::write::getSubModelPartId CONTACT "_HIDDEN_CONTACT_GROUP_"]
    dict set contact_parameters_dict model_part_name Structure
    if {$slave_group ne ""} {
        dict set contact_parameters_dict assume_master_slave [::write::getSubModelPartId CONTACT [$slave_group @n]]
    
        dict set contact_parameters_dict contact_type [write::getValueByNode [$slave_group selectNodes "./value\[@n='contact_type'\]"]]
    }
    dict set contact_process_dict Parameters $contact_parameters_dict
    
    return [list $contact_process_dict]
}


proc Structural::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]
    
}


# Project Parameters
proc Structural::write::getParametersEvent { } {
    # Get the base dictionary for the project parameters
    set project_parameters_dict [getOldParametersDict]

    # If using any element with the attribute RotationDofs set to true
    dict set project_parameters_dict solver_settings rotation_dofs [UsingRotationDofElements]

    # Merging the old solver_settings with the common one for this app
    set solverSettingsDict [dict get $project_parameters_dict solver_settings]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Structural] ]
    dict set project_parameters_dict solver_settings $solverSettingsDict

    return $project_parameters_dict
}
proc Structural::write::writeParametersEvent { } {
    write::WriteJSON [::Structural::write::getParametersEvent]
}

proc Structural::write::UsingRotationDofElements { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group/value\[@n='Element'\]"
    set elements [$root selectNodes $xp1]
    set bool false
    foreach element_node $elements {
        set elemid [$element_node @v]
        set elem [Model::getElement $elemid]
        if {[write::isBooleanTrue [$elem getAttribute "RotationDofs"]]} {set bool true; break}
    }

    return $bool
}
proc Structural::write::UsingFileInPrestressedMembrane { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group/value\[@n='Element'\]"
    set elements [$root selectNodes $xp1]
    set found false
    foreach element_node $elements {
        set elemid [$element_node @v]
        if {$elemid eq "PrestressedMembraneElement"} {
            set selector [write::getValueByNode [$element_node selectNodes "../value\[@n = 'PROJECTION_TYPE_COMBO'\]"]]
            if {$selector eq "file"} {set found true; break}
        }
    }

    return $found
}
