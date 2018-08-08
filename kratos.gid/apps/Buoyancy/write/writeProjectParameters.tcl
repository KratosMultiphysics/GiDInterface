# Project Parameters
proc ::Buoyancy::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # problem data
    dict set projectParametersDict problem_data [::Buoyancy::write::GetProblemData_Dict]

    # output configuration
    dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]

    # restart options 
    dict set projectParametersDict restart_options [Buoyancy::write::GetRestart_Dict]

    # solver settings
    dict set projectParametersDict solver_settings [Buoyancy::write::GetSolverSettings_Dict]

    # processes
    dict set projectParametersDict processes [dict create]

    return $projectParametersDict
}

proc Buoyancy::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

proc Buoyancy::write::GetProblemData_Dict { } {
    set problemDataDict [dict create ]

    # problem name
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set problemDataDict problem_name $model_name

    # domain size
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set problemDataDict domain_size $nDim

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    dict set problemDataDict "parallel_type" $paralleltype

    # Time Parameters
    dict set problemDataDict start_time [write::getValue FLTimeParameters StartTime]
    dict set problemDataDict end_time [write::getValue FLTimeParameters EndTime]
}

proc Buoyancy::write::GetRestart_Dict { } {
    
    set restartDict [dict create]
    dict set restartDict SaveRestart False
    dict set restartDict RestartFrequency 0
    dict set restartDict LoadRestart False
    dict set restartDict Restart_Step 0
}

proc Buoyancy::write::GetSolverSettings_Dict { } {
    set settings [dict create]

    dict set settings solver_type "ThermallyCoupled"

    # domain size
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set settings domain_size $nDim

    # Fluid things
    dict set settings fluid_solver_settings [Fluid::write::getSolverSettingsDict]

    # Thermal things
    dict set settings thermal_solver_settings [ConvectionDiffusion::write::getSolverSettingsDict]

    return $settings
}