
proc ::PfemMelting::write::getParametersDict { } {
    return [::Buoyancy::write::getParametersDict]
}

proc ::PfemMelting::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
