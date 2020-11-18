namespace eval ConvectionDiffusion::examples {

}

proc ConvectionDiffusion::examples::Init { } {
    uplevel #0 [list source [file join $::ConvectionDiffusion::dir examples HeatedSquare.tcl]]
}

ConvectionDiffusion::examples::Init