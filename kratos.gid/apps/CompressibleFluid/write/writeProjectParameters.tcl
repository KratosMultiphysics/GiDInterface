proc ::CompressibleFluid::write::writeParametersEvent { } {
    set projectParametersDict [Fluid::write::getParametersDict]
    set projectParametersDict [::write::GetModelersDict $projectParametersDict]

    set shock_capturing_type [dict get $projectParametersDict solver_settings shock_capturing_type]
    dict set projectParametersDict solver_settings shock_capturing_settings type $shock_capturing_type
    dict unset projectParametersDict solver_settings shock_capturing_type

    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
