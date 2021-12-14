
# Project Parameters

proc ::DEM::write::getParametersDict { } {
    set project_parameters_dict [dict create]

    set dimension [expr 3]
    if {$::Model::SpatialDimension eq "2D"} {set dimension [expr 2]}

    dict set project_parameters_dict "Dimension"                            [expr $dimension]
    dict set project_parameters_dict "PeriodicDomainOption"                 [write::getValue Boundingbox PeriodicDomain]
    dict set project_parameters_dict "BoundingBoxOption"                    [write::getValue Boundingbox UseBB]
    dict set project_parameters_dict "AutomaticBoundingBoxOption"           [write::getValue Boundingbox AutomaticBB]
    dict set project_parameters_dict "BoundingBoxEnlargementFactor"         [write::getValue Boundingbox BBFactor]
    dict set project_parameters_dict "BoundingBoxStartTime"                 [write::getValue Boundingbox StartTime]
    dict set project_parameters_dict "BoundingBoxStopTime"                  [write::getValue Boundingbox StopTime]
    dict set project_parameters_dict "BoundingBoxMaxX"                      [write::getValue Boundingbox MaxX]
    dict set project_parameters_dict "BoundingBoxMaxY"                      [write::getValue Boundingbox MaxY]
    dict set project_parameters_dict "BoundingBoxMaxZ"                      [write::getValue Boundingbox MaxZ]
    dict set project_parameters_dict "BoundingBoxMinX"                      [write::getValue Boundingbox MinX]
    dict set project_parameters_dict "BoundingBoxMinY"                      [write::getValue Boundingbox MinY]
    dict set project_parameters_dict "BoundingBoxMinZ"                      [write::getValue Boundingbox MinZ]

    # dem_inlet_option
    set dem_inlet_option true
    if {[llength [DEM::write::GetInletGroups]] == 0} {set dem_inlet_option false}
    dict set project_parameters_dict "dem_inlet_option"                     $dem_inlet_option

    # Gravity
    lassign [DEM::write::GetGravity] gx gy gz
    # Add data to the parameters_dict
    dict set project_parameters_dict "GravityX"                             $gx
    dict set project_parameters_dict "GravityY"                             $gy
    dict set project_parameters_dict "GravityZ"                             $gz

    # Advanced option are disabled
    dict set project_parameters_dict "RotationOption"                       [write::getValue AdvOptions CalculateRotations]
    dict set project_parameters_dict "CleanIndentationsOption"              [write::getValue AdvOptions CleanIndentations]
    set strategy_parameters_dict [dict create]

    set dem_strategy [DEM::write::GetDemStrategyName]

    dict set strategy_parameters_dict "RemoveBallsInitiallyTouchingWalls"   [write::getValue AdvOptions RemoveParticlesInWalls]
    dict set strategy_parameters_dict "strategy"                            $dem_strategy

    set material_import_settings [dict create]
    dict set material_import_settings "materials_filename" [GetAttribute materials_file]
    dict set strategy_parameters_dict "material_import_settings" $material_import_settings

    dict set project_parameters_dict "solver_settings"                      $strategy_parameters_dict

    set processes [dict create]

    # Boundary conditions processes
    # dict set processes constraints_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]

    #dict set processes constraints_process_list [DEM::write::getKinematicsProcessDictList]
    dict set processes loads_process_list [DEM::write::getForceProcessDictList]
    # lappend processes $processes_f

    dict set project_parameters_dict processes $processes


    dict set project_parameters_dict "VirtualMassCoefficient"               [write::getValue AdvOptions VirtualMassCoef]
    dict set project_parameters_dict "RollingFrictionOption"                [write::getValue AdvOptions RollingFriction]
    dict set project_parameters_dict "GlobalDamping"                        [write::getValue AdvOptions GlobalDamping]
    dict set project_parameters_dict "ContactMeshOption"                    [write::getValue BondElem ContactMeshOption]
    dict set project_parameters_dict "OutputFileType"                       [write::getValue GiDOptions GiDPostMode]
    dict set project_parameters_dict "Multifile"                            [write::getValue GiDOptions GiDMultiFileFlag]

    set used_elements [spdAux::GetUsedElements]
    set ElementType [lindex $used_elements 0]
    dict set project_parameters_dict "ElementType"                          $ElementType

    dict set project_parameters_dict "TranslationalIntegrationScheme"       [write::getValue DEMTranslationalScheme]
    dict set project_parameters_dict "RotationalIntegrationScheme"          [write::getValue DEMRotationalScheme]
    set time_params [DEM::write::GetTimeSettings]
    set MaxTimeStep [dict get $time_params DeltaTime]
    # TODO: MAXTIMESTEP is get from General and it should be getting its value from DEM block
    dict set project_parameters_dict "MaxTimeStep"                          $MaxTimeStep
    set FinalTime [dict get $time_params EndTime]
    dict set project_parameters_dict "FinalTime"                            $FinalTime
    # TODO: check for inconsistencies in DEMTIMEPARAMETERS  UN
    # dict set project_parameters_dict "ControlTime"                          [write::getValue DEMTimeParameters ScreenInfoOutput]
    dict set project_parameters_dict "NeighbourSearchFrequency"             [write::getValue DEMTimeParameters NeighbourSearchFrequency]
    dict set project_parameters_dict "SearchTolerance"                      [write::getValue AdvOptions SearchTolerance]
    dict set project_parameters_dict "GraphExportFreq"                      [write::getValue DGraphs GraphExportFreq]
    dict set project_parameters_dict "VelTrapGraphExportFreq"               1e-3

    # Output timestep
    set output_criterion [write::getValue DEMResults DEM-OTimeStepType]
    if {$output_criterion eq "Detail_priority"} {
        set output_timestep [write::getValue DEMResults DEM-OTimeStepDetail]
    } elseif {$output_criterion eq "Storage_priority"} {
        set amount [write::getValue DEMResults DEM-OTimeStepStorage]
        set OTimeStepStorage [expr (double($FinalTime)/$amount)]
        set maxamount [expr ($FinalTime/$MaxTimeStep)]
        if {$amount < $maxamount} {
            set output_timestep $OTimeStepStorage
        } else {
            set output_timestep $MaxTimeStep
        }
    }
    dict set project_parameters_dict "OutputTimeStep"                   $output_timestep
    dict set project_parameters_dict "PostBoundingBox"                  [write::getValue Boundingbox PostBB]
    dict set project_parameters_dict "PostLocalContactForce"            [write::getValue BondElem LocalContactForce]
    dict set project_parameters_dict "PostDisplacement"                 [write::getValue PostPrint Displacement]
    dict set project_parameters_dict "PostRadius"                       [write::getValue PostPrint Radius]
    dict set project_parameters_dict "PostVelocity"                     [write::getValue PostPrint PostVel]
    dict set project_parameters_dict "PostAngularVelocity"              [write::getValue PostPrint AngularVelocity]
    dict set project_parameters_dict "PostElasticForces"                [write::getValue PostPrint ElasForces]
    dict set project_parameters_dict "PostContactForces"                [write::getValue PostPrint ContactForces]
    dict set project_parameters_dict "PostRigidElementForces"           [write::getValue PostPrint RigidElementForces]
    dict set project_parameters_dict "PostStressStrainOption"           [write::getValue PostPrint Stresses]
    dict set project_parameters_dict "PostTangentialElasticForces"      [write::getValue PostPrint TangElasForces]
    dict set project_parameters_dict "PostTotalForces"                  [write::getValue PostPrint TotalForces]
    dict set project_parameters_dict "PostPressure"                     [write::getValue PostPrint Pressure]
    dict set project_parameters_dict "PostShearStress"                  [write::getValue PostPrint ShearStress]
    dict set project_parameters_dict "PostSkinSphere"                  [write::getValue PostPrint SkinSphere]
    dict set project_parameters_dict "PostNonDimensionalVolumeWear"     [write::getValue PostPrint Wear]
    dict set project_parameters_dict "PostParticleMoment"               [write::getValue PostPrint ParticleMoment]
    dict set project_parameters_dict "PostEulerAngles"                  [write::getValue PostPrint EulerAngles]
    dict set project_parameters_dict "PostRollingResistanceMoment"      [write::getValue PostPrint RollingResistanceMoment]
    dict set project_parameters_dict "problem_name" [Kratos::GetModelName]

    return $project_parameters_dict
}

