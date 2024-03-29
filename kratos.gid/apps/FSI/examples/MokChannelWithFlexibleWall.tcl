namespace eval ::FSI::examples::MokChannelFlexibleWall {
    namespace path ::FSI::examples
    Kratos::AddNamespace [namespace current]

}

proc ::FSI::examples::MokChannelFlexibleWall::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry
    AssignMeshSizes$::Model::SpatialDimension
    TreeAssignation
}

proc ::FSI::examples::MokChannelFlexibleWall::DrawGeometry {args} {
    Kratos::ResetModel
    GiD_Process Mescape 'Layers ChangeName Layer0 Fluid escape

    # Geometry creation
    set coordinates [list 0.5 0 0 0 0 0 0 0.5 0 1.75 0.5 0 1.75 0.3 0 1.35 0.3 0 1.3103 0.29881 0 1.2709 0.29453 0 1.232 0.28693 0 1.1937 0.27644 0 1.1565 0.26288 0 0.505 0 0]
    set fluidPoints [list ]
    foreach {x y z} $coordinates {
        lappend fluidPoints [GiD_Geometry create point append Fluid $x $y $z]
    }
    set coordinates [list 0.505 0.25 0 0.5 0.25 0]
    set fluidnterfacePoints [list ]
    foreach {x y z} $coordinates {
        lappend fluidnterfacePoints [GiD_Geometry create point append Fluid $x $y $z]
    }

    set fluidLines [list ]
    set initial [lindex $fluidPoints 0]
    foreach point [lrange $fluidPoints 1 end] {
        lappend fluidLines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }
    set fluidinteractionLines [list ]
    foreach point $fluidnterfacePoints {
        lappend fluidinteractionLines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }
    lappend fluidinteractionLines [GiD_Geometry create line append stline Fluid $initial [lindex $fluidPoints 0]]
    #set fluidSurface [GiD_Geometry create surface append plsurface Fluid [llength $fluidLines] {*}$fluidLines]
    set fluidalllines $fluidLines
    lappend fluidalllines {*}$fluidinteractionLines
    GiD_Process Mescape Geometry Create NurbsSurface {*}$fluidalllines escape escape


    GiD_Process 'Layers New Structure escape
    GiD_Process 'Layers Off Fluid escape
    GiD_Process 'Layers ToUse Structure escape


    set coordinates [list 0.505 0 0 0.505 0.25 0 0.5 0.25 0 0.5 0 0 ]
    set strucPoints [list ]
    foreach {x y z} $coordinates {
        lappend strucPoints [GiD_Geometry create point append Structure $x $y $z]
    }
    set strucLines [list ]
    set initial [lindex $strucPoints 0]
    foreach point [lrange $strucPoints 1 end] {
        lappend strucLines [GiD_Geometry create line append stline Structure $initial $point]
        set initial $point
    }
    lappend strucLines [GiD_Geometry create line append stline Structure $initial [lindex $strucPoints 0]]
    GiD_Process Mescape Geometry Create NurbsSurface {*}$strucLines escape escape

    GiD_Process 'Layers Color Fluid 047186223 Transparent Fluid 255 escape 'Layers Color Structure 187119038 Transparent Structure 255 escape
    GiD_Process 'Layers On Fluid escape

    if {$::Model::SpatialDimension eq "3D"} {
        GiD_Process 'Layers Off Structure escape Mescape
        GiD_Process Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,0.25 1 escape Mescape
        GiD_Process 'Layers On Structure escape 'Layers Off Fluid escape Mescape
        GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,0.25 2 escape Mescape
        GiD_Process 'Layers On Fluid escape
        GiD_Process 'Layers Transparent Fluid 127 escape
    }
    GiD_Process 'Zoom Frame
    GiD_Process 'Render Flat escape

    # Group creation
    GiD_Groups create Fluid
    GiD_Groups create Structure
    GiD_Groups create Inlet
    GiD_Groups create Outlet
    GiD_Groups create NoSlip
    GiD_Groups create Slip
    GiD_Groups create FluidInterface
    GiD_Groups create FixedDisplacement
    GiD_Groups create StructureInterface

    GiD_Groups create StructureLongSides
    GiD_Groups edit state StructureLongSides hidden
    GiD_Groups create StructureShortSides
    GiD_Groups edit state StructureShortSides hidden
    GiD_Groups create FluidLongSides
    GiD_Groups edit state FluidLongSides hidden
    GiD_Groups create FluidShortSides
    GiD_Groups edit state FluidShortSides hidden


    # Group entities
    if {$::Model::SpatialDimension eq "3D"} {
        GiD_Groups create FluidFixedDisplacement_full
        GiD_Groups create FluidFixedDisplacement_lat
        GiD_EntitiesGroups assign Fluid volumes 1
        GiD_EntitiesGroups assign Structure volumes 2
        GiD_EntitiesGroups assign Inlet surfaces 4
        GiD_EntitiesGroups assign Outlet surfaces 6
        GiD_EntitiesGroups assign NoSlip surfaces {3 7 8 9 10 11 12 13}
        GiD_EntitiesGroups assign Slip surfaces {1 5 17}
        GiD_EntitiesGroups assign FluidFixedDisplacement_full surfaces {3 4 5 6 7 8 9 10 11 12 13}
        GiD_EntitiesGroups assign FluidFixedDisplacement_lat surfaces {1 17}
        GiD_EntitiesGroups assign FluidInterface surfaces {14 15 16}
        GiD_EntitiesGroups assign FixedDisplacement surfaces {21}
        GiD_EntitiesGroups assign StructureInterface surfaces {18 19 20}

    } {
        GiD_Groups create FluidALEMeshBC
        GiD_EntitiesGroups assign Fluid surfaces 1
        GiD_EntitiesGroups assign Structure surfaces 2
        GiD_EntitiesGroups assign Inlet lines 2
        GiD_EntitiesGroups assign Slip lines 3
        GiD_EntitiesGroups assign Outlet lines 4
        GiD_EntitiesGroups assign NoSlip lines $fluidLines
        GiD_EntitiesGroups unassign NoSlip lines {2 3 4}
        GiD_EntitiesGroups assign FluidALEMeshBC lines $fluidLines
        GiD_EntitiesGroups assign FluidInterface lines $fluidinteractionLines
        GiD_EntitiesGroups assign FixedDisplacement lines [lindex $strucLines end]
        GiD_EntitiesGroups assign StructureInterface lines [lrange $strucLines 0 end-1]

        GiD_EntitiesGroups assign StructureLongSides lines {15 17}
        GiD_EntitiesGroups assign StructureShortSides lines {16 18}
        GiD_EntitiesGroups assign FluidLongSides lines {12 14}
        GiD_EntitiesGroups assign FluidShortSides lines 13
    }

    GidUtils::UpdateWindow GROUPS
}

