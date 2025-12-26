##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::runsimulations {
    Kratos::AddNamespace [namespace current]

    variable folder_name
    variable spd_un
}


proc runsimulations::Init { } {
    variable folder_name
    variable spd_un

    set folder_name "Simulations"
    set spd_un "simulation_runs"
}

proc runsimulations::GetPastSimulationsRunsList { } {

    set return_list [list ]

    # Find in the folder
    set dir [GidUtils::GetDirectoryModel]
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
    set run_name "Run_$run_index"
    while {[lsearch -exact $previous_runs_names $run_name] != -1} {
        incr run_index
        set run_name "Run_$run_index"
    }
    return $run_name
}
proc runsimulations::GetCurrentSimulationRunName {  } {
    set dir [GidUtils::GetDirectoryModel]
    variable folder_name
    set simulations_dir [file join $dir $folder_name]
    if {[file isdirectory $simulations_dir]} {
        # find all the folders inside
        set dir_list [glob -nocomplain -directory $simulations_dir *]
        set latest_time 0
        set latest_run ""
        foreach sim_dir $dir_list {
            if {[file isdirectory $sim_dir]} {
                set mod_time [file mtime $sim_dir]
                if {$mod_time > $latest_time} {
                    set latest_time $mod_time
                    set latest_run [file tail $sim_dir]
                }
            }
        }
        return $latest_run
    } else {
        return ""
    }
}

proc runsimulations::DeleteSimulationRun { sim_path } {
    # delete the folder and all its contents
    if {[file isdirectory $sim_path]} {
        file delete -force $sim_path
    }
}

proc runsimulations::GetSimulationRunPath { run_name } {
    set dir [GidUtils::GetDirectoryModel]
    variable folder_name
    set simulations_dir [file join $dir $folder_name]
    set run_path [file join $simulations_dir $run_name]
    return $run_path
}

runsimulations::Init