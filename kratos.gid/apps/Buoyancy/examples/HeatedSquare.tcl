
proc ::Buoyancy::examples::HeatedSquare {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawSquareGeometry$::Model::SpatialDimension
    AssignSquareGeometryMeshSizes$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Buoyancy::examples::DrawSquareGeometry3D {args} {
    # DrawSquareGeometry2D
    # GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    # GiD_Layers edit opaque Fluid 0

    # GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate obj x -150 y -30 escape escape 
}
proc Buoyancy::examples::DrawSquareGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list 0 0 0 0 1 0 1 1 0 1 0 0]
    set fluidPoints [list ]
    foreach {x y z} $coordinates {
        lappend fluidPoints [GiD_Geometry create point append Fluid $x $y $z]
    }

    ## Lines ##
    set fluidLines [list ]
    set initial [lindex $fluidPoints 0]
    foreach point [lrange $fluidPoints 1 end] {
        lappend fluidLines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }
    lappend fluidLines [GiD_Geometry create line append stline Fluid $initial [lindex $fluidPoints 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$fluidLines escape escape

}

# Mesh sizes assign
proc Buoyancy::examples::AssignSquareGeometryMeshSizes2D {args} {
    set default_mesh_size 0.0125
    GiD_Process Mescape Meshing AssignSizes Surfaces $default_mesh_size 1 escape escape 
    GiD_Process Mescape Meshing AssignSizes Lines $default_mesh_size 1 2 3 4 escape escape
}

proc Buoyancy::examples::AssignSquareGeometryMeshSizes3D {args} {
    # To be implemented
}

# Group assign
proc Buoyancy::examples::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Left_Wall
    GiD_Groups edit color Left_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Left_Wall lines 1

    GiD_Groups create Top_Wall
    GiD_Groups edit color Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Top_Wall lines 2

    GiD_Groups create Right_Wall
    GiD_Groups edit color Right_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Right_Wall lines 3

    GiD_Groups create Bottom_Wall
    GiD_Groups edit color Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Bottom_Wall lines 4

    GiD_Groups create Pressure
    GiD_Groups edit color Pressure "#42eb71ff"
    GiD_EntitiesGroups assign Pressure point 1

}
proc Buoyancy::examples::AssignGroups3D {args} {
    # Create the groups
    # GiD_Groups create Fluid
    # GiD_Groups edit color Fluid "#26d1a8ff"
    # GiD_EntitiesGroups assign Fluid volumes 1

    # GiD_Groups create Inlet
    # GiD_Groups edit color Inlet "#e0210fff"
    # GiD_EntitiesGroups assign Inlet surfaces 5

    # GiD_Groups create Outlet
    # GiD_Groups edit color Outlet "#42eb71ff"
    # GiD_EntitiesGroups assign Outlet surfaces 3

    # GiD_Groups create No_Slip_Walls
    # GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
    # GiD_EntitiesGroups assign No_Slip_Walls surfaces {1 2 4 7}

    # GiD_Groups create No_Slip_Cylinder
    # GiD_Groups edit color No_Slip_Cylinder "#3b3b3bff"
    # GiD_EntitiesGroups assign No_Slip_Cylinder surfaces 6
}

# Tree assign
proc Buoyancy::examples::TreeAssignation3D {args} {
    # TreeAssignationCylinderInFlow2D
    # AddCuts
}
proc Buoyancy::examples::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    set fluidtype surface
    if {$nd eq "3D"} { set condtype surface; set fluidtype volume }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element QSVMS$nd ConstitutiveLaw Newtonian2DLaw DENSITY 1.2039 DYNAMIC_VISCOSITY 0.000587 CONDUCTIVITY 0.83052 SPECIFIC_HEAT 1004.84]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions [spdAux::getRoute "FLBC"]

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Pressure]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" Left_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" Top_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" Right_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" Bottom_Wall] setAttribute ov $condtype

    # Thermal Nodal Conditions (Initial condition)
    set thermalNodalConditions [spdAux::getRoute "CNVDFFNodalConditions"]
    set thermalnodcond "$thermalNodalConditions/condition\[@n='TEMPERATURE'\]"
    set thermalnodNode [customlib::AddConditionGroupOnXPath $thermalnodcond Fluid]
    $thermalnodNode setAttribute ov $fluidtype
    set props [list ByFunction Yes function_value "303.15-10*x"]
    spdAux::SetValuesOnBaseNode $thermalnodNode $props

    # Thermal Conditions (Boundary conditions)
    set thermalConditions [spdAux::getRoute "CNVDFFBC"]
    set thermalcond "$thermalConditions/condition\[@n='ImposedTemperature$nd'\]"
    set thermalNode [customlib::AddConditionGroupOnXPath $thermalcond Left_Wall]
    $thermalNode setAttribute ov $condtype
    set props [list value 303.15 Interval Total]
    spdAux::SetValuesOnBaseNode $thermalNode $props

    set thermalNode [customlib::AddConditionGroupOnXPath $thermalcond Right_Wall]
    $thermalNode setAttribute ov $condtype
    set props [list value 293.15 Interval Total]
    spdAux::SetValuesOnBaseNode $thermalNode $props

    # Time parameters
    set time_parameters [list EndTime 200 DeltaTime 0.5]
    set time_params_path [spdAux::getRoute "FLTimeParameters"]
    spdAux::SetValuesOnBasePath $time_params_path $time_parameters
    
    # Output
    set parameters [list OutputControlType step OutputDeltaStep 1]
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters
    
    # Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set params_path [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $params_path $parameters

    spdAux::RequestRefresh
}

proc Buoyancy::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}

proc Buoyancy::examples::AddCuts { } {
    # Cuts
    set results "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]"
    set cp [[customlib::GetBaseRoot] selectNodes "$results/container\[@n = 'CutPlanes'\]/blockdata\[@name = 'CutPlane'\]"] 
    [$cp selectNodes "./value\[@n = 'point'\]"] setAttribute v "0.0,0.5,0.0"
}