proc ::FSI::examples::MokChannelFlexibleWall::AssignMeshSizes2D {args} {
    set long_side_divisions 100
    set short_side_divisions 4
    set outlet_element_size 0.01
    set noslip_element_size 0.01
    set fluid_element_size 0.02

    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing ElemType Quadrilateral [GiD_EntitiesGroups get Structure surfaces] escape
    GiD_Process Mescape Meshing Structured Surfaces [GiD_EntitiesGroups get Structure surfaces] escape $long_side_divisions [GiD_EntitiesGroups get StructureLongSides lines] escape $short_side_divisions [GiD_EntitiesGroups get StructureShortSides lines] escape escape
    GiD_Process Mescape Meshing Structured Lines $long_side_divisions {*}[GiD_EntitiesGroups get FluidLongSides lines] escape $short_side_divisions [GiD_EntitiesGroups get FluidShortSides lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $outlet_element_size {*}[GiD_EntitiesGroups get Outlet lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $noslip_element_size {*}[GiD_EntitiesGroups get NoSlip lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_element_size {*}[GiD_EntitiesGroups get Fluid surfaces] escape escape
    GiD_Process Mescape Meshing ElemType Triangle [GiD_EntitiesGroups get Fluid surfaces] escape escape
}

proc ::FSI::examples::MokChannelFlexibleWall::AssignMeshSizes3D {args} {
    set long_side_divisions 100
    set short_side_divisions 4
    set outlet_element_size 0.01
    set noslip_element_size 0.01
    set slip_element_size 0.01
    set fluid_element_size 0.02

    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing ElemType Tetrahedra [GiD_EntitiesGroups get Fluid volumes] escape
    GiD_Process Mescape Meshing ElemType Tetrahedra [GiD_EntitiesGroups get Structure volumes] escape
    # GiD_Process Mescape Meshing ElemType Hexahedra [GiD_EntitiesGroups get Structure volumes] escape
    GiD_Process Mescape Meshing Structured Surfaces 14 16 escape $long_side_divisions 12 14 escape $long_side_divisions 45 46 escape escape
    GiD_Process Mescape Meshing Structured Surfaces 15 escape $short_side_divisions 13 escape $long_side_divisions 45 46 escape escape
    GiD_Process Mescape Meshing Structured Volumes [GiD_EntitiesGroups get Structure volumes] escape $short_side_divisions 48 escape $long_side_divisions 15 17 52 53 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $outlet_element_size {*}[GiD_EntitiesGroups get Outlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $noslip_element_size {*}[GiD_EntitiesGroups get NoSlip surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $slip_element_size {*}[GiD_EntitiesGroups get Slip surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Volumes $fluid_element_size [GiD_EntitiesGroups get Fluid volumes] escape escape
}

proc ::FSI::examples::MokChannelFlexibleWall::TreeAssignation {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$::Model::SpatialDimension eq "3D"} { set condtype surface }

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 956.0 DYNAMIC_VISCOSITY 0.145]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions {container[@n='FSI']/container[@n='Fluid']/container[@n='BoundaryConditions']}

    # Fluid Interface
    set fluidInlet "$fluidConditions/condition\[@n='AutomaticInlet$nd'\]"

    # Fluid Inlet
    Fluid::xml::CreateNewInlet Inlet {new true name interval1 ini 0 end 10.0} true "0.1214*(1-cos(0.1*pi*t))*y*(1-y)"
    Fluid::xml::CreateNewInlet Inlet {new true name interval2 ini 10.0 end End} true "0.2428*y*(1-y)"

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" NoSlip] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Slip] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='FluidNoSlipInterface$nd'\]" FluidInterface] setAttribute ov $condtype

    # Displacement 3D
    if {$nd eq "3D"} {
        set fluidDisplacement "$fluidConditions/condition\[@n='ALEMeshDisplacementBC3D'\]"
        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement FluidFixedDisplacement_full]
        $fluidDisplacementNode setAttribute ov surface
        set props [list selector_component_X ByValue selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
        spdAux::SetValuesOnBaseNode $fluidDisplacementNode $props

        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement FluidFixedDisplacement_lat]
        $fluidDisplacementNode setAttribute ov surface
        set props [list selector_component_X Not selector_component_Y Not value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
        spdAux::SetValuesOnBaseNode $fluidDisplacementNode $props
    } {
        GiD_Groups create "FluidALEMeshBC//Total"
        GiD_Groups edit state "FluidALEMeshBC//Total" hidden
        spdAux::AddIntervalGroup FluidALEMeshBC "FluidALEMeshBC//Total"
        set fluidDisplacement "$fluidConditions/condition\[@n='ALEMeshDisplacementBC2D'\]"
        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement "FluidALEMeshBC//Total"]
        $fluidDisplacementNode setAttribute ov line
        set props [list selector_component_X ByValue selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
        spdAux::SetValuesOnBaseNode $fluidDisplacementNode $props
    }

    # Fluid domain time parameters
    set parameters [list EndTime 25.0 DeltaTime 0.1]
    set xpath [spdAux::getRoute FLTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Fluid domain output parameters
    set parameters [list OutputControlType step]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Fluid monolithic strategy setting
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid domain strategy settings
    set parameters [list relative_velocity_tolerance "1e-8" absolute_velocity_tolerance "1e-10" relative_pressure_tolerance "1e-8" absolute_pressure_tolerance "1e-10" maximum_iterations "20"]
    set xpath [spdAux::getRoute FLStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structural
    gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov [expr {$nd == "3D" ? "volume" : "surface"}]
    set constLawNameStruc [expr {$nd == "3D" ? "LinearElastic3DLaw" : "LinearElasticPlaneStress2DLaw"}]
    # set props [list Element TotalLagrangianElement$nd ConstitutiveLaw $constLawNameStruc THICKNESS 1.0 DENSITY 1500.0 VISCOSITY 1e-6 YIELD_STRESS 0 YOUNG_MODULUS 2.3e6 POISSON_RATIO 0.45]
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw $constLawNameStruc THICKNESS 1.0 DENSITY 1500.0 YOUNG_MODULUS 2.3e6 POISSON_RATIO 0.45]
    spdAux::SetValuesOnBaseNode $structPartsNode $props

    # Structural Displacement
    set structDisplacement {container[@n='FSI']/container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement FixedDisplacement]
    $structDisplacementNode setAttribute ov [expr {$nd == "3D" ? "surface" : "line"}]
    set props [list selector_component_X ByValue selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Structural Interface
    customlib::AddConditionGroupOnXPath "container\[@n='FSI'\]/container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='StructureInterface$nd'\]" StructureInterface

    # Structure domain time parameters
    set parameters [list EndTime 25.0 DeltaTime 0.1]
    set xpath [spdAux::getRoute STTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structure domain output parameters
    set parameters [list OutputControlType step]
    set xpath "[spdAux::getRoute STResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structure Bossak scheme setting
    spdAux::SetValueOnTreeItem v "bossak" STScheme

    # Structure domain strategy settings
    set parameters [list residual_relative_tolerance "1e-8" residual_absolute_tolerance "1e-10" max_iteration "20"]
    set xpath [spdAux::getRoute STStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Coupling settings
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    set parameters [list nl_tol "1e-8" nl_max_it 25]
    set xpath [spdAux::getRoute FSIStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    set parameters [list Solver MVQN_recursive buffer_size 7]
    set xpath [spdAux::getRoute FSIPartitionedcoupling_strategy]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
