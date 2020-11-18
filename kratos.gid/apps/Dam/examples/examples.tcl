namespace eval Dam::examples {

}

proc Dam::examples::Init { } {
    uplevel #0 [list source [file join $::Dam::dir examples ThermoMechaDam2D.tcl]]
    uplevel #0 [list source [file join $::Dam::dir examples ThermoMechaDam3D.tcl]]
}

proc ::Dam::examples::ThermoMechaDam { } {
    #W $::Model::SpatialDimension 
    if {$::Model::SpatialDimension eq "2D"} {
        ::Dam::examples::ThermoMechaDam2D
    } {
        ::Dam::examples::ThermoMechaDam3D
    }
}

Dam::examples::Init
