proc CDEM::write::WriteMDPAParts { } {
    variable last_property_id

    # Prepare properties
    write::processMaterials "" $last_property_id;   # TODO Aqui es la segunda vez que se llama. PQ?
    set last_property_id [expr $last_property_id + [dict size $::write::mat_dict]]

    # Headers
    write::writeModelPartData

    # Materials
    writeMaterialsParts

    # Nodal coordinates (only for DEM Parts <inefficient> )
    write::writeNodalCoordinatesOnParts
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsCustomSubmodelpart]
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsInitialC]
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsBoundayC]

    # Element connectivities
    write::writeElementConnectivities

    # Begin NodalData RADIUS
    writeSphereRadius

    # Begin NodalData COHESIVE_GROUP
    writeCohesiveGroups

    # Begin NodalData SKIN_SPHERE
    writeSkinSphereNodes

    # SubmodelParts
    write::writePartSubModelPart
	if {$::Model::SpatialDimension eq "2D"} {DEM::write::writeDEMConditionMeshes2D
    } else {DEM::write::writeDEMConditionMeshes}

    # CustomSubmodelParts
    #WriteWallCustomDEMSmp not required for dem.
}

proc CDEM::write::WriteWallCustomDEMSmp { } {
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
	if {$destination_mdpa == "DEM"} {

	    write::WriteString  "Begin SubModelPart $groupid \/\/ Custom SubModelPart. Group name: $groupid"
	    write::WriteString  "Begin SubModelPartData // DEM-FEM-Wall. Group name: $groupid"
	    write::WriteString  "End SubModelPartData"
	    write::WriteString  "Begin SubModelPartNodes"
	    GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $groupid] [subst "%10i\n"]]
	    write::WriteString  "End SubModelPartNodes"
	    write::WriteString  "End SubModelPart"
	    write::WriteString  ""
	}
    }
}

proc CDEM::write::GetDEMGroupsCustomSubmodelpart { } {
    set groups [list ]
    set xp2 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp2] {
	set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
	if {$destination_mdpa == "DEM"} {
	    set groupid [$group @n]
	    lappend groups [write::GetWriteGroupName $groupid]
	}
    }
    return $groups
}

proc CDEM::write::GetDEMGroupsInitialC { } {
    set groups [list ]
    set xp3 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityIC'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp3] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc CDEM::write::GetDEMGroupsBoundayC { } {
    set groups [list ]
    set xp4 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityBC'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp4] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}


proc CDEM::write::writeSphereRadius { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute partscont_un]]/group"
    foreach group [$root selectNodes $xp1] {
	set groupid [$group @n]
	set grouppid [write::GetWriteGroupName $groupid]
	write::WriteString "Begin NodalData RADIUS // GUI group identifier: $grouppid"
	GiD_WriteCalculationFile connectivities [dict create $groupid "%.0s %10d 0 %10g\n"]
	write::WriteString "End NodalData"
	write::WriteString ""
    }
}


proc CDEM::write::writeCohesiveGroups { } {
    set root [customlib::GetBaseRoot]
    if {$::Model::SpatialDimension eq "3D"} {
        set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-Cohesive'\]/group"
    } else {
        set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-Cohesive2D'\]/group"
    }
    set cohesive_group 0
    foreach group [$root selectNodes $xp1] {
        incr cohesive_group
        set groupid [$group @n]
        set grouppid [write::GetWriteGroupName $groupid]
        write::WriteString "Begin NodalData COHESIVE_GROUP // GUI group identifier: $grouppid"
        GiD_WriteCalculationFile connectivities [dict create $groupid "%.0s %10d 0 $cohesive_group\n"]
        write::WriteString "End NodalData"
        write::WriteString ""

    }
}

