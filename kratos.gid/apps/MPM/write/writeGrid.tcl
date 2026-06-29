proc MPM::write::WriteGridMDPA { } {
    # Headers
    ::write::writeModelPartData
    ::write::WriteString "Begin Properties 0"
    ::write::WriteString "End Properties"

    # Nodal coordinates
    set list_of_groups [concat [MPM::write::GetPartsGroupsNames grid] [MPM::write::GetConditionsGroups] [MPM::write::GetNodalConditionsGroups]]
    ::write::writeNodalCoordinatesOnGroups $list_of_groups

    # Grid element connectivities
    ::write::writeGeometryConnectivities [MPM::write::GetPartsGroups grid] 

    # Write conditions
    ::write::writeGeometryConnectivities [::write::GetGroupsAssignedIn [GetAttribute conditions_un]]
    MPM::write::ResetNonConformingPointGeometryIds
    MPM::write::writePointGeometriesFromNodes [MPM::write::GetNonConformingPointLoadGeometryGroups]

    # Write Submodelparts
    writeSubmodelparts grid
    writeConditionsSubmodelparts

}

proc MPM::write::writeConditionsSubmodelparts { } {
    set processed_groups [list ]

    foreach gNode [MPM::write::GetNonConformingPointLoadGeometryGroups] {
        set group [get_domnode_attribute $gNode n]
        set group [write::GetWriteGroupName $group]
        if {$group in $processed_groups} {
            continue
        }
        lappend processed_groups $group
        write::writeGroupSubModelPartAsGeometry $group 1 1 [MPM::write::GetNonConformingPointGeometryIdsForGroup $group]
    }

    foreach group [MPM::write::GetConditionsGroups] {
        if {$group in $processed_groups} {
            continue
        }
        lappend processed_groups $group
        write::writeGroupSubModelPartAsGeometry $group
    }

    foreach gNode [::write::GetGroupsAssignedIn [GetAttribute nodal_conditions_un]] {
        set group [get_domnode_attribute $gNode n]
        set group [write::GetWriteGroupName $group]
        if {$group in $processed_groups} {
            continue
        }
        lappend processed_groups $group
        if {[MPM::write::IsNonConformingPointLoadGroup $gNode]} {
            write::writeGroupSubModelPartAsGeometry $group 1 1 [MPM::write::GetNonConformingPointGeometryIdsForGroup $group]
        } else {
            write::writeGroupSubModelPartAsGeometry $group 0
        }
    }
}

proc MPM::write::GetNodalConditionsGroups { } {
    set groups [::write::GetGroupsNamesAssignedIn [GetAttribute nodal_conditions_un]]
    return $groups
}

proc MPM::write::GetNonConformingPointLoadGeometryGroups { } {
    set non_conforming_point_load_groups [list ]
    foreach un [list [GetAttribute conditions_un] [GetAttribute nodal_conditions_un]] {
        foreach gNode [::write::GetGroupsAssignedIn $un] {
            if {[MPM::write::IsNonConformingPointLoadGroup $gNode]} {
                lappend non_conforming_point_load_groups $gNode
            }
        }
    }
    return $non_conforming_point_load_groups
}

proc MPM::write::GetNonConformingPointLoadGeometryGroupNames { } {
    set groups [list ]
    foreach gNode [MPM::write::GetNonConformingPointLoadGeometryGroups] {
        set group_name [get_domnode_attribute $gNode n]
        set group_name [write::GetWriteGroupName $group_name]
        if {$group_name ni $groups} {
            lappend groups $group_name
        }
    }
    return $groups
}

proc MPM::write::writePointGeometriesFromNodes { group_list } {
    set processed_groups [list ]
    foreach gNode $group_list {
        set group [get_domnode_attribute $gNode n]
        set group [write::GetWriteGroupName $group]
        if {$group in $processed_groups} {
            continue
        }
        lappend processed_groups $group
        MPM::write::writePointGeometryFromGroupNodes $group
    }
}

