
proc ::ConjugateHeatTransfer::examples::CylinderCooling {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    DrawCylinderCoolingGeometry$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension
    AssignMeshSizes$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ConjugateHeatTransfer::examples::DrawCylinderCoolingGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers create Cylinder
    GiD_Layers edit to_use Fluid

    ## Fluid channel creation
    # Points
    set coordinates [list 0 0 0 5 0 0 5 2 0 0 2 0]
    set fluid_points [list ]
    foreach {x y z} $coordinates {
        lappend fluid_points [GiD_Geometry create point append Fluid $x $y $z]
    }

    # Lines
    set fluid_lines [list ]
    set initial [lindex $fluid_points 0]
    foreach point [lrange $fluid_points 1 end] {
        lappend fluid_lines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }
    lappend fluid_lines [GiD_Geometry create line append stline Fluid $initial [lindex $fluid_points 0]]

    # Square surface
    GiD_Process Mescape Geometry Create NurbsSurface {*}$fluid_lines escape escape

    # Fluid cylinder
    set circle_center_x 0.9375
    set circle_center_y 1.0
    set circle_center_z 0.0
    set center_radius 0.0625
    GiD_Process Mescape Geometry Create Object CirclePNR $circle_center_x $circle_center_y $circle_center_z 0.0 0.0 1.0 $center_radius escape
    GiD_Geometry delete surface 2

    # Create the fluid cylinder hole
    GiD_Layers edit to_use Fluid
    GiD_Process MEscape Geometry Edit HoleNurb 1 5 escape escape

    ## Solid creation
    # Cylinder creation
    GiD_Layers edit to_use Cylinder
    GiD_Process Mescape Geometry Create Object CirclePNR $circle_center_x $circle_center_y $circle_center_z 0.0 0.0 1.0 $center_radius escape
}

proc ConjugateHeatTransfer::examples::DrawCylinderCoolingGeometry3D {args} {
    # To be implemented
}

# Groups assign
proc ConjugateHeatTransfer::examples::AssignGroups2D {args} {
    # Create the groups for the fluid
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Fluid_Bottom_Wall
    GiD_Groups edit color Fluid_Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Bottom_Wall lines 1

    GiD_Groups create Fluid_Right_Wall
    GiD_Groups edit color Fluid_Right_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Right_Wall lines 2

    GiD_Groups create Fluid_Top_Wall
    GiD_Groups edit color Fluid_Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Top_Wall lines 3

    GiD_Groups create Fluid_Left_Wall
    GiD_Groups edit color Fluid_Left_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Left_Wall lines 4

    GiD_Groups create Fluid_Interface
    GiD_Groups edit color Fluid_Interface "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Interface lines 5

    # Create the groups for the cylinder
    GiD_Groups create Solid
    GiD_Groups edit color Solid "#d12f1f"
    GiD_EntitiesGroups assign Solid surfaces 2

    GiD_Groups create Solid_Interface
    GiD_Groups edit color Solid_Interface "#3b3b3bff"
    GiD_EntitiesGroups assign Solid_Interface lines 6
}

proc ConjugateHeatTransfer::examples::AssignGroups3D {args} {
    # To be implemented
}

