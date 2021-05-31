proc DEM::write::WriteMDPAParts { } {
    # Headers
    write::writeModelPartData
    
    # Process properties
    DEM::write::processPartMaterials
    
    # Write Materials
    writeMaterialsParts
    
    # Nodal coordinates (only for DEM Parts <inefficient> )
    write::writeNodalCoordinatesOnParts
    write::writeNodalCoordinatesOnGroups [DEM::write::GetDEMGroupNamesCustomSubmodelpart]
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsInitialC]
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsBoundaryC]
    write::writeNodalCoordinatesOnGroups [GetNodesForGraphs]
    
    # Element connectivities (Groups on Parts)
    PrepareCustomMeshedParts
    write::writeElementConnectivities
    RestoreCustomMeshedParts
    
    # Element radius
    writeSphereRadius
    
    # SubmodelParts
    write::writePartSubModelPart
    writeDEMConditionMeshes
    
    # CustomSubmodelParts
    WriteCustomDEMSmp
}


proc DEM::write::GetDEMGroupNamesCustomSubmodelpart { } {
    set groups [list ]
    foreach group [DEM::write::GetDEMGroupsCustomSubmodelpart] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}
proc DEM::write::GetDEMGroupsCustomSubmodelpart { } {
    set groups [list ]
    set xp2 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp2] {
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        if {$destination_mdpa == "DEM"} {
            lappend groups $group
        }
    }
    return $groups
}

