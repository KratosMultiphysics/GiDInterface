namespace eval ::RunWindow {
    Kratos::AddNamespace [namespace current]

    variable run_window
    variable run_window_name

    
    variable gid_output
    variable vtk_output
    variable show_dialog_again

    variable num_threads
}

proc RunWindow::Init { } {

    variable run_window_name
    set run_window_name ".gid.kratosrunwindow"

    variable gid_output
    variable vtk_output

    # initialize show-again flag from global Kratos private setting
    variable show_dialog_again
    if {![info exists ::Kratos::kratos_private(run_window)]} {
        set ::Kratos::kratos_private(run_window) 1
    }
    set show_dialog_again $::Kratos::kratos_private(run_window)

    variable num_processes
    if {![info exists ::Kratos::kratos_private(num_processes)]} {
        set ::Kratos::kratos_private(num_processes) 1
    }
}

proc RunWindow::ShowRunWindow { } {
    variable run_window
    variable run_window_name

    # if ::Kratos::kratos_private(run_window) is 1, show the window
    if {$::Kratos::kratos_private(run_window) == 1} {
        # check if the window is already created

        if {[winfo exists $run_window_name]} {
            # destry
            destroy $run_window_name
        }
        RunWindow::InitRunWindow
    }
}

proc RunWindow::InitRunWindow { } {
    variable run_window_name
    set w $run_window_name

    InitWindow $w [_ "Kratos Multiphysics - Run Simulations"] Kratos "" "" 1

    # run window content must be a in entry for the run name, 2 checkboxes for options (gid output, vtk output) and
    # a check button to toggle between show again or not, and a run button

    set frame_main $w.frame_main
    ttk::frame $frame_main
    pack $frame_main -side top -fill both -expand 1 -padx 20 -pady 15
    
    # Row 0: Run name section
    ttk::labelframe $frame_main.name_frame -text [_ "Simulation Run"] -padding {10 5}
    grid $frame_main.name_frame -row 0 -column 0 -columnspan 3 -sticky ew -pady {0 15}
    
    # Label must be on the previous line, attached to the left margin
    ttk::label $frame_main.name_frame.run_name_label -text [_ "Run name"] -width 15 -anchor w
    pack $frame_main.name_frame.run_name_label
    ttk::entry $frame_main.name_frame.run_name_entry -width 50
    pack $frame_main.name_frame.run_name_entry -fill x
    set default_run_name [runsimulations::GetNextSimulationRunName]
    $frame_main.name_frame.run_name_entry insert 0 $default_run_name
    
    # Create checkbuttons with command callbacks
    ttk::checkbutton $frame_main.name_frame.gid_output_check -text [_ "Enable GiD Output"] -variable ::RunWindow::gid_output -command "RunWindow::ToggleOutput ::RunWindow::gid_output EnableGiDOutput"  
    ttk::checkbutton $frame_main.name_frame.vtk_output_check -text [_ "Enable VTK Output"] -variable ::RunWindow::vtk_output -command "RunWindow::ToggleOutput ::RunWindow::vtk_output EnableVtkOutput"
    
    # Set initial state from tree
    set gid_enabled [write::getValue EnableGiDOutput]
    if {$gid_enabled eq "Yes"} {
        $frame_main.name_frame.gid_output_check state selected
    } else {
        $frame_main.name_frame.gid_output_check state !selected
    }
    
    set vtk_enabled [write::getValue EnableVtkOutput]
    if {$vtk_enabled eq "Yes"} {
        $frame_main.name_frame.vtk_output_check state selected
    } else {
        $frame_main.name_frame.vtk_output_check state !selected
    }
    
    pack $frame_main.name_frame.gid_output_check -side left -padx {0 20}
    pack $frame_main.name_frame.vtk_output_check -side left

    
    # // TODO: Add parallel run option, with a spinbox for the number of processes
    set current_threads [write::getValue Parallelization OpenMPNumberOfThreads]
    if {$current_threads eq ""} {
        set current_threads 1
    }
    # place the spinbox in its own row below the run name frame
    ttk::frame $frame_main.parallel_frame
    grid $frame_main.parallel_frame -row 1 -column 0 -columnspan 3 -sticky w -pady {0 15}
    ttk::label $frame_main.parallel_frame.parallel_label -text [_ "Number of OMP Threads"] -width 20 -anchor w
    pack $frame_main.parallel_frame.parallel_label -side left -padx {0 10}

    # ttk scale
    ttk::scale $frame_main.parallel_frame.parallel_scale -from 1 -to 32 -variable ::RunWindow::num_threads -command "RunWindow::OnNumThreadsChanged"
    pack $frame_main.parallel_frame.parallel_scale -side left
    ttk::entry $frame_main.parallel_frame.parallel_value_entry -textvariable ::RunWindow::num_threads -width 5
    pack $frame_main.parallel_frame.parallel_value_entry -side left -padx {10 0}
    set ::RunWindow::num_threads $current_threads

    # Row 2: Bottom row with checkbox and button
    ttk::checkbutton $frame_main.show_again_check -text [_ "Show this dialog again"] -variable ::RunWindow::show_dialog_again -onvalue 1 -offvalue 0 -command RunWindow::ToggleShowAgain
    ttk::button $frame_main.run_button -text [_ "Run Simulation"] -command RunWindow::OnRunSimulationButtonPressed -width 15
    grid $frame_main.show_again_check -row 2 -column 0 -sticky w
    

    grid $frame_main.run_button -row 2 -column 2 -sticky e
    
    grid columnconfigure $frame_main 1 -weight 1


}

proc RunWindow::OnNumThreadsChanged { value } {
    variable num_threads
    set num_threads [expr {int($value)}]
}

proc RunWindow::ToggleOutput { variable_name un } {
    # get current value from the window
    set current [set $variable_name]
    if {$current eq 1} {
        set current "Yes"
    } else {
        set current "No"
    }
    spdAux::SetValueOnTreeItem v $current $un

}

# keep global run window flag in sync with the checkbox
proc RunWindow::ToggleShowAgain { } {
    variable show_dialog_again
    if {![info exists show_dialog_again]} {
        set show_dialog_again 1
    }
    set ::Kratos::kratos_private(run_window) $show_dialog_again
}

proc RunWindow::OnRunSimulationButtonPressed { } {
    variable run_window_name
    set w $run_window_name
    variable gid_output
    variable vtk_output

    # get the run name
    set run_name [$w.frame_main.name_frame.run_name_entry get]

    # check that the name is not empty
    if {[string length $run_name] == 0} {
        W [_ "The simulation run name cannot be empty."]
        return
    }

    # Check that the name is valid (no special characters, only letters, numbers, underscores and hyphens)
    if {[regexp {[^a-zA-Z0-9_-]} $run_name]} {
        W [_ "The simulation run name can only contain letters, numbers, underscores and hyphens."]
        return
    }
    # Check that the name is not already used
    set simulation_case [runsimulations::GetSimulationRunPath $run_name]
    if {[file exists $simulation_case]} {
        W [_ "The simulation run name is already used."]
        return
    }

    # Set the number of processes in the tree
    variable num_threads  
    spdAux::SetValueOnTreeItem v $num_threads Parallelization OpenMPNumberOfThreads

    # TODO: Store the next name, run and close the window
    # proceed to run the simulation
    runsimulations::RunSimulation $run_name

    # close the window
    destroy $w
}

::RunWindow::Init