namespace eval ::Structural::examples::MeshCantileverTest {
    namespace path ::Structural::examples
    Kratos::AddNamespace [namespace current]

}

proc ::Structural::examples::MeshCantileverTest::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    
    Kratos::LoadWizardFiles
    uplevel #0 [list source [file join $::Structural::dir examples MeshCantileverWizard Wizard_steps.tcl]]
    smart_wizard::LoadWizardDoc [file join $::Structural::dir examples MeshCantileverWizard Wizard_default.wiz]
    smart_wizard::ImportWizardData

    after 600 [::Structural::examples::MeshCantileverTest::StartWizardWindow]
}


proc ::Structural::examples::MeshCantileverTest::StartWizardWindow { } {
    variable dir
    gid_groups_conds::close_all_windows
    
    smart_wizard::Init
    smart_wizard::SetWizardNamespace "::Structural::examples::MeshCantileverTest::Wizard"
    smart_wizard::SetWizardWindowName ".gid.activewizard"
    smart_wizard::SetWizardImageDirectory [file join $::Structural::dir images]
    smart_wizard::LoadWizardDoc [file join $::Structural::dir examples MeshCantileverWizard Wizard_default.wiz]
    smart_wizard::ImportWizardData
    smart_wizard::CreateWindow 
}
