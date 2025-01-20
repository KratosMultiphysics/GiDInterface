# Project Parameters
proc ::ConjugateHeatTransfer::write::getParametersDict { } {
    InitExternalProjectParameters

    set projectParametersDict [dict create]

    # Analysis stage field
    dict set projectParametersDict analysis_stage "KratosMultiphysics.ConvectionDiffusionApplication.convection_diffusion_analysis"

    # Set the problem data section
    dict set projectParametersDict problem_data [write::GetDefaultProblemDataDict]

    # Solver settings
    dict set projectParametersDict solver_settings [ConjugateHeatTransfer::write::GetSolverSettingsDict]

    # output processes
    dict set projectParametersDict output_processes [ConjugateHeatTransfer::write::GetOutputProcessesList]

    # Restart options
    dict set projectParametersDict restart_options [write::GetDefaultRestartDict]

    # processes
    dict set projectParametersDict processes [ConjugateHeatTransfer::write::GetProcessList]

    # modelers
    set projectParametersDict [::write::GetModelersDict $projectParametersDict]
    set projectParametersDict [::ConjugateHeatTransfer::write::PlaceMDPAImports $projectParametersDict]
    set projectParametersDict [::ConjugateHeatTransfer::write::ModelersPrefix $projectParametersDict]

    dict unset projectParametersDict solver_settings model_import_settings

    return $projectParametersDict
}

proc ::ConjugateHeatTransfer::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

proc ::ConjugateHeatTransfer::write::GetSolverSettingsDict {} {
    set solver_settings_dict [dict create]
    dict set solver_settings_dict solver_type "conjugate_heat_transfer"
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solver_settings_dict domain_size $nDim
    dict set solver_settings_dict echo_level 0

    set filename [Kratos::GetModelName]

    # Prepare the solver strategies
    dict unset ConjugateHeatTransfer::write::fluid_domain_solver_settings model_import_settings
    # Buoyancy Thermic > model_part_name
    dict set ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings thermal_solver_settings model_part_name "FluidThermalModelPart"
    
    dict set solver_settings_dict fluid_domain_solver_settings [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings]
    dict set solver_settings_dict solid_domain_solver_settings thermal_solver_settings [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings solver_settings]

    # Coupling settings
    set solid_interfaces_list_raw [write::GetSubModelPartFromCondition CNVDFFBC SolidThermalInterface$::Model::SpatialDimension]
    set fluid_interfaces_list_raw [write::GetSubModelPartFromCondition Buoyancy_CNVDFFBC FluidThermalInterface$::Model::SpatialDimension]
    foreach solid_interface $solid_interfaces_list_raw {lappend solid_interfaces_list [join [list ThermalModelPart $solid_interface] "."]}
    foreach fluid_interface $fluid_interfaces_list_raw {lappend fluid_interfaces_list [join [list FluidThermalModelPart $fluid_interface] "."]}

    set coupling_settings [dict create]
    dict set coupling_settings max_iteration [write::getValue CHTGeneralParameters max_iteration]
    dict set coupling_settings temperature_relative_tolerance  [write::getValue CHTGeneralParameters temperature_relative_tolerance]
    dict set coupling_settings fluid_interfaces_list $fluid_interfaces_list
    dict set coupling_settings solid_interfaces_list $solid_interfaces_list
    dict set solver_settings_dict coupling_settings $coupling_settings

    dict unset solver_settings_dict fluid_domain_solver_settings model_import_settings
    
    return $solver_settings_dict
}

proc ::ConjugateHeatTransfer::write::GetProcessList { } {
    set processes [dict create]

    # Get and add fluid processes
    set fluid_constraints_process_list [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings processes constraints_process_list]
    dict set processes fluid_constraints_process_list [::ConjugateHeatTransfer::write::TransformFluidProcess $fluid_constraints_process_list]

    # Get and add solid processes
    dict set processes solid_initial_conditions_process_list [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings processes initial_conditions_process_list]
    dict set processes solid_constraints_process_list [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings processes constraints_process_list]
    dict set processes solid_list_other_processes [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings processes list_other_processes]

    return $processes
}

