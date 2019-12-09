proc DEM::write::WriteMDPAWalls { } {
    # Headers
    write::writeModelPartData

    # Material
    set wall_properties [WriteWallProperties]

    # Nodal coordinates (only for Walls <inefficient> )
    write::writeNodalCoordinatesOnGroups [GetWallsGroups]
    write::writeNodalCoordinatesOnGroups [GetWallsGroupsSmp]
    write::writeNodalCoordinatesOnGroups [GetNodesForGraphs]

    # Nodal conditions and conditions
    writeConditions $wall_properties

    # SubmodelParts
    if {$::Model::SpatialDimension eq "2D"} { writeConditionMeshes2D
    } else {writeConditionMeshes}


    # CustomSubmodelParts
    WriteWallCustomSmp
    # WriteWallGraphsFlag  # TODO, under revision
}



proc DEM::write::WriteWallProperties { } {
    set wall_properties [dict create ]
    set cnd [Model::getCondition "DEM-FEM-Wall"]

    if {$::Model::SpatialDimension eq "2D"} {set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall2D'\]/group"
    } else {    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
    }

    #set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
    set i $DEM::write::last_property_id
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	incr i
	write::WriteString "Begin Properties $i"
	#foreach {prop obj} [$cnd getAllInputs] {
	#    if {$prop in $print_list} {
	#        set v [write::getValueByNode [$group selectNodes "./value\[@n='$prop'\]"]]
	#        write::WriteString "  $prop $v"
	#    }
	#}
    set friction_value [write::getValueByNode [$group selectNodes "./value\[@n='friction_angle'\]"]]
    set pi $MathUtils::PI
    set propvalue [expr {tan($friction_value*$pi/180.0)}]
	write::WriteString "  FRICTION $propvalue"
	# write::WriteString "  FRICTION [write::getValueByNode [$group selectNodes "./value\[@n='friction_coeff'\]"]]"
	write::WriteString "  WALL_COHESION [write::getValueByNode [$group selectNodes "./value\[@n='WallCohesion'\]"]]"
	set compute_wear_bool [write::getValueByNode [$group selectNodes "./value\[@n='DEM_Wear'\]"]]
	if {[write::isBooleanTrue $compute_wear_bool]} {
	    set compute_wear 1
	    set severiy_of_wear [write::getValueByNode [$group selectNodes "./value\[@n='K_Abrasion'\]"]]
	    set impact_wear_severity [write::getValueByNode [$group selectNodes "./value\[@n='K_Impact'\]"]]
	    set brinell_hardness [write::getValueByNode [$group selectNodes "./value\[@n='H_Brinell'\]"]]
	} else {
	    set compute_wear 0
	    set severiy_of_wear 0.001
	    set impact_wear_severity 0.001
	    set brinell_hardness 200.0
	}
	set rigid_structure_bool [write::getValueByNode [$group selectNodes "./value\[@n='RigidPlane'\]"]]
	if {[write::isBooleanTrue $rigid_structure_bool]} {
	    set young_modulus [write::getValueByNode [$group selectNodes "./value\[@n='YoungModulus'\]"]]
	    set poisson_ratio [write::getValueByNode [$group selectNodes "./value\[@n='PoissonRatio'\]"]]
	} else {
	    set young_modulus 1e20
	    set poisson_ratio 0.25
	}
	write::WriteString "  COMPUTE_WEAR $compute_wear"
	write::WriteString "  SEVERITY_OF_WEAR $severiy_of_wear"
	write::WriteString "  IMPACT_WEAR_SEVERITY $impact_wear_severity"
	write::WriteString "  BRINELL_HARDNESS $brinell_hardness"
	write::WriteString "  YOUNG_MODULUS $young_modulus"
	write::WriteString "  POISSON_RATIO $poisson_ratio"

	write::WriteString "End Properties"
	set groupid [$group @n]
	dict set wall_properties $groupid $i
	incr DEM::write::last_property_id
    }
    write::WriteString ""
    return $wall_properties
}