proc ::DEM::write::getKinematicsProcessDictList {} {

    set root [customlib::GetBaseRoot]
    set process_list [list ]

    set xp1         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='FEMVelocity'\]/group"
    set xp2         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='DEMVelocity'\]/group"
    set xp3         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='FEMAngular'\]/group"
    set xp4         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='DEMAngular'\]/group"

    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        # set write_output [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='write'\]"]]]
        # set print_screen [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='print'\]"]]]
        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]
        set pdict [dict create]
        dict set pdict "python_module" "apply_velocity_constraints_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        #dict set pdict "process_name" "ComputeProcess"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]

        # dict set subparams "constrained" [write::getConstrains $values]
        dict set subparams "constrained" "\[false, false, false\]"
        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"
        dict set pdict "velocity_constraints_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }


    set groups [$root selectNodes $xp2]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "apply_velocity_constraints_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]

        # dict set subparams "constrained" [write::getConstrains $values]
        dict set subparams "constrained" "\[false, false, false\]"
        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"

        dict set pdict "velocity_constraints_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    set groups [$root selectNodes $xp3]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "apply_angular_velocity_constraints_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]

        # dict set subparams "constrained" [write::getConstrains $values]
        dict set subparams "constrained" "\[false, false, false\]"
        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"

        dict set pdict "angular_velocity_constraints_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    set groups [$root selectNodes $xp4]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "apply_angular_velocity_constraints_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]

        # dict set subparams "constrained" [write::getConstrains $values]
        dict set subparams "constrained" "\[false, false, false\]"
        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"

        dict set pdict "angular_velocity_constraints_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    return $process_list
}



