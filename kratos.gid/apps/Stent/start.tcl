namespace eval ::Stent {
    # Variable declaration
    variable dir
    variable app_id
}

proc ::Stent::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    set dir [apps::getMyDir "Stent"]
    set _app $app
        
    spdAux::processIncludes
    
    smart_wizard::LoadWizardDoc [file join $dir wizard StentGeometry_default.wiz]
    smart_wizard::ImportWizardData

    Stent::xml::Init
    Stent::write::Init

}

proc ::Stent::StartWizardWindow { } {
    variable dir
    #gid_groups_conds::close_all_windows
    
    smart_wizard::Init
    smart_wizard::SetWizardNamespace "::Stent::Wizard"
    smart_wizard::SetWizardWindowName ".gid.activewizard"
    smart_wizard::SetWizardImageDirectory [file join $dir images]
    smart_wizard::LoadWizardDoc [file join $dir wizard StentGeometry_default.wiz]
    smart_wizard::ImportWizardData

    smart_wizard::CreateWindow
}

proc ::Stent::CustomToolbarItems { } {
    variable dir
    
    Kratos::ToolbarAddItem "Generator" "example.png" [list -np- ::Stent::StartWizardWindow] [= "Geometry generator"]
}

proc ::Stent::BeforeMeshGeneration { size } { 
    ::Structural::BeforeMeshGeneration $size
}
