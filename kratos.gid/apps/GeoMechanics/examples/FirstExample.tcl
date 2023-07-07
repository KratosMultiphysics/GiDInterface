namespace eval ::GeoMechanics::examples::FirstExample {
    namespace path ::GeoMechanics::examples
    Kratos::AddNamespace [namespace current]

}

proc ::GeoMechanics::examples::FirstExample::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    Kratos::ResetModel

    DrawGeometry
    AssignGroups
    return ""
    AssignMeshSizes
    TreeAssignation

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::GeoMechanics::examples::FirstExample::DrawGeometry {args} {
    
    Kratos::ResetModel
    set layer_in_use Model
    GiD_Layers create $layer_in_use
    GiD_Layers edit to_use $layer_in_use

    set points [list {0 -15 0} {30 -15 0} {30 0 0} {29 0 0} {26 -3 0} {25 -3 0} {22 0 0} {20 0 0} {10 0 0} {0 0 0} ]
    set model_points [list ]
    foreach point $points {
        lassign $point x y z
        lappend model_points [GiD_Geometry create point append $layer_in_use $x $y $z]
    }

    set model_lines [list ]
    set initial [lindex $model_points 0]
    foreach point [lrange $model_points 1 end] {
        lappend model_lines [GiD_Geometry create line append stline $layer_in_use $initial $point]
        set initial $point
    }
    lappend model_lines [GiD_Geometry create line append stline $layer_in_use $initial [lindex $model_points 0]]
    lappend model_lines [GiD_Geometry create line append stline $layer_in_use 4 7]

    GiD_Process Mescape Geometry Create NurbsSurface 4 5 6 11 escape escape
    GiD_Process Mescape Geometry Create NurbsSurface 1 2 10 7 8 9 3 4 5 6 escape escape

}

proc ::GeoMechanics::examples::FirstExample::AssignGroups {args} {
    # Fluid group creation
    GiD_Groups create Bottom
    GiD_EntitiesGroups assign Bottom lines 1

    GiD_Groups create Clay_after_excavation
    GiD_EntitiesGroups assign Clay_after_excavation surfaces 2

    GiD_Groups create Excavated
    GiD_EntitiesGroups assign Excavated surfaces 1

    GiD_Groups create Load
    GiD_EntitiesGroups assign Load lines 8

    GiD_Groups create Body
    GiD_EntitiesGroups assign Body surfaces {1 2}

    GiD_Groups create Hydrostatic_load_in_sloot
    GiD_EntitiesGroups assign Hydrostatic_load_in_sloot lines {4 5 6}

    GiD_Groups create Side_sliders
    GiD_EntitiesGroups assign Side_sliders lines {2 10}

}


proc ::GeoMechanics::examples::FirstExample::AssignMeshSizes {args} {
    ::Fluid::examples::HighRiseBuilding::AssignMeshSizes$::Model::SpatialDimension
    ::Structural::examples::HighRiseBuilding::AssignMeshSizes$::Model::SpatialDimension
}

proc ::GeoMechanics::examples::FirstExample::TreeAssignation {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$::Model::SpatialDimension eq "3D"} { set condtype surface }

    # Fluid monolithic strategy setting
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.225 DYNAMIC_VISCOSITY 1.846e-5]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions {container[@n='FSI']/container[@n='Fluid']/container[@n='BoundaryConditions']}

    # Fluid Inlet
    Fluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 10.0} true "25.0*t/10.0"
    Fluid::xml::CreateNewInlet Inlet {new true name inlet2 ini 10.0 end End} false 25.0
    
    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Top_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Bottom_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='FluidNoSlipInterface$nd'\]" InterfaceFluid] setAttribute ov $condtype

    # Displacement 3D
    if {$nd eq "3D"} {
        # To be implemented
    } {
        GiD_Groups create "FluidALEMeshBC//Total"
        GiD_Groups edit state "FluidALEMeshBC//Total" hidden
        spdAux::AddIntervalGroup FluidALEMeshBC "FluidALEMeshBC//Total"
        set fluidDisplacement "$fluidConditions/condition\[@n='ALEMeshDisplacementBC2D'\]"
        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement "FluidALEMeshBC//Total"]
        $fluidDisplacementNode setAttribute ov line
        set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
        
        spdAux::SetValuesOnBaseNode $fluidDisplacementNode $props
    }

    # Time parameters
    set parameters [list EndTime 40.0 DeltaTime 0.05]
    set xpath [spdAux::getRoute "FLTimeParameters"]
    
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType time OutputDeltaTime 1.0]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Fluid domain strategy settings
    set parameters [list relative_velocity_tolerance "1e-8" absolute_velocity_tolerance "1e-10" relative_pressure_tolerance "1e-8" absolute_pressure_tolerance "1e-10" maximum_iterations "20"]
    set xpath [spdAux::getRoute FLStratParams]
    
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structural
    gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStress2DLaw"
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 7850 YOUNG_MODULUS 206.9e9 POISSON_RATIO 0.29 THICKNESS 0.1]
    spdAux::SetValuesOnBaseNode $structPartsNode $props

    # Structural Displacement
    GiD_Groups clone Ground Total
    GiD_Groups edit parent Total Ground
    spdAux::AddIntervalGroup Ground "Ground//Total"
    GiD_Groups edit state "Ground//Total" hidden
    set structDisplacement {container[@n='FSI']/container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement Ground]
    $structDisplacementNode setAttribute ov line
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Structure domain time parameters
    set parameters [list EndTime 40.0 DeltaTime 0.05]
    set xpath [spdAux::getRoute STTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structural Interface
    customlib::AddConditionGroupOnXPath "container\[@n='FSI'\]/container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='StructureInterface$nd'\]" InterfaceStructure

    # Structure domain output parameters
    set parameters [list OutputControlType time OutputDeltaTime 1.0]
    set xpath "[spdAux::getRoute STResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structure Bossak scheme setting
    spdAux::SetValueOnTreeItem v "bossak" STScheme

    # Structure domain strategy settings
    set parameters [list echo_level 0 residual_relative_tolerance "1e-8" residual_absolute_tolerance "1e-10" max_iteration "20"]
    set xpath [spdAux::getRoute STStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Coupling settings
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    set parameters [list nl_tol "1e-8" nl_max_it 25]
    set xpath [spdAux::getRoute FSIStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    set parameters [list Solver Relaxation]
    set xpath [spdAux::getRoute FSIPartitionedcoupling_strategy]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
