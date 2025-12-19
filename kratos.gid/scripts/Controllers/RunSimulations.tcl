##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::runsimulations {
    Kratos::AddNamespace [namespace current]

    variable folder_name
    variable spd_un
    variable dir 
}


proc runsimulations::Init { } {
    variable folder_name
    variable spd_un
    variable dir 

    set folder_name "Simulations"
    set spd_un "simulation_runs"
    set dir [GidUtils::GetDirectoryModel]
}

proc runsimulations::GetPastSimulationsRunsList { } {

}

proc runsimulations::GetNextSimulationRun { } {
    

}

