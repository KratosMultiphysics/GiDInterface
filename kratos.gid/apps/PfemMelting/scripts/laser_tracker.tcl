namespace eval ::PfemMelting::LaserTracker {
    namespace path ::PfemMelting
    Kratos::AddNamespace [namespace current]

    variable status
    set status 0

    variable functions
    set functions [list ]

    variable steps_set
    set steps_set [list ]

}

proc ::PfemMelting::LaserTracker::Start { } {
    variable status
    if {$status} {TurnOff} {TurnOn}
    GiD_Process 'Redraw
}

proc ::PfemMelting::LaserTracker::TurnOn { } {
    variable status
    set status 1
    variable functions
    variable steps_set
    set steps_set [list ]

    set laser_cond_xpath "[spdAux::getRoute PFEMMELTING_Laser]"
    set paths [[customlib::GetBaseRoot] selectNodes "$laser_cond_xpath/blockdata/value\[@n='laser_path'\]"]
    foreach path_node $paths {
        set coordinates [list ]
        set path [write::getValueByNode $path_node]
        set fullpath [file join [GidUtils::GetDirectoryModel] $path]
        if {![file exists $fullpath]} {error "file $fullpath not found"}
        set laser_dict [Kratos::ReadJsonDict $fullpath]
        set steps [dict get $laser_dict laser_settings]
        lappend steps_set $steps
        set id [GiD_OpenGL register ::PfemMelting::LaserTracker::MyRedrawProcedure]
        lappend functions $id
    }
}

proc ::PfemMelting::LaserTracker::MyRedrawProcedure { } {
    variable steps_set

    foreach path $steps_set {
        set director [dict get $path direction]
        lassign $director dx dy dz
        set steps [dict get $path path]
        for {set i 0} {$i < [llength $steps]} {incr i} {
            if {[expr 1+$i] < [llength $steps]} {
                set step [lindex $steps $i]
                set x [dict get $step x]
                set y [dict get $step y]
                set z [dict get $step z]
                lappend coordinates [list $x $y $z]

                set x1 [expr $x + (0.0*$dx)]
                set y1 [expr $y + (0.0*$dy)]
                set z1 [expr $z + (0.0*$dz)]
                set x2 [expr $x - (10.0*$dx)]
                set y2 [expr $y - (10.0*$dy)]
                set z2 [expr $z - (10.0*$dz)]

                set next_step [lindex $steps [expr 1+$i]]
                set x [dict get $next_step x]
                set y [dict get $next_step y]
                set z [dict get $next_step z]
                lappend coordinates [list $x $y $z]
                set x3 [expr $x + (0.0*$dx)]
                set y3 [expr $y + (0.0*$dy)]
                set z3 [expr $z + (0.0*$dz)]
                set x4 [expr $x - (10.0*$dx)]
                set y4 [expr $y - (10.0*$dy)]
                set z4 [expr $z - (10.0*$dz)]

                GiD_OpenGL draw -color "0.69841 0.190464 0.69841"
                foreach mode [list line fill] {
                    GiD_OpenGL draw -polygonmode frontandback $mode
                    GiD_OpenGL draw -begin quads
                    GiD_OpenGL draw -vertex [list $x1 $y1 $z1]
                    GiD_OpenGL draw -vertex [list $x2 $y2 $z2]
                    GiD_OpenGL draw -vertex [list $x4 $y4 $z4]
                    GiD_OpenGL draw -vertex [list $x3 $y3 $z3]
                    GiD_OpenGL draw -end
                }
            }
        }
    }
}

proc ::PfemMelting::LaserTracker::TurnOff { } {
    variable functions
    variable status
    set status 0

    foreach function $functions {
        catch {GiD_OpenGL unregister $function}
    }

    set functions [list ]
}

proc ::PfemMelting::EndEvent {} {
    ::PfemMelting::LaserTracker::TurnOff
}