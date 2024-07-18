# Project Parameters
proc ::FreeSurface::write::getParametersDict { } {
    set projectParametersDict [dict create]

    ::write::SetConfigurationAttribute model_part_name [::FreeSurface::write::GetModelPartName]

    # # Analysis stage field
    dict set projectParametersDict analysis_stage "KratosMultiphysics.FreeSurfaceApplication.free_surface_analysis"

    # # problem data
    dict set projectParametersDict problem_data [::Fluid::write::GetProblemData_Dict]

    # # output configuration
    ::write::SetConfigurationAttribute output_model_part_name [::FreeSurface::GetWriteProperty output_model_part_name]
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict [::Fluid::GetAttribute id]]

    # # restart options
    #dict set projectParametersDict restart_options [Fluid::write::GetRestart_Dict]

    # # solver settings
    dict set projectParametersDict solver_settings [FreeSurface::write::getSolverSettingsDict]

    # # processes
    dict set projectParametersDict processes [::Fluid::write::GetProcesses_Dict]

    set projectParametersDict [::write::GetModelersDict $projectParametersDict]

    return $projectParametersDict
}

proc ::FreeSurface::write::getSolverSettingsDict { } {
    set solverSettingsDict [dict create]
    # model_part_name
    dict set solverSettingsDict model_part_name [::FreeSurface::write::GetModelPartName]

    # domain_size
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solverSettingsDict domain_size $nDim

    # solver_type
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

    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict FLSolStrat FLScheme FLStratParams] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Fluid] ]

    return $solverSettingsDict
}

proc ::FreeSurface::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
