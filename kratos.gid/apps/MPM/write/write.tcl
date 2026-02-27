namespace eval MPM::write {
    namespace path ::MPM
    Kratos::AddNamespace [namespace current]

    variable writeAttributes
    variable ConditionsDictGroupIterators  [dict create]

    variable grid_elems [list GRID2D GRID3D]
}

proc MPM::write::Init { } {

    SetAttribute parts_un [::MPM::GetUniqueName parts]
    SetAttribute nodal_conditions_un [::MPM:::GetUniqueName nodal_conditions]
    SetAttribute conditions_un [::MPM::GetUniqueName conditions]

    SetAttribute writeCoordinatesByGroups [::MPM::GetWriteProperty coordinates]
    SetAttribute main_launch_file [::MPM::GetAttribute main_launch_file]
    SetAttribute materials_file [::MPM::GetWriteProperty materials_file]
    SetAttribute properties_location [::MPM::GetWriteProperty properties_location]
    SetAttribute model_part_name [::MPM::GetWriteProperty model_part_name]
    SetAttribute write_mdpa_mode [::MPM::GetWriteProperty write_mdpa_mode]
}

# Events
proc MPM::write::writeModelPartEvent { } {
    write::initWriteConfiguration [Structural::write::GetAttributes]
    write::initWriteConfiguration [GetAttributes]

    MPM::write::UpdateMaterials

    set filename [Kratos::GetModelName]

    ## Grid MPDA ##
    MPM::write::WriteGridMDPA

    write::CloseFile
    write::RenameFileInModel "$filename.mdpa" "${filename}_Grid.mdpa"

    ## Body MDPA ##
    write::OpenFile "${filename}_Body.mdpa"

    # Headers
    MPM::write::WriteBodyMDPA

    write::CloseFile
}

proc MPM::write::GetPartsGroupsNames { part_type } {
    set groups [MPM::write::GetPartsGroups $part_type]
    set result [list ]
    foreach group $groups {
        lappend result [$group @n]
    }
    return $result
}

proc MPM::write::GetPartsGroups { part_type } {
    variable grid_elems
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition/group"
    set body_groups [list ]
    
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]

        if {($part_type eq "grid" && $elem in $grid_elems) || ($part_type ne "grid" && $elem ni $grid_elems)} {
            lappend body_groups $gNode
        }
    }
    return $body_groups
}

proc ::MPM::write::GetUsedElements { {get "Objects"} } {
    set lista [list ]
    foreach gNode [MPM::write::GetPartsGroups Body] {
        set elem_name [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element']"] ]
        set e [Model::getElement $elem_name]
        if {$get eq "Name"} { set e [$e getName] }
        lappend lista $e
    }
    return $lista
}

proc MPM::write::writeBodyNodalCoordinates { } {
    write::writeNodalCoordinatesOnGroups [MPM::write::GetPartsGroupsNames Body]
}


proc MPM::write::writeSubmodelparts { type } {

    variable grid_elements
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition/group"
    foreach gNode [MPM::write::GetPartsGroups $type] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        set part_name [get_domnode_attribute [$gNode parent] n]
        set group_name [get_domnode_attribute $gNode n]
        write::writeGroupSubModelPart $part_name $group_name "Elements"
    }
    if {$type eq "grid"} {
        # Write the boundary conditions submodelpart
        write::writeNodalConditions [GetAttribute nodal_conditions_un]

        # A Condition y a meshes-> salvo lo que no tenga topologia
        writeLoads
    }
}

proc MPM::write::GetConditionsGroups { } {

    set groups [::write::GetGroupsNamesAssignedIn [GetAttribute conditions_un]]
    return $groups
}

proc MPM::write::GetNodalConditionsGroups { } {
    return [::write::GetGroupsNamesAssignedIn [GetAttribute nodal_conditions_un]]
}

proc MPM::write::writeLoads { } {
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

proc MPM::write::writeCustomFilesEvent { } {
    # Materials file
    set mats_json [dict get [write::getPropertiesList [GetAttribute parts_un] True Initial_MPM_Material] properties ]
    set new_mats [list ]
    foreach mat $mats_json {
        set type [dict exists $mat Material constitutive_law]
#         if {$type eq 0} {
#             set submodelpart [lindex [split [dict get $mat model_part_name] "."] end]
#             dict set mat model_part_name Background_Grid.$submodelpart
#         }
        if {$type eq 1} {
            lappend new_mats $mat
        }
    }
    write::OpenFile [GetAttribute materials_file]
    write::WriteJSON [dict create properties $new_mats]
    write::CloseFile

    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}

proc MPM::write::UpdateMaterials { } {
    set matdict [write::getMatDict]
    foreach {mat props} $matdict {
        # Modificar la ley constitutiva
        dict set matdict $mat THICKNESS  1.0000E+00

        set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition/group\[@n='$mat'\]/value\[@n='THICKNESS'\]"
        set vNode [[customlib::GetBaseRoot] selectNodes $xp1]
        if {$vNode ne ""} {
            dict set matdict $mat THICKNESS [write::getValueByNode $vNode]
        }

    }
    write::setMatDict $matdict
}

proc MPM::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc MPM::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc MPM::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}
