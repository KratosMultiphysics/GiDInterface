proc DEM::write::WriteMDPAWalls { } {
    # Headers
    write::writeModelPartData
    
    # Material
    set wall_properties [WriteWallProperties]
    
    # Nodal coordinates (only for Walls <inefficient> )
    write::writeNodalCoordinatesOnGroups [GetWallsGroups]
    
    # Nodal conditions and conditions
    writeConditions $wall_properties
    
    # SubmodelParts
    writeConditionMeshes
}

proc DEM::write::WriteWallProperties { } {    
    #set print_list [list "WALL_FRICTION" "WALL_COHESION" "COMPUTE_WEAR" "SEVERITY_OF_WEAR" "IMPACT_WEAR_SEVERITY" "BRINELL_HARDNESS" "YOUNG_MODULUS" "POISSON_RATIO"]
    set wall_properties [dict create ]
    set cnd [Model::getCondition "DEM-FEM-Wall"]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
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
        write::WriteString "  WALL_FRICTION [write::getValueByNode [$group selectNodes "./value\[@n='WALL_FRICTION'\]"]]"
        write::WriteString "  WALL_COHESION [write::getValueByNode [$group selectNodes "./value\[@n='WALL_COHESION'\]"]]"
        set compute_wear_bool [write::getValueByNode [$group selectNodes "./value\[@n='COMPUTE_WEAR'\]"]]
        if {[write::isBooleanTrue $compute_wear_bool]} {
            set compute_wear 1
            set severiy_of_wear [write::getValueByNode [$group selectNodes "./value\[@n='SEVERITY_OF_WEAR'\]"]]
            set impact_wear_severity [write::getValueByNode [$group selectNodes "./value\[@n='IMPACT_WEAR_SEVERITY'\]"]]
            set brinell_hardness [write::getValueByNode [$group selectNodes "./value\[@n='BRINELL_HARDNESS'\]"]]
        } else {
            set compute_wear 0
            set severiy_of_wear 0.001
            set impact_wear_severity 0.001
            set brinell_hardness 200.0
        }
        set rigid_structure_bool [write::getValueByNode [$group selectNodes "./value\[@n='Rigid_structure'\]"]]
        if {[write::isBooleanTrue $rigid_structure_bool]} {
            set young_modulus [write::getValueByNode [$group selectNodes "./value\[@n='SEVERITY_OF_WEAR'\]"]]
            set poisson_ratio [write::getValueByNode [$group selectNodes "./value\[@n='POISSON_RATIO'\]"]]
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

proc DEM::write::writeConditions { wall_properties } {
    foreach group [GetWallsGroups] {
        set mid [dict get $wall_properties $group]
        set format [write::GetFormatDict $group $mid 3]
        write::WriteString "Begin Conditions RigidFace3D3N // GUI DEM-FEM-Wall group identifier: $group"
        GiD_WriteCalculationFile connectivities $format
        write::WriteString "End Conditions"
        write::WriteString ""
    }
}

proc DEM::write::GetWallsGroups { } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
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
    foreach {cond group_list} [GetWallsGroupsListInConditions] {
        if {$cond eq "DEM-FEM-Wall"} {
            set cnd [Model::getCondition $cond]
            foreach group $group_list {
                incr i
                write::WriteString "Begin SubModelPart $i // GUI DEM-FEM-Wall - $cond - group identifier: $group"
                write::WriteString "  Begin SubModelPartData // DEM-FEM-Wall. Group name: $group"
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
                    
                    set fixed_mesh_option_bool [write::getValueByNode [$group_node selectNodes "./value\[@n='FIXED_MESH_OPTION'\]"]]
                    if {[write::isBooleanTrue $fixed_mesh_option_bool]} {
                        set fixed_mesh_option 1
                    } else {
                        set fixed_mesh_option 0
                    }
                    set rigid_body_motion 1
                } else {
                    set fixed_mesh_option 0
                    set rigid_body_motion 0
                }
                # Hardcoded
                write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
                write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
                write::WriteString "    FREE_BODY_MOTION 0"
                write::WriteString "    RIGID_BODY_MASS 0.0"
                write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] (0.0,0.0,0.0)"
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] (0.0,0.0,0.0)"
                write::WriteString "    IDENTIFIER [write::transformGroupName $group]"
                write::WriteString "    TOP 0"
                write::WriteString "    BOTTOM 0"
                write::WriteString "    FORCE_INTEGRATION_GROUP 0"
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

