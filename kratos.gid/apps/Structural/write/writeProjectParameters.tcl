# Project Parameters

proc ::Structural::write::getOldParametersDict { {stage ""} } {
    set model_part_name [GetAttribute model_part_name]
    set projectParametersDict [dict create]

    # Problem data
    # Create section
    set problemDataDict [write::GetDefaultProblemDataDict [::Structural::GetAttribute id]]

    set solutiontype [write::getValue STSoluType]

    # Time Parameters
    set timeSteppingDict [dict create]
    set enable_dynamic_substepping [::Structural::GetWriteProperty "enable_dynamic_substepping"]
    if {[write::isBooleanFalse $enable_dynamic_substepping] || ($solutiontype eq "Static" || $solutiontype eq "eigen_value")} {
        set time_step "1.1"
        dict set problemDataDict start_time "0.0"
        dict set problemDataDict end_time "1.0"

        # Time stepping settings for static
        dict set timeSteppingDict time_step $time_step

    } {
        set time_step_table [write::GetTimeStepIntervals]

        # Time stepping settings for dynamic
        dict set timeSteppingDict time_step_table $time_step_table
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
        dict set params "file_format" "gid"
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
        dict set params "print_mdpa" [write::getValue STResults print_prestress]
        dict set params "print_prestress" [write::getValue STResults print_mdpa]
        dict set params "read_prestress" [Structural::write::UsingFileInPrestressedMembrane]
        dict set formfinding_process_dict "Parameters" $params
    }

    # TODO: Use default
    # Solution strategy
    set solverSettingsDict [dict create]
    # Time stepping
    dict set solverSettingsDict time_stepping $timeSteppingDict
    set currentStrategyId [write::getValue STSolStrat]
    # set strategy_write_name [[::Model::GetSolutionStrategy $currentStrategyId] getAttribute "n"]
    set solver_type_name $solutiontype
    if {$solutiontype eq "Quasi-static"} {set solver_type_name "Static"}
    dict set solverSettingsDict solver_type $solver_type_name
    dict set solverSettingsDict model_part_name $model_part_name
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set solverSettingsDict domain_size $nDim
    dict set solverSettingsDict echo_level [write::getValue STResults EchoLevel]
    dict set solverSettingsDict analysis_type [write::getValue STAnalysisType]

    if {$solutiontype eq "Dynamic"} {
        dict set solverSettingsDict time_integration_method [write::getValue STSolStrat]
        dict set solverSettingsDict scheme_type [write::getValue STScheme]
    }

    # Model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename [Kratos::GetModelName]
    dict set solverSettingsDict model_import_settings $modelDict

    set materialsDict [dict create]
    dict set materialsDict materials_filename [GetAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    # Solution strategy parameters and Solvers
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict STSolStrat STScheme STStratParams] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Structural] ]

    if {[write::getValue STAnalysisType] ne "non_linear"} {
        dict unset solverSettingsDict use_old_stiffness_in_first_iteration
    }
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

    if {[usesContact]} {
        # Mirar type y ver si es Frictionless o Frictional
        dict set solverSettingsDict contact_settings mortar_type "ALMContactFrictionlessComponents"

        set convergence_criterion [dict get $solverSettingsDict convergence_criterion]
        dict set solverSettingsDict convergence_criterion "contact_$convergence_criterion"
    }

    dict set projectParametersDict solver_settings $solverSettingsDict

    # Lists of processes
    set processesDict [dict create]

    set initial_conditions_list_raw [write::getConditionsParametersDict [GetAttribute initial_conditions_un] "Nodal"]
    set initial_conditions_list [list ]
    foreach process $initial_conditions_list_raw {
        if {[dict exists $process Parameters constrained]} {
            if {[llength [dict get $process Parameters constrained]] == 1} {dict set process Parameters constrained false}
            if {[llength [dict get $process Parameters constrained]] == 3} {dict set process Parameters constrained [list false false false]}
        }
        lappend initial_conditions_list $process
    }
    set nodal_conditions_list [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    dict set processesDict constraints_process_list [concat $initial_conditions_list $nodal_conditions_list]
    if {[usesContact]} {
        set contact_conditions_dict [GetContactConditionsDict]
        dict set processesDict contact_process_list $contact_conditions_dict
    }
    dict set processesDict loads_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]

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
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict [::Structural::GetAttribute id]]

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
        dict set projectParametersDict solver_settings builder_and_solver_settings use_block_builder false
    }

    return $projectParametersDict
}

proc ::Structural::write::GetContactConditionsDict { {stage ""} } {
    variable ContactsDict
    set root [customlib::GetBaseRoot]

    # Prepare the xpaths
    set xp_master "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT'\]/group"
    set xp_slave  "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT_SLAVE'\]/group"

    # Get the groups
    set master_group [$root selectNodes $xp_master]
    set slave_group [$root selectNodes $xp_slave]

    set contacts [list ]

    #if {[llength $master_group] > 1 || [llength $slave_group] > 1} {error "Max 1 group allowed in contact master and slave"}

    set contact_process_dict [dict create ]
    dict set contact_process_dict python_module alm_contact_process
    dict set contact_process_dict kratos_module "KratosMultiphysics.ContactStructuralMechanicsApplication"
    dict set contact_process_dict process_name ALMContactProcess

    set contact_parameters_dict [dict create]
    set model_part_name [GetAttribute model_part_name]
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

    lappend contacts $contact_process_dict

    return $contacts
}

proc ::Structural::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]

}

# Project Parameters
proc ::Structural::write::getParametersDict { {stage ""} } {
    # Get the base dictionary for the project parameters
    set project_parameters_dict [getOldParametersDict $stage]

    # Analysis stage field
    dict set project_parameters_dict analysis_stage "KratosMultiphysics.StructuralMechanicsApplication.structural_mechanics_analysis"

    # If using any element with specific DOFs attribute set to true
    dict set project_parameters_dict solver_settings rotation_dofs [UsingSpecificDofElements RotationDofs $stage]
    dict set project_parameters_dict solver_settings strain_dofs [UsingSpecificDofElements StrainDofs $stage]
    dict set project_parameters_dict solver_settings volumetric_strain_dofs [UsingSpecificDofElements VolumetricStrainDofs $stage]

    # Merging the old solver_settings with the common one for this app
    set solverSettingsDict [dict get $project_parameters_dict solver_settings]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Structural] ]
    dict set project_parameters_dict solver_settings $solverSettingsDict

    return $project_parameters_dict
}
proc ::Structural::write::writeParametersEvent { } {
    write::WriteJSON [::Structural::write::getParametersDict]
}

proc ::Structural::write::UsingSpecificDofElements { SpecificDof {stage ""} } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un] $stage]/condition/group/value\[@n='Element'\]"
    set elements [$root selectNodes $xp1]
    set bool false
    foreach element_node $elements {
        set elemid [write::getValueByNode $element_node]
        set elem [Model::getElement $elemid]
        if {[write::isBooleanTrue [$elem getAttribute $SpecificDof]]} {set bool true; break}
    }

    return $bool
}

proc ::Structural::write::UsingFileInPrestressedMembrane { {stage ""} } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un] $stage]/condition/group/value\[@n='Element'\]"
    set elements [$root selectNodes $xp1]
    set found false
    foreach element_node $elements {
        set elemid [write::getValueByNode $element_node]
        if {$elemid eq "PrestressedMembraneElement"} {
            set selector [write::getValueByNode [$element_node selectNodes "../value\[@n = 'PROJECTION_TYPE_COMBO'\]"]]
            if {$selector eq "file"} {set found true; break}
        }
    }

    return $found
}
