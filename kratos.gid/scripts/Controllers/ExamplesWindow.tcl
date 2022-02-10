namespace eval ::Examples {
    Kratos::AddNamespace [namespace current]

    # Variable declaration
    variable dir
    variable doc
    variable examples_window
    variable filter_entry
    variable groups_of_examples

    variable _canvas_scroll
    variable _canvas_scroll_w

    variable info_main_window_text
}

proc Examples::Init { } {
    # Variable initialization
    variable dir
    variable examples_window
    set examples_window .gid.examples_window

    set dir [apps::getMyDir "Examples"]

    # Don't open the tree
    set ::spdAux::TreeVisibility 0

    LoadMyFiles

    variable filter_entry
    set filter_entry ""
    variable groups_of_examples
    set groups_of_examples [dict create]
}

proc Examples::LoadMyFiles { } {
    variable dir
    variable doc

    # uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    set xmlfd [tDOM::xmlOpenFile [file join $dir xml examples.xml]]
    set doc [dom parse -channel $xmlfd]
    close $xmlfd
    ResolveLinks
}

proc ::Examples::StartWindowEmpty {args} {
    Examples::StartWindow
}

proc Examples::StartWindow { {filter ""} } {
    variable examples_window
    variable _canvas_scroll
    variable _canvas_scroll_w

    set ::spdAux::must_open_dim_window 0

    if { [GidUtils::IsTkDisabled] } {
        return 0
    }

    spdAux::DestroyInitWindow
    Examples::DestroyExamplesWindow
    toplevel $examples_window
    wm withdraw $examples_window

    set x [expr [winfo rootx .gid]+[winfo width .gid]/2-[winfo width $examples_window]/2]
    set y [expr [winfo rooty .gid]+[winfo height .gid]/2-[winfo height $examples_window]/2]

    wm geom $examples_window +$x+$y
    wm transient $examples_window .gid

    InitWindow $examples_window [_ "Kratos Multiphysics - Examples"] Kratos "" "" 1

    spdAux::RegisterWindow $examples_window

    set c_to_scroll [CreateScrolledCanvas $examples_window.center]
    set fcenter [tk::frame $c_to_scroll.fcenter]
    set _canvas_scroll $fcenter
    set _canvas_scroll_w $examples_window.center
    AddToScrolledCanvas $examples_window.center $fcenter
    grid $examples_window.center -row 0 -column 0 -sticky nsew

    set Examples::filter_entry $filter
    set filter_txt [ttk::label $fcenter.filter_text -text [_ "Search an example:"]]
    set filter_ent [ttk::entry $fcenter.filter_entry -textvariable Examples::filter_entry]
    set filter_btn [ttk::button $fcenter.filter_button -text "Filter" -command [list Examples::PrintGroups]]
    grid $filter_txt $filter_ent $filter_btn -sticky ew

    # Information panel
    ttk::labelframe $examples_window.info -text " Information " -relief ridge
    ttk::label $examples_window.info.text -textvariable Examples::info_main_window_text
    grid $examples_window.info.text
    grid $examples_window.info -sticky ew

    set groups [GetGroupsFromXML]

    PrintGroups
}

proc Examples::getImgFrom {group_name example_logo} {
    return [apps::getImgFrom $group_name $example_logo]
}

proc Examples::PrintGroups { } {
    variable groups_of_examples
    variable examples_window
    variable _canvas_scroll
    variable _canvas_scroll_w
    variable filter_entry

    set filter $filter_entry

    foreach group_id [dict keys $groups_of_examples] {
        set group [dict get $groups_of_examples $group_id]
        set group_name [dict get $group name]

        if {[winfo exists $_canvas_scroll.title_text$group_id]} {destroy $_canvas_scroll.title_text$group_id}
        set parent [ttk::labelframe $_canvas_scroll.title_text$group_id -text $group_name]
        set buttons_frame [ttk::frame $parent.buttonframe]
        set col 0
        set row 0
        foreach example_id [dict keys [dict get $group examples]] {
            set example [dict get $group examples $example_id]
            if {[IsAproved $example $group_name $filter]} {
                set inner_id "$group_id*$example_id"
                set example_name [subst -nocommands -novariables [dict get $example name]]
                set example_logo [dict get $example logo]
                set example_dim [dict get $example dim]
                set example_app [dict get $example app]
                set example_cmd [dict get $example cmd]
                set img [Examples::getImgFrom $example_app $example_logo]
                ttk::button $buttons_frame.img~$inner_id -image $img -command [list Examples::LaunchExample $example_app $example_dim $example_cmd ]
                ttk::label $buttons_frame.title$example_id -text $example_app; # -font {bold}
                ttk::label $buttons_frame.text$example_id -text $example_name
                grid $buttons_frame.img~$inner_id -column $col -row $row
                grid $buttons_frame.title$example_id -column $col -row [expr $row +1]
                grid $buttons_frame.text$example_id -column $col -row [expr $row +2]

                bind $buttons_frame.img~$inner_id <Enter> {::Examples::PlaceInformationWindowByPath %W}

                incr col
                if {$col >= 4} {set col 0; incr row; incr row; incr row}
            }
        }
        if {$col > 0 || $row > 0 } {
            grid $parent -sticky ew -columnspan 3
            grid $buttons_frame
            grid columnconfigure $parent 0 -weight 1
        }
    }

    grid columnconfigure $examples_window 0 -weight 1
    grid rowconfigure $examples_window 0 -weight 1
    wm minsize $examples_window 700 500
    update

    ResizeScrolledCanvas $_canvas_scroll_w
}

