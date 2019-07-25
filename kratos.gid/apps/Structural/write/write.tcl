namespace eval Structural::write {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable writeAttributes
    variable ContactsDict
}

proc Structural::write::Init { } {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]

    variable ContactsDict
    set ContactsDict [dict create]

    variable writeAttributes
    set writeAttributes [dict create]
    SetAttribute validApps [list "Structural"]
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute properties_location json
    SetAttribute parts_un STParts
    SetAttribute time_parameters_un STTimeParameters
    SetAttribute results_un STResults
    SetAttribute materials_un STMaterials
    SetAttribute conditions_un STLoads
    SetAttribute nodal_conditions_un STNodalConditions
    SetAttribute nodal_conditions_no_submodelpart [list CONDENSED_DOF_LIST CONDENSED_DOF_LIST_2D CONTACT CONTACT_SLAVE]
    SetAttribute materials_file "StructuralMaterials.json"
    SetAttribute main_script_file "KratosStructural.py"
    SetAttribute model_part_name "Structure"
    SetAttribute output_model_part_name ""
}

# MDPA Blocks
proc Structural::write::writeModelPartEvent { } {
    variable ConditionsDictGroupIterators
    initLocalWriteConfiguration
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates (1: Print only Structural nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on STParts)
    write::writeElementConnectivities

    # Local Axes
    Structural::write::writeLocalAxes

    # Hinges special section
    Structural::write::writeHinges

    # Write Conditions section
    Structural::write::writeConditions

    # SubmodelParts
    Structural::write::writeMeshes

    # Custom SubmodelParts
    set basicConds [write::writeBasicSubmodelParts [getLastConditionId]]
    set ConditionsDictGroupIterators [dict merge $ConditionsDictGroupIterators $basicConds]
}

proc Structural::write::writeConditions { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [write::writeConditions [GetAttribute conditions_un] ]

    set last_iter [Structural::write::getLastConditionId]
    writeContactConditions $last_iter
}

proc Structural::write::writeMeshes { } {

    # There are some Conditions and nodalConditions that dont generate a submodelpart
    # Add them to this list
    set special_nodal_conditions_dont_generate_submodelpart_names [GetAttribute nodal_conditions_no_submodelpart]
    set special_nodal_conditions [list ]
    foreach cnd_name $special_nodal_conditions_dont_generate_submodelpart_names {
        lappend special_nodal_conditions [Model::getNodalConditionbyId $cnd_name]
        Model::ForgetNodalCondition $cnd_name
    }
    write::writePartSubModelPart

    # Solo Malla , no en conditions
    write::writeNodalConditions [GetAttribute nodal_conditions_un]

    # A Condition y a meshes-> salvo lo que no tenga topologia
    writeLoads

    # Recover the conditions and nodal conditions that we didn't want to print in submodelparts
    foreach cnd $special_nodal_conditions {
        lappend ::Model::NodalConditions $cnd
    }

    writeContacts
}

proc Structural::write::writeContactConditions { last_iter } {
    variable ConditionsDictGroupIterators
    set root [customlib::GetBaseRoot]
    set ov "line"
    set kname "LineCondition2D2N"
    if {$::Model::SpatialDimension eq "3D"} {set ov "surface"; set kname "SurfaceCondition3D3N"}
    set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT'\]/group"
    set xp2 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT_SLAVE'\]/group"
    foreach group [ concat {*}[$root selectNodes $xp1] {*}[$root selectNodes $xp2] ] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        lassign [write::getEtype $ov $groupid] etype nnodes
        if {$::Model::SpatialDimension eq "3D" && $nnodes == 4} {set kname "SurfaceCondition3D4N"}
        lassign [write::writeGroupCondition $groupid $kname $nnodes  [incr last_iter]] initial final
        dict set ConditionsDictGroupIterators $groupid [list $initial $final]
        set last_iter $final
    }
}

proc Structural::write::writeLoads { } {
    variable ConditionsDictGroupIterators
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        #W "Writing mesh of Load $groupid"
        if {$groupid in [dict keys $ConditionsDictGroupIterators]} {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "Conditions" [dict get $ConditionsDictGroupIterators $groupid]
        } else {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "nodal"
        }
    }
}

