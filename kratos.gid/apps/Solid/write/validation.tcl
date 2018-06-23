
# return 0 means ok; return [list 1 "Error message to be displayed"]
proc Solid::write::writeValidateEvent { } {
    set problem_message [list ]
    
    # Entities assigned to parts validation
    lappend problem_message {*}[Solid::write::validatePartsMesh]

    # Entities assigned to parts validation
    lappend problem_message {*}[Solid::write::validateNodalConditionsMesh]

    # Entities assigned to parts validation
    lappend problem_message {*}[Solid::write::validateLoadsMesh]

    return [list [llength $problem_message] $problem_message]
}

proc Solid::write::validatePartsMesh {} {
    set problem_messages [list ]
    # Get the Parts node
    set parts_un "SLParts"
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $parts_un]/group"
    # Foreach group assigned
    foreach gNode [$root selectNodes $xp1] {
        # Get group name
        set group_name [$gNode @n]
        # Get the assigned element
        set element [write::getValueByNode [$gNode selectNodes "./value\[@n = 'Element'\]"]]
        # Get the element available topologies
        set topologies [Solid::write::GetTopologies [::Model::getElement $element]]
        # Validate if the group has any of the valid topologies assigned
        set has_any [Solid::write::ValidateGroupEmpty $group_name $topologies]
        if {$has_any == 0} {
            # Get the topologies to show the message
            set valid_topologies [list ]
            foreach topology $topologies {
                lappend valid_topologies [$topology getGeometry]
            }
            # Add the message to the list of problems
            lappend problem_messages "Parts > group: $group_name must have one of this elements assigned: $valid_topologies. Assign something in geometry and remesh"
        }
    }
    return $problem_messages
}
proc Solid::write::validateNodalConditionsMesh {} {
    set problem_messages [list ]
    # Get the Nodal conditions node
    set nodal_conditions_un "SLNodalConditions"
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $nodal_conditions_un]/condition/group"
    # Foreach group assigned
    foreach gNode [$root selectNodes $xp1] {
        # Get group name
        set group_name [write::GetWriteGroupName [$gNode @n]]
        # Get the assigned nodal condition
        set nodal_condition [[$gNode parent] @n]
        # Get the nodal condition available topologies
        set topologies [list [::Model::Topology new "Point" 1 ""]]
        # Validate if the group has any of the valid topologies assigned
        set has_any [Solid::write::ValidateGroupEmpty $group_name $topologies]
        if {$has_any == 0} {
            # Get the topologies to show the message
            set valid_topologies [list ]
            foreach topology $topologies {
                lappend valid_topologies [$topology getGeometry]
            }
            # Add the message to the list of problems
            lappend problem_messages "Conditions > group: $group_name must have one of this elements assigned: $valid_topologies. Assign something in geometry and remesh"
        }
    }
    return $problem_messages
}

proc Solid::write::validateLoadsMesh {} {
    set problem_messages [list ]
    # Get the Conditions node
    set conditions_un "SLLoads"
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $conditions_un]/condition/group"
    # Foreach group assigned
    foreach gNode [$root selectNodes $xp1] {
        # Get group name
        set group_name [write::GetWriteGroupName [$gNode @n]]
        # Get the assigned nodal condition
        set condition [[$gNode parent] @n]
        # Get the entity selected condition
        if {[$gNode hasAttribute ov]} {set ov [$gNode getAttribute ov]} {set ov [[$gNode parent ] getAttribute ov]}
        # Get the nodal condition available topologies
        set topologies [Solid::write::GetTopologies [Model::getCondition $condition] ]
        # Validate if the group has any of the valid topologies assigned
        set has_any [Solid::write::ValidateGroupEmpty $group_name $topologies $ov]
        if {$has_any == 0} {
            # Get the topologies to show the message
            set valid_topologies [list ]
            foreach topology $topologies {
                lappend valid_topologies [$topology getGeometry]
            }
            # Add the message to the list of problems
            lappend problem_messages "Loads > group: $group_name must have one of this elements assigned: $valid_topologies. Assign something in geometry and remesh"
        }
    }
    return $problem_messages
}

proc Solid::write::GetTopologies { entity } {
    if {$entity eq ""} {return [list ]}
    return [$entity getTopologyFeatures]
}
proc Solid::write::ValidateGroupEmpty { group_name topologies {ov ""} } {
    set any 0
    set isquadratic [write::isquadratic]
    foreach topology $topologies {
        set geo [$topology getGeometry]
        if {$ov ne "" && [string tolower $geo] ne $ov} {continue}
        if {$geo == "Point"} {
            if {[GiD_EntitiesGroups get $group_name nodes -count] > 0} {
                # TODO: check number of nodes if quadratic
                set any 1
                break
            }
        } else {
            if {[GiD_EntitiesGroups get $group_name elements -count -element_type $geo] > 0} {
                # TODO: check number of nodes if quadratic
                set any 1
                break
            }
        }
    }
    return $any
}