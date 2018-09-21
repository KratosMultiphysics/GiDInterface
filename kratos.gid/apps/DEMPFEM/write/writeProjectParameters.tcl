# Project Parameters
proc ::DEMPFEM::write::getParametersDict { } {
    set projectParametersDict [dict create]

    return $projectParametersDict
}

proc DEMPFEM::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
