# Project Parameters

proc Structural::write::getOldParametersDict { } {
    set model_part_name [write::GetConfigurationAttribute model_part_name]
    set projectParametersDict [dict create]

    # Problem data
    # Create section
    set problemDataDict [write::GetDefaultProblemDataDict $Structural::app_id]

    set solutiontype [write::getValue [write::GetConfigurationAttribute solution_type_un]]
    # Time Parameters
    if {$solutiontype eq "Static" || $solutiontype eq "eigen_value"} {
        set time_step "1.1"
        dict set problemDataDict start_time "0.0"
        dict set problemDataDict end_time "1.0"
    } {
        set time_step [write::getValue [write::GetConfigurationAttribute time_parameters_un] DeltaTime]
    }
    # Add section to document
    dict set projectParametersDict problem_data $problemDataDict

    if {$solutiontype eq "eigen_value"} {
        set eigen_process_dict [dict create]
        dict set eigen_process_dict python_module postprocess_eigenvalues_process
        dict set eigen_process_dict kratos_module KratosMultiphysics.StructuralMechanicsApplication
        dict set eigen_process_dict help "This process postprocces the eigen values for GiD"
        dict set eigen_process_dict process_name "PostProcessEigenvaluesProcess"
        set params [dict create]
        dict set params "result_file_name" [Kratos::GetModelName]
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
        dict set params "print_mdpa" [write::getValue [write::GetConfigurationAttribute results_un] print_prestress]
        dict set params "print_prestress" [write::getValue [write::GetConfigurationAttribute results_un] print_mdpa]
        dict set params "read_prestress" [Structural::write::UsingFileInPrestressedMembrane]
        dict set formfinding_process_dict "Parameters" $params
    }

    # TODO: Use default
    # Solution strategy
    set solverSettingsDict [dict create]
    set currentStrategyId [write::getValue [write::GetConfigurationAttribute solution_strategy_un]]
    # set strategy_write_name [[::Model::GetSolutionStrategy $currentStrategyId] getAttribute "n"]
    set solver_type_name $solutiontype
    if {$solutiontype eq "Quasi-static"} {set solver_type_name "Static"}
    dict set solverSettingsDict solver_type $solver_type_name
    dict set solverSettingsDict model_part_name $model_part_name
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set solverSettingsDict domain_size $nDim
    dict set solverSettingsDict echo_level [write::getValue [write::GetConfigurationAttribute results_un] EchoLevel]
    dict set solverSettingsDict analysis_type [write::getValue [write::GetConfigurationAttribute analysis_type_un] ]

    if {$solutiontype eq "Dynamic"} {
        dict set solverSettingsDict time_integration_method [write::getValue [write::GetConfigurationAttribute solution_strategy_un]]
        dict set solverSettingsDict scheme_type [write::getValue [write::GetConfigurationAttribute scheme_un]]
    }

    # Model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename [Kratos::GetModelName]
    dict set solverSettingsDict model_import_settings $modelDict

    set materialsDict [dict create]
    dict set materialsDict materials_filename [write::GetConfigurationAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    # Time stepping settings
    set timeSteppingDict [dict create]
    dict set timeSteppingDict "time_step" $time_step
    dict set solverSettingsDict time_stepping $timeSteppingDict

    # Solution strategy parameters and Solvers
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict [write::GetConfigurationAttribute solution_strategy_un] [write::GetConfigurationAttribute scheme_un] [write::GetConfigurationAttribute solution_strategy_parameters_un] ] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Structural] ]

    # Submodelpart lists

    # There are some Conditions and nodalConditions that dont generate a submodelpart
    # Add them to this list
    set special_nodal_conditions_dont_generate_submodelpart_names [write::GetConfigurationAttribute nodal_conditions_no_submodelpart]
    set special_nodal_conditions [list ]
    foreach cnd_name $special_nodal_conditions_dont_generate_submodelpart_names {
        set cnd [Model::getNodalConditionbyId $cnd_name]
        if {$cnd ne ""} {
            lappend special_nodal_conditions $cnd
            Model::ForgetNodalCondition $cnd_name
        }
    }

    if {[usesContact]} {
        # Mirar type y ver si es Frictionless o Frictional
        dict set solverSettingsDict contact_settings mortar_type "ALMContactFrictionlessComponents"

        set convergence_criterion [dict get $solverSettingsDict convergence_criterion]
        dict set solverSettingsDict convergence_criterion "contact_$convergence_criterion"
    }

    dict set projectParametersDict solver_settings $solverSettingsDict

    # Lists of processes
    set processesDict [dict create]

    set nodal_conditions_dict [write::getConditionsParametersDict [write::GetConfigurationAttribute nodal_conditions_un] "Nodal"]
    #lassign [ProcessContacts $nodal_conditions_dict] nodal_conditions_dict contact_conditions_dict
    dict set processesDict constraints_process_list $nodal_conditions_dict
    if {[usesContact]} {
        set contact_conditions_dict [GetContactConditionsDict]
        dict set processesDict contact_process_list $contact_conditions_dict
    }
    W [write::GetConfigurationAttribute conditions_un]
    dict set processesDict loads_process_list [write::getConditionsParametersDict [write::GetConfigurationAttribute conditions_un]]

    # Recover the conditions and nodal conditions that we didn't want to print in submodelparts
    foreach cnd $special_nodal_conditions {
        lappend ::Model::NodalConditions $cnd
    }

    dict set processesDict list_other_processes [list ]
    if {$solutiontype eq "eigen_value"} {
        dict lappend processesDict list_other_processes $eigen_process_dict
    }
    if {$solutiontype eq "formfinding"} {
        dict lappend processesDict list_other_processes $formfinding_process_dict
    }

    dict set projectParametersDict processes $processesDict

    # GiD output configuration
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict $Structural::app_id]

    set check_list [list "UpdatedLagrangianElementUP2D" "UpdatedLagrangianElementUPAxisym"]
    foreach elem $check_list {
        if {$elem in [Structural::write::GetUsedElements Name]} {
            dict set projectParametersDict pressure_dofs true
            break
        }
    }

    if {$solutiontype eq "eigen_value"} {
        dict unset projectParametersDict output_processes
        dict unset projectParametersDict solver_settings analysis_type
    }

    return $projectParametersDict
}

