namespace eval ::DEM {

}

proc ::DEM::Init { } {
    set Kratos::must_quit 1
    if {[GidUtils::GiveProblemTypeFullname Dem.gid] ne ""} {
        GiD_Process Mescape Data Defaults ProblemType Dem escape 
    } else {
        W "Dem is not installed"
    }
}
::DEM::Init