proc MPM::write::writePointGeometryFromGroupNodes { group } {
    set geometry_ids_by_node [MPM::write::EnsureNonConformingPointGeometryIdsForGroup $group]
    if {[dict size $geometry_ids_by_node] < 1} {
        return
    }

    set nDim $::Model::SpatialDimension
    if {$nDim eq "2Da"} {
        set nDim "2D"
    }

    set s [::write::mdpaIndent]
    ::write::WriteString "${s}Begin Geometries Point${nDim} // GUI group identifier: $group"
    incr ::write::current_mdpa_indent_level
    set s1 [::write::mdpaIndent]
    foreach node_id [lsort -integer [dict keys $geometry_ids_by_node]] {
        set geometry_id [dict get $geometry_ids_by_node $node_id]
        ::write::WriteString "${s1}$geometry_id $node_id"
    }
    incr ::write::current_mdpa_indent_level -1
    ::write::WriteString "${s}End Geometries"
    ::write::WriteString ""
}

proc MPM::write::ResetNonConformingPointGeometryIds { } {
    variable non_conforming_point_geometry_ids_by_group
    variable next_non_conforming_point_geometry_id

    set non_conforming_point_geometry_ids_by_group [dict create]
    set next_non_conforming_point_geometry_id [expr {[GiD_Info Mesh MaxNumElements] + 1}]
}

proc MPM::write::EnsureNonConformingPointGeometryIdsForGroup { group } {
    variable non_conforming_point_geometry_ids_by_group
    variable next_non_conforming_point_geometry_id

    if {![info exists non_conforming_point_geometry_ids_by_group] || ![info exists next_non_conforming_point_geometry_id]} {
        MPM::write::ResetNonConformingPointGeometryIds
    }

    set group [write::GetWriteGroupName $group]
    if {[dict exists $non_conforming_point_geometry_ids_by_group $group]} {
        return [dict get $non_conforming_point_geometry_ids_by_group $group]
    }

    set geometry_ids_by_node [dict create]
    foreach node_id [lsort -integer [GiD_EntitiesGroups get $group nodes]] {
        dict set geometry_ids_by_node $node_id $next_non_conforming_point_geometry_id
        incr next_non_conforming_point_geometry_id
    }
    dict set non_conforming_point_geometry_ids_by_group $group $geometry_ids_by_node
    return $geometry_ids_by_node
}

proc MPM::write::GetNonConformingPointGeometryIdsForGroup { group } {
    set geometry_ids_by_node [MPM::write::EnsureNonConformingPointGeometryIdsForGroup $group]
    set geometry_ids [list ]
    foreach node_id [lsort -integer [dict keys $geometry_ids_by_node]] {
        lappend geometry_ids [dict get $geometry_ids_by_node $node_id]
    }
    return $geometry_ids
}

proc MPM::write::IsNonConformingPointLoadGroup { gNode } {
    set cond_id [get_domnode_attribute [$gNode parent] n]
    if {$cond_id in [list PointLoad2DMPM PointLoad3DMPM]} {
        return 1
    }

    set group_name [get_domnode_attribute $gNode n]
    if {[string match "Nonconforming Point Load*" $group_name] || [string match "Non-Conforming Load on points*" $group_name]} {
        return 1
    }

    set condition [Model::getCondition $cond_id]
    if {$condition eq ""} {
        set condition [Model::getNodalConditionbyId $cond_id]
    }
    if {$condition eq "" || ![$condition hasAttribute ElementType] || ![$condition hasAttribute ProcessName]} {
        return 0
    }
    return [expr {
        "Point" in [$condition getAttribute ElementType]
        && "ApplyMPMParticleNeumannConditionProcess" in [$condition getAttribute ProcessName]
    }]
}

proc MPM::write::GetConditionsGroups { } {
    set groups [::write::GetGroupsNamesAssignedIn [GetAttribute conditions_un]]
    return $groups
}