proc DEM::write::GetDEMGroupsInitialC { } {
    set groups [list ]
    if {$::Model::SpatialDimension eq "2D"} { 
        set xp3 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityIC2D'\]/group"
    } else {
        set xp3 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityIC'\]/group"
    }
    foreach group [[customlib::GetBaseRoot] selectNodes $xp3] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::GetDEMGroupsBoundaryC { } {
    set groups [list ]
    if {$::Model::SpatialDimension eq "2D"} { 
        set xp4 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityBC2D'\]/group"
    } else {
        set xp4 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-VelocityBC'\]/group"
    }
    foreach group [[customlib::GetBaseRoot] selectNodes $xp4] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::GetNodesForGraphs { } {
    set groups [list ]
    if {$::Model::SpatialDimension eq "2D"} { 
        set xp5 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-GraphCondition2D'\]/group"
    } else {
        set xp5 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-GraphCondition'\]/group"
    }
    foreach group [[customlib::GetBaseRoot] selectNodes $xp5] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::writeSphereRadius { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach group [$root selectNodes $xp1] {
        DEM::write::writeSphereRadiusOnGroup $group
    }
}

proc DEM::write::writeSphereRadiusOnGroup { group } {
    set groupid [$group @n]
    set print_groupid [write::GetWriteGroupName $groupid]
    write::WriteString "Begin NodalData RADIUS // GUI group identifier: $print_groupid"
    GiD_WriteCalculationFile connectivities [dict create $groupid "%.0s %10d 0 %10g\n"]
    write::WriteString "End NodalData"
    write::WriteString ""
}

proc DEM::write::writeDEMConditionMeshes { } {
    foreach {cond group_list} [GetSpheresGroupsListInConditions] {
        if {$cond in {"DEM-VelocityBC" "DEM-VelocityBC2D"}} {
            #set cnd [Model::getCondition $cond]
            foreach group $group_list {
                set mid [write::AddSubmodelpart $cond $group]
                write::WriteString "Begin SubModelPart $mid // GUI DEM-VelocityBC - $cond - group identifier: $group"
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
                        if {$::Model::SpatialDimension eq "2D"} {
                            lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y]] velocity_X velocity_Y
                            lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y] ] vx vy
                            write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, 0.0)"
                        } else {
                            lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                            lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                            write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, $vz)"}
                        
                        # Period
                        set periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriodic'\]"]]
                        if {[write::isBooleanTrue $periodic]} {
                            set period [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriod'\]"]]
                        } else {set period 0.0}
                        write::WriteString "    VELOCITY_PERIOD $period"
                        
                        # Angular velocity
                        set avelocity [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularVelocityModulus'\]"]]
                        if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    ANGULAR_VELOCITY \[3\] (0.0,0.0,$avelocity)"
                        } else {
                            lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularDirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                            lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                            lassign [MathUtils::ScalarByVectorProd $avelocity [list $velocity_X $velocity_Y $velocity_Z] ] wX wY wZ
                            write::WriteString "    ANGULAR_VELOCITY \[3\] ($wX,$wY,$wZ)"}
                        
                        # Angular center of rotation
                        lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='CenterOfRotation'\]"]] oX oY oZ
                        if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,0.0)"
                        } else {write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,$oZ)"}
                        
                        # Angular Period
                        set angular_periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularPeriodic'\]"]]
                        if {[write::isBooleanTrue $angular_periodic]} {
                            set angular_period [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularPeriod'\]"]]
                        } else {
                            set angular_period 0.0
                        }
                        write::WriteString "    ANGULAR_VELOCITY_PERIOD $angular_period"
                        
                        set LinearStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearStartTime'\]"]]
                        set LinearEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearEndTime'\]"]]
                        set AngularStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularStartTime'\]"]]
                        set AngularEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularEndTime'\]"]]
                        set rigid_body_motion 1
                        write::WriteString "    VELOCITY_START_TIME $LinearStartTime"
                        write::WriteString "    VELOCITY_STOP_TIME $LinearEndTime"
                        write::WriteString "    ANGULAR_VELOCITY_START_TIME $AngularStartTime"
                        write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $AngularEndTime"
                        write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                        
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
                        write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                        
                    }
                }
                
                DefineDEMExtraConditions $group_node $group
                write::WriteString "  End SubModelPartData"
                write::WriteString "  Begin SubModelPartNodes"
                GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
                write::WriteString "  End SubModelPartNodes"
                write::WriteString "End SubModelPart"
                write::WriteString ""
            }
        } elseif {$cond in {"DEM-VelocityIC" "DEM-VelocityIC2D"}} {
            set rigid_body_motion 0
            #set cnd [Model::getCondition $cond]
            foreach group $group_list {
                set mid [write::AddSubmodelpart $cond $group]
                write::WriteString "Begin SubModelPart $mid // GUI DEM-VelocityIC - $cond - group identifier: $group"
                write::WriteString "  Begin SubModelPartData // DEM-VelocityIC. Group name: $group"
                set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$cond'\]/group\[@n = '$group'\]"
                set group_node [[customlib::GetBaseRoot] selectNodes $xp1]
                
                set prescribeMotion_flag [write::getValueByNode [$group_node selectNodes "./value\[@n='PrescribeMotion_flag'\]"]]
                if {[write::isBooleanTrue $prescribeMotion_flag]} {
                    
                    # Linear velocity
                    set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='InitialVelocityModulus'\]"]]
                    lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='iDirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                    #write::WriteString "    INITIAL_VELOCITY \[3\] ($vx, $vy, $vz)"
                    if {$::Model::SpatialDimension eq "2D"} {
                        lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y]] velocity_X velocity_Y
                        lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y] ] vx vy
                        write::WriteString "    INITIAL_VELOCITY_X_VALUE $vx"
                        write::WriteString "    INITIAL_VELOCITY_Y_VALUE $vy"
                        write::WriteString "    INITIAL_VELOCITY_Z_VALUE 0.0"
                    } else {
                        lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                        write::WriteString "    INITIAL_VELOCITY_X_VALUE $vx"
                        write::WriteString "    INITIAL_VELOCITY_Y_VALUE $vy"
                        write::WriteString "    INITIAL_VELOCITY_Z_VALUE $vz"}
                    
                    # Angular velocity
                    set avelocity [write::getValueByNode [$group_node selectNodes "./value\[@n='InitialAngularVelocityModulus'\]"]]
                    if {$::Model::SpatialDimension eq "2D"} {
                        write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE 0.0"
                        write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE 0.0"
                        write::WriteString "    INITIAL_ANGULAR_VELOCITY_Z_VALUE $avelocity"
                    } else {
                        lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='iAngularDirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::ScalarByVectorProd $avelocity [list $velocity_X $velocity_Y $velocity_Z] ] wX wY wZ
                        write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE $wX"
                        write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE $wY"
                        write::WriteString "    INITIAL_ANGULAR_VELOCITY_Z_VALUE $wZ"}
                }
                #Hardcoded
                write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                DefineDEMExtraConditions $group_node $group
                
                write::WriteString "  End SubModelPartData"
                write::WriteString "  Begin SubModelPartNodes"
                GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
                write::WriteString "  End SubModelPartNodes"
                write::WriteString "End SubModelPart"
                write::WriteString ""
            }
        } elseif {$cond in {"DEM-GraphCondition" "DEM-GraphCondition2D"}} {
            foreach group $group_list {
                
                set mid [write::AddSubmodelpart $cond $group]
                write::WriteString "Begin SubModelPart $mid // GUI DEM-GraphCondition - $cond - group identifier: $group"
                write::WriteString "  Begin SubModelPartData // DEM-GraphCondition. Group name: $group"
                set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$cond'\]/group\[@n = '$group'\]"
                set group_node [[customlib::GetBaseRoot] selectNodes $xp1]
                
                DefineDEMExtraConditions $group_node $group
                
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

proc DEM::write::DefineDEMExtraConditions {group_node group} {
    set GraphPrint [write::getValueByNode [$group_node selectNodes "./value\[@n='GraphPrint'\]"]]
    if {$GraphPrint == "true"} {
        set GraphPrintval 1
    } else {
        set GraphPrintval 0
    }
    write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
    write::WriteString "    IDENTIFIER [write::transformGroupName $group]"
}

# TODO: This code is extremely inefficient -> find a simple way to solve it
proc DEM::write::GetSpheresGroupsListInConditions { } {
    set conds_groups_dict [dict create ]
    set groups [list ]
    
    # Get all the groups with spheres
    foreach group [GetSpheresGroups] {
        foreach surface [GiD_EntitiesGroups get $group nodes] {
            foreach involved_group [GiD_EntitiesGroups entity_groups nodes $surface] {
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

    set conditions_list {DEM-VelocityBC DEM-VelocityIC DEM-GraphCondition}
    if {$::Model::SpatialDimension eq "2D"} {
        set conditions_list {DEM-VelocityBC2D DEM-VelocityIC2D DEM-GraphCondition2D}
    }

    foreach condition $conditions_list {
        set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition'\]/group"
        foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
            set groupid [$group @n]
            lappend groups [write::GetWriteGroupName $groupid]
        }
    }
    
    return $groups
}


proc DEM::write::processPartMaterials { } {
    variable partsProperties
    # Materials for parts are already processed
    #W [write::processMaterials]
    set partsProperties [write::getPropertiesList [GetAttribute parts_un] 0 SpheresPart]
}

proc DEM::write::writeMaterialsParts { } {
    
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
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


proc DEM::write::WriteCustomDEMSmp { } {
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set group_id [$group @n]
        
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        if {$destination_mdpa == "DEM"} {
            set mid [write::AddSubmodelpart DEM-CustomSmp $group_id]
            write::WriteString  "Begin SubModelPart $mid \/\/ Custom SubModelPart. Group name: $group_id"
            write::WriteString  "Begin SubModelPartData"
            write::WriteString  "End SubModelPartData"
            write::WriteString  "Begin SubModelPartNodes"
            GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group_id] [subst "%10i\n"]]
            write::WriteString  "End SubModelPartNodes"
            write::WriteString  "End SubModelPart"
            write::WriteString  ""
        }
    }
}