proc ::DEM::write::getForceProcessDictList {} {

    set root [customlib::GetBaseRoot]
    set process_list [list ]

    set xp1         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='FEMForce'\]/group"
    set xp2         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='DEMForce'\]/group"
    set xp3         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='DEMTorque'\]/group"
    set xp4         "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='DEMTorque'\]/group"

    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        # set write_output [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='write'\]"]]]
        # set print_screen [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='print'\]"]]]
        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]
        set pdict [dict create]
        dict set pdict "python_module" "apply_forces_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        #dict set pdict "process_name" "ComputeProcess"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]

        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"
        dict set pdict "force_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }


    set groups [$root selectNodes $xp2]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "apply_forces_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]

        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"

        dict set pdict "force_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    set groups [$root selectNodes $xp3]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "apply_moments_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]
        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"

        dict set pdict "moment_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    set groups [$root selectNodes $xp4]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "apply_moments_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"
        set params [dict create]

        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        set subparams [dict create]

        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" "\[null, null, null\]"

        dict set pdict "moment_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    return $process_list
}

proc ::DEM::write::writeWallConditionMeshes { } {
    variable wallsProperties
    variable phantomwallsProperties

    set condition_name [GetRigidWallConditionName]
    foreach group [GetRigidWallsGroups] {
        set mid [write::AddSubmodelpart $condition_name $group]
        set props [DEM::write::FindPropertiesBySubmodelpart $wallsProperties $mid]
        writeWallConditionMesh $condition_name $group $props
    }

    if {$::Model::SpatialDimension ne "2D"} {
        set condition_name [GetPhantomWallConditionName]
        foreach group [GetPhantomWallsGroups] {
            set mid [write::AddSubmodelpart $condition_name $group]
            set props [DEM::write::FindPropertiesBySubmodelpart $phantomwallsProperties $mid]
            writeWallConditionMesh $condition_name $group $props
        }
    }
}

