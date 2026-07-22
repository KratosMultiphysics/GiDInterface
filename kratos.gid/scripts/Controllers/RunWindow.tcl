namespace eval ::RunWindow {
    Kratos::AddNamespace [namespace current]

    variable run_window
    variable run_window_name

    
    variable gid_output
    variable vtk_output
    variable show_dialog_again
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
    
    # Row 2: Bottom row with checkbox and button
    ttk::checkbutton $frame_main.show_again_check -text [_ "Show this dialog again"] -variable ::RunWindow::show_dialog_again -onvalue 1 -offvalue 0 -command RunWindow::ToggleShowAgain
    ttk::button $frame_main.run_button -text [_ "Run Simulation"] -command RunWindow::OnRunSimulationButtonPressed -width 15
    grid $frame_main.show_again_check -row 2 -column 0 -sticky w
    

    grid $frame_main.run_button -row 2 -column 2 -sticky e
    
    grid columnconfigure $frame_main 1 -weight 1

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
        Kratos::ShowErrorMessage [_ "Error"] [_ "The simulation run name cannot be empty."]
        return
    }

    # TODO: Store the next name, run and close the window
    # proceed to run the simulation
    runsimulations::RunSimulation $run_name

    # close the window
    destroy $w
}

::RunWindow::Init