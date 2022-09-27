# Project Parameters
proc ::PfemSw::write::getParametersDict { } {
    set projectParametersDict [dict create]

    return $projectParametersDict
}

proc ::PfemSw::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    InitExternalProjectParameters
    write::WriteJSON $PfemSw::write::pfem_project_parameters
    write::WriteJSON $PfemSw::write::sw_project_parameters
}

proc ::PfemSw::write::GetProcessesDict { } {
    set processes_dict [dict create]

    return $processes_dict
}

proc ::PfemSw::write::GetOutputProcessesDict { } {
    set output_processes_dict [dict create]

    return $output_processes_dict
}

proc ::PfemSw::write::UpdateUniqueNames { appid } {
    set unList [list "Results"]
    foreach un $unList {
        set current_un [apps::getAppUniqueName $appid $un]
        spdAux::setRoute $un [spdAux::getRoute $current_un]
    }
}

proc ::PfemSw::write::InitExternalProjectParameters { } {
    # Pfem Fluid section
    UpdateUniqueNames PfemFluid
    apps::setActiveAppSoft PfemFluid
    set PfemSw::write::pfem_project_parameters [PfemFluid::write::getParametersDict]

    # Shallow water section
    UpdateUniqueNames ShallowWater
    apps::setActiveAppSoft ShallowWater
    set PfemSw::write::sw_project_parameters [ShallowWater::write::getParametersDict]

    apps::setActiveAppSoft PfemSw
}