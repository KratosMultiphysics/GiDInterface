
proc PotentialFluid::write::writeParametersEvent { } {
    set projectParametersDict [Fluid::write::getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
