namespace eval ::FSI::examples::TurekBenchmark {
    namespace path ::FSI::examples

}

proc ::FSI::examples::TurekBenchmark::Init {args} {
    # At this moment we do only support 2D for this test
    if {$::Model::SpatialDimension eq "2D"} {
        if {![Kratos::IsModelEmpty]} {
            set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
            set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
            if { $retval == "cancel" } { return }
        }
        # Set up geometry and groups
        DrawGeometryFluid
        DrawGeometryStructure
        # Generated geometry frame zoom
        GiD_Process 'Layers On Fluid escape
        GiD_Process 'Layers On Structure escape
        GiD_Process 'Zoom Frame
        GiD_Process 'Render Flat escape
        # Assign mesh sizes
        AssignMeshSizes$::Model::SpatialDimension
        # Assign tree values
        TreeAssignation
    }
}

proc ::FSI::examples::TurekBenchmark::DrawGeometryFluid {args} {
    Kratos::ResetModel

    # Set fluid domain geometry
    if {$::Model::SpatialDimension eq "2D"} {
        GiD_Process 'Layers ChangeName Layer0 Fluid escape Mescape 
        GiD_Process MEscape Geometry Create Object Rectangle 0,0 2.5,0.41 Mescape 
        GiD_Process MEscape Geometry Delete Surfaces 1 escape Mescape \
        'GetPointCoord Silent FNoJoin 0.2,0.2 escape escape 
        GiD_Process MEscape Geometry Create Object CirclePNR 0.2 0.2 0.0 0.0 0.0 1.0 0.05 escape escape escape 
        GiD_Process MEscape Geometry Delete Surfaces 1 escape escape  
        GiD_Process MEscape Geometry Create Line 0.6,0.19 @-0.4,0 escape Join 6 NoJoin @0,0.02 @-0.4,0 escape escape escape escape escape  
        GiD_Process MEscape Geometry Create IntMultLines 5 6 escape 8 10 escape escape escape escape  
        GiD_Process MEscape Geometry Delete AllTypes points 7 9 lines 12 14 surfaces volumes dimensions points lines 15 surfaces volumes dimensions escape escape 
        GiD_Process MEscape Geometry Create NurbsSurface 1 2 3 4 7 9 11 13 16 escape escape
    } else {
        # 3D version not implemented yet
    }

    # Set layer coloring
    GiD_Process 'Layers Color Fluid 047186223 Transparent Fluid 255 escape 
    GiD_Process 'Layers On Fluid escape

    # Group creation
    GiD_Groups create Fluid
    GiD_Groups create Inlet
    GiD_Groups create Outlet
    GiD_Groups create NoSlip
    GiD_Groups create Cylinder
    GiD_Groups create FluidInterface
    GiD_Groups create CylinderAndFlag

    # Groups entities assignation
    if {$::Model::SpatialDimension eq "2D"} {
        GiD_Groups create FluidALEMeshFreeX
        GiD_Groups create FluidALEMeshFixXY
        GiD_EntitiesGroups assign Fluid surfaces 1
        GiD_EntitiesGroups assign Inlet lines 4
        GiD_EntitiesGroups assign Outlet lines 2
        GiD_EntitiesGroups assign NoSlip lines {1 3}
        GiD_EntitiesGroups assign Cylinder lines {9 16}
        GiD_EntitiesGroups assign FluidInterface lines {7 11 13}
        GiD_EntitiesGroups assign FluidALEMeshFreeX lines {1 3}
        GiD_EntitiesGroups assign FluidALEMeshFixXY lines {4 2}
        GiD_EntitiesGroups assign CylinderAndFlag lines {9 16 7 11 13}
    } else {
        # 3D version not implemented yet
    }

    GidUtils::UpdateWindow GROUPS
}

