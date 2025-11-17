##################################################################################

namespace eval ::Mesh {
    Kratos::AddNamespace [namespace current]


}
proc Mesh::PrepareMeshGeneration {elementsize} {

    GiD_MeshData mesh_criteria to_be_meshed 1 lines [GiD_Geometry list line]
    GiD_MeshData mesh_criteria to_be_meshed 1 surfaces [GiD_Geometry list surface]
    GiD_MeshData mesh_criteria to_be_meshed 1 volumes  [GiD_Geometry list volume ]

    # We need to mesh every line and surface assigned to a group that appears in the tree
    foreach group [spdAux::GetAppliedGroups] {
        GiD_MeshData mesh_criteria to_be_meshed 2 lines [GiD_EntitiesGroups get $group lines]
        GiD_MeshData mesh_criteria to_be_meshed 2 surfaces [GiD_EntitiesGroups get $group surfaces]
        GiD_MeshData mesh_criteria to_be_meshed 2 volumes  [GiD_EntitiesGroups get $group volumes]
    }
}


proc Mesh::CheckMeshCriteria { elementsize } {

    set force_mesh_order [dict create]
    set elements_used [spdAux::GetUsedElements]
    set forced_mesh_order -1
    foreach element_id $elements_used {
        set element [Model::getElement $element_id]
        if {[$element hasAttribute "MeshOrder"]} {
            set element_forces [$element getAttribute "MeshOrder"]
            if {$element_forces eq "Quadratic"} {
                set element_forces 1
            } else {
                set element_forces 0
            }
            dict set force_mesh_order $element_id $element_forces
            if {$forced_mesh_order eq -1} {
                set forced_mesh_order $element_forces
            } else {
                if {$forced_mesh_order ne $element_forces} {
                    # W "The element $element_id requires a different mesh order"
                    W "Incompatible mesh orders in elements"
                    return -1
                }
            }
        }        
    }
    
    if {$forced_mesh_order ne -1} {
        
        set element [lindex [dict keys $force_mesh_order] 0]
        set previous_mesh_order [write::isquadratic]
        set current_mesh_type [Kratos::GetMeshOrderName $previous_mesh_order]
        set desired_mesh_type [Kratos::GetMeshOrderName $forced_mesh_order]
        if {$previous_mesh_order ne $forced_mesh_order} {
            W "The element $element requires a different mesh order: $desired_mesh_type"
            W "Currently the mesh order is $current_mesh_type. please change it in the menu Mesh > Quadratic type"
            return -1
        }
    }
    return 0
}

proc Mesh::AddPointElementsIfNeeded {} {
    # Foreach groups assigned in tree
    set condition_groups [spdAux::GetUsedConditions]

    # condition_groups is a dict of conditionid -> list of group nodes (tdom)
    foreach condid [dict keys $condition_groups] {
        set cond [Model::getCondition $condid]
        if {$cond eq ""} {
            continue
        }
        set topology [$cond getTopologyFeature "Point" 1]
        if {$topology eq ""} {
            continue
        }
        W " Groups assigned to condition $condid will be meshed with Point elements."

        set group_nodes [dict get $condition_groups $condid]
        foreach node_tdom $group_nodes {
            set group_id [get_domnode_attribute $node_tdom n]
            # Get the goodname of the group
            set group_id [write::GetWriteGroupName $group_id]
            
            set node_ids [GiD_EntitiesGroups get $group_id nodes]
            set new_nodeids [list]
            foreach nodeid $node_ids {
                set new_nodeid [GiD_Mesh create element append Point 1 [list $nodeid]]
                # Add to same groups as the node
                lappend new_nodeids $new_nodeid
            }
            GiD_EntitiesGroups assign $group_id elements $new_nodeids
        }
    }

    # if group element is point and has topology for points

    # foreach nodeid [GiD_Mesh] GiD_Mesh create element append Point 1 [list $nodeid]
}