proc Structural::write::writeContacts { } {
    variable ConditionsDictGroupIterators
    variable ContactsDict

    set ContactsDict [dict create]
    if {[Structural::write::usesContact]} {
        set root [customlib::GetBaseRoot]

        # Prepare the xpaths
        set xp_slave  "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT_SLAVE'\]/group"
        foreach slave_group [$root selectNodes $xp_slave] {
            if {$slave_group ne ""} {
                set slave_groupid_raw [$slave_group @n]
                set slave_group_pair_id [get_domnode_attribute [$slave_group selectNodes "./value\[@n='pair'\]"] v]
                set slave_groupid [write::GetWriteGroupName $slave_groupid_raw]
                set prev [list ]
                if {[dict exists $ContactsDict Slaves $slave_group_pair_id]} {set prev [dict get $ContactsDict Slaves $slave_group_pair_id]}
                set good_name [::write::writeGroupSubModelPart CONTACT $slave_groupid "Conditions" [dict get $ConditionsDictGroupIterators $slave_groupid]]
                dict set ContactsDict Slaves $slave_group_pair_id [lappend prev $good_name]
            }
        }

        set xp_master "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT'\]/group"
        foreach master_group [$root selectNodes $xp_master] {
            if {$master_group ne ""} {
                set master_groupid_raw [$master_group @n]
                set master_groupid [write::GetWriteGroupName $master_groupid_raw]
                set master_group_pair_id [get_domnode_attribute [$master_group selectNodes "./value\[@n='pair'\]"] v]
                set prev [list ]
                if {[dict exists $ContactsDict Masters $master_group_pair_id]} {
                    set prev [dict get $ContactsDict Masters $master_group_pair_id]
                }
                set good_name [::write::writeGroupSubModelPart CONTACT $master_groupid "Conditions" [dict get $ConditionsDictGroupIterators $master_groupid]]
                set name [lappend prev $good_name]
                dict set ContactsDict Masters $master_group_pair_id $name

            }
        }
    }
}

proc Structural::write::writeCustomBlock { } {
    write::WriteString "Begin Custom"
    write::WriteString "Custom write for Structural, any app can call me, so be careful!"
    write::WriteString "End Custom"
    write::WriteString ""
}

proc Structural::write::getLastConditionId { } {
    variable ConditionsDictGroupIterators
    set top 1
    if {$ConditionsDictGroupIterators ne ""} {
        foreach {group iters} $ConditionsDictGroupIterators {
            set top [expr max($top,[lindex $iters 1])]
        }
    }
    return $top
}

# Custom files
proc Structural::write::WriteMaterialsFile { } {
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] True [GetAttribute model_part_name]
}

proc Structural::write::GetUsedElements { {get "Objects"} } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition/group"
    set lista [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem_name [get_domnode_attribute [$gNode selectNodes ".//value\[@n='Element']"] v]
        set e [Model::getElement $elem_name]
        if {$get eq "Name"} { set e [$e getName] }
        lappend lista $e
    }
    return $lista
}

proc Structural::write::writeLocalAxes { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition/group"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem_name [get_domnode_attribute [$gNode selectNodes ".//value\[@n='Element']"] v]
        set e [Model::getElement $elem_name]
        if {[write::isBooleanTrue [$e getAttribute "RequiresLocalAxes"]]} {
            set group [$gNode @n]
            write::writeLinearLocalAxesGroup $group
        }
    }
}