proc ::FSI::examples::TurekBenchmark::DrawGeometryStructure {args} {

    # Set structure domain geometry
    if {$::Model::SpatialDimension eq "2D"} {
        
        GiD_Process 'Layers New Structure escape
        GiD_Process 'Layers Off Fluid escape
        GiD_Process 'Layers ToUse Structure escape

        GiD_Process Mescape Geometry Create Object CirclePNR 0.2 0.2 0.0 0.0 0.0 1.0 0.05 escape Mescape 
        GiD_Process Mescape Geometry Create Line 0.6,0.19 @-0.4,0 escape Join 13 NoJoin @0,0.02 @-0.4,0 escape escape Mescape 
        GiD_Process Mescape Geometry Delete Surfaces 2 escape escape Mescape 
        GiD_Process Mescape Geometry Create IntMultLines 17 18 escape 20 22 escape escape escape escape escape Mescape 
        GiD_Process Mescape Geometry Delete Lines 21 28 escape Mescape 
        GiD_Process Mescape Geometry Delete AllTypes points 12 14 16 lines 24 26 surfaces volumes dimensions escape escape escape escape escape escape Mescape 
        GiD_Process Mescape Geometry Create NurbsSurface 19 23 25 27 escape escape escape escape
    } else {
        # 3D version not implemented yet
    }

    # Set layer coloring
    GiD_Process 'Layers Color Structure 187119038 Transparent Structure 255 escape
    GiD_Process 'Layers On Structure escape

    # Group creation
    GiD_Groups create Structure
    GiD_Groups create FixedDisplacement
    GiD_Groups create StructureInterface

    # Groups entities assignation
    if {$::Model::SpatialDimension eq "2D"} {
        GiD_EntitiesGroups assign Structure surfaces 2
        GiD_EntitiesGroups assign FixedDisplacement lines 27
        GiD_EntitiesGroups assign StructureInterface lines {19 23 25}
    } else {
        # 3D version not implemented yet
    }

    GidUtils::UpdateWindow GROUPS
}

proc ::FSI::examples::TurekBenchmark::AssignMeshSizes2D {args} {
    # Structure and fluid mesh settings
    set str_flag_tail_divisions 15
    set str_flag_long_sides_divisions 175
    set fluid_cylinder_element_size 0.0015
    set fluid_flag_tail_element_size 0.00125
    set fluid_flag_long_sides_element_size 0.002
    set fluid_walls_element_size 0.01
    set fluid_domain_element_size 0.01

    # Transition factor settings
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.3 escape escape

    # Structure meshing settings
    GiD_Process Mescape Meshing ElemType Quadrilateral 2 escape 
    GiD_Process Mescape Meshing Structured Surfaces 2 escape $str_flag_long_sides_divisions 23 25 escape $str_flag_tail_divisions 27 escape escape

    # Fluid meshing settings
    GiD_Process Mescape Meshing ElemType Triangle 1 escape 
    GiD_Process Mescape Meshing AssignSizes Lines $fluid_flag_tail_element_size 7 escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $fluid_cylinder_element_size 9 16 escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $fluid_walls_element_size 1 2 3 4 escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $fluid_flag_long_sides_element_size 11 13 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_domain_element_size 1 escape escape
}

# proc ::FSI::examples::TurekBenchmark::AssignTurekBenchmarkMeshSizes3D {args} {
#     set long_side_divisions 100
#     set short_side_divisions 4
#     set outlet_element_size 0.01
#     set noslip_element_size 0.01
#     set slip_element_size 0.01
#     set fluid_element_size 0.02

#     GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
#     GiD_Process Mescape Meshing ElemType Tetrahedra [GiD_EntitiesGroups get Fluid volumes] escape
#     GiD_Process Mescape Meshing ElemType Hexahedra [GiD_EntitiesGroups get Structure volumes] escape
#     GiD_Process Mescape Meshing Structured Surfaces 14 16 escape $long_side_divisions 12 14 escape $long_side_divisions 45 46 escape escape
#     GiD_Process Mescape Meshing Structured Surfaces 15 escape $short_side_divisions 13 escape $long_side_divisions 45 46 escape escape
#     GiD_Process Mescape Meshing Structured Volumes [GiD_EntitiesGroups get Structure volumes] escape $short_side_divisions 48 escape $long_side_divisions 15 17 52 53 escape escape
#     GiD_Process Mescape Meshing AssignSizes Surfaces $outlet_element_size {*}[GiD_EntitiesGroups get Outlet surfaces] escape escape
#     GiD_Process Mescape Meshing AssignSizes Surfaces $noslip_element_size {*}[GiD_EntitiesGroups get NoSlip surfaces] escape escape
#     GiD_Process Mescape Meshing AssignSizes Surfaces $slip_element_size {*}[GiD_EntitiesGroups get Slip surfaces] escape escape
#     GiD_Process Mescape Meshing AssignSizes Volumes $fluid_element_size [GiD_EntitiesGroups get Fluid volumes] escape escape
# }

