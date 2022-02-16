
namespace eval ::Chimera::examples::ChimeraCross {
    namespace path ::Chimera::examples
    Kratos::AddNamespace [namespace current]
}

proc ::Chimera::examples::ChimeraCross::Init {args} {
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

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::Chimera::examples::ChimeraCross::DrawGeometry {args} {
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
proc ::Chimera::examples::ChimeraCross::AssignGroups {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces {1 2}

    GiD_Groups create Background
    GiD_Groups edit color Background "#26d1a8ff"
    GiD_EntitiesGroups assign Background surfaces 1

    GiD_Groups create Patch
    GiD_Groups edit color Patch "#26d1a8ff"
    GiD_EntitiesGroups assign Patch surfaces 2

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet lines 4

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet lines 2

    GiD_Groups create No_Slip_Walls
    GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Walls lines {1 3}

    GiD_Groups create No_Slip_Cross
    GiD_Groups edit color No_Slip_Cross "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Cross lines {9 10 11 12 13 14 15 16 17 18 19 20}
}

# Mesh sizes
proc ::Chimera::examples::ChimeraCross::AssignMeshSizes {args} {
    set cross_mesh_size 0.05
    set surface_mesh_size 0.2
    GiD_Process Mescape Meshing AssignSizes Lines $cross_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cross lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $surface_mesh_size 5 7 8 6 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $surface_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    Kratos::Event_BeforeMeshGeneration $surface_mesh_size
}

# Tree assign
proc ::Chimera::examples::ChimeraCross::TreeAssignation {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1000.0 DYNAMIC_VISCOSITY 0.001]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    # Chimera Patches
    set chimeraPatches [spdAux::getRoute "ChimParts"]
    set chimeraNode [customlib::AddConditionGroupOnXPath $chimeraPatches Patch]
    set chimera_patch_props [list overlap_distance 0.7]
    foreach {prop val} $chimera_patch_props {
        set propnode [$chimeraNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne ""} {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Chimera patches $prop"
        }
    }

    # Set conditions
    set fluidConditions [spdAux::getRoute "FLBC"]
    ErasePreviousIntervals

    # Fluid Inlet
    ::Fluid::xml::CreateNewInlet Inlet {new false name Total ini 0 end 1} true 1.0

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
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Cross] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='ChimeraInternalBoundary$nd'\]" No_Slip_Cross] setAttribute ov $condtype

    # Time parameters
    set time_parameters [list EndTime 1.0 DeltaTime 0.01]
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
