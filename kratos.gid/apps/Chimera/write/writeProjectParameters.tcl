# Project Parameters
proc ::Chimera::write::getParametersDict { } {
    set param_dict [Fluid::write::getParametersDict]

    return $param_dict
}

proc Chimera::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