#legacy walls.tcl
proc ::DEM::write::writeWallConditionMesh { condition group props } {

    set mid [write::AddSubmodelpart $condition $group]
    write::WriteString "Begin SubModelPart $mid // $condition - group identifier: $group"
    write::WriteString "  Begin SubModelPartData // $condition. Group name: $group"
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition'\]/group\[@n = '$group'\]"
    set group_node [[customlib::GetBaseRoot] selectNodes $xp1]
    set is_active [dict get $props Material Variables SetActive]
    if {[write::isBooleanTrue $is_active]} {
        set motion_type [dict get $props Material Variables DEM-ImposedMotion]
        if {$motion_type == "LinearPeriodic"} {
            # Linear velocity
            set velocity [dict get $props Material Variables VelocityModulus]
            lassign [dict get $props Material Variables DirectionVector] velocity_X velocity_Y velocity_Z
            if {$::Model::SpatialDimension eq "2D"} {
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y]] velocity_X velocity_Y
                lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y] ] vx vy
                write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, 0.0)"
            } else {
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, $vz)"
            }
            # set vX [dict get $props Material Variables LinearVelocityX'\]"]]

            # Period
            set periodic [dict get $props Material Variables LinearPeriodic]
            if {[write::isBooleanTrue $periodic]} {
                set period [dict get $props Material Variables LinearPeriod]
            } else {
                set period 0.0
            }
            write::WriteString "    VELOCITY_PERIOD $period"

            # Angular velocity
            set avelocity [dict get $props Material Variables AngularVelocityModulus]
            if {$::Model::SpatialDimension eq "2D"} {
                write::WriteString "    ANGULAR_VELOCITY \[3\] (0.0,0.0,$avelocity)"
            } else {
                lassign [dict get $props Material Variables AngularDirectionVector] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::ScalarByVectorProd $avelocity [list $velocity_X $velocity_Y $velocity_Z] ] wx wy wz
                write::WriteString "    ANGULAR_VELOCITY \[3\] ($wx,$wy,$wz)"}

            # Angular center of rotation
            lassign  [dict get $props Material Variables CenterOfRotation] oX oY oZ
            if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,0.0)"
            } else {write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,$oZ)"}

            # Angular Period
            set angular_periodic [dict get $props Material Variables AngularPeriodic]
            set angular_period 0.0
            if {[write::isBooleanTrue $angular_periodic]} {
                set angular_period [dict get $props Material Variables AngularPeriod]
            }
            write::WriteString "    ANGULAR_VELOCITY_PERIOD $angular_period"

            # set intervals
            set LinearStartTime  [dict get $props Material Variables LinearStartTime]
            set LinearEndTime    [dict get $props Material Variables LinearEndTime]
            set AngularStartTime [dict get $props Material Variables AngularStartTime]
            set AngularEndTime   [dict get $props Material Variables AngularEndTime]
            write::WriteString "    VELOCITY_START_TIME $LinearStartTime"
            write::WriteString "    VELOCITY_STOP_TIME $LinearEndTime"
            write::WriteString "    ANGULAR_VELOCITY_START_TIME $AngularStartTime"
            write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $AngularEndTime"

            set fixed_mesh_option_bool [dict get $props Material Variables fixed_wall]
            set fixed_mesh_option 0
            if {[write::isBooleanTrue $fixed_mesh_option_bool]} {
                set fixed_mesh_option 1
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

            set mass [dict get $props Material Variables Mass]
            write::WriteString "    RIGID_BODY_MASS $mass"

            lassign [dict get $props Material Variables CenterOfMass] cX cY cZ
            if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] ($cX,$cY,0.0)"
            } else {write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] ($cX,$cY,$cZ)"}

            set inertias [dict get $props Material Variables Inertia]
            if {$::Model::SpatialDimension eq "2D"} {
                set iX $inertias
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] (0.0,0.0,$iX)"
            } else {
                lassign $inertias iX iY iZ
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] ($iX,$iY,$iZ)"
            }

            # DOFS
            set Ax [dict get $props Material Variables Ax]
            set Ay [dict get $props Material Variables Ay]
            set Az [dict get $props Material Variables Az]
            set Bx [dict get $props Material Variables Bx]
            set By [dict get $props Material Variables By]
            set Bz [dict get $props Material Variables Bz]
            if {$Ax == "Constant"} {
                set fix_vx [dict get $props Material Variables Vx]
                write::WriteString "    IMPOSED_VELOCITY_X_VALUE $fix_vx"
            }
            if {$Ay == "Constant"} {
                set fix_vy [dict get $props Material Variables Vy]
                write::WriteString "    IMPOSED_VELOCITY_Y_VALUE $fix_vy"
            }
            if {$Az == "Constant"} {
                set fix_vz [dict get $props Material Variables Vz]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    IMPOSED_VELOCITY_Z_VALUE 0.0"
                } else {write::WriteString "    IMPOSED_VELOCITY_Z_VALUE $fix_vz"}

            }
            if {$Bx == "Constant"} {
                set fix_avx [dict get $props Material Variables AVx]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_X_VALUE 0.0"
                } else {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_X_VALUE $fix_avx"}

            }
            if {$By == "Constant"} {
                set fix_avy [dict get $props Material Variables AVy]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Y_VALUE 0.0"
                } else {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Y_VALUE $fix_avy"}

            }
            if {$Bz == "Constant"} {
                set fix_avz [dict get $props Material Variables AVz]
                write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Z_VALUE $fix_avz"
            }
            set VStart [dict get $props Material Variables VStart]
            set VEnd [dict get $props Material Variables VEnd]
            write::WriteString "    VELOCITY_START_TIME $VStart"
            write::WriteString "    VELOCITY_STOP_TIME $VEnd"

            # initial conditions
            set iAx [dict get $props Material Variables iAx]
            set iAy [dict get $props Material Variables iAy]
            set iAz [dict get $props Material Variables iAz]
            set iBx [dict get $props Material Variables iBx]
            set iBy [dict get $props Material Variables iBy]
            set iBz [dict get $props Material Variables iBz]
            if {$iAx == "true"} {
                set fix_vx [dict get $props Material Variables iVx]
                write::WriteString "    INITIAL_VELOCITY_X_VALUE $fix_vx"
            }
            if {$iAy == "true"} {
                set fix_vy [dict get $props Material Variables iVy]
                write::WriteString "    INITIAL_VELOCITY_Y_VALUE $fix_vy"
            }
            if {$iAz == "true"} {
                set fix_vz [dict get $props Material Variables iVz]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    INITIAL_VELOCITY_Z_VALUE 0.0"
                } else {write::WriteString "    INITIAL_VELOCITY_Z_VALUE $fix_vz"}

            }
            if {$iBx == "true"} {
                set fix_avx [dict get $props Material Variables iAVx]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE 0.0"
                } else {write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE $fix_avx"}

            }
            if {$iBy == "true"} {
                set fix_avy [dict get $props Material Variables iAVy]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE 0.0"
                } else {write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE $fix_avy"}

            }
            if {$iBz == "true"} {
                set fix_avz [dict get $props Material Variables iAVz]
                write::WriteString "    INITIAL_ANGULAR_VELOCITY_Z_VALUE $fix_avz"
            }

            # impose forces and moments
            set ExternalForceX [dict get $props Material Variables ExternalForceX]
            set ExternalForceY [dict get $props Material Variables ExternalForceY]
            set ExternalForceZ [dict get $props Material Variables ExternalForceZ]
            set ExternalMomentX [dict get $props Material Variables ExternalMomentX]
            set ExternalMomentY [dict get $props Material Variables ExternalMomentY]
            set ExternalMomentZ [dict get $props Material Variables ExternalMomentZ]

            if {$ExternalForceX == "true"} {
                set FX [dict get $props Material Variables FX]
                write::WriteString "    EXTERNAL_APPLIED_FORCE_X $FX"
            }
            if {$ExternalForceY == "true"} {
                set FY [dict get $props Material Variables FY]
                write::WriteString "    EXTERNAL_APPLIED_FORCE_Y $FY"
            }
            if {$ExternalForceZ == "true"} {
                set FZ [dict get $props Material Variables FZ]
                write::WriteString "    EXTERNAL_APPLIED_FORCE_Z $FZ"
            }
            if {$ExternalMomentX == "true"} {
                set MX [dict get $props Material Variables MX]
                write::WriteString "    EXTERNAL_APPLIED_MOMENT_X $MX"
            }
            if {$ExternalMomentY == "true"} {
                set MY [dict get $props Material Variables MY]
                write::WriteString "    EXTERNAL_APPLIED_MOMENT_Y $MY"
            }
            if {$ExternalMomentZ == "true"} {
                set MZ [dict get $props Material Variables MZ]
                write::WriteString "    EXTERNAL_APPLIED_MOMENT_Z $MZ"
            }
            #Hardcoded
            write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
            write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
            write::WriteString "    FREE_BODY_MOTION $free_body_motion"
        }

        #Hardcoded
        set is_ghost [dict get $props Material Variables IsGhost]
        if {$is_ghost == "true"} {
            write::WriteString "    IS_GHOST 1"
        } else {
            write::WriteString "    IS_GHOST 0"
        }
        write::WriteString "    IDENTIFIER [write::transformGroupName $group]"

        DEM::write::DefineFEMExtraConditions $props

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