proc ::FSI::examples::TurekBenchmark::TreeAssignation {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$::Model::SpatialDimension eq "3D"} { set condtype surface }

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1000.0 DYNAMIC_VISCOSITY 1.0]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions {container[@n='FSI']/container[@n='Fluid']/container[@n='BoundaryConditions']}
    
    # Fluid Interface
    set fluidInlet "$fluidConditions/condition\[@n='AutomaticInlet$nd'\]"
    
    # Fluid Inlet
    Fluid::xml::CreateNewInlet Inlet {new true name interval1 ini 0 end 2.0} true "1.5*(0.5*(1-cos(0.5*pi*t))*1.0)*(4.0/0.1681)*y*(0.41-y)"
    Fluid::xml::CreateNewInlet Inlet {new true name interval2 ini 2.0 end end} true "1.5*(1.0)*(4.0/0.1681)*y*(0.41-y)"
    
    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" NoSlip] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" Cylinder] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='FluidNoSlipInterface$nd'\]" FluidInterface] setAttribute ov $condtype

    # Displacement 3D
    if {$nd eq "3D"} {
        
    } {
        set gname "FluidALEMeshFreeX//Total"
        GiD_Groups create $gname
        GiD_Groups edit state $gname hidden
        spdAux::AddIntervalGroup FluidALEMeshFreeX $gname

        set fluidDisplacement "$fluidConditions/condition\[@n='ALEMeshDisplacementBC2D'\]"
        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement $gname]
        $fluidDisplacementNode setAttribute ov line
        set props [list selector_component_X Not selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
        spdAux::SetValuesOnBaseNode $fluidDisplacementNode $props
        
        set gname "FluidALEMeshFixXY//Total"
        GiD_Groups create $gname
        GiD_Groups edit state $gname hidden
        spdAux::AddIntervalGroup FluidALEMeshFixXY $gname
        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement $gname]
        $fluidDisplacementNode setAttribute ov line
        set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z Not.0 Interval Total]
        spdAux::SetValuesOnBaseNode $fluidDisplacementNode $props

        set gname "Cylinder//Total"
        GiD_Groups create $gname
        GiD_Groups edit state $gname hidden
        spdAux::AddIntervalGroup Cylinder $gname
        set fluidDisplacementNode [customlib::AddConditionGroupOnXPath $fluidDisplacement $gname]
        $fluidDisplacementNode setAttribute ov line
        set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
        spdAux::SetValuesOnBaseNode $fluidDisplacementNode $props
    }

    # Fluid domain time parameters
    set parameters [list EndTime 20.0 DeltaTime 0.002]
    set xpath [spdAux::getRoute FLTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Fluid domain output parameters
    set parameters [list OutputControlType time OutputDeltaTime 0.01]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Fluid monolithic strategy setting
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid domain strategy settings
    set parameters [list relative_velocity_tolerance "1e-6" absolute_velocity_tolerance "1e-8" relative_pressure_tolerance "1e-6" absolute_pressure_tolerance "1e-8" maximum_iterations "10"]
    set xpath [spdAux::getRoute FLStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structural
    gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov [expr {$nd == "3D" ? "volume" : "surface"}]
    set constLawNameStruc [expr {$nd == "3D" ? "KirchhoffSaintVenant3DLaw" : "KirchhoffSaintVenantPlaneStrain2DLaw"}]
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 10000.0 YOUNG_MODULUS 1.4e6 POISSON_RATIO 0.4]
    spdAux::SetValuesOnBaseNode $structPartsNode $props

    # Structural Displacement
    set gname "FixedDisplacement//Total"
    GiD_Groups create $gname
    GiD_Groups edit state $gname hidden
    spdAux::AddIntervalGroup FixedDisplacement $gname
    set structDisplacement {container[@n='FSI']/container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement $gname]
    $structDisplacementNode setAttribute ov [expr {$nd == "3D" ? "surface" : "line"}]
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Structural Interface
    customlib::AddConditionGroupOnXPath "container\[@n='FSI'\]/container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='StructureInterface$nd'\]" StructureInterface

    # Structure domain time parameters
    set parameters [list EndTime 20.0 DeltaTime 0.002]
    set xpath [spdAux::getRoute STTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structure domain output parameters
    set parameters [list OutputControlType time OutputDeltaTime 0.01]
    set xpath "[spdAux::getRoute STResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Structure Bossak scheme setting
    spdAux::SetValueOnTreeItem v "bossak" STScheme

    # Structure domain strategy settings
    set parameters [list residual_relative_tolerance "1e-6" residual_absolute_tolerance "1e-8" max_iteration "10"]
    set xpath [spdAux::getRoute STStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Coupling settings
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    set parameters [list nl_tol "1e-6" nl_max_it 10]
    set xpath [spdAux::getRoute FSIStratParams]
    spdAux::SetValuesOnBasePath $xpath $parameters

    set parameters [list Solver MVQN]
    set xpath [spdAux::getRoute FSIPartitionedcoupling_strategy]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