# Tree assign
proc ConjugateHeatTransfer::examples::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set cond_type line
    set body_type surface
    if {$nd eq "3D"} { set cond_type surface; set body_type volume }

    ## Set thermal solution strategy to transient
    spdAux::SetValueOnTreeItem v "transient" CNVDFFSolStrat

    ## Fluid parts
    set parts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $parts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.0 DYNAMIC_VISCOSITY 0.00125 CONDUCTIVITY 0.625 SPECIFIC_HEAT 1000.0]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    ## Thermal parts
    set parts [spdAux::getRoute "CNVDFFParts"]
    set solid_node [customlib::AddConditionGroupOnXPath $parts Solid]
    set props [list Element EulerianConvDiff$nd Material Gold DENSITY 4.0 CONDUCTIVITY 2000.0 SPECIFIC_HEAT 250.0]
    foreach {prop val} $props {
        set propnode [$solid_node selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Solid $prop"
        }
    }

    ## Fluid CFD conditions
    set fluid_conditions [spdAux::getRoute "FLBC"]

    # Inlet
    Fluid::xml::CreateNewInlet Fluid_Left_Wall {new false name Total} true 1.0

    # Outlet
    set fluid_outlet "$fluid_conditions/condition\[@n='Outlet$nd'\]"
    set fluid_outlet_cond [customlib::AddConditionGroupOnXPath $fluid_outlet Fluid_Right_Wall]
    $fluid_outlet_cond setAttribute ov $cond_type

    # No-slip
    set fluid_noslip "$fluid_conditions/condition\[@n='NoSlip$nd'\]"
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Interface]
    $no_slip_cond setAttribute ov $cond_type

    # Slip
    set fluid_slip "$fluid_conditions/condition\[@n='Slip$nd'\]"
    set slip_cond [customlib::AddConditionGroupOnXPath $fluid_slip Fluid_Top_Wall]
    $slip_cond setAttribute ov $cond_type
    set slip_cond [customlib::AddConditionGroupOnXPath $fluid_slip Fluid_Bottom_Wall]
    $slip_cond setAttribute ov $cond_type

    ## Fluid thermal conditions
    set fluid_thermal_conditions [spdAux::getRoute "Buoyancy_CNVDFFBC"]

    # Set thermal interface
    set fluid_thermal_interface_cond "$fluid_thermal_conditions/condition\[@n='FluidThermalInterface$nd'\]"
    set fluid_thermal_interface [customlib::AddConditionGroupOnXPath $fluid_thermal_interface_cond Fluid_Interface]
    $fluid_thermal_interface setAttribute ov $cond_type

    # Fix left wall temperature
    set fluid_thermal_temperature_cond "$fluid_thermal_conditions/condition\[@n='ImposedTemperature$nd'\]"
    set fluid_thermal_imposed_temp_cond [customlib::AddConditionGroupOnXPath $fluid_thermal_temperature_cond Fluid_Left_Wall]
    $fluid_thermal_imposed_temp_cond setAttribute ov $cond_type
    set props [list constrained True Interval Total value 0.0]
    foreach {prop val} $props {
         set propnode [$fluid_thermal_imposed_temp_cond selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property ImposedTemperature $prop"
        }
    }

    # Fluid Boussinesq settings
    set fluid_boussinesq_settings_xpath [spdAux::getRoute "Buoyancy_Boussinesq"]
    set fluid_boussinesq_params [list gravity "0.0,0.0,0.0" ambient_temperature 273.15]
    foreach {field value} $fluid_boussinesq_params {
        [$root selectNodes "$fluid_boussinesq_settings_xpath/value\[@n = '$field'\]"] setAttribute v $value
    }

    ## Solid thermal conditions
    # Initial conditions
    set solid_initial_conditions [spdAux::getRoute "CNVDFFNodalConditions"]
    set solid_initial_temperature "$solid_initial_conditions/condition\[@n='TEMPERATURE'\]"
    GiD_Groups create "Solid//Initial"
    GiD_Groups edit state "Solid//Initial" hidden
    spdAux::AddIntervalGroup Solid "Solid//Initial"
    set solid_temperature_node [customlib::AddConditionGroupOnXPath $solid_initial_temperature "Solid//Initial"]
    $solid_temperature_node setAttribute ov $body_type
    set props [list value 1.0]
    foreach {prop val} $props {
         set propnode [$solid_temperature_node selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Solid Temperature $prop"
        }
    }

    # Set thermal interface
    set solid_thermal_conditions [spdAux::getRoute "CNVDFFBC"]
    set solid_thermal_interface_cond "$solid_thermal_conditions/condition\[@n='SolidThermalInterface$nd'\]"
    set solid_thermal_interface [customlib::AddConditionGroupOnXPath $solid_thermal_interface_cond Solid_Interface]
    $solid_thermal_interface setAttribute ov $cond_type

    # Time parameters
    set time_parameters [list EndTime 15.0 DeltaTime 0.1]
    set time_params_path [spdAux::getRoute "TimeParameters"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    # Output
    set time_parameters [list OutputControlType step OutputDeltaStep 1]
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
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

proc ConjugateHeatTransfer::examples::TreeAssignation3D {args} {
    # To be implemented
}

# Assign mesh settings and sizes
proc ConjugateHeatTransfer::examples::AssignMeshSizes2D {args} {
    # Assign centered structured triangular mesh in the solid cylinder
    GiD_Process Mescape Meshing ElemType Triangle 2 escape escape
    GiD_Process MEscape Meshing CenterStruct Assign 0.0 0.5 10 110 2 escape escape

    # Assign unstructured triangular mesh in the fluid domain
    GiD_Process Mescape Meshing ElemType Triangle 1 escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 0.05 1 3 4 2 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 0.05 1 escape escape

    # Set a structured mesh in both interfaces so they are conformant
    GiD_Process Mescape Meshing Structured Lines 120 5 escape escape
    GiD_Process Mescape Meshing Structured Lines 120 6 escape escape
}

proc ConjugateHeatTransfer::examples::AssignMeshSizes3D {args} {
    # To be implemented
}