namespace eval ConjugateHeatTransfer::examples {

}

proc ConjugateHeatTransfer::examples::Init { } {
    uplevel #0 [list source [file join $::ConjugateHeatTransfer::dir examples HeatedSquare.tcl]]
    uplevel #0 [list source [file join $::ConjugateHeatTransfer::dir examples cylinder_cooling.tcl]]
    uplevel #0 [list source [file join $::ConjugateHeatTransfer::dir examples BFS.tcl]]
}

ConjugateHeatTransfer::examples::Init