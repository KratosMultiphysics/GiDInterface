# Project Parameters
proc ::FreeSurface::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # # Analysis stage field
    # dict set projectParametersDict analysis_stage "KratosMultiphysics.ConvectionDiffusionApplication.convection_diffusion_analysis"

    # # problem data
    # dict set projectParametersDict problem_data [::FreeSurface::write::GetProblemData_Dict]

    # # output configuration
    # dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict]

    # # restart options
    # dict set projectParametersDict restart_options [FreeSurface::write::GetRestart_Dict]

    # # solver settings
    # dict set projectParametersDict solver_settings [FreeSurface::write::GetSolverSettings_Dict]

    # # processes
    # dict set projectParametersDict processes [FreeSurface::write::GetProcesses_Dict]

    return $projectParametersDict
}

proc ::FreeSurface::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
