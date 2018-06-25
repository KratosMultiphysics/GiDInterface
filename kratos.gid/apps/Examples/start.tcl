namespace eval ::Examples {
    # Variable declaration
    variable dir
    variable doc
    variable examples_window
}

proc ::Examples::Init { } {
    # Variable initialization
    variable dir
    variable examples_window
    set examples_window .gid.examples_window
    
    set dir [apps::getMyDir "Examples"]
    
    # Don't open the tree
    set ::spdAux::TreeVisibility 0
    set ::spdAux::must_open_dim_window 0
    
    LoadMyFiles

    after 200 [list ::Examples::StartWindow]
}

proc ::Examples::LoadMyFiles { } {
    variable dir
    variable doc
    
    # uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    set xmlfd [tDOM::xmlOpenFile [file join $dir xml examples.xml]]
    set doc [dom parse -channel $xmlfd]
    close $xmlfd
}

proc ::Examples::StartWindow { } {
    variable doc
    variable examples_window
    set root [$doc documentElement]

    spdAux::DestroyInitWindow
    Examples::DestroyExamplesWindow
    toplevel $examples_window
    wm withdraw $examples_window
    
    set x [expr [winfo rootx .gid]+[winfo width .gid]/2-[winfo width $examples_window]/2]
    set y [expr [winfo rooty .gid]+[winfo height .gid]/2-[winfo height $examples_window]/2]
    
    wm geom $examples_window +$x+$y
    wm transient $examples_window .gid    
    
    InitWindow $examples_window [_ "Kratos Multiphysics - Examples"] Kratos "" "" 1
    set initwind $examples_window
    
    set groups [$root getElementsByTagName "Group"]
    foreach group $groups {
        set group_id [$group @id]
        set group_name [$group @name]
        set title_frame [ttk::frame $examples_window.information_$group_id]
        grid [ttk::label $title_frame.title_text$group_id -text $group_name]
        
        set buttons_frame [ttk::frame $examples_window.buttons_$group_id -relief ridge ]
        set examples [$group getElementsByTagName "Example"]
        set col 0
        set row 0
        foreach example $examples {
            set example_id [$example @id]
            set example_name [subst -nocommands -novariables [$example @name]]
            set example_logo [$example @logo]
            set example_dim [$example @dim]
            set example_app [$example @app]
            set example_cmd [$example @cmd]
            set img [Examples::getImgFrom $group_id $example_logo]
            ttk::button $buttons_frame.img$example_id -image $img -command [list Examples::LaunchExample $example_app $example_dim $example_cmd ]
            ttk::label $buttons_frame.text$example_id -text $example_name
            grid $buttons_frame.img$example_id -column $col -row $row
            grid $buttons_frame.text$example_id -column $col -row [expr $row +1]
            
            incr col
            if {$col >= 7} {set col 0; incr row; incr row}
        }
        grid $title_frame
        grid $buttons_frame
    }
}

proc ::Examples::getImgFrom {group_name example_logo} {
    
    return [apps::getImgFrom "Examples" [file join $group_name $example_logo]]
}

proc ::Examples::LaunchExample {example_app example_dim example_cmd} {
    Examples::DestroyExamplesWindow
    spdAux::SetSpatialDimmension $example_dim
    apps::setActiveApp $example_app
    $example_cmd
    spdAux::OpenTree

}

proc ::Examples::DestroyExamplesWindow {} {
    
    variable examples_window
    if {[winfo exists $examples_window]} {destroy $examples_window}
}

::Examples::Init
