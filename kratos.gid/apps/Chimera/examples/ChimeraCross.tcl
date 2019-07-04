
proc ::Chimera::examples::ChimeraCross {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    Kratos::ResetModel

    DrawChimeraCrossGeometry$::Model::SpatialDimension
    # AssignGroupsChimeraCross$::Model::SpatialDimension
    # AssignChimeraCrossMeshSizes$::Model::SpatialDimension
    # TreeAssignationChimeraCross$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ::Chimera::examples::DrawChimeraCrossGeometry3D {args} {
    DrawChimeraCrossGeometry2D
    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    GiD_Layers edit opaque Background 0
    GiD_Layers edit opaque Patch 0

    GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate obj x -150 y -30 escape escape
}

proc ::Chimera::examples::DrawChimeraCrossGeometry2D {args} {
    # Background mesh geometry creation
    GiD_Layers create Background
    GiD_Layers edit to_use Background

    ## Points ##
    set back_coords [list 0.0 0.0 0.0 15.0 0.0 0.0 15.0 10.0 0.0 0.0 10.0 0.0]
    set back_points [list ]
    foreach {x y z} $back_coords {
        lappend back_points [GiD_Geometry create point append Background $x $y $z]
    }

    ## Lines ##
    set back_lines [list ]
    set initial [lindex $back_points 0]
    foreach point [lrange $back_points 1 end] {
        lappend back_lines [GiD_Geometry create line append stline Background $initial $point]
        set initial $point
    }
    lappend back_lines [GiD_Geometry create line append stline Background $initial [lindex $back_points 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$back_lines escape escape

    # Patch mesh geometry creation
    GiD_Layers create Patch
    GiD_Layers edit to_use Patch

    ## Points ##
    set patch_coords [list 3.849 2.7749 0.0 8.0104 2.7749 0.0 8.0104 6.8667 0.0 3.849 6.8667 0.0]
    set patch_points [list ]
    foreach {x y z} $patch_coords {
        lappend patch_points [GiD_Geometry create point append Patch $x $y $z]
    }

    ## Lines ##
    set patch_lines [list ]
    set initial [lindex $patch_points 0]
    foreach point [lrange $patch_points 1 end] {
        lappend patch_lines [GiD_Geometry create line append stline Patch $initial $point]
        set initial $point
    }
    lappend patch_lines [GiD_Geometry create line append stline Patch $initial [lindex $patch_points 0]]

    # Cross mesh geometry creation
    ## Points ##
    set cross_coords [list 5.0737 4.7791 0.0 5.7557 4.7791 0.0 5.7557 4.2084 0.0 5.9366 4.2084 0.0 5.9366 4.7791 0.0 6.7995 4.7791 0.0 6.7995 4.96 0.0 5.9366 4.96 0.0 5.9366 5.461 0.0 5.7557 5.461 0.0 5.7557 4.96 0.0 5.0737 4.96 0.0]
    set cross_points [list ]
    foreach {x y z} $cross_coords {
        lappend cross_points [GiD_Geometry create point append Patch $x $y $z]
    }

    ## Lines ##
    set initial [lindex $cross_points 0]
    foreach point [lrange $cross_points 1 end] {
        lappend patch_lines [GiD_Geometry create line append stline Patch $initial $point]
        set initial $point
    }
    lappend patch_lines [GiD_Geometry create line append stline Patch $initial [lindex $cross_points 0]]


    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$patch_lines escape escape
}

# Group assign
proc ::Chimera::examples::AssignGroupsChimeraCross2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet lines 4

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet lines 2

    GiD_Groups create No_Slip_Walls
    GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Walls lines {1 3}

    GiD_Groups create No_Slip_Cylinder
    GiD_Groups edit color No_Slip_Cylinder "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Cylinder lines 5
}
proc ::Chimera::examples::AssignGroupsChimeraCross3D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid volumes 1

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet surfaces 5

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet surfaces 3

    GiD_Groups create No_Slip_Walls
    GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Walls surfaces {1 2 4 7}

    GiD_Groups create No_Slip_Cylinder
    GiD_Groups edit color No_Slip_Cylinder "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Cylinder surfaces 6
}


# Mesh sizes
proc ::Chimera::examples::AssignChimeraCrossMeshSizes3D {args} {
    set cylinder_mesh_size 0.005
    set walls_mesh_size 0.05
    set fluid_mesh_size 0.05
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Walls surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Volumes $fluid_mesh_size [GiD_EntitiesGroups get Fluid volumes] escape escape
    Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}
proc ::Chimera::examples::AssignChimeraCrossMeshSizes2D {args} {
    set cylinder_mesh_size 0.005
    set fluid_mesh_size 0.05
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}


# Tree assign
proc ::Chimera::examples::TreeAssignationChimeraCross3D {args} {
    TreeAssignationChimeraCross2D
    AddCuts
}
proc ::Chimera::examples::TreeAssignationChimeraCross2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    # set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.0 DYNAMIC_VISCOSITY 0.002 YIELD_STRESS 0 POWER_LAW_K 1 POWER_LAW_N 1]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.0 DYNAMIC_VISCOSITY 0.002]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    set fluidConditions [spdAux::getRoute "FLBC"]
    ErasePreviousIntervals

    # Fluid Inlet
    ::Chimera::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 1} true "6*y*(1-y)*sin(pi*t*0.5)"
    ::Chimera::xml::CreateNewInlet Inlet {new true name inlet2 ini 1 end End} true "6*y*(1-y)"

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    foreach {prop val} $props {
         set propnode [$outletNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Outlet $prop"
        }
    }

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Walls] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Cylinder] setAttribute ov $condtype

    # Time parameters
    set time_parameters [list EndTime 45 DeltaTime 0.1]
    set time_params_path [spdAux::getRoute "FLTimeParameters"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }
    # Output
    set time_parameters [list OutputControlType step OutputDeltaStep 1]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    foreach {n v} $time_parameters {
        [$root selectNodes "$xpath/value\[@n = '$n'\]"] setAttribute v $v
    }
    # Parallelism
    set time_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set time_params_path [spdAux::getRoute "Parallelization"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    spdAux::RequestRefresh
}

proc ::Chimera::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}

proc ::Chimera::examples::AddCuts { } {
    # Cuts
    set results "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]"
    set cp [[customlib::GetBaseRoot] selectNodes "$results/container\[@n = 'CutPlanes'\]/blockdata\[@name = 'CutPlane'\]"]
    [$cp selectNodes "./value\[@n = 'point'\]"] setAttribute v "0.0,0.5,0.0"
}