proc ::DEM::write::GetDemStrategyName { } {
    return sphere_strategy
    # set ElementType [::wkcf::GetElementType]   # TODO: check old ::wkcf::GetElementType functionalities if required
    # set used_elements [spdAux::GetUsedElements]

    # set ElementType SphericPartDEMElement3D
	# if {$ElementType eq "SphericPartDEMElement3D" || $ElementType eq "CylinderPartDEMElement2D"} {
	#     set dem_strategy "sphere_strategy"
	# } elseif {$ElementType eq "SphericContPartDEMElement3D" || $ElementType eq "CylinderContPartDEMElement3D"} {
	#     set dem_strategy "continuum_sphere_strategy"
	# } elseif {$ElementType eq "ThermalSphericPartDEMElement3D"} {
	#    set dem_strategy "thermal_sphere_strategy"
	# } elseif {$ElementType eq "ThermalSphericContPartDEMElement3D"} {
	#    set dem_strategy "thermal_continuum_sphere_strategy"
	# } elseif {$ElementType eq "SinteringSphericConPartDEMElement3D"} {
	#    set dem_strategy "thermal_continuum_sphere_strategy"
	# } elseif {$ElementType eq "IceContPartDEMElement3D"} {
	#    set dem_strategy "ice_continuum_sphere_strategy"
	# }
}

proc ::DEM::write::GetTimeSettings { } {
    set result [dict create]
    dict set result DeltaTime [write::getValue DEMTimeParameters DeltaTime]
    dict set result EndTime [write::getValue DEMTimeParameters EndTime]
    return $result
}

proc ::DEM::write::GetGravity { } {
    set gravity_value [write::getValue DEMGravity GravityValue]
    set gravity_X [write::getValue DEMGravity Cx]
    set gravity_Y [write::getValue DEMGravity Cy]
    set gravity_Z [write::getValue DEMGravity Cz]
    # Normalize director vector
    lassign [MathUtils::VectorNormalized [list $gravity_X $gravity_Y $gravity_Z]] gravity_X gravity_Y gravity_Z
    # Get value by components
    lassign [MathUtils::ScalarByVectorProd $gravity_value [list $gravity_X $gravity_Y $gravity_Z] ] gx gy gz

    return [list $gx $gy $gz]
}

proc ::DEM::write::writeParametersEvent { } {
    write::SetParallelismConfiguration
    write::WriteJSON [getParametersDict]
}
