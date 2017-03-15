
proc PotentialFluid::write::writeParametersEvent { } {
    set projectParametersDict [Fluid::write::getParametersDict]
    
    set projectParametersDict [dict remove $projectParametersDict gravity]
    set projectParametersDict [dict remove $projectParametersDict auxiliar_process_list]
    set solverDict [dict get $projectParametersDict solver_settings]
    set solverDict [dict remove $solverDict time_stepping]
    dict set projectParametersDict solver_settings $solverDict
    
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
