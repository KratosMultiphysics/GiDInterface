
proc ::ConjugateHeatTransfer::examples::HeatedSquare {args} {
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
proc ConjugateHeatTransfer::examples::DrawSquareGeometry3D {args} {
    # DrawSquareGeometry2D
    # GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    # GiD_Layers edit opaque Fluid 0

    # GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate obj x -150 y -30 escape escape
}

proc ConjugateHeatTransfer::examples::DrawSquareGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers create HeatSource
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list 0 0 0 0 1 0 1 1 0 1 0 0]
    set fluid_points [list ]
    foreach {x y z} $coordinates {
        lappend fluid_points [GiD_Geometry create point append Fluid $x $y $z]
    }

    set coordinates [list 1 1 0 2 1 0 2 0 0 1 0 0]
    set convection_points [list ]
    foreach {x y z} $coordinates {
        lappend convection_points [GiD_Geometry create point append HeatSource $x $y $z]
    }

    ## Lines ##
    set fluid_lines [list ]
    set initial [lindex $fluid_points 0]
    foreach point [lrange $fluid_points 1 end] {
        lappend fluid_lines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }
    lappend fluid_lines [GiD_Geometry create line append stline Fluid $initial [lindex $fluid_points 0]]

    set convection_lines [list ]
    set initial [lindex $convection_points 0]
    foreach point [lrange $convection_points 1 end] {
        lappend convection_lines [GiD_Geometry create line append stline HeatSource $initial $point]
        set initial $point
    }
    lappend convection_lines [GiD_Geometry create line append stline HeatSource $initial [lindex $convection_points 0]]

    ## Surface ##
    GiD_Layers edit to_use Fluid
    GiD_Process Mescape Geometry Create NurbsSurface {*}$fluid_lines escape escape
    GiD_Layers edit to_use HeatSource
    GiD_Process Mescape Geometry Create NurbsSurface {*}$convection_lines escape escape

}


