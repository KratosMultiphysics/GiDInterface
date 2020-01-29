
# Project Parameters

proc CDEM::write::getParametersDict { } {
    set project_parameters_dict [DEM::write::getParametersDict]

    set ElementType SphericContPartDEMElement3D
	if {$ElementType eq "SphericPartDEMElement3D" || $ElementType eq "CylinderPartDEMElement2D"} {
	    set dem_strategy "sphere_strategy"
	} elseif {$ElementType eq "SphericContPartDEMElement3D" || $ElementType eq "CylinderContPartDEMElement3D"} {
	    set dem_strategy "continuum_sphere_strategy"
	} elseif {$ElementType eq "ThermalSphericPartDEMElement3D"} {
	   set dem_strategy "thermal_sphere_strategy"
	} elseif {$ElementType eq "ThermalSphericContPartDEMElement3D"} {
	   set dem_strategy "thermal_continuum_sphere_strategy"
	} elseif {$ElementType eq "SinteringSphericConPartDEMElement3D"} {
	   set dem_strategy "thermal_continuum_sphere_strategy"
	} elseif {$ElementType eq "IceContPartDEMElement3D"} {
	   set dem_strategy "ice_continuum_sphere_strategy"
	}

    dict set project_parameters_dict "solver_settings" "strategy" $dem_strategy
    dict set project_parameters_dict "ElementType" $ElementType

    dict set project_parameters_dict "DeltaOption"                          [write::getValue AdvOptions DeltaOption]
    dict set project_parameters_dict "SearchTolerance"                      [write::getValue AdvOptions TangencyAbsoluteTolerance]
    dict set project_parameters_dict "CoordinationNumber"                   [write::getValue AdvOptions TangencyCoordinationNumber]
    dict set project_parameters_dict "AmplifiedSearchRadiusExtension"       [write::getValue AdvOptions AmplifiedSearchRadius]
    dict set project_parameters_dict "PoissonEffectOption"                  [write::getValue AdvOptions PoissonEffect]
    dict set project_parameters_dict "ShearStrainParallelToBondOption"      [write::getValue AdvOptions ShearStrainParallelToBondEffect]
    dict set project_parameters_dict "ComputeStressTensorOption"            [write::getValue AdvOptions ComputeStressTensorOption]
    dict set project_parameters_dict "MaxAmplificationRatioOfSearchRadius"  1000

    set material_test_parameters_dict [dict create]
    set material_analysis [write::getValue DEMTestMaterial Active]
    if {$material_analysis == "true"} {
        dict set material_test_parameters_dict "TestType"           [write::getValue DEMTestMaterial TestType]
        dict set material_test_parameters_dict "ConfinementPressure" [write::getValue DEMTestMaterial ConfinementPressure]
        dict set material_test_parameters_dict "LoadingVelocity"       [write::getValue DEMTestMaterial LoadVelocity]
        dict set material_test_parameters_dict "MeshType"           [write::getValue DEMTestMaterial Meshtype]
        dict set material_test_parameters_dict "SpecimenLength"     [write::getValue DEMTestMaterial Specimenlength]
        dict set material_test_parameters_dict "SpecimenDiameter"   [write::getValue DEMTestMaterial Specimendiameter]
        set SpecimenDiameter                                        [write::getValue DEMTestMaterial Specimendiameter]
        set MeasuringSurface [expr ($SpecimenDiameter*$SpecimenDiameter*3.141592/4.0)]
        dict set material_test_parameters_dict "MeasuringSurface"   $MeasuringSurface
        dict set project_parameters_dict "material_test_settings"   $material_test_parameters_dict
    }

    dict set project_parameters_dict "PostContactFailureId"             [write::getValue BondElem TypeOfFailure]

    return $project_parameters_dict
}

proc CDEM::write::GetTimeSettings { } {
    return [DEM::write::GetTimeSettings]
}

proc CDEM::write::GetGravity { } {
    return [DEM::write::GetGravity]
}

proc CDEM::write::writeParametersEvent { } {
    write::SetParallelismConfiguration
    write::WriteJSON [CDEM::write::getParametersDict]
}
