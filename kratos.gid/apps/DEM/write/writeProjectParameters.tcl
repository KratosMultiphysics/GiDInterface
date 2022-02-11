
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

    dict set processes constraints_process_list [DEM::write::getKinematicsProcessDictList]
    dict set processes loads_process_list [DEM::write::getForceProcessDictList]

    dict set project_parameters_dict processes $processes


    dict set project_parameters_dict "VirtualMassCoefficient"               [write::getValue AdvOptions VirtualMassCoef]
    dict set project_parameters_dict "RollingFrictionOption"                [write::getValue AdvOptions RollingFriction]
    dict set project_parameters_dict "GlobalDamping"                        [write::getValue AdvOptions GlobalDamping]
    dict set project_parameters_dict "ContactMeshOption"                    [write::getValue BondElem ContactMeshOption]
    dict set project_parameters_dict "OutputFileType"                       [write::getValue GiDOptions GiDPostMode]
    dict set project_parameters_dict "Multifile"                            [write::getValue GiDOptions GiDMultiFileFlag]

    dict set project_parameters_dict "ElementType"                          [GetElementType]

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

proc DEM::write::getSubModelPartId {cid group} {
    return $cid$group
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
        set cid [[$group parent] @n]
        set submodelpart [DEM::write::getSubModelPartId $cid $groupName]
        # I want it to be FEMVelocity-Floor

        # set write_output [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='write'\]"]]]
        # set print_screen [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='print'\]"]]]
        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "apply_velocity_constraints_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"

        set params [dict create]
        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]

        set subparams [dict create]
        # proc write::ProcessVectorFunctionComponents { groupNode condition process}

        set constraints [write::getValueByNode [$group selectNodes "./value\[@n='Constraints'\]"]]
        # set value [write::getValueByNode [$group selectNodes "./value\[@n='component'\]"]]
        set table [write::getValueByNode [$group selectNodes "./value\[@n='Table'\]"]]

        dict set subparams "constrained" $constraints
        # dict set subparams "value" $value
        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" $table

        dict set params "velocity_constraints_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]

        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    #same goes for conditions applied on DEM xp2 xp4

    set groups [$root selectNodes $xp3]
    foreach group $groups {
        set groupName [$group @n]
        set cid [[$group parent] @n]
        set submodelpart [DEM::write::getSubModelPartId $cid $groupName]
        set pdict [dict create]
        dict set pdict "python_module" "apply_angular_velocity_constraints_process"
        dict set pdict "kratos_module" "KratosMultiphysics.DEMApplication"

        set params [dict create]
        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]

        set subparams [dict create]
        # proc write::ProcessVectorFunctionComponents { groupNode condition process}

        set constraints [write::getValueByNode [$group selectNodes "./value\[@n='Constraints'\]"]]
        # set value [write::getValueByNode [$group selectNodes "./value\[@n='component'\]"]]
        set table [write::getValueByNode [$group selectNodes "./value\[@n='Table'\]"]]

        dict set subparams "constrained" $constraints
        # dict set subparams "value" $value
        dict set subparams "value" "\[-3.0, 0.0, 0.0\]"
        dict set subparams "table" $table

        dict set params "velocity_constraints_settings" $subparams

        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]
        dict set params "interval" [write::getInterval $interval_name]

        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }


    # solo referencia
    # proc write::ProcessVectorFunctionComponents { groupNode condition process} {
    # set processDict [write::GetProcessHeader $groupNode $process $condition]
    # set val [write::GetInputValue $groupNode [$process getInputPn component]]
    # foreach i $val {
    #     if {$i == "null"} {
    #         lappend constrained false
    #         lappend value null
    #     } {
    #         lappend constrained true
    #         lappend value $i
    #     }
    # }

    # dict set processDict Parameters constrained $constrained
    # dict set processDict Parameters value $value

    # return $processDict
    #   }

    return $process_list
}



proc ::DEM::write::getForceProcessDictList {} {

    set root [customlib::GetBaseRoot]
    set process_list [list ]

    set xp1 "[spdAux::getRoute [GetAttribute loads_un]]/condition\[@n='FEMForce'\]/group"
    set xp2 "[spdAux::getRoute [GetAttribute loads_un]]/condition\[@n='DEMForce'\]/group"
    set xp3 "[spdAux::getRoute [GetAttribute loads_un]]/condition\[@n='DEMTorque'\]/group"
    set xp4 "[spdAux::getRoute [GetAttribute loads_un]]/condition\[@n='DEMTorque'\]/group"

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
        dict set params "force_settings" $subparams
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

        dict set params "force_settings" $subparams
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

        dict set params "moment_settings" $subparams
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

        dict set params "moment_settings" $subparams
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    return $process_list
}

# proc ::DEM::write::writeWallConditionMeshes { } {
#     variable wallsProperties
#     variable phantomwallsProperties

#     set condition_name [GetRigidWallConditionName]
#     foreach group [GetRigidWallsGroups] {
#         set mid [write::AddSubmodelpart $condition_name $group]
#         set props [DEM::write::FindPropertiesBySubmodelpart $wallsProperties $mid]
#         writeWallConditionMesh $condition_name $group $props
#     }

#     if {$::Model::SpatialDimension ne "2D"} {
#         set condition_name [GetPhantomWallConditionName]
#         foreach group [GetPhantomWallsGroups] {
#             set mid [write::AddSubmodelpart $condition_name $group]
#             set props [DEM::write::FindPropertiesBySubmodelpart $phantomwallsProperties $mid]
#             writeWallConditionMesh $condition_name $group $props
#         }
#     }
# }

proc ::DEM::write::GetUsedElements {} {
    set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute [::DEM::write::GetAttribute parts_un]]/condition\[@n='Parts_DEM'\]/group"

    set lista [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set g $gNode
        set name [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element']"] ]
        if {$name ni $lista} {lappend lista $name}
    }

    return $lista
}

proc ::DEM::write::GetElementType { } {
    set used_elements [DEM::write::GetUsedElements]
    set element_type [lindex $used_elements 0]
    return $element_type
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
