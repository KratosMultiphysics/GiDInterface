
proc write::writeConditions { baseUN {iter 0} {cond_id ""}} {
    set dictGroupsIterators [dict create]

    set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute $baseUN]/condition/group"
    set groupNodes [$root selectNodes $xp1]
    if {[llength $groupNodes] < 1} {
        set xp1 "[spdAux::getRoute $baseUN]/group"
        set groupNodes [$root selectNodes $xp1]
    }
    foreach groupNode $groupNodes {
        if {$cond_id eq ""} {set condid [[$groupNode parent] @n]} {set condid $cond_id}
        set groupid [get_domnode_attribute $groupNode n]
        set groupid [GetWriteGroupName $groupid]
        set dictGroupsIterators [writeGroupNodeCondition $dictGroupsIterators $groupNode $condid [incr iter]]
        if { [dict exists $dictGroupsIterators $groupid] } {
            set iter [lindex [dict get $dictGroupsIterators $groupid] 1]
        } else {
            incr iter -1
        }
    }
    return $dictGroupsIterators
}


# proc write::writeGroupNodeCondition {dictGroupsIterators groupNode condid iter} {
#     set groupid [get_domnode_attribute $groupNode n]
#     set groupid [GetWriteGroupName $groupid]
#     if {![dict exists $dictGroupsIterators $groupid]} {
#         if {[$groupNode hasAttribute ov]} {set ov [$groupNode getAttribute ov]} {set ov [[$groupNode parent ] getAttribute ov]}
#         set cond [::Model::getCondition $condid]
#         if {$cond ne ""} {
#             lassign [write::getEtype $ov $groupid] etype nnodes
#             set kname [$cond getTopologyKratosName $etype $nnodes]
#             if {$kname ne ""} {
#                 lassign [write::writeGroupConditionNatural $groupid $kname $nnodes $iter] initial final
#                 dict set dictGroupsIterators $groupid [list $initial $final]
#             } else {
#                 # If kname eq "" => no topology feature match, condition written as nodal
#                 if {[$cond hasTopologyFeatures]} {W "$groupid assigned to $condid - Selected invalid entity $ov with $nnodes nodes - Check Conditions.xml"}
#             }
#         } else {
#             error "Could not find conditon named $condid"
#         }
#     }
#     return $dictGroupsIterators
# }

proc write::writeGroupNodeCondition {dictGroupsIterators groupNode condid iter} {
    set groupid [get_domnode_attribute $groupNode n]
    set groupid [GetWriteGroupName $groupid]
    if {![dict exists $dictGroupsIterators $groupid]} {
        if {[$groupNode hasAttribute ov]} {set ov [$groupNode getAttribute ov]} {set ov [[$groupNode parent ] getAttribute ov]}
        set cond [::Model::getCondition $condid]
        if {$cond ne ""} {
            lassign [write::getEtype $ov $groupid] etype nnodes
            set kname [$cond getTopologyKratosName $etype $nnodes]
            if {$kname ne ""} {
                lassign [write::writeGroupCondition $groupid $kname $nnodes $iter] initial final
                dict set dictGroupsIterators $groupid [list $initial $final]
            } else {
                # If kname eq "" => no topology feature match, condition written as nodal
                if {[$cond hasTopologyFeatures]} {W "$groupid assigned to $condid - Selected invalid entity $ov with $nnodes nodes - Check Conditions.xml"}
            }
        } else {
            error "Could not find conditon named $condid"
        }
    }
    return $dictGroupsIterators
}

proc write::writeGroupCondition {groupid kname nnodes iter} {
    set obj [list ]

    # Print header
    set s [mdpaIndent]
    WriteString "${s}Begin Conditions $kname// GUI group identifier: $groupid"

    # Get the entities to print
    if {$nnodes == 1} {
        set formats [dict create $groupid "%10d \n"]
        set obj [GiD_EntitiesGroups get $groupid nodes]
    } else {
        set formats [write::GetFormatDict $groupid 0 $nnodes]
        set elems [GiD_WriteCalculationFile connectivities -return $formats]
        set obj [GetListsOfNodes $elems $nnodes 2]
    }

    # Print the conditions and it's connectivities
    set initial $iter
    incr ::write::current_mdpa_indent_level
    set s1 [mdpaIndent]
    for {set i 0} {$i <[llength $obj]} {incr iter; incr i} {
        set nids [lindex $obj $i]
        WriteString "${s1}$iter 0 $nids"
    }
    set final [expr $iter -1]
    incr ::write::current_mdpa_indent_level -1

    # Print the footer
    WriteString "${s}End Conditions"
    WriteString ""

    return [list $initial $final]
}

proc write::writeNodalConditions { un } {

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $un]/condition/group"
    set groups [$root selectNodes $xp1]
    if {$groups eq ""} {
        set xp1 "[spdAux::getRoute $un]/group"
        set groups [$root selectNodes $xp1]
    }
    foreach group $groups {
        set cid [[$group parent] @n]
        if {[Model::getNodalConditionbyId $cid] ne ""} {
            set groupid [$group @n]
            set groupid [GetWriteGroupName $groupid]
            ::write::writeGroupSubModelPart $cid $groupid "nodal"
        }
    }
}

proc write::writeConditionGroupedSubmodelParts {cid groups_dict} {
    set s [mdpaIndent]
    WriteString "${s}Begin SubModelPart $cid // Condition $cid"

    incr ::write::current_mdpa_indent_level
    set s1 [mdpaIndent]
    WriteString "${s1}Begin SubModelPartNodes"
    WriteString "${s1}End SubModelPartNodes"
    WriteString "${s1}Begin SubModelPartElements"
    WriteString "${s1}End SubModelPartElements"
    WriteString "${s1}Begin SubModelPartConditions"
    WriteString "${s1}End SubModelPartConditions"

    foreach group [dict keys $groups_dict] {
        if {[dict exists $groups_dict $group what]} {set what [dict get $groups_dict $group what]} else {set what ""}
        if {[dict exists $groups_dict $group iniend]} {set iniend [dict get $groups_dict $group iniend]} else {set iniend ""}
        if {[dict exists $groups_dict $group tableid_list]} {set tableid_list [dict get $groups_dict $group tableid_list]} else {set tableid_list ""}
        write::writeGroupSubModelPart $cid $group $what $iniend $tableid_list
    }

    incr ::write::current_mdpa_indent_level -1
    WriteString "${s}End SubModelPart"
}
