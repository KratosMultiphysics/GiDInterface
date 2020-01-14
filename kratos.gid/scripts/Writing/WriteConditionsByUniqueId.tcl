
proc write::writeConditionsByUniqueId { baseUN ConditionMapVariableName {iter 0} {cond_id ""} {print_again_repeated 0}} {
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
        set iter [writeGroupNodeConditionByUniqueId $groupNode $condid $iter $ConditionMapVariableName $print_again_repeated]
    }
    return $iter
}


proc write::writeGroupNodeConditionByUniqueId {groupNode condid iter ConditionMapVariableName {print_again_repeated 0}} {
    set groupid [get_domnode_attribute $groupNode n]
    set groupid [GetWriteGroupName $groupid]
    if {[$groupNode hasAttribute ov]} {set ov [$groupNode getAttribute ov]} {set ov [[$groupNode parent ] getAttribute ov]}
    set cond [::Model::getCondition $condid]
    if {$cond ne ""} {
        lassign [write::getEtype $ov $groupid] etype nnodes
        set kname [$cond getTopologyKratosName $etype $nnodes]
        if {$kname ne ""} {
            set iter [write::writeGroupConditionByUniqueId $groupid $kname $nnodes $iter $ConditionMapVariableName]
        } else {
            # If kname eq "" => no topology feature match, condition written as nodal
            if {[$cond hasTopologyFeatures]} {W "$groupid assigned to $condid - Selected invalid entity $ov with $nnodes nodes - Check Conditions.xml"}
        }
    } else {
        error "Could not find conditon named $condid"
    }
    return $iter
}


proc write::_writeConditionsByUniqueIdForBasicSubmodelParts {un ConditionMap iter {print_again_repeated 0}} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $un]/group"
    set groups [$root selectNodes $xp1]
    Model::getConditions "../../Common/xml/Conditions.xml"
    set conditions_dict [dict create ]
    set elements_list [list ]
    set generic_condition_name GENERIC_CONDITION3D
    if {$::Model::SpatialDimension ne "3D"} {set generic_condition_name GENERIC_CONDITION2D}
    foreach group_node $groups {
        set needConds [write::getValueByNode [$group_node selectNodes "./value\[@n='WriteConditions'\]"]]
        if {$needConds} {
            # TODO: be careful with the answer to https://github.com/KratosMultiphysics/GiDInterface/issues/576#issuecomment-485928815
            set iter [write::writeGroupNodeConditionByUniqueId $group_node $generic_condition_name $iter $ConditionMap {print_again_repeated 0}]
        }
    }
    Model::ForgetCondition $generic_condition_name
    return $iter
}

proc write::writeBasicSubmodelPartsByUniqueId {ConditionMap iter {un "GenericSubmodelPart"}} {
    # Write elements
    set groups [write::_writeElementsForBasicSubmodelParts $un]
    # Write conditions (By unique id, so need the app ConditionMap)
    write::_writeConditionsByUniqueIdForBasicSubmodelParts $un $ConditionMap $iter
    # Write the submodelparts
    foreach group $groups {
        set needElems [write::getValueByNode [$group selectNodes "./value\[@n='WriteElements'\]"]]
        set needConds [write::getValueByNode [$group selectNodes "./value\[@n='WriteConditions'\]"]]
        set what "nodal"
        set iters ""
        if {$needElems} {append what "&Elements"}
        if {$needConds} {append what "&Conditions"}
        ::write::writeGroupSubModelPartByUniqueId "GENERIC" [$group @n] $ConditionMap $what
    }
}

proc write::writeGroupConditionByUniqueId {groupid kname nnodes iter ConditionMap {print_again_repeated 0}} {
    set obj [list ]

    # Print header
    set s [mdpaIndent]
    WriteString "${s}Begin Conditions $kname// GUI group identifier: $groupid"

    # Get the entities to print
    if {$nnodes == 1} {
        variable formats_dict
        set id_f [dict get $formats_dict ID]
        set formats [dict create $groupid "${s}$id_f \n"]
        set obj [GiD_EntitiesGroups get $groupid nodes]
    } else {
        set formats [write::GetFormatDict $groupid 0 $nnodes]
        set elems [GiD_EntitiesGroups get $groupid elements]
        set obj [GetListsOfNodes [GiD_WriteCalculationFile connectivities -return $formats] $nnodes 2]
    }

    # Print the conditions and it's connectivities
    incr ::write::current_mdpa_indent_level
    set s1 [mdpaIndent]
    for {set i 0} {$i <[llength $obj]} {incr i} {
        set nids [lindex $obj $i]
        set cndid 0
        set new 0
        if {$nnodes != 1} {
            set eid [lindex $elems $i]
            set cndid [objarray get $ConditionMap $eid]
        }
        if {$cndid == 0} {
            set new 1
            set cndid [incr iter]
            if {$nnodes != 1} {
                objarray set $ConditionMap $eid $cndid
            }
        }
        if {$print_again_repeated || $new} {
            WriteString "${s1}$cndid 0 $nids"
        }
    }
    incr ::write::current_mdpa_indent_level -1

    # Print the footer
    WriteString "${s}End Conditions"
    WriteString ""

    return $iter
}

