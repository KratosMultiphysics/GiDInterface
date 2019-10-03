proc DEM::write::WriteMDPAParts { } {
    W "aqui no deberia entrar"
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
    #write::writeNodalCoordinatesOnGroups [GetDEMGroupsCustomSubmodelpart]
    write::writeNodalCoordinatesOnGroups [WriteWallGraphsFlag]
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsInitialC]
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsBoundayC]

    # Element connectivities (Groups on STParts)
    PrepareCustomMeshedParts
    write::writeElementConnectivities;
    RestoreCustomMeshedParts

    # Element radius
    writeSphereRadius; # Begin NodalData RADIUS

    # SubmodelParts
    write::writePartSubModelPart
    writeVelocityMeshes

    # CustomSubmodelParts
    #WriteWallCustomDEMSmp not required for dem.
}

proc DEM::write::WriteWallCustomDEMSmp { } {
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
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

proc DEM::write::GetDEMGroupsCustomSubmodelpart { } {
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

proc DEM::write::GetDEMGroupsInitialC { } {
    set groups [list ]
    set xp3 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityIC'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp3] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::GetDEMGroupsBoundayC { } {
    set groups [list ]
    set xp4 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityBC'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp4] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
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

                    set motion_type [write::getValueByNode [$group_node selectNodes "./value\[@n='DEM-VelocityBCMotion'\]"]]
                    if {$motion_type == "LinearPeriodic"} {


                        # Linear velocity
                        set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='VelocityModulus'\]"]]
                        lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='DirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                        write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, $vz)"

                        # Period
                        set periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriodic'\]"]]
                        if {[write::isBooleanTrue $periodic]} {
                            set period [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriod'\]"]]
                        } else {
                            set period 0.0
                        }
                        write::WriteString "    VELOCITY_PERIOD $period"

                        # Angular velocity
                        set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularVelocityModulus'\]"]]
                        lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularDirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] wX wY wZ
                        write::WriteString "    ANGULAR_VELOCITY \[3\] ($wX,$wY,$wZ)"


                        # Angular center of rotation
                        lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='CenterOfRotation'\]"]] oX oY oZ
                        write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,$oZ)"


                        # Angular Period
                        set angular_periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularPeriodic'\]"]]
                        if {[write::isBooleanTrue $angular_periodic]} {
                            set angular_period [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularPeriod'\]"]]
                        } else {
                            set angular_period 0.0
                        }
                        write::WriteString "    ANGULAR_VELOCITY_PERIOD $angular_period"

                        # # Interval
                        # set interval [write::getValueByNode [$group_node selectNodes "./value\[@n='Interval'\]"]]
                        # lassign [write::getInterval $interval] ini end
                        # if {![string is double $ini]} {
                        #     set ini [write::getValue DEMTimeParameters StartTime]
                        # }
                        # # write::WriteString "    ${cond}_START_TIME $ini"
                        # write::WriteString "    VELOCITY_START_TIME $ini"
                        # write::WriteString "    ANGULAR_VELOCITY_START_TIME $ini"
                        # if {![string is double $end]} {
                        #     set end [write::getValue DEMTimeParameters EndTime]
                        # }
                        # # write::WriteString "    ${cond}_STOP_TIME $end"
                        # write::WriteString "    VELOCITY_STOP_TIME $end"
                        # write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $end"


                        set LinearStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearStartTime'\]"]]
                        set LinearEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearEndTime'\]"]]
                        set AngularStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularStartTime'\]"]]
                        set AngularEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularEndTime'\]"]]
                        set rigid_body_motion 1
                        write::WriteString "    VELOCITY_START_TIME $LinearStartTime"
                        write::WriteString "    VELOCITY_STOP_TIME $LinearEndTime"
                        write::WriteString "    ANGULAR_VELOCITY_START_TIME $AngularStartTime"
                        write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $AngularEndTime"

                    } elseif {$motion_type == "FixedDOFs"} {
                        set rigid_body_motion 0

                        # DOFS
                        set Ax [write::getValueByNode [$group_node selectNodes "./value\[@n='Ax'\]"]]
                        set Ay [write::getValueByNode [$group_node selectNodes "./value\[@n='Ay'\]"]]
                        set Az [write::getValueByNode [$group_node selectNodes "./value\[@n='Az'\]"]]
                        set Bx [write::getValueByNode [$group_node selectNodes "./value\[@n='Bx'\]"]]
                        set By [write::getValueByNode [$group_node selectNodes "./value\[@n='By'\]"]]
                        set Bz [write::getValueByNode [$group_node selectNodes "./value\[@n='Bz'\]"]]
                        if {$Ax == "Constant"} {
                            set fix_vx [write::getValueByNode [$group_node selectNodes "./value\[@n='Vx'\]"]]
                            write::WriteString "    IMPOSED_VELOCITY_X_VALUE $fix_vx"
                        }
                        if {$Ay == "Constant"} {
                            set fix_vy [write::getValueByNode [$group_node selectNodes "./value\[@n='Vy'\]"]]
                            write::WriteString "    IMPOSED_VELOCITY_Y_VALUE $fix_vy"
                        }
                        if {$Az == "Constant"} {
                            set fix_vz [write::getValueByNode [$group_node selectNodes "./value\[@n='Vz'\]"]]
                            write::WriteString "    IMPOSED_VELOCITY_Z_VALUE $fix_vz"
                        }
                        if {$Bx == "Constant"} {
                            set fix_avx [write::getValueByNode [$group_node selectNodes "./value\[@n='AVx'\]"]]
                            write::WriteString "    IMPOSED_ANGULAR_VELOCITY_X_VALUE $fix_avx"
                        }
                        if {$By == "Constant"} {
                            set fix_avy [write::getValueByNode [$group_node selectNodes "./value\[@n='AVy'\]"]]
                            write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Y_VALUE $fix_avy"
                        }
                        if {$Bz == "Constant"} {
                            set fix_avz [write::getValueByNode [$group_node selectNodes "./value\[@n='AVz'\]"]]
                            write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Z_VALUE $fix_avz"
                        }
                        set VStart [write::getValueByNode [$group_node selectNodes "./value\[@n='VStart'\]"]]
                        set VEnd  [write::getValueByNode [$group_node selectNodes "./value\[@n='VEnd'\]"]]
                        write::WriteString "    VELOCITY_START_TIME $VStart"
                        write::WriteString "    VELOCITY_STOP_TIME $VEnd"

                    }

                    #Hardcoded
                    write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"

                }

                write::WriteString "  End SubModelPartData"
                write::WriteString "  Begin SubModelPartNodes"
                GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
                write::WriteString "  End SubModelPartNodes"
                write::WriteString "End SubModelPart"
                write::WriteString ""
            }
        } elseif {$cond eq "DEM-VelocityIC"} {
            set rigid_body_motion 0
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
                    set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='InitialVelocityModulus'\]"]]
                    lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='iDirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                    lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                    lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                    #write::WriteString "    INITIAL_VELOCITY \[3\] ($vx, $vy, $vz)"   # why arent we using vectorial def for this
                    write::WriteString "    INITIAL_VELOCITY_X_VALUE $vx"
                    write::WriteString "    INITIAL_VELOCITY_Y_VALUE $vy"
                    write::WriteString "    INITIAL_VELOCITY_Z_VALUE $vz"

                    # Angular velocity
                    set avelocity [write::getValueByNode [$group_node selectNodes "./value\[@n='InitialAngularVelocityModulus'\]"]]
                    lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='iAngularDirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                    lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                    lassign [MathUtils::ScalarByVectorProd $avelocity [list $velocity_X $velocity_Y $velocity_Z] ] wX wY wZ
                    #write::WriteString "    INITIAL_ANGULAR_VELOCITY \[3\] ($wX,$wY,$wZ)"

                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE $wX"
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE $wY"
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_Z_VALUE $wZ"
                }
                #Hardcoded
                write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"

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
    set xp2 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityIC'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp2] {
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

    set printable [list PARTICLE_DENSITY YOUNG_MODULUS POISSON_RATIO FRICTION PARTICLE_COHESION COEFFICIENT_OF_RESTITUTION PARTICLE_MATERIAL ROLLING_FRICTION ROLLING_FRICTION_WITH_WALLS PARTICLE_SPHERICITY DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME]

    foreach group [dict keys $partsProperties] {
        if {[dict get $partsProperties $group APPID] eq "DEM"} {
            write::WriteString "Begin Properties [dict get $partsProperties $group MID]"
            dict set partsProperties $group DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME DEMContinuumConstitutiveLaw
            foreach {prop val} [dict get $partsProperties $group] {
                if {$prop in $printable} {
                    write::WriteString "    $prop $val"
                }
            }
            write::WriteString "End Properties\n"
        }
    }
}

proc DEM::write::PrepareCustomMeshedParts { } {
    variable restore_ov
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        if {[$group hasAttribute ov]} {set prev_ov [$group @ov]} {set prev_ov [[$group parent] @ov]}
        dict set restore_ov $groupid $prev_ov
        # We must force it to be volume/surface because anything applied to Parts will be converted into Spheres/Circles
        if {$::Model::SpatialDimension eq "3D"} {
            $group setAttribute ov volume
        } else {
            $group setAttribute ov surface
        }
    }
}

proc DEM::write::RestoreCustomMeshedParts { } {
    variable restore_ov
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        if {$groupid in [dict keys $restore_ov]} {
            set prev_ov [dict get $restore_ov $groupid]
            # Bring back to original entities (Check PrepareCustomMeshedParts)
            $group setAttribute ov $prev_ov
        }
    }
    set restore_ov [dict create]
}