proc Structural::write::GetContactConditionsDict { } {
    variable ContactsDict
    set root [customlib::GetBaseRoot]

    # Prepare the xpaths
    set xp_master "[spdAux::getRoute [write::GetConfigurationAttribute nodal_conditions_un]]/condition\[@n='CONTACT'\]/group"
    set xp_slave  "[spdAux::getRoute [write::GetConfigurationAttribute nodal_conditions_un]]/condition\[@n='CONTACT_SLAVE'\]/group"

    # Get the groups
    set master_group [$root selectNodes $xp_master]
    set slave_group [$root selectNodes $xp_slave]

    if {[llength $master_group] > 1 || [llength $slave_group] > 1} {error "Max 1 group allowed in contact master and slave"}

    set contact_process_dict [dict create ]
    dict set contact_process_dict python_module alm_contact_process
    dict set contact_process_dict kratos_module "KratosMultiphysics.ContactStructuralMechanicsApplication"
    dict set contact_process_dict process_name ALMContactProcess

    set contact_parameters_dict [dict create]
    set model_part_name [write::GetConfigurationAttribute model_part_name]
    dict set contact_parameters_dict model_part_name $model_part_name

    set print_contact [dict create]
    foreach pair [dict keys [dict get $ContactsDict Masters]] {
        set merge [list ]
        if {[dict exists $ContactsDict Slaves $pair]} {
            set merge [dict get $ContactsDict Slaves $pair]
        }
        lappend merge {*}[dict get $ContactsDict Masters $pair]
        dict set print_contact $pair $merge
    }
    dict set contact_parameters_dict contact_model_part $print_contact

    set val [dict get $ContactsDict Slaves]
    dict set contact_parameters_dict assume_master_slave $val

    dict set contact_parameters_dict contact_type [write::getValue STContactParams contact_type]
    
    dict set contact_process_dict Parameters $contact_parameters_dict

    return [list $contact_process_dict]
}

proc Structural::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]

}

# Project Parameters
proc Structural::write::getParametersDict { } {
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
    write::WriteJSON [::Structural::write::getParametersDict]
}

proc Structural::write::UsingRotationDofElements { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [write::GetConfigurationAttribute parts_un]]/group/value\[@n='Element'\]"
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
    set xp1 "[spdAux::getRoute [write::GetConfigurationAttribute parts_un]]/group/value\[@n='Element'\]"
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