proc DEM::write::WriteWallCustomSmp { } {
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    set i $DEM::write::last_property_id
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	incr i
	set groupid [$group @n]
	set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
	if {$destination_mdpa == "FEM"} {

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

proc DEM::write::WriteWallGraphsFlag { } {
    set xp1 "[spdAux::getRoute [GetAttribute graphs_un]]/group"
    #set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	    write::WriteString  "Begin SubModelPart $groupid \/\/ Custom SubModelPart. Group name: $groupid"
	    write::WriteString  "Begin SubModelPartData // DEM-FEM-Wall. Group name: $groupid"
	    write::WriteString  "FORCE_INTEGRATION_GROUP 1"
	    write::WriteString  "End SubModelPartData"
	    write::WriteString  "Begin SubModelPartNodes"
	    GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $groupid] [subst "%10i\n"]]
	    write::WriteString  "End SubModelPartNodes"
	    write::WriteString  "End SubModelPart"
	    write::WriteString  ""
    }
}

proc DEM::write::GetNodesForGraphs { } {
    set groups [list ]
    #set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
    #set xp1 "[spdAux::getRoute [GetAttribute graphs_un]]/condition\[@n = 'Graphs'\]/group"
    set xp1 "[spdAux::getRoute [GetAttribute graphs_un]]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::writeConditions { wall_properties } {

    write::writeConditionsByGiDId DEMConditions DEM-FEM-Wall $wall_properties
}



proc DEM::write::GetWallsGroups { } {
    set groups [list ]
    if {$::Model::SpatialDimension eq "2D"} {set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall2D'\]/group"
    } else {    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
    }
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::GetWallsGroupsSmp { } {
    set groups [list ]
    set xp2 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp2] {
	set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
	if {$destination_mdpa == "FEM"} {
	    set groupid [$group @n]
	    lappend groups [write::GetWriteGroupName $groupid]
	    }
	}
    return $groups
}

