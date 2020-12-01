namespace eval FSI::examples {

}

proc FSI::examples::Init { } {
    uplevel #0 [list source [file join $::FSI::dir examples MokChannelWithFlexibleWall.tcl]]
    uplevel #0 [list source [file join $::FSI::dir examples TurekBenchmark.tcl]]
    uplevel #0 [list source [file join $::FSI::dir examples HighRiseBuilding.tcl]]
}

FSI::examples::Init