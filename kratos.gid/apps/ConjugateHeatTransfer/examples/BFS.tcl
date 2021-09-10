namespace eval ::ConjugateHeatTransfer::examples::BFS {
    namespace path ::ConjugateHeatTransfer::examples

}

proc ::ConjugateHeatTransfer::examples::BFS::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ::ConjugateHeatTransfer::examples::BFS::DrawGeometry3D {args} {
    # DrawSquareGeometry2D
    # GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    # GiD_Layers edit opaque Fluid 0

    # GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate objaxes x -150 y -30 escape escape
}

proc ::ConjugateHeatTransfer::examples::BFS::DrawGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers create HeatSource
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list 30 0 0 30 1 0 0 1 0 0 0.5 0 0 0 0]
    set fluid_points [list ]
    foreach {x y z} $coordinates {
        lappend fluid_points [GiD_Geometry create point append Fluid $x $y $z]
    }

    set coordinates [list 30 -2.0 0 30 0 0 0 0 0 0 -2.0 0]
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
proc ::ConjugateHeatTransfer::examples::BFS::AssignGroups2D {args} {
    # Create the groups for the fluid
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Fluid_Right_Wall
    GiD_Groups edit color Fluid_Right_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Right_Wall lines 1

    GiD_Groups create Fluid_Top_Wall
    GiD_Groups edit color Fluid_Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Top_Wall lines 2

    GiD_Groups create Fluid_Left_Top_Wall
    GiD_Groups edit color Fluid_Left_Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Left_Top_Wall lines 3

    GiD_Groups create Fluid_Left_Bottom_Wall
    GiD_Groups edit color Fluid_Left_Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Left_Bottom_Wall lines 4

    GiD_Groups create Fluid_Bottom_Wall
    GiD_Groups edit color Fluid_Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Bottom_Wall lines 5

    GiD_Groups create Fluid_Outlet_Point
    GiD_Groups edit color Fluid_Outlet_Point "#3b3b3bff"
    GiD_EntitiesGroups assign Fluid_Outlet_Point points 1

    # Create the groups for the heating structure
    GiD_Groups create Heating
    GiD_Groups edit color Heating "#d12f1f"
    GiD_EntitiesGroups assign Heating surfaces 2

    GiD_Groups create Heating_Right_Wall
    GiD_Groups edit color Heating_Right_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Heating_Right_Wall lines 6

    GiD_Groups create Heating_Top_Wall
    GiD_Groups edit color Heating_Top_Wall "#c508cf"
    GiD_EntitiesGroups assign Heating_Top_Wall lines 7

    GiD_Groups create Heating_Left_Wall
    GiD_Groups edit color Heating_Left_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Heating_Left_Wall lines 8

    GiD_Groups create Heating_Bottom_Wall
    GiD_Groups edit color Heating_Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Heating_Bottom_Wall lines 9
}
proc ::ConjugateHeatTransfer::examples::BFS::AssignGroups3D {args} {
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
proc ::ConjugateHeatTransfer::examples::BFS::TreeAssignation3D {args} {
    # TreeAssignationCylinderInFlow2D
    # AddCuts
}
proc ::ConjugateHeatTransfer::examples::BFS::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set cond_type line
    set body_type surface
    if {$nd eq "3D"} { set cond_type surface; set body_type volume }

    # Solution strategy set only transient
    spdAux::SetValueOnTreeItem v "transient" CNVDFFSolStrat

    # Fluid parts
    set parts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $parts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian2DLaw DENSITY 1.0 DYNAMIC_VISCOSITY 0.001875 CONDUCTIVITY 1.0 SPECIFIC_HEAT 0.002640845]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    # Fluid boundary conditions
    set fluid_conditions [spdAux::getRoute "FLBC"]
    set fluid_outlet "$fluid_conditions/condition\[@n='Outlet$nd'\]"
    set fluid_outlet_cond [customlib::AddConditionGroupOnXPath $fluid_outlet Fluid_Right_Wall]
    $fluid_outlet_cond setAttribute ov $cond_type
    set fluid_noslip "$fluid_conditions/condition\[@n='NoSlip$nd'\]"
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Top_Wall]
    $no_slip_cond setAttribute ov $cond_type
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Bottom_Wall]
    $no_slip_cond setAttribute ov $cond_type
    set no_slip_cond [customlib::AddConditionGroupOnXPath $fluid_noslip Fluid_Left_Bottom_Wall]
    $no_slip_cond setAttribute ov $cond_type

    # Fluid inlet
    Fluid::xml::CreateNewInlet Fluid_Left_Top_Wall {new false name Total} true "-24*(y**2)+36*y-12"

    # Fluid thermal boundary condition
    set fluid_thermal_boundary_conditions_xpath [spdAux::getRoute "Buoyancy_CNVDFFBC"]
    set fluid_imposed_temperature "$fluid_thermal_boundary_conditions_xpath/condition\[@n='ImposedTemperature$nd'\]"
    set fluid_thermal_node [customlib::AddConditionGroupOnXPath $fluid_imposed_temperature Fluid_Left_Top_Wall]
    $fluid_thermal_node setAttribute ov $cond_type
    set props [list constrained True Interval Total value 273.15]
    spdAux::SetValuesOnBaseNode $fluid_thermal_node $props

    # Fluid thermal interface
    set fluid_thermal_interface_path "$fluid_thermal_boundary_conditions_xpath/condition\[@n='FluidThermalInterface$nd'\]"
    set fluid_interface [customlib::AddConditionGroupOnXPath $fluid_thermal_interface_path Fluid_Bottom_Wall]
    $fluid_interface setAttribute ov $cond_type

    # Fluid thermal initial condition
    set fluid_thermal_initial_conditions_xpath [spdAux::getRoute "Buoyancy_CNVDFFNodalConditions"]
    set thermic_fluid_temperature "$fluid_thermal_initial_conditions_xpath/condition\[@n='TEMPERATURE'\]"
    GiD_Groups create "Fluid//Initial"
    GiD_Groups edit state "Fluid//Initial" hidden
    spdAux::AddIntervalGroup Fluid "Fluid//Initial"
    set thermic_fluid_temperature_node [customlib::AddConditionGroupOnXPath $thermic_fluid_temperature "Fluid//Initial"]
    $thermic_fluid_temperature_node setAttribute ov $body_type
    set props [list Interval Initial value 273.15]
    spdAux::SetValuesOnBaseNode $thermic_fluid_temperature_node $props

    # Fluid Boussinesq settings
    set fluid_boussinesq_settings_xpath [spdAux::getRoute "Buoyancy_Boussinesq"]
    set fluid_boussinesq_params [list gravity "0.0,0.0,0.0" ambient_temperature 273.15]
    spdAux::SetValuesOnBasePath $fluid_boussinesq_settings_xpath $fluid_boussinesq_params

    # Solid parts
    set parts [spdAux::getRoute "CNVDFFParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $parts Heating]
    set props [list Element EulerianConvDiff$nd DENSITY 0.0 CONDUCTIVITY 10 SPECIFIC_HEAT 0.0]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    # Solid thermal initial conditions
    set thermalNodalConditions [spdAux::getRoute "CNVDFFNodalConditions"]
    set thermalnodcond "$thermalNodalConditions/condition\[@n='TEMPERATURE'\]"
    GiD_Groups create "Heating//Initial"
    GiD_Groups edit state "Heating//Initial" hidden
    spdAux::AddIntervalGroup Heating "Heating//Initial"
    set thermalnodNode [customlib::AddConditionGroupOnXPath $thermalnodcond "Heating//Initial"]
    $thermalnodNode setAttribute ov $body_type
    set props [list Interval Initial value 273.15]
    spdAux::SetValuesOnBaseNode $thermalnodNode $props

    # Solid thermal boundary conditions
    set thermalConditions [spdAux::getRoute "CNVDFFBC"]
    set thermalcond "$thermalConditions/condition\[@n='ImposedTemperature$nd'\]"
    set thermalNode [customlib::AddConditionGroupOnXPath $thermalcond Heating_Bottom_Wall]
    $thermalNode setAttribute ov $cond_type
    set props [list constrained True value 274.15 Interval Total]
    spdAux::SetValuesOnBaseNode $thermalNode $props

    set thermalcond "$thermalConditions/condition\[@n='SolidThermalInterface$nd'\]"
    set thermal_interface [customlib::AddConditionGroupOnXPath $thermalcond Heating_Top_Wall]
    $thermal_interface setAttribute ov $cond_type

    # Time parameters
    set time_parameters [list EndTime 500 DeltaTime 2.5]
    set time_params_path [spdAux::getRoute "TimeParameters"]
    spdAux::SetValuesOnBasePath $time_params_path $time_parameters

    # Output
    set parameters [list OutputControlType step OutputDeltaStep 1]
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Parallelism
    set parallelism_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set parallelism_params_path [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $parallelism_params_path $parallelism_parameters

    # Coupling settings
    set coupling_settings [list max_iteration 25 temperature_relative_tolerance 1e-6]
    set coupling_settings_path [spdAux::getRoute "CHTGeneralParameters"]
    spdAux::SetValuesOnBasePath $coupling_settings_path $coupling_settings

    spdAux::RequestRefresh
}