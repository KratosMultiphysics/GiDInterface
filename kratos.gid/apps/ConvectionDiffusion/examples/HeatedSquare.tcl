
proc ::ConvectionDiffusion::examples::HeatedSquare {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawSquareGeometry$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ConvectionDiffusion::examples::DrawSquareGeometry3D {args} {
    # DrawSquareGeometry2D
    # GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    # GiD_Layers edit opaque Fluid 0

    # GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate obj x -150 y -30 escape escape 
}

proc ConvectionDiffusion::examples::DrawSquareGeometry2D {args} {
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


# Group assign
proc ConvectionDiffusion::examples::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create Body
    GiD_Groups edit color Body "#26d1a8ff"
    GiD_EntitiesGroups assign Body surfaces 1

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

}
proc ConvectionDiffusion::examples::AssignGroups3D {args} {
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
proc ConvectionDiffusion::examples::TreeAssignation3D {args} {
    # TreeAssignationCylinderInFlow2D
    # AddCuts
}
proc ConvectionDiffusion::examples::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set cond_type line
    set body_type surface
    if {$nd eq "3D"} { set cond_type surface; set body_type volume }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "transient" CNVDFFSolStrat
    
    # Fluid Parts
    set parts [spdAux::getRoute "CNVDFFParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $parts Body]
    set props [list Element EulerianConvDiff$nd Material Gold DENSITY 19300.0 CONDUCTIVITY 310 SPECIFIC_HEAT 125.6]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    # Thermal Nodal Conditions
    set thermalNodalConditions [spdAux::getRoute "CNVDFFNodalConditions"]
    set thermalnodcond "$thermalNodalConditions/condition\[@n='TEMPERATURE'\]"
    GiD_Groups create "Body//Initial"
    GiD_Groups edit state "Body//Initial" hidden
    spdAux::AddIntervalGroup Body "Body//Initial"
    set thermalnodNode [customlib::AddConditionGroupOnXPath $thermalnodcond "Body//Initial"]
    $thermalnodNode setAttribute ov $body_type
    set props [list value 100]
    foreach {prop val} $props {
         set propnode [$thermalnodNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Temperature $prop"
        }
    }

    # Thermal Conditions
    set thermalConditions [spdAux::getRoute "CNVDFFBC"]
    set thermalcond "$thermalConditions/condition\[@n='ImposedTemperature$nd'\]"
    set thermalNode [customlib::AddConditionGroupOnXPath $thermalcond Left_Wall]
    $thermalNode setAttribute ov $cond_type
    set props [list value 303.15]
    foreach {prop val} $props {
         set propnode [$thermalNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property ImposedTemperature $prop"
        }
    }

    set thermalNode [customlib::AddConditionGroupOnXPath $thermalcond Right_Wall]
    $thermalNode setAttribute ov $cond_type
    set props [list value 293.15]
    foreach {prop val} $props {
         set propnode [$thermalNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property ImposedTemperature $prop"
        }
    }

    # Time parameters
    set time_parameters [list EndTime 100 DeltaTime 0.5]
    set time_params_path [spdAux::getRoute "CNVDFFTimeParameters"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }
    # Output
    set time_parameters [list OutputControlType step OutputDeltaStep 1]
    set time_params_path [spdAux::getRoute "Results"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }
    # Parallelism
    set time_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set time_params_path [spdAux::getRoute "Parallelization"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    spdAux::RequestRefresh
}


# proc ConvectionDiffusion::examples::AddCuts { } {
#     # Cuts
#     set results [spdAux::getRoute "Results"]
#     set cp [[customlib::GetBaseRoot] selectNodes "$results/container\[@n = 'CutPlanes'\]/blockdata\[@name = 'CutPlane'\]"] 
#     [$cp selectNodes "./value\[@n = 'point'\]"] setAttribute v "0.0,0.5,0.0"
# }