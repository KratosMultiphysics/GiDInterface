
proc ::Fluid::examples::HighRiseBuilding {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawHighRiseBuildingGeometry$::Model::SpatialDimension
    AssignGroupsHighRiseBuilding$::Model::SpatialDimension
    AssignHighRiseBuildingMeshSizes$::Model::SpatialDimension
    TreeAssignationHighRiseBuilding$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc Fluid::examples::DrawHighRiseBuildingGeometry3D {args} {
    # To be implemented
}

proc Fluid::examples::DrawHighRiseBuildingGeometry2D {args} {
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list -600 0 0 -15 0 0 -15 190 0 15 190 0 15 0 0 1200 0 0 1200 600 0 -600 600 0]
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
proc Fluid::examples::AssignGroupsHighRiseBuilding2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet lines 8

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet lines 6

    GiD_Groups create Top_Wall
    GiD_Groups edit color Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Top_Wall lines 7

    GiD_Groups create Bottom_Wall
    GiD_Groups edit color Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Bottom_Wall lines {1 5}

    GiD_Groups create InterfaceFluid
    GiD_Groups edit color InterfaceFluid "#3b3b3bff"
    GiD_EntitiesGroups assign InterfaceFluid lines {2 3 4}
}
proc Fluid::examples::AssignGroupsHighRiseBuilding3D {args} {
    # To be implemented
}


# Mesh sizes
proc Fluid::examples::AssignHighRiseBuildingMeshSizes3D {args} {
    # To be implemented
}

proc Fluid::examples::AssignHighRiseBuildingMeshSizes2D {args} {
    set fluid_mesh_size 30.0
    set walls_mesh_size 30.0
    set building_mesh_size 3.0
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Top_Wall lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Bottom_Wall lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $building_mesh_size {*}[GiD_EntitiesGroups get InterfaceFluid lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    Kratos::BeforeMeshGeneration $fluid_mesh_size
}


# Tree assign
proc Fluid::examples::TreeAssignationHighRiseBuilding3D {args} {
    # To be implemented
}

proc Fluid::examples::TreeAssignationHighRiseBuilding2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian Material Air]
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
    Fluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 10.0} true "25.0*t/10.0"
    Fluid::xml::CreateNewInlet Inlet {new true name inlet2 ini 10.0 end End} false 25.0

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
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Top_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Bottom_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" InterfaceFluid] setAttribute ov $condtype

    # Time parameters
    set time_parameters [list EndTime 40.0 DeltaTime 0.05]
    set time_params_path [spdAux::getRoute "FLTimeParameters"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    # Output
    set time_parameters [list OutputControlType time OutputDeltaTime 1.0]
    set time_params_path [spdAux::getRoute "FLResults"]
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

proc Fluid::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}