proc DEM::write::GetWallsGroupsListInConditions { } {
    set conds_groups_dict [dict create ]
    set groups [list ]

    # Get all the groups with surfaces involved in walls
    foreach group [GetWallsGroups] {
	foreach surface [GiD_EntitiesGroups get $group surfaces] {
	    foreach involved_group [GiD_EntitiesGroups entity_groups surfaces $surface] {
		set involved_group_id [write::GetWriteGroupName $involved_group]
		if {$involved_group_id ni $groups} {lappend groups $involved_group_id}
	    }
	}
    }

    foreach group [GetWallsGroups] {
        foreach line [GiD_EntitiesGroups get $group lines] {
            foreach involved_group [GiD_EntitiesGroups entity_groups lines $line] {
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

proc DEM::write::GetConditionsGroups { } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::writeConditionMeshes { } {
    set i 0
    set cond "DEM-FEM-Wall"
    foreach group [GetWallsGroups] {
        incr i
        write::WriteString "Begin SubModelPart $i // GUI DEM-FEM-Wall - $cond - group identifier: $group"
        write::WriteString "  Begin SubModelPartData // DEM-FEM-Wall. Group name: $group"
        set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$cond'\]/group\[@n = '$group'\]"
        set group_node [[customlib::GetBaseRoot] selectNodes $xp1]

        set is_active [write::getValueByNode [$group_node selectNodes "./value\[@n='SetActive'\]"]]
        if {[write::isBooleanTrue $is_active]} {
            set motion_type [write::getValueByNode [$group_node selectNodes "./value\[@n='DEM-ImposedMotion'\]"]]
            if {$motion_type == "LinearPeriodic"} {

                # Linear velocity
                set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='VelocityModulus'\]"]]
                lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='DirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, $vz)"

                # set vX [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearVelocityX'\]"]]
                # set vY [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearVelocityY'\]"]]
                # set vZ [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearVelocityZ'\]"]]
                # write::WriteString "    LINEAR_VELOCITY \[3\] ($vX,$vY,$vZ)"

                # Period
                set periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriodic'\]"]]
                if {[write::isBooleanTrue $periodic]} {
                    set period [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriod'\]"]]
                } else {
                    set period 0.0
                }
                write::WriteString "    VELOCITY_PERIOD $period"

                # Angular velocity
                set avelocity [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularVelocityModulus'\]"]]
                lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularDirectionVector'\]"]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::ScalarByVectorProd $avelocity [list $velocity_X $velocity_Y $velocity_Z] ] wx wy wz
                write::WriteString "    ANGULAR_VELOCITY \[3\] ($wx,$wy,$wz)"

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

                # set intervals
                set LinearStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearStartTime'\]"]]
                set LinearEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearEndTime'\]"]]
                set AngularStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularStartTime'\]"]]
                set AngularEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularEndTime'\]"]]
                write::WriteString "    VELOCITY_START_TIME $LinearStartTime"
                write::WriteString "    VELOCITY_STOP_TIME $LinearEndTime"
                write::WriteString "    ANGULAR_VELOCITY_START_TIME $AngularStartTime"
                write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $AngularEndTime"

                set fixed_mesh_option_bool [write::getValueByNode [$group_node selectNodes "./value\[@n='fixed_wall'\]"]]
                if {[write::isBooleanTrue $fixed_mesh_option_bool]} {
                    set fixed_mesh_option 1
                } else {
                    set fixed_mesh_option 0
                }
                set rigid_body_motion 1
                set free_body_motion 0
                #Hardcoded
                write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
                write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                write::WriteString "    FREE_BODY_MOTION $free_body_motion"

            } elseif {$motion_type == "FreeMotion"} {
                set fixed_mesh_option 0
                set rigid_body_motion 0
                set free_body_motion 1

                set mass [write::getValueByNode [$group_node selectNodes "./value\[@n='Mass'\]"]]
                write::WriteString "    RIGID_BODY_MASS $mass"

                lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='CenterOfMass'\]"]] cX cY cZ
                write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] ($cX,$cY,$cZ)"

                        lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='Inertia'\]"]] iX iY iZ
                        write::WriteString "    RIGID_BODY_INERTIAS \[3\] ($iX,$iY,$iZ)"

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

                # initial conditions
                set iAx [write::getValueByNode [$group_node selectNodes "./value\[@n='iAx'\]"]]
                set iAy [write::getValueByNode [$group_node selectNodes "./value\[@n='iAy'\]"]]
                set iAz [write::getValueByNode [$group_node selectNodes "./value\[@n='iAz'\]"]]
                set iBx [write::getValueByNode [$group_node selectNodes "./value\[@n='iBx'\]"]]
                set iBy [write::getValueByNode [$group_node selectNodes "./value\[@n='iBy'\]"]]
                set iBz [write::getValueByNode [$group_node selectNodes "./value\[@n='iBz'\]"]]
                if {$iAx == "true"} {
                    set fix_vx [write::getValueByNode [$group_node selectNodes "./value\[@n='iVx'\]"]]
                    write::WriteString "    INITIAL_VELOCITY_X_VALUE $fix_vx"
                }
                if {$iAy == "true"} {
                    set fix_vy [write::getValueByNode [$group_node selectNodes "./value\[@n='iVy'\]"]]
                    write::WriteString "    INITIAL_VELOCITY_Y_VALUE $fix_vy"
                }
                if {$iAz == "true"} {
                    set fix_vz [write::getValueByNode [$group_node selectNodes "./value\[@n='iVz'\]"]]
                    write::WriteString "    INITIAL_VELOCITY_Z_VALUE $fix_vz"
                }
                if {$iBx == "true"} {
                    set fix_avx [write::getValueByNode [$group_node selectNodes "./value\[@n='iAVx'\]"]]
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE $fix_avx"
                }
                if {$iBy == "true"} {
                    set fix_avy [write::getValueByNode [$group_node selectNodes "./value\[@n='iAVy'\]"]]
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE $fix_avy"
                }
                if {$iBz == "true"} {
                    set fix_avz [write::getValueByNode [$group_node selectNodes "./value\[@n='iAVz'\]"]]
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_Z_VALUE $fix_avz"
                }

                # impose forces and moments
                set ExternalForceX [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalForceX'\]"]]
                set ExternalForceY [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalForceY'\]"]]
                set ExternalForceZ [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalForceZ'\]"]]
                set ExternalMomentX [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalMomentX'\]"]]
                set ExternalMomentY [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalMomentY'\]"]]
                set ExternalMomentZ [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalMomentZ'\]"]]

                if {$ExternalForceX == "true"} {
                    set FX [write::getValueByNode [$group_node selectNodes "./value\[@n='FX'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_FORCE_X $FX"
                }
                if {$ExternalForceY == "true"} {
                    set FY [write::getValueByNode [$group_node selectNodes "./value\[@n='FY'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_FORCE_Y $FY"
                }
                if {$ExternalForceZ == "true"} {
                    set FZ [write::getValueByNode [$group_node selectNodes "./value\[@n='FZ'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_FORCE_Z $FZ"
                }
                if {$ExternalMomentX == "true"} {
                    set MX [write::getValueByNode [$group_node selectNodes "./value\[@n='MX'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_MOMENT_X $MX"
                }
                if {$ExternalMomentY == "true"} {
                    set MY [write::getValueByNode [$group_node selectNodes "./value\[@n='MY'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_MOMENT_Y $MY"
                }
                if {$ExternalMomentZ == "true"} {
                    set MZ [write::getValueByNode [$group_node selectNodes "./value\[@n='MZ'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_MOMENT_Z $MZ"
                }
                #Hardcoded
                write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
                write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                write::WriteString "    FREE_BODY_MOTION $free_body_motion"
            }

            #Hardcoded
            set is_ghost [write::getValueByNode [$group_node selectNodes "./value\[@n='IsGhost'\]"]]
            write::WriteString "    IS_GHOST $is_ghost"
            write::WriteString "    IDENTIFIER [write::transformGroupName $group]"



            set GraphPrint [write::getValueByNode [$group_node selectNodes "./value\[@n='GraphPrint'\]"]]
            if {$GraphPrint == "true"} {
                set GraphPrintval 1
            } else {
                set GraphPrintval 0
            }
            write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
        }
        write::WriteString "  End SubModelPartData"

        write::WriteString "  Begin SubModelPartNodes"
        GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
        write::WriteString "  End SubModelPartNodes"

        write::WriteString "Begin SubModelPartConditions"
        set gdict [dict create]
        set f "%10i\n"
        set f [subst $f]
        dict set gdict $group $f
        GiD_WriteCalculationFile elements -sorted $gdict
        write::WriteString "End SubModelPartConditions"
        write::WriteString ""
        write::WriteString "End SubModelPart"
        write::WriteString ""
    }
}


proc DEM::write::writeConditionMeshes2D { } {
    set i 0
    set cond "DEM-FEM-Wall2D"
    foreach group [GetWallsGroups] {
        incr i
        write::WriteString "Begin SubModelPart $i // GUI DEM-FEM-Wall - $cond - group identifier: $group"
        write::WriteString "  Begin SubModelPartData // DEM-FEM-Wall. Group name: $group"
        set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$cond'\]/group\[@n = '$group'\]"
        set group_node [[customlib::GetBaseRoot] selectNodes $xp1]
        set is_active [write::getValueByNode [$group_node selectNodes "./value\[@n='SetActive'\]"]]
        if {[write::isBooleanTrue $is_active]} {
            set motion_type [write::getValueByNode [$group_node selectNodes "./value\[@n='DEM-ImposedMotion'\]"]]
            if {$motion_type == "LinearPeriodic"} {

                # Linear velocity
                set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='VelocityModulus'\]"]]
                lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='DirectionVector'\]"]] velocity_X velocity_Y
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y]] velocity_X velocity_Y
                lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y] ] vx vy
                write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, 0.0)"

                # set vX [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearVelocityX'\]"]]
                # set vY [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearVelocityY'\]"]]
                # set vZ [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearVelocityZ'\]"]]
                # write::WriteString "    LINEAR_VELOCITY \[3\] ($vX,$vY,$vZ)"

                # Period
                set periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriodic'\]"]]
                if {[write::isBooleanTrue $periodic]} {
                    set period [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriod'\]"]]
                } else {
                    set period 0.0
                }
                write::WriteString "    VELOCITY_PERIOD $period"

                # Angular velocity
                set avelocity [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularVelocityModulus'\]"]]
                write::WriteString "    ANGULAR_VELOCITY \[3\] (0.0,0.0,$avelocity)"

                # Angular center of rotation
                lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='CenterOfRotation'\]"]] oX oY
                write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,0.0)"

                # Angular Period
                set angular_periodic [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularPeriodic'\]"]]
                if {[write::isBooleanTrue $angular_periodic]} {
                    set angular_period [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularPeriod'\]"]]
                } else {
                    set angular_period 0.0
                }
                write::WriteString "    ANGULAR_VELOCITY_PERIOD $angular_period"

                # set intervals
                set LinearStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearStartTime'\]"]]
                set LinearEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearEndTime'\]"]]
                set AngularStartTime [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularStartTime'\]"]]
                set AngularEndTime  [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularEndTime'\]"]]
                write::WriteString "    VELOCITY_START_TIME $LinearStartTime"
                write::WriteString "    VELOCITY_STOP_TIME $LinearEndTime"
                write::WriteString "    ANGULAR_VELOCITY_START_TIME $AngularStartTime"
                write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $AngularEndTime"

                set fixed_mesh_option_bool [write::getValueByNode [$group_node selectNodes "./value\[@n='fixed_wall'\]"]]
                if {[write::isBooleanTrue $fixed_mesh_option_bool]} {
                    set fixed_mesh_option 1
                } else {
                    set fixed_mesh_option 0
                }
                set rigid_body_motion 1
                set free_body_motion 0
                #Hardcoded
                write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
                write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                write::WriteString "    FREE_BODY_MOTION $free_body_motion"

            } elseif {$motion_type == "FreeMotion"} {
                set fixed_mesh_option 0
                set rigid_body_motion 0
                set free_body_motion 1

                set mass [write::getValueByNode [$group_node selectNodes "./value\[@n='Mass'\]"]]
                write::WriteString "    RIGID_BODY_MASS $mass"

                lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='CenterOfMass'\]"]] cX cY
                write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] ($cX,$cY,0.0)"

                lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='Inertia'\]"]] iX iY
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] (0.0,0.0,$iX)"

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

                # initial conditions
                set iAx [write::getValueByNode [$group_node selectNodes "./value\[@n='iAx'\]"]]
                set iAy [write::getValueByNode [$group_node selectNodes "./value\[@n='iAy'\]"]]
                set iAz [write::getValueByNode [$group_node selectNodes "./value\[@n='iAz'\]"]]
                set iBx [write::getValueByNode [$group_node selectNodes "./value\[@n='iBx'\]"]]
                set iBy [write::getValueByNode [$group_node selectNodes "./value\[@n='iBy'\]"]]
                set iBz [write::getValueByNode [$group_node selectNodes "./value\[@n='iBz'\]"]]
                if {$iAx == "true"} {
                    set fix_vx [write::getValueByNode [$group_node selectNodes "./value\[@n='iVx'\]"]]
                    write::WriteString "    INITIAL_VELOCITY_X_VALUE $fix_vx"
                }
                if {$iAy == "true"} {
                    set fix_vy [write::getValueByNode [$group_node selectNodes "./value\[@n='iVy'\]"]]
                    write::WriteString "    INITIAL_VELOCITY_Y_VALUE $fix_vy"
                }
                if {$iAz == "true"} {
                    set fix_vz [write::getValueByNode [$group_node selectNodes "./value\[@n='iVz'\]"]]
                    write::WriteString "    INITIAL_VELOCITY_Z_VALUE $fix_vz"
                }
                if {$iBx == "true"} {
                    set fix_avx [write::getValueByNode [$group_node selectNodes "./value\[@n='iAVx'\]"]]
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE $fix_avx"
                }
                if {$iBy == "true"} {
                    set fix_avy [write::getValueByNode [$group_node selectNodes "./value\[@n='iAVy'\]"]]
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE $fix_avy"
                }
                if {$iBz == "true"} {
                    set fix_avz [write::getValueByNode [$group_node selectNodes "./value\[@n='iAVz'\]"]]
                    write::WriteString "    INITIAL_ANGULAR_VELOCITY_Z_VALUE $fix_avz"
                }

                # impose forces and moments
                set ExternalForceX [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalForceX'\]"]]
                set ExternalForceY [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalForceY'\]"]]
                set ExternalForceZ [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalForceZ'\]"]]
                set ExternalMomentX [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalMomentX'\]"]]
                set ExternalMomentY [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalMomentY'\]"]]
                set ExternalMomentZ [write::getValueByNode [$group_node selectNodes "./value\[@n='ExternalMomentZ'\]"]]

                if {$ExternalForceX == "true"} {
                    set FX [write::getValueByNode [$group_node selectNodes "./value\[@n='FX'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_FORCE_X $FX"
                }
                if {$ExternalForceY == "true"} {
                    set FY [write::getValueByNode [$group_node selectNodes "./value\[@n='FY'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_FORCE_Y $FY"
                }
                if {$ExternalForceZ == "true"} {
                    set FZ [write::getValueByNode [$group_node selectNodes "./value\[@n='FZ'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_FORCE_Z $FZ"
                }
                if {$ExternalMomentX == "true"} {
                    set MX [write::getValueByNode [$group_node selectNodes "./value\[@n='MX'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_MOMENT_X $MX"
                }
                if {$ExternalMomentY == "true"} {
                    set MY [write::getValueByNode [$group_node selectNodes "./value\[@n='MY'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_MOMENT_Y $MY"
                }
                if {$ExternalMomentZ == "true"} {
                    set MZ [write::getValueByNode [$group_node selectNodes "./value\[@n='MZ'\]"]]
                    write::WriteString "    EXTERNAL_APPLIED_MOMENT_Z $MZ"
                }
                #Hardcoded
                write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
                write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                write::WriteString "    FREE_BODY_MOTION $free_body_motion"
            }

            #Hardcoded
            set is_ghost [write::getValueByNode [$group_node selectNodes "./value\[@n='IsGhost'\]"]]
            write::WriteString "    IS_GHOST $is_ghost"
            write::WriteString "    IDENTIFIER [write::transformGroupName $group]"
            write::WriteString "    TOP 0"
            write::WriteString "    BOTTOM 0"

            set GraphPrint [write::getValueByNode [$group_node selectNodes "./value\[@n='GraphPrint'\]"]]
            if {$GraphPrint == "true"} {
                set GraphPrintval 1
            } else {
                set GraphPrintval 0
            }
            write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
        }
        write::WriteString "  End SubModelPartData"

        write::WriteString "  Begin SubModelPartNodes"
        GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
        write::WriteString "  End SubModelPartNodes"

        write::WriteString "Begin SubModelPartConditions"
        set gdict [dict create]
        set f "%10i\n"
        set f [subst $f]
        dict set gdict $group $f
        GiD_WriteCalculationFile elements -sorted $gdict
        write::WriteString "End SubModelPartConditions"
        write::WriteString ""
        write::WriteString "End SubModelPart"
        write::WriteString ""
    }
}

