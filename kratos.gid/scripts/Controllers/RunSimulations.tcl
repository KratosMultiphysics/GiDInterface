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

    set return_list [list ]

    # Find in the folder
    variable dir
    variable folder_name
    set simulations_dir [file join $dir $folder_name]
    if {[file isdirectory $simulations_dir]} {
        # find all the folders inside
        set dir_list [glob -nocomplain -directory $simulations_dir *]
        foreach sim_dir $dir_list {
            set sim [dict create]
            if {[file isdirectory $sim_dir]} {
                set sim_name [file tail $sim_dir]
                dict set sim name $sim_name
                dict set sim path $sim_dir
                lappend return_list $sim
            }
        }
    }
    return $return_list

}

proc runsimulations::GetNextSimulationRunName {  } {
    
    set sim_runs_list [runsimulations::GetPastSimulationsRunsList]
    set previous_runs_names [list ]
    foreach sim_run $sim_runs_list {
        dict get $sim_run name
        lappend previous_runs_names [dict get $sim_run name]
    }

    set run_index [llength $previous_runs_names]
    incr run_index
    set run_name "Run $run_index"
    while {[lsearch -exact $previous_runs_names $run_name] != -1} {
        incr run_index
        set run_name "Run $run_index"
    }
    return $run_name
}

proc runsimulations::DeleteSimulationRun { sim_path } {
    # delete the folder and all its contents
    if {[file isdirectory $sim_path]} {
        file delete -force $sim_path
    }
}

runsimulations::Init