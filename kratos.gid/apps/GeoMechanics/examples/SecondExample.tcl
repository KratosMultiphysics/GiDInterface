namespace eval ::GeoMechanics::examples::SecondExample {
    namespace path ::GeoMechanics::examples
    Kratos::AddNamespace [namespace current]

}

proc ::GeoMechanics::examples::SecondExample::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    Kratos::ResetModel

    DrawGeometry
    AssignGroups
    AssignMeshSizes
    TreeAssignation
    MeshGenerationOKDo 1

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::GeoMechanics::examples::SecondExample::DrawGeometry {args} {
    
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

proc ::GeoMechanics::examples::SecondExample::AssignGroups {args} {
    # Fluid group creation
    GiD_Groups create Bottom
    GiD_EntitiesGroups assign Bottom lines 1

    GiD_Groups create Clay_after_excavation
    GiD_EntitiesGroups assign Clay_after_excavation surfaces 2
    GiD_Groups edit color Clay_after_excavation "#995e05"

    GiD_Groups create Excavated
    GiD_EntitiesGroups assign Excavated surfaces 1
    GiD_Groups edit color Excavated "#6e4aff"

    GiD_Groups create Load
    GiD_EntitiesGroups assign Load lines 8

    GiD_Groups create Hydrostatic_load_in_sloot
    GiD_EntitiesGroups assign Hydrostatic_load_in_sloot lines {4 5 6}

    GiD_Groups create Side_sliders
    GiD_EntitiesGroups assign Side_sliders lines {2 10}

}


proc ::GeoMechanics::examples::SecondExample::AssignMeshSizes {args} {

}

proc ::GeoMechanics::examples::SecondExample::TreeAssignation {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    # Stage 1
    set stage [$root selectNodes ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 1'\]"]

    # Solution type
    set xpath [spdAux::getRoute "GEOMSoluType" $stage]
    [[customlib::GetBaseRoot] selectNodes $xpath] setAttribute v "Quasi-static"

    # Time parameters
    set parameters [list StartTime 0.0 EndTime 1.0]
    set xpath [spdAux::getRoute "GEOMTimeParameters" $stage]
    spdAux::SetValuesOnBasePath $xpath $parameters
    
    set parameters [list DeltaTime 1.0 StartTime 0]
    set xpath "[spdAux::getRoute GEOMTimeParameters $stage]/container\[@n = 'TimeStep'\]/blockdata"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Parts
    set parts [spdAux::getRoute "GEOMParts" $stage]/condition\[@n='Parts_GeoSteadyState'\]
    set body_node [customlib::AddConditionGroupOnXPath $parts Clay_after_excavation]
    set props [list YOUNG_MODULUS 1000 POISSON_RATIO 0.3]
    spdAux::SetValuesOnBaseNode $body_node $props
    set body_node [customlib::AddConditionGroupOnXPath $parts Excavated]
    set props [list YOUNG_MODULUS 1000 POISSON_RATIO 0.3]
    spdAux::SetValuesOnBaseNode $body_node $props

    # Phreatic line 
    ::GeoMechanics::xml::AddPhreaticPoint $stage 0.0 -1.0 0.0
    ::GeoMechanics::xml::AddPhreaticPoint $stage 30.0 -1.0 0.0

    # Fix ground
    GiD_Groups clone Bottom Total
    GiD_Groups edit parent Total Bottom
    spdAux::AddIntervalGroup Bottom "Bottom//Total"
    GiD_Groups edit state "Bottom//Total" hidden
    set displacement [spdAux::getRoute "GEOMNodalConditions" $stage]/condition\[@n='DISPLACEMENT'\]
    set displacement_node [customlib::AddConditionGroupOnXPath $displacement "Bottom//Total"]
    $displacement_node setAttribute ov line
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue selector_component_Z Not Interval Total]
    spdAux::SetValuesOnBaseNode $displacement_node $props

    # Fix sides only X
    GiD_Groups clone Side_sliders Total
    GiD_Groups edit parent Total Side_sliders
    spdAux::AddIntervalGroup Side_sliders "Side_sliders//Total"
    GiD_Groups edit state "Side_sliders//Total" hidden
    set displacement [spdAux::getRoute "GEOMNodalConditions" $stage]/condition\[@n='DISPLACEMENT'\]
    set displacement_node [customlib::AddConditionGroupOnXPath $displacement "Side_sliders//Total"]
    $displacement_node setAttribute ov line
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y Not selector_component_Z Not Interval Total]
    spdAux::SetValuesOnBaseNode $displacement_node $props
    
    # Gravity
    if {![GiD_Groups exists "Clay_after_excavation//Total"]} {
        GiD_Groups clone Clay_after_excavation Total
        GiD_Groups edit parent Total Clay_after_excavation
        spdAux::AddIntervalGroup Clay_after_excavation "Clay_after_excavation//Total"
        GiD_Groups edit state "Clay_after_excavation//Total" hidden
    }
    set gravity [spdAux::getRoute "GEOMLoads" $stage]/condition\[@n='SelfWeight2D'\]
    set gravity_node [customlib::AddConditionGroupOnXPath $gravity "Clay_after_excavation//Total"]
    $gravity_node setAttribute ov surface
    set props [list modulus 9.81 value_direction_Y -1.0 Interval Total]
    spdAux::SetValuesOnBaseNode $gravity_node $props

    if {![GiD_Groups exists "Excavated//Total"]} {
        GiD_Groups clone Excavated Total
        GiD_Groups edit parent Total Excavated
        spdAux::AddIntervalGroup Excavated "Excavated//Total"
        GiD_Groups edit state "Excavated//Total" hidden
    }
    set gravity [spdAux::getRoute "GEOMLoads" $stage]/condition\[@n='SelfWeight2D'\]
    set gravity_node [customlib::AddConditionGroupOnXPath $gravity "Excavated//Total"]
    $gravity_node setAttribute ov surface
    set props [list modulus 9.81 value_direction_Y -1.0 Interval Total]
    spdAux::SetValuesOnBaseNode $gravity_node $props

    # Pressure on bottom line
    set pressure [spdAux::getRoute "STNodalConditions" $stage]/condition\[@n='WATER_PRESSURE'\]
    set pressure_node [customlib::AddConditionGroupOnXPath $pressure "Bottom"]
    $pressure_node setAttribute ov line
    set props [list value -137.34]
    spdAux::SetValuesOnBaseNode $pressure_node $props


    # Stage 2
    ::GeoMechanics::xml::NewStage "Stage 2"
    set stage [$root selectNodes ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 2'\]"]

    # Top Pressure
    GiD_Groups clone Load Total
    GiD_Groups edit parent Total Load
    spdAux::AddIntervalGroup Load "Load//Total"
    GiD_Groups edit state "Load//Total" hidden
    set pressure [spdAux::getRoute "GEOMLoads" $stage]/condition\[@n='LinePressure2D'\]
    set pressure_node [customlib::AddConditionGroupOnXPath $pressure "Load//Total"]
    $pressure_node setAttribute ov line
    set props [list value 5000 Interval Total]
    spdAux::SetValuesOnBaseNode $pressure_node $props

    # Stage 3
    ::GeoMechanics::xml::NewStage "Stage 3"
    set stage [$root selectNodes ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 3'\]"]
    
    # Remove body to split into excavated and clay
    gid_groups_conds::delete ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 3'\]/container\[@n = 'Parts']/condition/group"
    gid_groups_conds::delete ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 3'\]/container\[@n = 'Loads']/condition\[@n='SelfWeight2D'\]/group"

    # Parts
    set parts [spdAux::getRoute "GEOMParts" $stage]/condition\[@n='Parts_GeoSteadyState'\]
    set body_node [customlib::AddConditionGroupOnXPath $parts Clay_after_excavation]
    set props [list YOUNG_MODULUS 1000 POISSON_RATIO 0.3]
    spdAux::SetValuesOnBaseNode $body_node $props

    set parts [spdAux::getRoute "GEOMParts" $stage]/condition\[@n='Parts_GeoSteadyState'\]
    set body_node [customlib::AddConditionGroupOnXPath $parts Excavated]
    set props [list YOUNG_MODULUS 1000 POISSON_RATIO 0.3]
    spdAux::SetValuesOnBaseNode $body_node $props

    
    # Gravity
    if {![GiD_Groups exists "Clay_after_excavation//Total"]} {
        GiD_Groups clone Clay_after_excavation Total
        GiD_Groups edit parent Total Clay_after_excavation
        spdAux::AddIntervalGroup Clay_after_excavation "Clay_after_excavation//Total"
        GiD_Groups edit state "Clay_after_excavation//Total" hidden
    }
    set gravity [spdAux::getRoute "GEOMLoads" $stage]/condition\[@n='SelfWeight2D'\]
    set gravity_node [customlib::AddConditionGroupOnXPath $gravity "Clay_after_excavation//Total"]
    $gravity_node setAttribute ov surface
    set props [list modulus 9.81 value_direction_Y -1.0 Interval Total]
    spdAux::SetValuesOnBaseNode $gravity_node $props
    
    
    if {![GiD_Groups exists "Excavated//Total"]} {
        GiD_Groups clone Excavated Total
        GiD_Groups edit parent Total Excavated
        spdAux::AddIntervalGroup Excavated "Excavated//Total"
        GiD_Groups edit state "Excavated//Total" hidden
    }
    set gravity [spdAux::getRoute "GEOMLoads" $stage]/condition\[@n='SelfWeight2D'\]
    set gravity_node [customlib::AddConditionGroupOnXPath $gravity "Excavated//Total"]
    $gravity_node setAttribute ov surface
    set props [list modulus 9.81 value_direction_Y -1.0 Interval Total]
    spdAux::SetValuesOnBaseNode $gravity_node $props

    
    # Stage 4
    ::GeoMechanics::xml::NewStage "Stage 4"
    set stage [$root selectNodes ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 4'\]"]

    # Remove excavated
    gid_groups_conds::delete ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 4'\]/container\[@n = 'Parts']/condition/group\[@n='Excavated'\]"
    gid_groups_conds::delete ".//container\[@n='stages'\]/blockdata\[@name = 'Stage 4'\]/container\[@n = 'Loads']/condition\[@n='SelfWeight2D'\]/group\[@n='Excavated//Total'\]"
    
    
    spdAux::parseRoutes

    ::GeoMechanics::PrevStage
    return ""


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