# Group assign
proc ConjugateHeatTransfer::examples::AssignGroups2D {args} {
    # Create the groups for the fluid
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Fluid_Left_Wall
    GiD_Groups edit color Fluid_Left_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Left_Wall lines 1

    GiD_Groups create Fluid_Top_Wall
    GiD_Groups edit color Fluid_Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Top_Wall lines 2

    GiD_Groups create Fluid_Right_Wall
    GiD_Groups edit color Fluid_Right_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Right_Wall lines 3

    GiD_Groups create Fluid_Bottom_Wall
    GiD_Groups edit color Fluid_Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Bottom_Wall lines 4

    GiD_Groups create Fluid_Bottom_Left_Corner
    GiD_Groups edit color Fluid_Bottom_Left_Corner "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Bottom_Left_Corner points 1

    # Create the groups for the heating structure
    GiD_Groups create Heating
    GiD_Groups edit color Heating "#d12f1f"
    GiD_EntitiesGroups assign Heating surfaces 2

    GiD_Groups create Heating_Top_Wall
    GiD_Groups edit color Heating_Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Heating_Top_Wall lines 5

    GiD_Groups create Heating_Right_Wall
    GiD_Groups edit color Heating_Right_Wall "#c508cf"
    GiD_EntitiesGroups assign Heating_Right_Wall lines 6

    GiD_Groups create Heating_Bottom_Wall
    GiD_Groups edit color Heating_Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Heating_Bottom_Wall lines 7

    GiD_Groups create Heating_Left_Wall
    GiD_Groups edit color Heating_Left_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Heating_Left_Wall lines 8
}
proc ConjugateHeatTransfer::examples::AssignGroups3D {args} {
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
proc ConjugateHeatTransfer::examples::TreeAssignation3D {args} {
    # TreeAssignationCylinderInFlow2D
    # AddCuts
}
proc ConjugateHeatTransfer::examples::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set cond_type line
    set body_type surface
    if {$nd eq "3D"} { set cond_type surface; set body_type volume }

    # Solution strategy set only transient
    spdAux::SetValueOnTreeItem v "transient" CNVDFFSolStrat
    spdAux::SetValueOnTreeItem v "ExternalSolversApplication.SuperLUSolver" CNVDFFtransientlinear_solver_settings Solver

    # Fluid Parts
    set parts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $parts Fluid]
    set props [list Element Monolithic$nd Material Water ConstitutiveLaw Newtonian]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    # Fluid conditions
    set fluid_conditions [spdAux::getRoute "FLBC"]
    set fluid_noslip "$fluid_conditions/condition\[@n='NoSlip$nd'\]"
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Left_Wall]
    $no_slip_cond setAttribute ov $cond_type
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Top_Wall]
    $no_slip_cond setAttribute ov $cond_type
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Right_Wall]
    $no_slip_cond setAttribute ov $cond_type
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Bottom_Wall]
    $no_slip_cond setAttribute ov $cond_type
    set outletNode [customlib::AddConditionGroupOnXPath "$fluid_conditions/condition\[@n='Outlet$nd'\]" Fluid_Bottom_Left_Corner]
    $outletNode setAttribute ov Point
    set props [list value 9800.0]
    foreach {prop val} $props {
         set propnode [$outletNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Outlet $prop"
        }
    }


    # Fluid thermic initial condition
    set thermic_fluid_BC_xpath [spdAux::getRoute "Buoyancy_CNVDFFNodalConditions"]
    set thermic_fluid_temperature "$thermic_fluid_BC_xpath/condition\[@n='TEMPERATURE'\]"
    GiD_Groups create "Fluid//Initial"
    GiD_Groups edit state "Fluid//Initial" hidden
    spdAux::AddIntervalGroup Fluid "Fluid//Initial"
    set thermic_fluid_temperature_node [customlib::AddConditionGroupOnXPath $thermic_fluid_temperature "Fluid//Initial"]
    $thermic_fluid_temperature_node setAttribute ov $body_type
    set props [list value 100]
    foreach {prop val} $props {
         set propnode [$thermic_fluid_temperature_node selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Fluid Temperature $prop"
        }
    }
    set thermic_fluid_BC_xpath [spdAux::getRoute "Buoyancy_CNVDFFBC"]
    set thermic_fluid_interface_path "$thermic_fluid_BC_xpath/condition\[@n='FluidThermalInterface$nd'\]"
    set thermic_fluid_interface [customlib::AddConditionGroupOnXPath $thermic_fluid_interface_path Fluid_Right_Wall]
    $thermic_fluid_interface setAttribute ov $cond_type

    # Thermal Parts
    set parts [spdAux::getRoute "CNVDFFParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $parts Heating]
    set props [list Element EulerianConvDiff$nd Material Gold DENSITY 19300.0 CONDUCTIVITY 310 SPECIFIC_HEAT 125.6]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Heating $prop"
        }
    }

    # Thermal Nodal Conditions
    set thermalNodalConditions [spdAux::getRoute "CNVDFFNodalConditions"]
    set thermalnodcond "$thermalNodalConditions/condition\[@n='TEMPERATURE'\]"
    GiD_Groups create "Heating//Initial"
    GiD_Groups edit state "Heating//Initial" hidden
    spdAux::AddIntervalGroup Heating "Heating//Initial"
    set thermalnodNode [customlib::AddConditionGroupOnXPath $thermalnodcond "Heating//Initial"]
    $thermalnodNode setAttribute ov $body_type
    set props [list ByFunction Yes function_value "193*x - 93"]
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
    set thermalNode [customlib::AddConditionGroupOnXPath $thermalcond Heating_Right_Wall]
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

    set thermalcond "$thermalConditions/condition\[@n='SolidThermalInterface$nd'\]"
    set thermal_interface [customlib::AddConditionGroupOnXPath $thermalcond Heating_Left_Wall]
    $thermal_interface setAttribute ov $cond_type

    # Time parameters
    set time_parameters [list EndTime 100 DeltaTime 0.5]
    set time_params_path [spdAux::getRoute "TimeParameters"]
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


# proc ConjugateHeatTransfer::examples::AddCuts { } {
#     # Cuts
#     set results [spdAux::getRoute "Results"]
#     set cp [[customlib::GetBaseRoot] selectNodes "$results/container\[@n = 'CutPlanes'\]/blockdata\[@name = 'CutPlane'\]"]
#     [$cp selectNodes "./value\[@n = 'point'\]"] setAttribute v "0.0,0.5,0.0"
# }