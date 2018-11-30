proc DEM::write::WriteMDPAParts { } {
    variable last_property_id
    # Prepare properties
    write::processMaterials "" $last_property_id
    set last_property_id [expr $last_property_id + [dict size $::write::mat_dict]]
    # Headers
    write::writeModelPartData

    # Materials
    writeMaterialsParts

    # Nodal coordinates (only for DEM Parts <inefficient> )
    write::writeNodalCoordinatesOnParts; # Begin Nodes
    write::writeNodalCoordinatesOnGroups [GetWallsGroupsDEMSmp]

    # Element connectivities (Groups on STParts)
    write::writeElementConnectivities; # Begin elements SphericContinuumParticle3D

    # Element radius
    writeSphereRadius; # Begin NodalData RADIUS

    # Begin NodalData COHESIVE_GROUP
    # Begin NodalData SKIN_SPHERE

    # SubmodelParts
    write::writePartSubModelPart
    writeVelocityMeshes

    # CustomSubmodelParts
    #WriteWallCustomDEMSmp no cal pq en dem ja troba tots els grups.
}

proc DEM::write::WriteWallCustomDEMSmp { } {
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        W "$destination_mdpa"
        if {$destination_mdpa == "DEM"} {

            #write::WriteString  "Begin SubModelPart $groupid \/\/ Custom SubModelPart. Group name: $groupid"
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

proc DEM::write::GetWallsGroupsDEMSmp { } {
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


proc DEM::write::writeSphereRadius { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set grouppid [write::GetWriteGroupName $groupid]
        write::WriteString "Begin NodalData RADIUS // GUI group identifier: $grouppid"
        GiD_WriteCalculationFile connectivities [dict create $groupid "%.0s %10d 0 %10g\n"]
        write::WriteString "End NodalData"
        write::WriteString ""
    }
}

proc DEM::write::GetNodalConditionsGroups { {include_cond 0} } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        if {$include_cond} {lappend groups [[$group parent] @n]}
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::write2VelocityMeshes { } {
    foreach {cid groupid} [DEM::write::GetNodalConditionsGroups 1] {
        ::write::writeGroupSubModelPart $cid $groupid "nodal"
    }
}

proc DEM::write::writeVelocityMeshes { } {
    set i 0
    foreach {cond group_list} [GetSpheresGroupsListInConditions] {
        if {$cond eq "DEM-VelocityBC"} {
            set cnd [Model::getCondition $cond]
            foreach group $group_list {
                incr i
                write::WriteString "Begin SubModelPart $i // GUI DEM-VelocityBC - $cond - group identifier: $group"
                write::WriteString "  Begin SubModelPartData // DEM-VelocityBC. Group name: $group"
                set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$cond'\]/group\[@n = '$group'\]"
                set group_node [[customlib::GetBaseRoot] selectNodes $xp1]

                set prescribeMotion_flag [write::getValueByNode [$group_node selectNodes "./value\[@n='PrescribeMotion_flag'\]"]]
                if {[write::isBooleanTrue $prescribeMotion_flag]} {

                    # Linear velocity
                    set vX [write::getValueByNode [$group_node selectNodes "./value\[@n='LINEAR_VELOCITY_X'\]"]]
                    set vY [write::getValueByNode [$group_node selectNodes "./value\[@n='LINEAR_VELOCITY_Y'\]"]]
                    set vZ [write::getValueByNode [$group_node selectNodes "./value\[@n='LINEAR_VELOCITY_Z'\]"]]
                    write::WriteString "    LINEAR_VELOCITY \[3\] ($vX,$vY,$vZ)"

                    # Period
                    set periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='LINEAR_VELOCITY_PERIODIC_flag'\]"]]
                    if {[write::isBooleanTrue $periodic]} {
                        set period [write::getValueByNode [$group_node selectNodes "./value\[@n='VELOCITY_PERIOD'\]"]]
                    } else {
                        set period 0.0
                    }
                    write::WriteString "    VELOCITY_PERIOD $period"

                    # Angular velocity
                    set wX  [write::getValueByNode [$group_node selectNodes "./value\[@n='ANGULAR_VELOCITY_X'\]"]]
                    set wY  [write::getValueByNode [$group_node selectNodes "./value\[@n='ANGULAR_VELOCITY_Y'\]"]]
                    set wZ  [write::getValueByNode [$group_node selectNodes "./value\[@n='ANGULAR_VELOCITY_Z'\]"]]
                    write::WriteString "    ANGULAR_VELOCITY \[3\] ($wX,$wY,$wZ)"

                    # Angular center of rotation
                    set oX [write::getValueByNode [$group_node selectNodes "./value\[@n='ROTATION_CENTER_X'\]"]]
                    set oY [write::getValueByNode [$group_node selectNodes "./value\[@n='ROTATION_CENTER_Y'\]"]]
                    set oZ [write::getValueByNode [$group_node selectNodes "./value\[@n='ROTATION_CENTER_Z'\]"]]
                    write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,$oZ)"

                    # Angular Period
                    set angular_periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='ANGULAR_VELOCITY_PERIODIC_flag'\]"]]
                    if {[write::isBooleanTrue $angular_periodic]} {
                        set angular_period [write::getValueByNode [$group_node selectNodes "./value\[@n='ANGULAR_VELOCITY_PERIOD'\]"]]
                    } else {
                        set angular_period 0.0
                    }
                    write::WriteString "    ANGULAR_VELOCITY_PERIOD $angular_period"

                    # Interval
                    # set interval [write::getValueByNode [$group_node selectNodes "./value\[@n='Interval'\]"]]
                    # lassign [write::getInterval $interval] ini end
                    # if {![string is double $ini]} {
                    #     set ini [write::getValue DEMTimeParameters StartTime]
                    # }
                    # write::WriteString "    ${cond}_START_TIME $ini"
                    # if {![string is double $end]} {
                    #     set end [write::getValue DEMTimeParameters EndTime]
                    # }
                    # write::WriteString "    ${cond}_STOP_TIME $end"

                    write::WriteString "    VELOCITY_START_TIME 0.0"
                    write::WriteString "    VELOCITY_STOP_TIME 10100000"
                    write::WriteString "    ANGULAR_VELOCITY_START_TIME 0.0"
                    write::WriteString "    ANGULAR_VELOCITY_STOP_TIME 10100000.0"
                }

                # Hardcoded
                # write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
                # write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                # write::WriteString "    FREE_BODY_MOTION 0"
                # write::WriteString "    RIGID_BODY_MASS 0.0"
                # write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] (0.0,0.0,0.0)"
                # write::WriteString "    RIGID_BODY_INERTIAS \[3\] (0.0,0.0,0.0)"
                # write::WriteString "    IDENTIFIER [write::transformGroupName $group]"
                # write::WriteString "    TOP 0"
                # write::WriteString "    BOTTOM 0"
                # write::WriteString "    FORCE_INTEGRATION_GROUP 0"
                write::WriteString "  End SubModelPartData"
                write::WriteString "  Begin SubModelPartNodes"
                GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
                write::WriteString "  End SubModelPartNodes"
                write::WriteString "End SubModelPart"
                write::WriteString ""
            }
        } elseif {$cond eq "DEM-VelocityIC"} {
            set cnd [Model::getCondition $cond]
            foreach group $group_list {
                incr i
                write::WriteString "Begin SubModelPart $i // GUI DEM-VelocityIC - $cond - group identifier: $group"
                write::WriteString "  Begin SubModelPartData // DEM-VelocityIC. Group name: $group"
                set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$cond'\]/group\[@n = '$group'\]"
                set group_node [[customlib::GetBaseRoot] selectNodes $xp1]

                set prescribeMotion_flag [write::getValueByNode [$group_node selectNodes "./value\[@n='PrescribeMotion_flag'\]"]]
                if {[write::isBooleanTrue $prescribeMotion_flag]} {

                    # Linear velocity
                    set vX [write::getValueByNode [$group_node selectNodes "./value\[@n='INITIAL_VELOCITY_X_VALUE'\]"]]
                    set vY [write::getValueByNode [$group_node selectNodes "./value\[@n='INITIAL_VELOCITY_Y_VALUE'\]"]]
                    set vZ [write::getValueByNode [$group_node selectNodes "./value\[@n='INITIAL_VELOCITY_Z_VALUE'\]"]]
                    write::WriteString "    INITIAL_VELOCITY \[3\] ($vX,$vY,$vZ)"

                    # Angular velocity
                    set wX  [write::getValueByNode [$group_node selectNodes "./value\[@n='INITIAL_ANGULAR_VELOCITY_X_VALUE'\]"]]
                    set wY  [write::getValueByNode [$group_node selectNodes "./value\[@n='INITIAL_ANGULAR_VELOCITY_Y_VALUE'\]"]]
                    set wZ  [write::getValueByNode [$group_node selectNodes "./value\[@n='INITIAL_ANGULAR_VELOCITY_Z_VALUE'\]"]]
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY \[3\] ($wX,$wY,$wZ)"

                }

                write::WriteString "  End SubModelPartData"
                write::WriteString "  Begin SubModelPartNodes"
                GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
                write::WriteString "  End SubModelPartNodes"
                write::WriteString "End SubModelPart"
                write::WriteString ""
            }
        }
    }
}


proc DEM::write::GetSpheresGroupsListInConditions { } {
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

proc DEM::write::GetSpheresGroups { } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityBC'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::writeMaterialsParts { } {
    variable partsProperties
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Parts'\]/group"
    set partsProperties $::write::mat_dict
    #set ::write::mat_dict [dict create]
    #write::processMaterials $xp1
    #set partsProperties $::write::mat_dict
    #set ::write::mat_dict $old_mat_dict
    # WV inletProperties

    set printable [list PARTICLE_DENSITY YOUNG_MODULUS POISSON_RATIO FRICTION PARTICLE_COHESION COEFFICIENT_OF_RESTITUTION PARTICLE_MATERIAL ROLLING_FRICTION ROLLING_FRICTION_WITH_WALLS DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME]

    foreach group [dict keys $partsProperties] {
        write::WriteString "Begin Properties [dict get $partsProperties $group MID]"
        dict set partsProperties $group DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_D_Hertz_viscous_Coulomb
        dict set partsProperties $group DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME DEMContinuumConstitutiveLaw
        foreach {prop val} [dict get $partsProperties $group] {
            if {$prop in $printable} {
                write::WriteString "    $prop $val"
            }
        }
        write::WriteString "End Properties\n"
    }
}