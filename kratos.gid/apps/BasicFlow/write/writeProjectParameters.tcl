# Project Parameters
proc ::BasicFlow::write::getParametersDict { {stage ""} } {
    set projectParametersDict [dict create]

    

    return $projectParametersDict
}

proc ::BasicFlow::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::WriteJSON $projectParametersDict
}
