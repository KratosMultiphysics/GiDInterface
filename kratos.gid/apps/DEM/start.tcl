namespace eval ::DEM {

}

proc ::DEM::Init { } {
    set Kratos::must_quit 1
    GiD_Process Mescape Data Defaults ProblemType Dem escape 
}
::DEM::Init