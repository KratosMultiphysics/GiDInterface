namespace eval Structural::write {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable writeAttributes
}

proc Structural::write::Init { } {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]
    
    variable writeAttributes
    set writeAttributes [dict create]
    SetAttribute validApps [list "Structural"]
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute properties_location json 
    SetAttribute parts_un STParts
    SetAttribute materials_un STMaterials
    SetAttribute conditions_un STLoads
    SetAttribute nodal_conditions_un STNodalConditions
    SetAttribute nodal_conditions_no_submodelpart [list CONDENSED_DOF_LIST CONDENSED_DOF_LIST_2D CONTACT CONTACT_SLAVE]
    SetAttribute materials_file "StructuralMaterials.json"
    SetAttribute main_script_file "KratosStructural.py"
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

proc Structural::write::ApplyConfiguration { } {
    variable writeAttributes
    write::SetConfigurationAttributes $writeAttributes
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
    if {[Structural::write::usesContact]} {
        set root [customlib::GetBaseRoot]

        # Prepare the xpaths
        set xp_master "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT'\]/group"
        set xp_slave  "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='CONTACT_SLAVE'\]/group"

        # Get the groups
        set master_group [$root selectNodes $xp_master]
        set slave_group [$root selectNodes $xp_slave]
        if {$master_group ne ""} {
            if {[llength $master_group] > 1 || [llength $slave_group] > 1} {error "Max 1 group allowed in contact master and slave"}
            set master_groupid_raw [$master_group @n]
            set master_groupid [write::GetWriteGroupName $master_groupid_raw]
        }
        if {$slave_group ne ""} {
            set slave_groupid_raw [$slave_group @n]
            set slave_groupid [write::GetWriteGroupName $slave_groupid_raw]
        }
        # Create the joint group
        set joint_contact_group "_HIDDEN_CONTACT_GROUP_"
        if {[GiD_Groups exists $joint_contact_group]} {GiD_Groups delete $joint_contact_group}

        if {$slave_group ne ""} {
            spdAux::MergeGroups $joint_contact_group [list $master_groupid_raw $slave_groupid_raw]
        } {
            spdAux::MergeGroups $joint_contact_group [list $master_groupid_raw]
        }

        # Print the submodelpart
        ::write::writeGroupSubModelPart CONTACT $joint_contact_group "nodal"
        if {$slave_group ne ""} {
            ::write::writeGroupSubModelPart CONTACT $slave_groupid_raw "nodal"
        }

        GiD_Groups delete $joint_contact_group
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
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file]
}

proc Structural::write::GetUsedElements { {get "Objects"} } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
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
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
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

Structural::write::Init
