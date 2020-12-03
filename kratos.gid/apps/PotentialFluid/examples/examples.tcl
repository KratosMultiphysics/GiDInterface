namespace eval PotentialFluid::examples {

}

proc PotentialFluid::examples::Init { } {
    uplevel #0 [list source [file join $::PotentialFluid::dir examples NACA0012.tcl]]
}

PotentialFluid::examples::Init