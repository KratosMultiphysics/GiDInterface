
proc write::writeConditionsNatural { baseUN  {cond_id ""}} {
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
        writeGroupNodeConditionNatural $groupNode $condid
        
    }
}


proc write::writeGroupNodeConditionNatural {groupNode condid} {
    set groupid [get_domnode_attribute $groupNode n]
    set groupid [GetWriteGroupName $groupid]
    if {[$groupNode hasAttribute ov]} {set ov [$groupNode getAttribute ov]} {set ov [[$groupNode parent ] getAttribute ov]}
    set cond [::Model::getCondition $condid]
    if {$cond ne ""} {
        lassign [write::getEtype $ov $groupid] etype nnodes
        set kname [$cond getTopologyKratosName $etype $nnodes]
        if {$kname ne ""} {
            write::writeGroupConditionNatural $groupid $kname $nnodes
        } else {
            # If kname eq "" => no topology feature match, condition written as nodal
            if {[$cond hasTopologyFeatures]} {W "$groupid assigned to $condid - Selected invalid entity $ov with $nnodes nodes - Check Conditions.xml"}
        }
    } else {
        error "Could not find conditon named $condid"
    }
}


proc write::writeGroupConditionNatural {groupid kname nnodes} {
    set obj [list ]

    # Print header
    set s [mdpaIndent]
    WriteString "${s}Begin Conditions $kname// GUI group identifier: $groupid"

    # Get the entities to print
    if {$nnodes == 1} {
        set formats [dict create $groupid "${s}%10d \n"]
        GiD_WriteCalculationFile nodes $formats
    } else {
        set formats [write::GetFormatDict $groupid 0 $nnodes]
        GiD_WriteCalculationFile connectivities $formats
    }

    # Print the footer
    WriteString "${s}End Conditions"
    WriteString ""

}


# what can be: nodal, Elements, Conditions or Elements&Conditions
proc write::writeGroupSubModelPartNatural { cid group {what "Elements"} {tableid_list ""} } {
    variable submodelparts

    set mid ""
    set what [split $what "&"]
    set group [GetWriteGroupName $group]
    if {![dict exists $submodelparts [list $cid ${group}]]} {
        # Add the submodelpart to the catalog
        set good_name [write::transformGroupName $group]
        set mid "${cid}_${good_name}"
        dict set submodelparts [list $cid ${group}] $mid

        # Prepare the print formats
        incr ::write::current_mdpa_indent_level
        set s1 [mdpaIndent]
        incr ::write::current_mdpa_indent_level -1
        incr ::write::current_mdpa_indent_level 2
        set s2 [mdpaIndent]
        set gdict [dict create]
        set f "${s2}%5i\n"
        set f [subst $f]
        dict set gdict $group $f
        incr ::write::current_mdpa_indent_level -2

        # Print header
        set s [mdpaIndent]
        WriteString "${s}Begin SubModelPart $mid // Group $group // Subtree $cid"
        # Print tables
        if {$tableid_list ne ""} {
            set s1 [mdpaIndent]
            WriteString "${s1}Begin SubModelPartTables"
            foreach tableid $tableid_list {
                WriteString "${s2}$tableid"
            }
            WriteString "${s1}End SubModelPartTables"
        }
        WriteString "${s1}Begin SubModelPartNodes"
        GiD_WriteCalculationFile nodes -sorted $gdict
        WriteString "${s1}End SubModelPartNodes"
        WriteString "${s1}Begin SubModelPartElements"
        if {"Elements" in $what} {
            GiD_WriteCalculationFile elements -sorted $gdict
        }
        WriteString "${s1}End SubModelPartElements"
        WriteString "${s1}Begin SubModelPartConditions"
        if {"Conditions" in $what} {
            GiD_WriteCalculationFile elements -sorted $gdict
        }
        WriteString "${s1}End SubModelPartConditions"
        WriteString "${s}End SubModelPart"
    }
    return $mid
}

