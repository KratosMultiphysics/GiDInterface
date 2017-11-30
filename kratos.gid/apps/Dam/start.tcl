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

    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::Dam::examples::ThermoMechaDam] [= "Example\nThemo-Mechanical Dam"]   
    if {[ExistsAcombo]} {
        Kratos::ToolbarAddItem "Parabolic" "example.png" [list -np- ::Dam::LaunchParabolic] [= "Computer Aided\n Parabolic"]
        Kratos::ToolbarAddItem "Elliptical" "example.png" [list -np- ::Dam::LaunchElliptical] [= "Computer Aided\n Elliptical"]
    }
}
 
proc ::Dam::ExistsAcombo { } {
    set path [GidUtils::GiveProblemTypeFullname ACOMBO]
    if {[file isdirectory ${path}.gid]} {return 1} 
    return 0
}
 
proc ::Dam::LaunchParabolic { } {

    exec GiDx64/13.1.7d/gid -p ACOMBO -t "after 2000 {InputParab}"
    GiD_Process Mescape Files InsertGeom 
}

proc ::Dam::LaunchElliptical { } {

    exec GiDx64/13.1.7d/gid -p ACOMBO -t "after 2000 {InputElip}"
    GiD_Process Mescape Files InsertGeom 
}

::Dam::Init
