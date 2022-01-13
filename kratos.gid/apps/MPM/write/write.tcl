namespace eval MPM::write {
    namespace path ::MPM
    Kratos::AddNamespace [namespace current]

    variable writeAttributes
    variable ConditionsDictGroupIterators
}

proc MPM::write::Init { } {
    # Namespace variables inicialization
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [dict create]

    SetAttribute parts_un [::MPM::GetUniqueName parts]
    SetAttribute nodal_conditions_un [::MPM:::GetUniqueName nodal_conditions]
    SetAttribute conditions_un [::MPM::GetUniqueName conditions]

    SetAttribute writeCoordinatesByGroups [::MPM::GetWriteProperty coordinates]
    SetAttribute main_launch_file [::MPM::GetAttribute main_launch_file]
    SetAttribute materials_file [::MPM::GetWriteProperty materials_file]
    SetAttribute properties_location [::MPM::GetWriteProperty properties_location]
    SetAttribute model_part_name [::MPM::GetWriteProperty model_part_name]
}

# Events
proc MPM::write::writeModelPartEvent { } {
    write::initWriteConfiguration [Structural::write::GetAttributes]
    write::initWriteConfiguration [GetAttributes]

    MPM::write::UpdateMaterials

    set filename [Kratos::GetModelName]

    ## Grid MPDA ##
    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates
    write::writeNodalCoordinates

    # Grid element connectivities
    writeGridConnectivities

    # Write conditions
    writeConditions

    # Write Submodelparts
    writeSubmodelparts grid

    write::CloseFile
    write::RenameFileInModel "$filename.mdpa" "${filename}_Grid.mdpa"

    ## Body MDPA ##
    write::OpenFile "${filename}_Body.mdpa"

    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates
    writeBodyNodalCoordinates

    # Body element connectivities
    writeBodyElementConnectivities

    # Write Submodelparts
    writeSubmodelparts particles

    write::CloseFile
}

proc MPM::write::GetPartsGroups { part_type {what "name"} } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition/group"
    set body_groups [list ]
    set grid_elems [list GRID2D GRID3D]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]

        if {($part_type eq "grid" && $elem in $grid_elems) || ($part_type ne "grid" && $elem ni $grid_elems)} {
            if {$what eq "name"} {
                lappend body_groups [$gNode @n]
            } {
                lappend body_groups $gNode
            }
        }
    }
    return $body_groups
}

proc MPM::write::writeBodyNodalCoordinates { } {
    write::writeNodalCoordinatesOnGroups [MPM::write::GetPartsGroups Body]
}

proc MPM::write::writeBodyElementConnectivities { } {
    foreach gNode [MPM::write::GetPartsGroups Body node] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem ni [list GRID2D GRID3D]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeGridConnectivities { } {
    foreach gNode [MPM::write::GetPartsGroups grid node] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem in [list GRID2D GRID3D]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeConditions { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [::write::writeConditions [GetAttribute conditions_un] ]
}

proc MPM::write::writeSubmodelparts { type } {

    set grid_elements [list GRID2D GRID3D]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition/group"
    foreach gNode [MPM::write::GetPartsGroups $type node] {
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
        if {$type eq 0} {
            set submodelpart [lindex [split [dict get $mat model_part_name] "."] end]
            dict set mat model_part_name Background_Grid.$submodelpart
        }
        lappend new_mats $mat
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