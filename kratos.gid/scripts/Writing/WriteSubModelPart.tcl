
# what can be: nodal, Elements, Conditions or Elements&Conditions
proc write::writeGroupSubModelPart { cid group {what "Elements"} {iniend ""} {tableid_list ""} } {
    variable submodelparts
    variable formats_dict

    set id_f [dict get $formats_dict ID]
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
        set f "${s2}$id_f\n"
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
            #GiD_WriteCalculationFile elements -sorted $gdict
            if {$iniend ne ""} {
                #W $iniend
                foreach {ini end} $iniend {
                    for {set i $ini} {$i<=$end} {incr i} {
                        WriteString "${s2}[format $id_f $i]"
                    }
                }
            }
        }
        WriteString "${s1}End SubModelPartConditions"
        WriteString "${s}End SubModelPart"
    }
    return $mid
}

proc write::writeBasicSubmodelParts {cond_iter {un "GenericSubmodelPart"}} {
    # Write elements
    set groups [write::_writeElementsForBasicSubmodelParts $un]
    # Write conditions (By iterator, so need the app condition iterator)
    set conditions_dict [write::_writeConditionsForBasicSubmodelParts $un $cond_iter ]
    foreach group $groups {
        set needElems [write::getValueByNode [$group selectNodes "./value\[@n='WriteElements'\]"]]
        set needConds [write::getValueByNode [$group selectNodes "./value\[@n='WriteConditions'\]"]]
        set what "nodal"
        set iters ""
        if {$needElems} {append what "&Elements"}
        if {$needConds} {append what "&Conditions"; set iters [dict get $conditions_dict [$group @n]]}
        ::write::writeGroupSubModelPart "GENERIC" [$group @n] $what $iters
    }
    return $conditions_dict
}

proc write::_writeConditionsForBasicSubmodelParts {un cond_iter} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $un]/group"
    set groups [$root selectNodes $xp1]
    Model::getConditions "../../Common/xml/Conditions.xml"
    set conditions_dict [dict create ]
    set elements_list [list ]
    set generic_condition_name GENERIC_CONDITION3D
    if {$::Model::SpatialDimension ne "3D"} {set generic_condition_name GENERIC_CONDITION2D}
    foreach group $groups {
        set needConds [write::getValueByNode [$group selectNodes "./value\[@n='WriteConditions'\]"]]
        if {$needConds} {
            set iters [write::writeGroupNodeCondition $conditions_dict $group $generic_condition_name [incr cond_iter]]
            set conditions_dict [dict merge $conditions_dict $iters]
            set cond_iter [lindex $iters end end]
        }
    }
    Model::ForgetCondition $generic_condition_name
    return $conditions_dict
}

proc write::_writeElementsForBasicSubmodelParts {un} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $un]/group"
    set groups [$root selectNodes $xp1]
    Model::getElements "../../Common/xml/Elements.xml"
    #set elements_list [list ]
    foreach group $groups {
        set needElems [write::getValueByNode [$group selectNodes "./value\[@n='WriteElements'\]"]]
        if {$needElems} {
            writeGroupElementConnectivities $group "GENERIC_ELEMENT"
            #lappend elements_list [$group @n]
        }
    }
    Model::ForgetElement GENERIC_ELEMENT
    return $groups
}

proc write::getSubModelPartNames { args } {

    set root [customlib::GetBaseRoot]

    set listOfProcessedGroups [list ]
    set groups [list ]
    foreach un $args {
        set xp1 "[spdAux::getRoute $un]/condition/group"
        set xp2 "[spdAux::getRoute $un]/group"
        set grs [$root selectNodes $xp1]
        if {$grs ne ""} {lappend groups {*}$grs}
        set grs [$root selectNodes $xp2]
        if {$grs ne ""} {lappend groups {*}$grs}
    }
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        if {[Model::getNodalConditionbyId $cid] ne "" || [Model::getCondition $cid] ne "" || [string first Parts $cid] >= 0 } {
            set gname [::write::getSubModelPartId $cid $groupName]
            if {$gname ni $listOfProcessedGroups} {lappend listOfProcessedGroups $gname}
        }
    }

    return $listOfProcessedGroups
}


proc write::GetSubModelPartFromCondition { base_UN condition_id } {

    set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute $base_UN]/condition\[@n='$condition_id'\]/group"
    set groups [$root selectNodes $xp1]

    set submodelpart_list [list ]
    foreach gNode $groups {
        set group [$gNode @n]
        set group [write::GetWriteGroupName $group]
        set submodelpart_id [write::getSubModelPartId $condition_id $group]
        lappend submodelpart_list $submodelpart_id
    }
    return $submodelpart_list
}