proc Examples::PlaceInformationWindowByPath {win_path} {
    variable examples_window
    variable groups_of_examples
    set inner_id [lindex [split $win_path "~"] end]
    lassign [split $inner_id "*"] example_group example_id
    set example [dict get $groups_of_examples $example_group examples $example_id]
    if {$example ne ""} {
        $examples_window.info configure -text "Information: [dict get $example name]"
        set description [dict get $example description]
        set ::Examples::info_main_window_text $description
    }
}

proc Examples::getExampleById {example_id} {
    variable groups_of_examples

    foreach group_id [dict keys $groups_of_examples] {
        set group [dict get $groups_of_examples $group_id]
        foreach example [dict keys [dict get $group examples]] {
            if {$example_id eq $example} {return [dict get $group examples $example]}
        }
    }
}

proc Examples::IsAproved {example group filter} {
    # if empty, no filter, go
    if {$filter eq ""} {return 1}
    set filter [string tolower $filter]
    # filter by app id
    set app_name [string tolower [dict get $example app]]
    if {[string first $filter $app_name] > -1} {return 2}
    # filter by app name
    set group [string tolower $group]
    if {[string first $filter $group] > -1} {return 3}
    # filter by example name
    set example_name [string tolower [dict get $example name]]
    if {[string first $filter $example_name] > -1} {return 4}

    return 0
}

proc Examples::GetGroupsFromXML {} {
    variable doc
    variable groups_of_examples

    set root [$doc documentElement]
    set groups [$root getElementsByTagName "Group"]
    foreach group $groups {
        set group_id [$group @id]
        if {[$group hasAttribute name]} {dict set groups_of_examples $group_id name [$group @name]}
        set examples [$group getElementsByTagName "Example"]
        foreach example $examples {
            set example_id [$example @id]
            dict set groups_of_examples $group_id examples $example_id name [subst -nocommands -novariables [$example @name]]
            dict set groups_of_examples $group_id examples $example_id logo [$example @logo]
            dict set groups_of_examples $group_id examples $example_id dim [$example @dim]
            dict set groups_of_examples $group_id examples $example_id app [$example @app]
            dict set groups_of_examples $group_id examples $example_id cmd [$example @cmd]
            dict set groups_of_examples $group_id examples $example_id description [[$example getElementsByTagName "Description"] text]
        }
    }
}

proc Examples::LaunchExample {example_app example_dim example_cmd} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry. You should save your work first.\nDo you want to lose your unsaved work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    Examples::DestroyExamplesWindow
    Kratos::ResetModel
    Model::DestroyEverything
    set ::problemtype_current(CustomLibAutomatic) 1
    gid_common_problemtype_init_customlib_automatic $Kratos::kratos_private(Path)
    set ::problemtype_current(CustomLibAutomatic) 0
    spdAux::SetSpatialDimmension $example_dim
    apps::setActiveApp $example_app
    $example_cmd
    spdAux::OpenTree
}

proc Examples::DestroyExamplesWindow {} {

    variable examples_window
    if { ![GidUtils::IsTkDisabled] } {
        if {[winfo exists $examples_window]} {destroy $examples_window}
    }
}

proc Examples::ResolveLinks { } {
    variable doc

    set examples_node [$doc selectNodes "/examples"]
    foreach link [$examples_node getElementsByTagName link] {
        catch {
            set xmlfd [tDOM::xmlOpenFile [file join $::Kratos::kratos_private(Path) [$link @path]]]
            set nodes [[dom parse -channel $xmlfd] getElementsByTagName Group]
            close $xmlfd
            foreach node $nodes {
                $examples_node insertBefore $node $link
            }
            $link delete
        }
    }

}

Examples::Init
