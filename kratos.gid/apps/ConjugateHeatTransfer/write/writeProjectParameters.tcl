# Project Parameters
proc ::ConjugateHeatTransfer::write::getParametersDict { } {
    InitExternalProjectParameters

    set projectParametersDict [dict create]

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

    return $projectParametersDict

}

proc ConjugateHeatTransfer::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

proc ConjugateHeatTransfer::write::GetSolverSettingsDict {} {
    set solver_settings_dict [dict create]
    dict set solver_settings_dict solver_type "conjugate_heat_transfer"
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solver_settings_dict domain_size $nDim
    dict set solver_settings_dict echo_level 0

    set filename [Kratos::GetModelName]

    # Prepare the solver strategies
    # Buoyancy Fluid > model_import_settings -> mdpa fluid
    dict set ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings fluid_solver_settings model_import_settings input_filename "${filename}_[GetAttribute fluid_mdpa_suffix]"
    # Buoyancy Thermic > model_import_settings -> none
    dict set ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings thermal_solver_settings model_import_settings input_filename "use_input_model_part"
    dict unset ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings thermal_solver_settings model_import_settings input_type
    # Buoyancy Thermic > model_part_name
    dict set ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings thermal_solver_settings model_part_name "FluidThermalModelPart"
    # Solid Thermic > Modelpart name -> mdpa solid
    dict set ConjugateHeatTransfer::write::solid_domain_solver_settings solver_settings model_import_settings input_filename "${filename}_[GetAttribute solid_mdpa_suffix]"

    dict set solver_settings_dict fluid_domain_solver_settings [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings]
    dict set solver_settings_dict solid_domain_solver_settings thermal_solver_settings [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings solver_settings]

    # Coupling settings
    set solid_interfaces_list [write::GetSubModelPartFromCondition CNVDFFBC SolidThermalInterface$::Model::SpatialDimension]
    set fluid_interfaces_list [write::GetSubModelPartFromCondition Buoyancy_CNVDFFBC FluidThermalInterface$::Model::SpatialDimension]

    set coupling_settings [dict create]
    dict set coupling_settings max_iteration [write::getValue CHTGeneralParameters max_iteration]
    dict set coupling_settings temperature_relative_tolerance  [write::getValue CHTGeneralParameters temperature_relative_tolerance]
    dict set coupling_settings fluid_interfaces_list $fluid_interfaces_list
    dict set coupling_settings solid_interfaces_list $solid_interfaces_list
    dict set solver_settings_dict coupling_settings $coupling_settings

    return $solver_settings_dict
}

proc ConjugateHeatTransfer::write::GetProcessList { } {
    set processes [dict create]

    # Get and add fluid processes
    dict set processes fluid_constraints_process_list [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings processes constraints_process_list]

    # Get and add solid processes
    dict set processes solid_initial_conditions_process_list [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings processes initial_conditions_process_list]
    dict set processes solid_constraints_process_list [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings processes constraints_process_list]
    dict set processes solid_list_other_processes [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings processes list_other_processes]

    return $processes
}
proc ConjugateHeatTransfer::write::GetOutputProcessesList { } {
    set output_process [dict create]
    set gid_output_list [list]

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

    return $output_process
}

proc ConjugateHeatTransfer::write::InitExternalProjectParameters { } {
    # Buoyancy section
    apps::setActiveAppSoft Buoyancy
    write::initWriteConfiguration [Buoyancy::write::GetAttributes]
    ConvectionDiffusion::write::SetAttribute nodal_conditions_un Buoyancy_CNVDFFNodalConditions
    ConvectionDiffusion::write::SetAttribute conditions_un Buoyancy_CNVDFFBC
    ConvectionDiffusion::write::SetAttribute thermal_bc_un Buoyancy_CNVDFFBC
    ConvectionDiffusion::write::SetAttribute model_part_name FluidThermalModelPart
    set ConjugateHeatTransfer::write::fluid_domain_solver_settings [Buoyancy::write::getParametersDict]

    # Heating section
    apps::setActiveAppSoft ConvectionDiffusion
    ConvectionDiffusion::write::SetAttribute nodal_conditions_un CNVDFFNodalConditions
    ConvectionDiffusion::write::SetAttribute conditions_un CNVDFFBC
    ConvectionDiffusion::write::SetAttribute model_part_name ThermalModelPart
    ConvectionDiffusion::write::SetAttribute thermal_bc_un CNVDFFBC
    write::initWriteConfiguration [ConvectionDiffusion::write::GetAttributes]
    set ConjugateHeatTransfer::write::solid_domain_solver_settings [ConvectionDiffusion::write::getParametersDict]

    apps::setActiveAppSoft ConjugateHeatTransfer
}