# This is the kind of code I hate
proc Structural::write::writeHinges { } {

    # Preprocess old_conditions. Each mesh linear element remembers the origin line in geometry
    set match_dict [dict create]
    foreach line [GiD_Info conditions relation_line_geo_mesh mesh] {
        lassign $line E eid - geom_line
        dict lappend match_dict $geom_line $eid
    }

    # Process groups assigned to Hinges
    if {$::Model::SpatialDimension eq "3D"} {
        set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n = 'CONDENSED_DOF_LIST'\]/group"
    } else {
        set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n = 'CONDENSED_DOF_LIST_2D'\]/group"
    }
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set group [$gNode @n]

        # If the group has any line
        if {[GiD_EntitiesGroups get $group lines -count] > 0} {
            # Print the header once per group
            write::WriteString "Begin ElementalData CONDENSED_DOF_LIST // Group: $group"

            # Get the tree data for this group
            set first_list [list ]
            set last_list [list ]
            if {$::Model::SpatialDimension eq "3D"} {
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstDisplacementX']"] v]]} {lappend first_list 0}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstDisplacementY']"] v]]} {lappend first_list 1}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstDisplacementZ']"] v]]} {lappend first_list 2}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstMomentX']"] v]]} {lappend first_list 3}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstMomentY']"] v]]} {lappend first_list 4}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstMomentZ']"] v]]} {lappend first_list 5}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondDisplacementX']"] v]]} {lappend last_list 6}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondDisplacementY']"] v]]} {lappend last_list 7}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondDisplacementZ']"] v]]} {lappend last_list 8}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondMomentX']"] v]]} {lappend last_list 9}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondMomentY']"] v]]} {lappend last_list 10}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondMomentZ']"] v]]} {lappend last_list 11}
            } else {
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstDisplacementX']"] v]]} {lappend first_list 0}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstDisplacementY']"] v]]} {lappend first_list 1}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='FirstMomentZ']"] v]]} {lappend first_list 2}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondDisplacementX']"] v]]} {lappend last_list 3}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondDisplacementY']"] v]]} {lappend last_list 4}
                if {[write::isBooleanTrue [get_domnode_attribute [$gNode selectNodes ".//value\[@n='SecondMomentZ']"] v]]} {lappend last_list 5}
            }

            # Write Left and Rigth end of each geometrical bar
            foreach geom_line [GiD_EntitiesGroups get $group lines] {
                set linear_elements [dict get $match_dict $geom_line]
                set first [::tcl::mathfunc::min {*}$linear_elements]
                set end [::tcl::mathfunc::max {*}$linear_elements]
                if {[llength $first_list] > 0} {
                    set value [join $first_list ,]
                    write::WriteString [format "%5d \[%d\] (%s)" $first [llength $first_list] $value]
                }
                if {[llength $last_list] > 0} {
                    set value [join $last_list ,]
                    write::WriteString [format "%5d \[%d\] (%s)" $end [llength $last_list] $value]
                }
            }
            # Write the tail
            write::WriteString "End ElementalData"
            write::WriteString ""
        }
    }
}

proc Structural::write::initLocalWriteConfiguration { } {

    if {[usesContact]} {
         SetAttribute main_script_file "KratosContactStructural.py"
    }
}

proc Structural::write::usesContact { } {
    set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute STNodalConditions]/condition\[@n = 'CONTACT'\]/group"]

    if {$result_node ne ""} {
        return 1
    } {
        return 0
    }
}

# return 0 means ok; return [list 1 "Error message to be displayed"]
proc Structural::write::writeValidateEvent { } {
    set problem 0
    set problem_message [list ]

    # Truss mesh validation
    set validation [validateTrussMesh]
    incr problem [lindex $validation 0]
    lappend problem_message {*}[lindex $validation 1]

    return [list $problem $problem_message]
}

proc Structural::write::validateTrussMesh { } {
    # Elements to be checked
    set truss_element_names [list "TrussLinearElement2D" "TrussElement2D" "TrussLinearElement3D" "TrussElement3D"]
    set error 0
    set error_message ""

    # Used elements
    set truss_elements [list ]
    foreach elem [GetUsedElements "Name"] {
        if {$elem in $truss_element_names} {
            lappend truss_elements $elem
        }
    }

    # Check groups assigned to each element
    foreach element_name $truss_elements {
        set group_nodes [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute [GetAttribute parts_un]]/group/value\[@n = 'Element' and @v = '$element_name'\]/.."]

        foreach group_node $group_nodes {
            set group_name [$group_node @n]
            set num_lines [GiD_EntitiesGroups get $group_name lines -count]
            set num_elements [GiD_EntitiesGroups get $group_name elements -count -element_type {linear}]
            # All lines must have only 1 linear element, so num_lines should be equal to num_elements
            if {$num_elements != $num_lines} {
                set error 1
                lappend error_message "Error in Truss element, group: $group_name. You must mesh each line with only 1 linear element."
            }
        }
    }

    return [list $error $error_message]
}


proc Structural::write::writeCustomFilesEvent { } {
    WriteMaterialsFile

    write::SetParallelismConfiguration

    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc Structural::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

proc Structural::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Structural::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Structural::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc Structural::write::AddAttribute {att val} {
    variable writeAttributes
    dict append writeAttributes $att $val]
}

proc Structural::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc Structural::write::AddValidApps {appList} {
    AddAttribute validApps $appList
}

proc Structural::write::ApplyConfiguration { } {
    variable writeAttributes
    write::SetConfigurationAttributes $writeAttributes
}

Structural::write::Init