proc CDEM::write::writeSkinSphereNodes { } {
    # Write Skin Sphere
    set number 1
    set list_of_active_dem_elements ""
	if {[GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE]} {
        if {$::Model::SpatialDimension eq "2D"} {
            set skin_element_ids [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE all_mesh -element_type circle] ; # Get the ids of elements in SKIN_SPHERE
        } else {
            set skin_element_ids [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE all_mesh -element_type sphere]
        }
	} else {
	    set skin_element_ids [list]
	}

    write::WriteString "Begin NodalData SKIN_SPHERE"
    GiD_WriteCalculationFile connectivities [dict create SKIN_SPHERE_DO_NOT_DELETE "%.0s %10d 0 $number\n"]
    write::WriteString "End NodalData"
	write::WriteString ""
}



proc CDEM::write::GetNodalConditionsGroups { {include_cond 0} } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	if {$include_cond} {lappend groups [[$group parent] @n]}
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

# proc DEM::write::write2VelocityMeshes { } {
#     foreach {cid groupid} [DEM::write::GetNodalConditionsGroups 1] {
# 	::write::writeGroupSubModelPart $cid $groupid "nodal"
#     }
# }

proc CDEM::write::GetSpheresGroupsListInConditions { } {
    set conds_groups_dict [dict create ]
    set groups [list ]

    # Get all the groups with spheres
    foreach group [GetSpheresGroups] {
		foreach surface [GiD_EntitiesGroups get $group elements] {
			foreach involved_group [GiD_EntitiesGroups entity_groups elements $surface] {
				set involved_group_id [write::GetWriteGroupName $involved_group]
				if {$involved_group_id ni $groups} {lappend groups $involved_group_id}
			}
		}
    }

    # Find the relations condition -> group
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition"
    foreach cond [[customlib::GetBaseRoot] selectNodes $xp1] {
		set condid [$cond @n]
		foreach cond_group [$cond selectNodes "group"] {
			set group [write::GetWriteGroupName [$cond_group @n]]
			if {$group in $groups} {dict lappend conds_groups_dict $condid [$cond_group @n]}
		}
    }
    return $conds_groups_dict
}

proc CDEM::write::GetSpheresGroups { } {
    set groups [list ]
	if {$::Model::SpatialDimension eq "2D"} { set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityBC2D'\]/group"
    } else {set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityBC'\]/group"}
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    if {$::Model::SpatialDimension eq "2D"} { set xp2 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityIC2D'\]/group"
    } else {set xp2 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityIC'\]/group"}
    foreach group [[customlib::GetBaseRoot] selectNodes $xp2] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }

    return $groups
}

proc CDEM::write::writeMaterialsParts { } {
    variable partsProperties
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'PartsCont'\]/group"
    set partsProperties $::write::mat_dict
    set printable [list PARTICLE_DENSITY \
						YOUNG_MODULUS \
						POISSON_RATIO \
						FRICTION \
						COEFFICIENT_OF_RESTITUTION \
						PARTICLE_MATERIAL \
						ROLLING_FRICTION \
						ROLLING_FRICTION_WITH_WALLS \
						CONTACT_SIGMA_MIN \
						CONTACT_TAU_ZERO \
						CONTACT_INTERNAL_FRICC \
						ConstitutiveLaw \
						SHEAR_ENERGY_COEF \
						LOOSE_MATERIAL_YOUNG_MODULUS \
						FRACTURE_ENERGY \
						INTERNAL_FRICTION_ANGLE]

	foreach group [dict keys $partsProperties] {
        write::WriteString "Begin Properties [dict get $partsProperties $group MID]"
        foreach {prop val} [dict get $partsProperties $group] {
            if {$prop in $printable} {
                if {$prop eq "ConstitutiveLaw"} {
                    write::WriteString "    DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME $val"
                } elseif {$prop eq "FRICTION"} {
                    set pi $MathUtils::PI
                    set propvalue [expr {tan($val*$pi/180.0)}]
                    write::WriteString "    FRICTION $propvalue"
                } else {
                    write::WriteString "    $prop $val"
                }
            }
        }
        if {$::Model::SpatialDimension eq "2D"} {
            write::WriteString "    DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_D_Linear_viscous_Coulomb2D"
        } else {
            write::WriteString "    DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_D_Linear_viscous_Coulomb"}

        write::WriteString "End Properties\n"
    }
}