proc ::ConjugateHeatTransfer::write::GetOutputProcessesList { } {
    set output_process [dict create]

    set need_gid [write::getValue EnableGiDOutput]
    if {[write::isBooleanTrue $need_gid]} {
        # Set a different output_name for the fluid and solid domains
        set fluid_output [lindex [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings output_processes gid_output] 0]
        dict set fluid_output Parameters output_name "[dict get $fluid_output Parameters output_name]_fluid"
        set solid_output [lindex [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings output_processes gid_output] 0]
        dict set solid_output Parameters output_name "[dict get $solid_output Parameters output_name]_solid"

        set solid_nodal_variables [dict get $solid_output Parameters postprocess_parameters result_file_configuration nodal_results]
        set valid_list [list ]
        foreach solid_nodal_variable $solid_nodal_variables {
            if {$solid_nodal_variable in [list "TEMPERATURE"]} {
                lappend valid_list $solid_nodal_variable
            }
        }
        dict set solid_output Parameters postprocess_parameters result_file_configuration nodal_results $valid_list

        # Append the fluid and solid output processes to the output processes list
        lappend gid_output_processes_list $fluid_output
        lappend gid_output_processes_list $solid_output
        dict set output_process gid_output_processes $gid_output_processes_list
    }

    set need_vtk [write::getValue EnableVtkOutput]
    if {[write::isBooleanTrue $need_vtk]} {
    # Set a different output_name for the fluid and solid domains
        set fluid_output [lindex [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings output_processes vtk_output] 0]
        set solid_output [lindex [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings output_processes vtk_output] 0]

        set solid_nodal_variables [dict get $solid_output Parameters nodal_solution_step_data_variables]
        set valid_list [list ]
        foreach solid_nodal_variable $solid_nodal_variables {
            if {$solid_nodal_variable in [list "TEMPERATURE"]} {
                lappend valid_list $solid_nodal_variable
            }
        }
        dict set solid_output Parameters nodal_solution_step_data_variables $valid_list

        # Append the fluid and solid output processes to the output processes list
        lappend vtk_output_processes_list $fluid_output
        lappend vtk_output_processes_list $solid_output
        dict set output_process vtk_output_processes $vtk_output_processes_list
    }

    return $output_process
}

proc ::ConjugateHeatTransfer::write::InitExternalProjectParameters { } {
    # Buoyancy section
    apps::setActiveAppSoft Buoyancy
    write::initWriteConfiguration [Buoyancy::write::GetAttributes]
    ::ConvectionDiffusion::write::SetAttribute nodal_conditions_un Buoyancy_CNVDFFNodalConditions
    ::ConvectionDiffusion::write::SetAttribute conditions_un Buoyancy_CNVDFFBC
    ::ConvectionDiffusion::write::SetAttribute thermal_bc_un Buoyancy_CNVDFFBC
    ::ConvectionDiffusion::write::SetAttribute model_part_name FluidThermalModelPart
    set ConjugateHeatTransfer::write::fluid_domain_solver_settings [Buoyancy::write::getParametersDict]

    # Heating section
    apps::setActiveAppSoft ConvectionDiffusion
    ::ConvectionDiffusion::write::SetAttribute nodal_conditions_un CNVDFFNodalConditions
    ::ConvectionDiffusion::write::SetAttribute conditions_un CNVDFFBC
    ::ConvectionDiffusion::write::SetAttribute model_part_name ThermalModelPart
    ::ConvectionDiffusion::write::SetAttribute thermal_bc_un CNVDFFBC
    write::initWriteConfiguration [ConvectionDiffusion::write::GetAttributes]
    set ConjugateHeatTransfer::write::solid_domain_solver_settings [ConvectionDiffusion::write::getParametersDict]

    apps::setActiveAppSoft ConjugateHeatTransfer
}

