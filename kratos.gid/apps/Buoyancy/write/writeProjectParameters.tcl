# Project Parameters
proc ::Buoyancy::write::getParametersDict { } {
    set projectParametersDict [dict create]

    return $projectParametersDict
}

proc Buoyancy::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

