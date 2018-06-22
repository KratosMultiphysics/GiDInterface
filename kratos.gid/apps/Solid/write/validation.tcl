
# return 0 means ok; return [list 1 "Error message to be displayed"]
proc Solid::write::writeValidateEvent { } {
    set problem 0
    set problem_message [list ]
    
    # Entities assigned to parts validation
    set validation [Solid::write::validatePartsMesh]
    incr problem [lindex $validation 0]
    lappend problem_message {*}[lindex $validation 1]

    # Entities assigned to parts validation
    set validation [Solid::write::validateNodalConditionsMesh]
    incr problem [lindex $validation 0]
    lappend problem_message {*}[lindex $validation 1]

    # Entities assigned to parts validation
    set validation [Solid::write::validateLoadsMesh]
    incr problem [lindex $validation 0]
    lappend problem_message {*}[lindex $validation 1]

    return [list $problem $problem_message]
}

proc Solid::write::validatePartsMesh {} {
    # Get the Parts node
    set part_un "SLParts"
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $parts_un]/group"
    # Foreach group assigned
    foreach gNode [$root selectNodes $xp1] {
        # Get group name
        set group_name [$gNode selectNodes "./value\[@n='Material'\]"]
    }
}