proc ::ConjugateHeatTransfer::write::PlaceMDPAImports { projectParametersDict } {
    variable mdpa_files

    set new_modelers [list]
    
    set modelers [dict get $projectParametersDict modelers]
    # remove the modelers that import the mdpa files (name = Modelers.KratosMultiphysics.ImportMDPAModeler)
    set modelers [lsearch -all -inline -not -glob $modelers *ImportMDPAModeler*]
    lappend new_modelers [dict create name "Modelers.KratosMultiphysics.ImportMDPAModeler" parameters [dict create input_filename [lindex $mdpa_files 0] model_part_name "FluidModelPart"]]
    lappend new_modelers [dict create name "Modelers.KratosMultiphysics.ImportMDPAModeler" parameters [dict create input_filename [lindex $mdpa_files 1] model_part_name "ThermalModelPart"]]
    lappend new_modelers [dict create name "Modelers.KratosMultiphysics.ConnectivityPreserveModeler" parameters [dict create origin_model_part_name "FluidModelPart" destination_model_part_name "FluidThermalModelPart"]]
    set modelers [concat $new_modelers $modelers]
    dict set projectParametersDict modelers $modelers
    return $projectParametersDict
}

proc ::ConjugateHeatTransfer::write::ModelersPrefix { projectParametersDict } {
    set modelers [dict get $projectParametersDict modelers]
    set new_modelers [list]
    set thermal_modelparts [dict get $projectParametersDict solver_settings solid_domain_solver_settings thermal_solver_settings processes_sub_model_part_list]
    # W "Thermal modelparts: $thermal_modelparts"
    foreach modeler $modelers {
        set name [dict get $modeler name]
        if {[string match "Modelers.KratosMultiphysics.CreateEntitiesFromGeometriesModeler" $name]} {
            set new_parameters [dict create]
            set new_modeler [dict create name $name parameters [dict create elements_list [dict create] conditions_list [dict create]]]
            set new_element_list [list ]
            foreach element [dict get $modeler parameters elements_list] {
                set model_part_name [dict get $element model_part_name]
                set raw_name [lindex [split $model_part_name "."] 1]

                if {$raw_name in $thermal_modelparts} {
                    set new_element $element
                    lappend new_element_list $new_element
                } else {
                    set new_element [dict create model_part_name "FluidModelPart.$raw_name" element_name [dict get $element element_name]]
                    set new_element2 [dict create model_part_name "FluidThermalModelPart.$raw_name" element_name [dict get $element element_name]]
                    lappend new_element_list $new_element
                    lappend new_element_list $new_element2
                }
                dict set new_parameters elements_list $new_element_list
            }
            set new_conditions_list [list ]
            foreach condition [dict get $modeler parameters conditions_list] {
                set model_part_name [dict get $condition model_part_name]
                set raw_name [lindex [split $model_part_name "."] 1]
                if {$raw_name in $thermal_modelparts} {
                    set new_condition $condition
                } else {
                    set new_condition [dict create model_part_name "FluidModelPart.$raw_name" condition_name [dict get $condition condition_name]]
                }
                lappend new_conditions_list $new_condition
                dict set new_parameters conditions_list $new_conditions_list
            }
            dict set new_modeler parameters $new_parameters
            set modeler $new_modeler
        }
        lappend new_modelers $modeler
    }
    dict set projectParametersDict modelers $new_modelers
    return $projectParametersDict
}

proc ::ConjugateHeatTransfer::write::TransformFluidProcess {fluid_constraints_process_list} {
    # Find any process with python_module = apply_thermal_face_process and change the Parameters.model_part_name to FluidThermalModelPart
    set new_fluid_constraints_process_list [list] 
    foreach process $fluid_constraints_process_list {
        set new_process $process
        if {[dict get $process python_module] == "apply_thermal_face_process"} {
            set old_name [dict get $process Parameters model_part_name]
            # old name is in the form FluidModelPart.XXX
            # new name is in the form FluidThermalModelPart.XXX
            set new_name "FluidThermalModelPart.[lindex [split $old_name "."] 1]"
            dict set new_process Parameters model_part_name $new_name
        }
        lappend new_fluid_constraints_process_list $new_process
    }
    return $new_fluid_constraints_process_list
}