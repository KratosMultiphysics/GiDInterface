
# Project Parameters
proc DEM::write::getParametersEvent { } {
    set project_parameters_dict [dict create]

    dict set project_parameters_dict "Dimension"                        3
    dict set project_parameters_dict "PeriodicDomainOption"             false
    dict set project_parameters_dict "BoundingBoxOption"                [write::getValue DEM-Boundingbox UseBoundingBox]
    dict set project_parameters_dict "AutomaticBoundingBoxOption"       false
    dict set project_parameters_dict "BoundingBoxEnlargementFactor"     1.0
    dict set project_parameters_dict "BoundingBoxStartTime"             [write::getValue DEM-Boundingbox StartTime]
    dict set project_parameters_dict "BoundingBoxStopTime"              [write::getValue DEM-Boundingbox StopTime]
    dict set project_parameters_dict "BoundingBoxMaxX"                  [write::getValue DEM-Boundingbox MaxX]
    dict set project_parameters_dict "BoundingBoxMaxY"                  [write::getValue DEM-Boundingbox MaxY]
    dict set project_parameters_dict "BoundingBoxMaxZ"                  [write::getValue DEM-Boundingbox MaxZ]
    dict set project_parameters_dict "BoundingBoxMinX"                  [write::getValue DEM-Boundingbox MinX]
    dict set project_parameters_dict "BoundingBoxMinY"                  [write::getValue DEM-Boundingbox MinY]
    dict set project_parameters_dict "BoundingBoxMinZ"                  [write::getValue DEM-Boundingbox MinZ]

    # dem_inlet_option
    set numinlets [llength [DEM::write::GetInletGroups]]
    if {$numinlets == 0} {
        set dem_inlet_option "false"
    } else {
        set dem_inlet_option "true"
    }
    dict set project_parameters_dict "dem_inlet_option"                 $dem_inlet_option
    # Gravity
        # Get data
        set gravity_value [write::getValue DEMGravity GravityValue]
        set gravity_X [write::getValue DEMGravity Cx]
        set gravity_Y [write::getValue DEMGravity Cy]
        set gravity_Z [write::getValue DEMGravity Cz]
        # Normalize director vector
        lassign [MathUtils::VectorNormalized [list $gravity_X $gravity_Y $gravity_Z]] gravity_X gravity_Y gravity_Z
        # Get value by components
        lassign [MathUtils::ScalarByVectorProd $gravity_value [list $gravity_X $gravity_Y $gravity_Z] ] gx gy gz
        # Add data to the parameters_dict
    dict set project_parameters_dict "GravityX"                         $gx
    dict set project_parameters_dict "GravityY"                         $gy
    dict set project_parameters_dict "GravityZ"                         $gz
    
    # Advanced option are disabled
    dict set project_parameters_dict "EnergyCalculationOption"          false           
    dict set project_parameters_dict "VelocityTrapOption"               false
    dict set project_parameters_dict "RotationOption"                   true
    dict set project_parameters_dict "CleanIndentationsOption"          true
    dict set project_parameters_dict "RemoveBallsInEmbeddedOption"      true
    
    dict set project_parameters_dict "DeltaOption"                      "Absolute"
    dict set project_parameters_dict "SearchTolerance"                  0.0
    dict set project_parameters_dict "AmplifiedSearchRadiusExtension"   0.0
    dict set project_parameters_dict "ModelDataInfo"                    false
    dict set project_parameters_dict "VirtualMassCoefficient"           1.0
    dict set project_parameters_dict "RollingFrictionOption"            false
    dict set project_parameters_dict "ContactMeshOption"                false
    dict set project_parameters_dict "OutputFileType"                   "Binary"
    dict set project_parameters_dict "Multifile"                        "multiple_files"
    dict set project_parameters_dict "ElementType"                      "SphericPartDEMElement3D"
    
    dict set project_parameters_dict "TranslationalIntegrationScheme"   "Symplectic_Euler"
    dict set project_parameters_dict "RotationalIntegrationScheme"      "Direct_Integration"
    dict set project_parameters_dict "AutomaticTimestep"                false
    dict set project_parameters_dict "DeltaTimeSafetyFactor"            1.0
        set MaxTimeStep  [write::getValue DEMTimeParameters DeltaTime]
    dict set project_parameters_dict "MaxTimeStep"                      $MaxTimeStep
        set TTime  [write::getValue DEMTimeParameters EndTime]
    dict set project_parameters_dict "FinalTime"                        $TTime
    dict set project_parameters_dict "ControlTime"                      [write::getValue DEMTimeParameters DEM-ScreenInfoOutput]
    dict set project_parameters_dict "NeighbourSearchFrequency"         [write::getValue DEMTimeParameters DEM-NeighbourSearchFrequency]
    
    dict set project_parameters_dict "GraphExportFreq"                  1e-3
    dict set project_parameters_dict "VelTrapGraphExportFreq"           1e-3
    # Output timestep
        set output_criterion [write::getValue Results DEM-OTimeStepType]
        if {$output_criterion eq "Detail_priority"} {
            set output_timestep [write::getValue Results DEM-OTimeStepDetail]
        } elseif {$output_criterion eq "Storage_priority"} {
            set amount [write::getValue Results DEM-OTimeStepStorage]
            set OTimeStepStorage [expr (double($TTime)/$amount)]
            set maxamount [expr ($TTime/$MaxTimeStep)]
            if {$amount < $maxamount} {
                set output_timestep $OTimeStepStorage
            } else {
                set output_timestep $MaxTimeStep
            }
        }
    dict set project_parameters_dict "OutputTimeStep"                   $output_timestep
    dict set project_parameters_dict "PostBoundingBox"                  [write::getValue DEM-Boundingbox PrintBoundingBox]
    dict set project_parameters_dict "PostDisplacement"                 [write::getValue Results DEM-Displacement]
    dict set project_parameters_dict "PostVelocity"                     [write::getValue Results DEM-PostVel]
    dict set project_parameters_dict "PostTotalForces"                  [write::getValue Results DEM-TotalForces]
    dict set project_parameters_dict "PostRigidElementForces"           [write::getValue Results DEM-RigidElementForces]
    dict set project_parameters_dict "PostRadius"                       [write::getValue Results DEM-Radius]
    dict set project_parameters_dict "PostAngularVelocity"              [write::getValue Results DEM-AngularVelocity]
    dict set project_parameters_dict "PostParticleMoment"               [write::getValue Results DEM-ParticleMoment]
    dict set project_parameters_dict "PostEulerAngles"                  [write::getValue Results DEM-EulerAngles]
    dict set project_parameters_dict "PostRollingResistanceMoment"      [write::getValue Results DEM-RollingResistanceMoment]
    dict set project_parameters_dict "PostElasticForces"                [write::getValue Results DEM-ElasForces]
    dict set project_parameters_dict "PostContactForces"                [write::getValue Results DEM-ContactForces]
    dict set project_parameters_dict "PostTangentialElasticForces"      [write::getValue Results DEM-TangElasForces]
    dict set project_parameters_dict "PostShearStress"                  [write::getValue Results DEM-ShearStress]
    dict set project_parameters_dict "PostPressure"                     [write::getValue Results DEM-Pressure]
    dict set project_parameters_dict "PostNonDimensionalVolumeWear"     [write::getValue Results DEM-Wear]
    dict set project_parameters_dict "PostNodalArea"                    [write::getValue Results DEM-NodalArea]
    dict set project_parameters_dict "PostRHS"                          [write::getValue Results DEM-Rhs]
    dict set project_parameters_dict "PostDampForces"                   [write::getValue Results DEM-DampForces]
    dict set project_parameters_dict "PostAppliedForces"                [write::getValue Results DEM-AppliedForces]
    dict set project_parameters_dict "PostGroupId"                      [write::getValue Results DEM-GroupId]
    dict set project_parameters_dict "PostExportId"                     [write::getValue Results DEM-ExportId]
    
    dict set project_parameters_dict "problem_name" [file tail [GiD_Info Project ModelName]]

    return $project_parameters_dict
}
proc DEM::write::writeParametersEvent { } {
    write::SetParallelismConfiguration
    write::WriteJSON [getParametersEvent]
}
