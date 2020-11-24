namespace eval MPM::examples {

}

proc MPM::examples::Init { } {
    uplevel #0 [list source [file join $::MPM::dir examples FallingSandBall.tcl]]
}

proc MPM::examples::UpdateMenus { } {
}

MPM::examples::Init