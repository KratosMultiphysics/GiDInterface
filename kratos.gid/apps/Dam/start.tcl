namespace eval ::Dam {
    # Variable declaration
    variable dir
    variable kratos_name
}

proc ::Dam::Init { } {
    # Variable initialization
    variable dir
    variable kratos_name
    set kratos_name "DamApplication"
    
    set dir [apps::getMyDir "Dam"]
    set ::Model::ValidSpatialDimensions [list 2D 3D]
    
    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    LoadMyFiles
    ::spdAux::CreateDimensionWindow
    
}

proc ::Dam::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $dir examples examples.tcl]]   
}

proc ::Dam::CustomToolbarItems { } {

    # Adding local image directory
    variable dir
    set img_dir [file join $dir images]

    # Getting spatial dimension
    set root [customlib::GetBaseRoot]
    set nd [ [$root selectNodes "value\[@n='nDim'\]"] getAttribute v]

    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::Dam::examples::ThermoMechaDam] [= "Example\nThemo-Mechanical Dam"]   
    if {([ExistsAcombo]) && ($nd == "3D")} {
        Kratos::ToolbarAddItem "SpacerApp" "" "" ""
        Kratos::ToolbarAddItem "Parabolic" [file join $img_dir "parabolic.png"] [list -np- ::Dam::LaunchParabolic] [= "Computer Aided\n Parabolic"]
        Kratos::ToolbarAddItem "Elliptical" [file join $img_dir "elliptical.png"] [list -np- ::Dam::LaunchElliptical] [= "Computer Aided\n Elliptical"]
    }
}
 
proc ::Dam::ExistsAcombo { } {
    set path [GidUtils::GiveProblemTypeFullname ACOMBO]
    if {[file isdirectory ${path}.gid]} {return 1} 
    return 0
}
 
proc ::Dam::LaunchParabolic { } {

    set scriptAtInvocation $::argv0
    exec $scriptAtInvocation -p ACOMBO -t "after 2000 {InputParab}"
    GiD_Process Mescape Files InsertGeom 
}

proc ::Dam::LaunchElliptical { } {

    set scriptAtInvocation $::argv0
    exec $scriptAtInvocation -p ACOMBO -t "after 2000 {InputElip}"
    GiD_Process Mescape Files InsertGeom 
}

::Dam::Init
