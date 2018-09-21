# Project Parameters
proc ::DEMPFEM::write::getParametersDict { } {
    set projectParametersDict [DEM::write::getParametersEvent]
    dict set projectParametersDict PizzaType [write::getValue DEMPFEM_CouplingParameters PizzaType]
    return $projectParametersDict
}

proc DEMPFEM::write::writeParametersEvent { } {
    # DEM
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
    write::CloseFile
    write::RenameFileInModel ProjectParameters.json ProjectParametersDEM.json

    # PFEM
    write::OpenFile ProjectParameters.json
    PfemFluid::write::writeParametersEvent

}
