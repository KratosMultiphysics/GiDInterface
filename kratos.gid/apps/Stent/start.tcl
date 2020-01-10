namespace eval ::Stent {
    # Variable declaration
    variable dir
    variable app_id
}

proc ::Stent::Init { } {
    # Variable initialization
    variable dir
    variable attributes
    variable kratos_name
    variable app_id

    if {[GiDVersionCmp 14.1.3d] < 0} {
        W "Minimum GiD version recommended 14.1.3d"
        W "Download it at https://www.gidhome.com/download/developer-versions/"
    }

    set app_id Stent
    set dir [apps::getMyDir "Stent"]

    # We'll work on 3D space
    spdAux::SetSpatialDimmension "3D"
    # Load Fluid App
    apps::LoadAppById "Structural"
    
    spdAux::processIncludes
    set attributes [dict create]
    
    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    
    # Intervals 
    dict set attributes UseIntervals 1
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {dict set attributes UseIntervals 1}
    
    set kratos_name StructuralMechanicsApplication
    
    # Enable the Wizard Module
    Kratos::LoadWizardFiles
    LoadMyFiles
}

proc ::Stent::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]

    
    smart_wizard::LoadWizardDoc [file join $dir wizard StentGeometry_default.wiz]
    uplevel #0 [list source [file join $dir wizard StentGeometry.tcl]]
    smart_wizard::ImportWizardData
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


::Stent::Init
