proc ::DEM::write::getDEMMaterialsDict { } {
    # TODO: Remove properties in mdpas ? Check with MA. Probably remove material properties but check the process properties
    # TODO: Check 2d dem fem wall is written twice, also as phantom
    # TODO: Materials have more properties than expected. Write from properties variables, not from xml

    # Loop over parts, inlets and walls to list the materials to print. For each material used print: DENSITY, YOUNG_MODULUS, POISSON_RATIO
    # print COMPUTE_WEAR as false always, too (temporal fix)
    # While looping, create the assignation_table_list
    set materials_node_list [DEM::write::GetDEMUsedMaterialsNodeList]
    set materials_list [list ]
    set processed_mats [dict create ]

    set matid 0
    foreach mat_node $materials_node_list {
        set mat_name [write::getValueByNode $mat_node]
        if {$mat_name ni [dict keys $processed_mats]} {
            incr matid
            set mat [dict create]
            dict set mat material_name $mat_name
            dict set mat material_id $matid
            set material_xp "[spdAux::getRoute [GetAttribute materials_un]]/blockdata\[@name='$mat_name'\]"
            foreach param [[customlib::GetBaseRoot] selectNodes "$material_xp/value"] {
                dict set mat Variables [$param @n] [write::getValueByNode $param]
            }
            lappend materials_list $mat
            dict set processed_mats $mat_name $matid
        }
    }

    # Loop over the material relations, which is a new menu in the tree linking each possible pair of materials
    set material_relations_node_list [DEM::write::GetMaterialRelationsNodeList]
    set material_relations_list [list ]

    foreach mat_rel_node $material_relations_node_list {
        set mat_rel [dict create ]
        set mat_a [write::getValueByNode [$mat_rel_node selectNodes "./value\[@n = 'MATERIAL_A'\]"]]
        set mat_b [write::getValueByNode [$mat_rel_node selectNodes "./value\[@n = 'MATERIAL_B'\]"]]
        if {[dict exists $processed_mats $mat_a] && [dict exists $processed_mats $mat_b]} {
            dict set mat_rel material_names_list [list $mat_a $mat_b]
            dict set mat_rel material_ids_list [list [dict get $processed_mats $mat_a] [dict get $processed_mats $mat_b]]
            foreach param [$mat_rel_node selectNodes "./value"] {
                set param_name [$param @n]
                if {$param_name eq "ConstitutiveLaw"} {set param_name "DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME"}
                if {$param_name ni [list MATERIAL_A MATERIAL_B]} {
                    dict set mat_rel Variables $param_name [write::getValueByNode $param]
                }
            }
            lappend material_relations_list $mat_rel
        }
    }

    # Submodelpart - material assignation
    set assignation_table_list [list ]
    foreach mnode $materials_node_list {
        set gnode [$mnode parent]
        set active_group_node [$gnode selectNodes "value\[@n='SetActive'\]"]
        if {$active_group_node ne ""} {
            if {[write::isBooleanFalse [write::getValueByNode $active_group_node]]} {
                continue
            }
        }
        set mat_name [write::getValueByNode $mnode]
        set group_name [write::GetWriteGroupName [$gnode @n]]
        set cond_name [[$gnode parent] @n]
        set submodelpart_id [write::getSubModelPartId $cond_name $group_name]
        set modelpart_parent [DEM::write::GetModelPartParentNameFromGroup $cond_name]
        lappend assignation_table_list [list ${modelpart_parent}.${submodelpart_id} $mat_name]

    }


    dict set global_dict "materials" $materials_list
    dict set global_dict "material_relations" $material_relations_list
    dict set global_dict "material_assignation_table" $assignation_table_list

    ValidateMaterialRelations $materials_list $material_relations_list $assignation_table_list

    return $global_dict
}

proc ::DEM::write::GetModelPartParentNameFromGroup {condition} {

    set model_part_parent SpheresPart
    # if {$group in [DEM::write::GetWallsGroups]} {set model_part_parent "RigidFacePart"}
    if {$condition in [list "Parts_FEM" "FEMVelocity" ""]} {set model_part_parent "RigidFacePart"}
    # if {$group in [DEM::write::GetInletGroups]} {set model_part_parent "DEMInletPart"}
    return $model_part_parent
}


proc ::DEM::write::GetDEMUsedMaterialsNodeList { } {
    # Dem needs more material information than default
    set materials [list ]

    set root [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute DEMROOT]]
    foreach mat [$root selectNodes "descendant::group/value\[@n='Material'\]"] {
        lappend materials $mat
    }
    return $materials
}

proc ::DEM::write::GetMaterialRelationsNodeList { } {
    # Dem needs more material information than default
    set material_relations [list ]

    set root [customlib::GetBaseRoot]

    set material_relations_xp "[spdAux::getRoute DEMMaterialRelations]/blockdata\[@n='material_relation'\]"
    foreach mat_rel_node [[customlib::GetBaseRoot] selectNodes $material_relations_xp] {
        lappend material_relations $mat_rel_node
    }
    return $material_relations
}

proc ::DEM::write::ValidateMaterialRelations {materials relations assignations} {
    set material_relations [DEM::xml::GetMaterialRelationsTable]

    foreach relation_ref [dict keys $material_relations] {
        foreach relation_check [dict keys [dict get $material_relations $relation_ref]] {
            if {![dict get $material_relations $relation_ref $relation_check]} {
                W "Missing relation between $relation_ref and $relation_check"
            }
        }
    }
}