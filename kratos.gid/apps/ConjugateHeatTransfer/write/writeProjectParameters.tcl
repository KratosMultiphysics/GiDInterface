# Project Parameters
proc ::ConjugateHeatTransfer::write::getParametersDict { } {
    InitExternalProjectParameters
    
    set projectParametersDict [dict create]

    # Set the problem data section
    dict set projectParametersDict problem_data [write::GetDefaultProblemDataDict]

    # Solver settings
    dict set projectParametersDict solver_settings [ConjugateHeatTransfer::write::GetSolverSettingsDict]

    # output processes
    dict set projectParametersDict output_processes [ConjugateHeatTransfer::write::GetOutputProcessList]

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
    
    dict set solver_settings_dict fluid_domain_solver_settings [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings]
    dict set solver_settings_dict solid_domain_solver_settings [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings solver_settings]
    
    return $solver_settings_dict
}

proc ConjugateHeatTransfer::write::GetProcessList { } {
    set output_process [dict create ]
    
    lappend fluid_output [lindex [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings output_processes gid_output] 0]
    dict set output_process fluid_output_processes $fluid_output

    lappend solid_output [lindex [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings output_processes gid_output] 0]
    dict set output_process solid_output_processes $solid_output
    
    return $output_process
}
proc ConjugateHeatTransfer::write::GetOutputProcessList { } {
    set output_process [dict create ]
    
    lappend fluid_output [lindex [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings output_processes gid_output] 0]
    dict set output_process fluid_output_processes $fluid_output

    lappend solid_output [lindex [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings output_processes gid_output] 0]
    dict set output_process solid_output_processes $solid_output
    
    return $output_process
}

proc ConjugateHeatTransfer::write::InitExternalProjectParameters { } {
    # Buoyancy section
    apps::setActiveAppSoft Buoyancy
    write::initWriteConfiguration [Buoyancy::write::GetAttributes]
    set ConjugateHeatTransfer::write::fluid_domain_solver_settings [Buoyancy::write::getParametersDict]

    # Heating section
    apps::setActiveAppSoft ConvectionDiffusion
    write::initWriteConfiguration [ConvectionDiffusion::write::GetAttributes]
    set ConjugateHeatTransfer::write::solid_domain_solver_settings [ConvectionDiffusion::write::getParametersDict]

    apps::setActiveAppSoft ConjugateHeatTransfer
}