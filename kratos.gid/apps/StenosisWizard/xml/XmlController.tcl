namespace eval ::StenosisWizard::xml {
    namespace path ::StenosisWizard
    Kratos::AddNamespace [namespace current]
}

proc StenosisWizard::xml::Init { } {
    Model::InitVariables dir $::StenosisWizard::dir

    spdAux::processIncludes
}

proc StenosisWizard::xml::CustomTree {args} {
    
    spdAux::processIncludes
    Fluid::xml::CustomTree {*}$args
}

proc StenosisWizard::xml::getUniqueName {name} {
    return [::StenosisWizard::GetAttribute prefix]$name
}

proc ::StenosisWizard::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames FL StenWiz
    }
}
