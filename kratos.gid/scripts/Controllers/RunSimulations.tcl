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

proc runsimulations::DeleteAllSimulationRuns {  } {
    set sim_runs_list [runsimulations::GetPastSimulationsRunsList]
    foreach sim_run $sim_runs_list {
        set sim_path [dict get $sim_run path]
        runsimulations::DeleteSimulationRun $sim_path
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

proc runsimulations::GoToPostprocess { sim_path } {
    set Kratos::pending_postprocess_simulation $sim_path
    # W "Changing to Postprocess... $sim_path"
    runsimulations::WritePostprocessRequest $sim_path
    GiD_Process MEscape Postprocess MEscape
}

# TODO: Ask kike if there is a better way to change to post and return the path of a post.lst file
# Instead of writing the post.lst manually
proc runsimulations::WritePostprocessRequest { sim_path } {
    # In the model folder, create a file named "{model_name}.post.lst" 
    # The content of the file is a copy of the file simp_path/{simulation_name}.post.lst but adding the full path to the simulation folder
    set dir [GidUtils::GetDirectoryModel]
    set model_name [file tail $dir]
    # remove the extension if any
    set model_name [file rootname $model_name]

    # remove  from sim_path the dir (initial part)
    if {[string first $dir $sim_path] == 0} {
        set sim_path [string range $sim_path [expr [string length $dir] +1] end]
    }

    set postprocess_request_file [file join $dir "${model_name}.post.lst"]
    set sim_name [file tail $sim_path]  
    set sim_postprocess_file [file join $dir $sim_path "${sim_name}.post.lst"]
    # W "Writing postprocess request from $sim_postprocess_file to $postprocess_request_file"
    if {[file exists $sim_postprocess_file]} {
        set infile [open $sim_postprocess_file r]
        set outfile [open $postprocess_request_file w]
        while {[gets $infile line] >= 0} {
            # write the line to the output file, if it is not "Multiple" "Single" or "Merge", add the path
            if {[string match "Multiple*" $line] || [string match "Single*" $line] || [string match "Merge*" $line]} {
                puts $outfile $line
            } else {
                puts $outfile "[file join $sim_path $line]"
            }
        }
        close $infile
        close $outfile
    } else {
        W "Simulation postprocess file not found: $sim_postprocess_file"
    }

}


runsimulations::Init