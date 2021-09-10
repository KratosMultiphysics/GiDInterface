namespace eval StenosisWizard::write {

}

proc StenosisWizard::write::Init { } {
    
}


proc StenosisWizard::write::writeCustomFilesEvent { } {
    ::Fluid::write::writeCustomFilesEvent
    ::Fluid::write::SetAttribute main_launch_file [StenosisWizard::GetAttribute main_launch_file]
}

# MDPA Blocks
proc StenosisWizard::write::writeModelPartEvent { } {
    Fluid::write::AddValidApps StenosisWizard
    write::writeAppMDPA Fluid
}

# Project Parameters
proc StenosisWizard::write::writeParametersEvent { } {
    set project_parameters_dict [::Fluid::write::getParametersDict]
    write::WriteJSON $project_parameters_dict
}
