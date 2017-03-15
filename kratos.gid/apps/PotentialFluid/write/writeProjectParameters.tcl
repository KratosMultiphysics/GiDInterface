
proc PotentialFluid::write::writeParametersEvent { } {
    set projectParametersDict [Fluid::write::getParametersDict]
    
    set projectParametersDict [dict remove $projectParametersDict gravity]
    set projectParametersDict [dict remove $projectParametersDict auxiliar_process_list]
    set projectParametersDict [dict remove $projectParametersDict solver_settings time_stepping]
    
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
