namespace eval ::StenosisWizard {
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::StenosisWizard::Init { app } {
    # Variable initialization
    variable dir
    variable _app $app
    
    set  must_open_wizard_window 1
    
    # Init Working directory
    set dir [apps::getMyDir "StenosisWizard"]
        
    spdAux::processIncludes
    
    smart_wizard::LoadWizardDoc [file join $dir wizard Wizard_default.wiz]
    smart_wizard::ImportWizardData

    
    StenosisWizard::xml::Init
    StenosisWizard::write::Init
    
    # Init the Wizard Window
    after 600 [::StenosisWizard::StartWizardWindow]
}

proc ::StenosisWizard::StartWizardWindow { } {
    variable dir
    gid_groups_conds::close_all_windows
    
    smart_wizard::Init
    smart_wizard::SetWizardNamespace "::StenosisWizard::Wizard"
    smart_wizard::SetWizardWindowName ".gid.activewizard"
    smart_wizard::SetWizardImageDirectory [file join $dir images]
    smart_wizard::LoadWizardDoc [file join $dir wizard Wizard_default.wiz]
    smart_wizard::ImportWizardData
    smart_wizard::CreateWindow 
}
