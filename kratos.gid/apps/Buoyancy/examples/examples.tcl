namespace eval Buoyancy::examples {

}

proc Buoyancy::examples::Init { } {
    uplevel #0 [list source [file join $::Buoyancy::dir examples HeatedSquare.tcl]]
}


Buoyancy::examples::Init