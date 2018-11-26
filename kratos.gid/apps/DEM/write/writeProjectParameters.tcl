
# Project Parameters
proc DEM::write::getParametersEvent { } {
    set project_parameters_dict [dict create]

    dict set project_parameters_dict "Dimension" [expr 3]
    dict set project_parameters_dict "PeriodicDomainOption" [write::getValue Boundingbox PeriodicDomain]
    dict set project_parameters_dict "BoundingBoxOption"    [write::getValue Boundingbox UseBB]
    dict set project_parameters_dict "AutomaticBoundingBoxOption"   [write::getValue Boundingbox AutomaticBB]
    dict set project_parameters_dict "BoundingBoxEnlargementFactor" [write::getValue Boundingbox BBFactor]
    dict set project_parameters_dict "BoundingBoxStartTime" [write::getValue Boundingbox StartTime]
    dict set project_parameters_dict "BoundingBoxStopTime"  [write::getValue Boundingbox StopTime]
    dict set project_parameters_dict "BoundingBoxMaxX"      [write::getValue Boundingbox MaxX]
    dict set project_parameters_dict "BoundingBoxMaxY"      [write::getValue Boundingbox MaxY]
    dict set project_parameters_dict "BoundingBoxMaxZ"      [write::getValue Boundingbox MaxZ]
    dict set project_parameters_dict "BoundingBoxMinX"      [write::getValue Boundingbox MinX]
    dict set project_parameters_dict "BoundingBoxMinY"      [write::getValue Boundingbox MinY]
    dict set project_parameters_dict "BoundingBoxMinZ"      [write::getValue Boundingbox MinZ]

    # dem_inlet_option
    set numinlets [llength [DEM::write::GetInletGroups]]
    if {$numinlets == 0} {
        set dem_inlet_option "false"
    } else {
        set dem_inlet_option "true"
    }
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
    dict set strategy_parameters_dict "RemoveBallsInitiallyTouchingWalls"   [write::getValue AdvOptions RemoveParticlesInWalls]
    dict set project_parameters_dict "strategy_parameters"                  $strategy_parameters_dict

    dict set project_parameters_dict "VirtualMassCoefficient"               [write::getValue AdvOptions VirtualMassCoef]
    dict set project_parameters_dict "RollingFrictionOption"                [write::getValue AdvOptions RollingFriction]
    dict set project_parameters_dict "GlobalDamping"                        [write::getValue AdvOptions GlobalDamping]
    dict set project_parameters_dict "ContactMeshOption"                    [write::getValue BondElem ContactMeshOption]
    dict set project_parameters_dict "OutputFileType"                       [write::getValue GiDOptions GiDPostMode]
    dict set project_parameters_dict "Multifile"                            [write::getValue GiDOptions GiDMultiFileFlag]
    dict set project_parameters_dict "ElementType"                          "SphericPartDEMElement3D"

    dict set project_parameters_dict "TranslationalIntegrationScheme"       [write::getValue DEMTranslationalScheme]
    dict set project_parameters_dict "RotationalIntegrationScheme"          [write::getValue DEMRotationalScheme]
    set time_params [DEM::write::GetTimeSettings]
        set MaxTimeStep [dict get $time_params DeltaTime]
    dict set project_parameters_dict "MaxTimeStep"                          $MaxTimeStep
        set FinalTime [dict get $time_params EndTime]
    dict set project_parameters_dict "FinalTime"                            $FinalTime
    dict set project_parameters_dict "ControlTime"                          [write::getValue DEMTimeParameters ScreenInfoOutput]
    dict set project_parameters_dict "NeighbourSearchFrequency"             [write::getValue DEMTimeParameters NeighbourSearchFrequency]
    dict set project_parameters_dict "GraphExportFreq"                      1e-3
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
    dict set project_parameters_dict "PostNonDimensionalVolumeWear"     [write::getValue PostPrint Wear]
    dict set project_parameters_dict "PostParticleMoment"               [write::getValue PostPrint ParticleMoment]
    dict set project_parameters_dict "PostEulerAngles"                  [write::getValue PostPrint EulerAngles]
    dict set project_parameters_dict "PostRollingResistanceMoment"      [write::getValue PostPrint RollingResistanceMoment]
    #dict set project_parameters_dict "PostNodalArea"                    [write::getValue PostPrint NodalArea]
    #dict set project_parameters_dict "PostRHS"                          [write::getValue PostPrint Rhs]
    #dict set project_parameters_dict "PostDampForces"                   [write::getValue PostPrint DampForces]
    #dict set project_parameters_dict "PostAppliedForces"                [write::getValue PostPrint AppliedForces]
    #dict set project_parameters_dict "PostGroupId"                      [write::getValue PostPrint GroupId]
    #dict set project_parameters_dict "PostExportId"                     [write::getValue PostPrint ExportId]
    dict set project_parameters_dict "problem_name"                     [file tail [GiD_Info Project ModelName]]

    return $project_parameters_dict
}

proc DEM::write::GetTimeSettings { } {
    set result [dict create]
    dict set result DeltaTime [write::getValue DEMTimeParameters DeltaTime]
    dict set result EndTime [write::getValue DEMTimeParameters EndTime]
    return $result
}

proc DEM::write::GetGravity { } {
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

proc DEM::write::writeParametersEvent { } {
    write::SetParallelismConfiguration
    write::WriteJSON [getParametersEvent]
}
