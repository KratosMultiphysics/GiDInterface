
# Project Parameters
proc DEM::write::getParametersEvent { } {
    set project_parameters_dict [dict create]

    dict set project_parameters_dict "Dimension"                        3
    dict set project_parameters_dict "PeriodicDomainOption"             false
    dict set project_parameters_dict "BoundingBoxOption"                [write::getValue DEM-Boundingbox UseBoundingBox]
    dict set project_parameters_dict "AutomaticBoundingBoxOption"       false
    dict set project_parameters_dict "BoundingBoxStartTime"             [write::getValue DEM-Boundingbox StartTime]
    dict set project_parameters_dict "BoundingBoxStopTime"              [write::getValue DEM-Boundingbox StopTime]
    dict set project_parameters_dict "BoundingBoxMaxX"                  [write::getValue DEM-Boundingbox MaxX]
    dict set project_parameters_dict "BoundingBoxMaxY"                  [write::getValue DEM-Boundingbox MaxY]
    dict set project_parameters_dict "BoundingBoxMaxZ"                  [write::getValue DEM-Boundingbox MaxZ]
    dict set project_parameters_dict "BoundingBoxMinX"                  [write::getValue DEM-Boundingbox MinX]
    dict set project_parameters_dict "BoundingBoxMinY"                  [write::getValue DEM-Boundingbox MinY]
    dict set project_parameters_dict "BoundingBoxMinZ"                  [write::getValue DEM-Boundingbox MinZ]
    
    # Gravity
        # Get data
        set gravity_value [write::getValue DEMGravity GravityValue]
        set gravity_X [write::getValue DEMGravity Cx]
        set gravity_Y [write::getValue DEMGravity Cy]
        set gravity_Z [write::getValue DEMGravity Cz]
        # Normalize director vector
        lassign [MathUtils::VectorNormalized [list $gravity_X $gravity_Y $gravity_Z]] gravity_X gravity_Z gravity_Y
        # Get value by components
        lassign [MathUtils::ScalarByVectorProd $gravity_value [list $gravity_X $gravity_Y $gravity_Z] ] gx gy gz
        # Add data to the parameters_dict
        dict set project_parameters_dict "GravityX" $gx
        dict set project_parameters_dict "GravityY" $gy
        dict set project_parameters_dict "GravityZ" $gz

    dict set project_parameters_dict "dem_inlet_option"                 true
    dict set project_parameters_dict "EnergyCalculationOption"          false
    dict set project_parameters_dict "VelocityTrapOption"               false
    dict set project_parameters_dict "RotationOption"                   true
    dict set project_parameters_dict "CleanIndentationsOption"          true
    dict set project_parameters_dict "RemoveBallsInEmbeddedOption"      false
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
    
    dict set project_parameters_dict "IntegrationScheme"                "Symplectic_Euler"
    dict set project_parameters_dict "AutomaticTimestep"                false
    dict set project_parameters_dict "DeltaTimeSafetyFactor"            1
    dict set project_parameters_dict "MaxTimeStep"                      [write::getValue DEMTimeParameters DeltaTime]
    dict set project_parameters_dict "FinalTime"                        [write::getValue DEMTimeParameters EndTime]
    dict set project_parameters_dict "ControlTime"                      20
    dict set project_parameters_dict "NeighbourSearchFrequency"         [write::getValue DEMTimeParameters DEM-NeighbourSearchFrequency]
    
    dict set project_parameters_dict "GraphExportFreq"                  1
    dict set project_parameters_dict "VelTrapGraphExportFreq"           1
    dict set project_parameters_dict "OutputTimeStep"                   1
    dict set project_parameters_dict "PostBoundingBox"                  false
    dict set project_parameters_dict "PostDisplacement"                 true
    dict set project_parameters_dict "PostVelocity"                     true
    dict set project_parameters_dict "PostTotalForces"                  true
    dict set project_parameters_dict "PostRigidElementForces"           false
    dict set project_parameters_dict "PostRadius"                       true
    dict set project_parameters_dict "PostAngularVelocity"              true
    dict set project_parameters_dict "PostParticleMoment"               true
    dict set project_parameters_dict "PostEulerAngles"                  false
    dict set project_parameters_dict "PostRollingResistanceMoment"      false
    dict set project_parameters_dict "PostElasticForces"                false
    dict set project_parameters_dict "PostContactForces"                false
    dict set project_parameters_dict "PostTangentialElasticForces"      false
    dict set project_parameters_dict "PostShearStress"                  false
    dict set project_parameters_dict "PostPressure"                     false
    dict set project_parameters_dict "PostNonDimensionalVolumeWear"     false
    dict set project_parameters_dict "PostNodalArea"                    false
    dict set project_parameters_dict "PostRHS"                          false
    dict set project_parameters_dict "PostDampForces"                   false
    dict set project_parameters_dict "PostAppliedForces"                false
    dict set project_parameters_dict "PostGroupId"                      false
    dict set project_parameters_dict "PostExportId"                     false
    

    dict set project_parameters_dict "problem_name" [file tail [GiD_Info Project ModelName]]

    return $project_parameters_dict
}
proc DEM::write::writeParametersEvent { } {
    write::WriteJSON [getParametersEvent]
}
