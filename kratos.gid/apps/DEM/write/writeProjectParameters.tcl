
# Project Parameters
proc DEM::write::getParametersEvent { } {
    set project_parameters_dict [dict create]

    dict set project_parameters_dict "Dimension"                        [write::getValue nDim nDim]
    dict set project_parameters_dict "PeriodicDomainOption"             false
    dict set project_parameters_dict "BoundingBoxOption"                [write::getValue nDim nDim]
    dict set project_parameters_dict "AutomaticBoundingBoxOption"       [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxEnlargementFactor"     [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxStartTime"             [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxStopTime"              [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxMaxX"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxMaxY"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxMaxZ"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxMinX"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxMinY"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "BoundingBoxMinZ"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "dem_inlet_option"                 [write::getValue nDim nDim]
    
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

    dict set project_parameters_dict "EnergyCalculationOption"          false
    dict set project_parameters_dict "VelocityTrapOption"               false
    dict set project_parameters_dict "RotationOption"                   true
    dict set project_parameters_dict "CleanIndentationsOption"          true
    dict set project_parameters_dict "RemoveBallsInEmbeddedOption"      false
    dict set project_parameters_dict "DeltaOption"                      [write::getValue nDim nDim]
    dict set project_parameters_dict "SearchTolerance"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "AmplifiedSearchRadiusExtension"   [write::getValue nDim nDim]
    dict set project_parameters_dict "ModelDataInfo"                    false
    dict set project_parameters_dict "VirtualMassCoefficient"           [write::getValue nDim nDim]
    dict set project_parameters_dict "RollingFrictionOption"            [write::getValue nDim nDim]
    dict set project_parameters_dict "ContactMeshOption"                [write::getValue nDim nDim]
    dict set project_parameters_dict "OutputFileType"                   [write::getValue nDim nDim]
    dict set project_parameters_dict "Multifile"                        [write::getValue nDim nDim]
    dict set project_parameters_dict "ElementType"                      [write::getValue nDim nDim]
    
    dict set project_parameters_dict "AutomaticTimestep"                false
    dict set project_parameters_dict "DeltaTimeSafetyFactor"            1
    dict set project_parameters_dict "MaxTimeStep"                      [write::getValue DeltaTime DeltaTime]
    dict set project_parameters_dict "FinalTime"                        [write::getValue nDim nDim]
    dict set project_parameters_dict "ControlTime"                      [write::getValue EndTime EndTime]
    dict set project_parameters_dict "NeighbourSearchFrequency"         [write::getValue nDim nDim]
    
    dict set project_parameters_dict "GraphExportFreq"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "VelTrapGraphExportFreq"           false
    dict set project_parameters_dict "OutputTimeStep"                   [write::getValue nDim nDim]
    dict set project_parameters_dict "PostBoundingBox"                  false
    dict set project_parameters_dict "PostDisplacement"                 [write::getValue nDim nDim]
    dict set project_parameters_dict "PostVelocity"                     [write::getValue nDim nDim]
    dict set project_parameters_dict "PostTotalForces"                  [write::getValue nDim nDim]
    dict set project_parameters_dict "PostRigidElementForces"           false
    dict set project_parameters_dict "PostRadius"                       [write::getValue nDim nDim]
    dict set project_parameters_dict "PostAngularVelocity"              [write::getValue nDim nDim]
    dict set project_parameters_dict "PostParticleMoment"               [write::getValue nDim nDim]
    dict set project_parameters_dict "PostEulerAngles"                  [write::getValue nDim nDim]
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
    dict set project_parameters_dict "IntegrationScheme"                [write::getValue nDim nDim]

    dict set project_parameters_dict "problem_name" [file tail [GiD_Info Project ModelName]]

    return $project_parameters_dict
}
proc DEM::write::writeParametersEvent { } {
    write::WriteJSON [getParametersEvent]
}
