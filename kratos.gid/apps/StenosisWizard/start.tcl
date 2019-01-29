namespace eval ::StenosisWizard {
    # Variable declaration
    variable dir
    variable kratos_name
    variable attributes
}

proc ::StenosisWizard::Init { } {
    # Variable initialization
    variable dir
    variable kratos_name
    variable attributes
    
    # Init Working directory
    set dir [apps::getMyDir "StenosisWizard"]
    # We'll work on 3D space
    spdAux::SetSpatialDimmension "3D"
    # Load Fluid App
    apps::LoadAppById "Fluid"
    set kratos_name $::Fluid::kratos_name
    # Don't open the tree
    set ::spdAux::TreeVisibility 0

    dict set attributes UseIntervals 1
    
    # Enable the Wizard Module
    Kratos::LoadWizardFiles
    LoadMyFiles
}

proc ::StenosisWizard::LoadMyFiles { } {
    variable dir
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    smart_wizard::LoadWizardDoc [file join $dir wizard Wizard_default.wiz]
    uplevel #0 [list source [file join $dir wizard Wizard_Steps.tcl]]
    smart_wizard::ImportWizardData
    
    
    # Init the Wizard Window
    after 600 [::StenosisWizard::StartWizardWindow]
}


proc ::StenosisWizard::StartWizardWindow { } {
    variable dir
    gid_groups_conds::close_all_windows
    
    smart_wizard::Init
    uplevel #0 [list source [file join $dir wizard Wizard_Steps.tcl]]
    smart_wizard::SetWizardNamespace "::StenosisWizard::Wizard"
    smart_wizard::SetWizardWindowName ".gid.activewizard"
    smart_wizard::SetWizardImageDirectory [file join $dir images]
    smart_wizard::LoadWizardDoc [file join $dir wizard Wizard_default.wiz]
    smart_wizard::ImportWizardData

    smart_wizard::CreateWindow
}
proc ::StenosisWizard::CustomToolbarItems { } {
    return "-1"    
}
proc ::StenosisWizard::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

::StenosisWizard::Init
