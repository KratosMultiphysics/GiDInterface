
proc ::FluidDEM::examples::CylinderInFlow {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawCylinderInFlowGeometry$::Model::SpatialDimension
    AssignGroupsCylinderInFlow$::Model::SpatialDimension
    AssignCylinderInFlowMeshSizes$::Model::SpatialDimension
    TreeAssignationCylinderInFlow$::Model::SpatialDimension
    AssignToTree

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc FluidDEM::examples::DrawCylinderInFlowGeometry3D {args} {
    DrawCylinderInFlowGeometry2D
    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    GiD_Layers edit opaque Fluid 0


    ## Surface 8, volume 2 ##
    GiD_Process Mescape Geometry Create Object Circle 3 0.5 0.5 1.0 0.0 0.0 0.2 escape
    GiD_Process Mescape Geometry Create Object Sphere 3.5 0.5 0.5 0.1 escape escape

    GiD_Layers create "Spheres"
    GiD_Layers create "SpheresInlet"

    GiD_EntitiesLayers assign "SpheresInlet" -also_lower_entities surfaces 8
    GiD_EntitiesLayers assign "Spheres" -also_lower_entities volumes 2


    GiD_Process escape escape 'Render Flat escape
    GiD_Process 'Rotate Angle 0 0 'rotate scr y -45 'rotate scr x 45 escape
}
proc FluidDEM::examples::DrawCylinderInFlowGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list 0 1 0 5 1 0 5 0 0 0 0 0]
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

    # Body #
    GiD_Layers create Body
    GiD_Layers edit to_use Body
    set circle_center_x 1.25
    set circle_center_y 0.5
    set circle_center_z 0.0
    set center_radius 0.1
    GiD_Process Mescape Geometry Create Object CirclePNR $circle_center_x $circle_center_y $circle_center_z 0.0 0.0 1.0 $center_radius escape
    GiD_Geometry delete surface 2

    # Create the hole
    GiD_Layers edit to_use Fluid
    GiD_Process MEscape Geometry Edit HoleNurb 1 5 escape escape

}


# Group assign

proc FluidDEM::examples::AssignGroupsCylinderInFlow3D {args} {
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

    GiD_Groups create Spheres
    GiD_Groups edit color Spheres "#3b8b8bff"
    GiD_EntitiesGroups assign Spheres volumes 2

    GiD_Groups create SpheresInlet
    GiD_Groups edit color SpheresInlet "#12ff11ff"
    GiD_EntitiesGroups assign SpheresInlet surfaces 8

}

GiD_Process "-tcl- RaiseEvent_GenericProc ::GiD_Event_BeforeMeshGeneration 0.1" Mescape Meshing MeshCriteria Mesh Lines escape escape escape Mescape Meshing MeshCriteria Mesh Surfaces escape escape Mescape Meshing MeshCriteria Mesh Lines escape escape escape Mescape Meshing MeshCriteria Mesh Surfaces 5 escape escape Mescape Meshing MeshCriteria Mesh Lines escape escape escape Mescape Meshing MeshCriteria Mesh Surfaces 6 escape escape Mescape Meshing MeshCriteria Mesh Lines escape escape escape Mescape Meshing MeshCriteria Mesh Surfaces 1 2 4 7 escape escape Mescape Meshing MeshCriteria Mesh Lines escape escape escape Mescape Meshing MeshCriteria Mesh Surfaces 3 escape escape Mescape Meshing MeshCriteria Mesh Lines escape escape escape Mescape Meshing MeshCriteria Mesh Surfaces escape escape Mescape Meshing ElemType Sphere Volumes 2 escape escape Mescape Utilities SwapNormals Surfaces Select 1 5 4 3 2 Mescape Meshing ElemType Triangle {1 2 3 4 5 6 7} escape Mescape Meshing MeshCriteria Mesh Surfaces 1 2 3 4 5 6 7 escape Mescape Meshing Generate Yes 0.1 MeshingParametersFrom=Preferences escape

# Mesh sizes
proc FluidDEM::examples::AssignCylinderInFlowMeshSizes3D {args} {
    set cylinder_mesh_size 0.1
    set walls_mesh_size 0.1
    set fluid_mesh_size 0.1
    # Auto remesh when reloading the problem
    GiD_Process "::GiD_Event_BeforeMeshGeneration 0.1" Mescape
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Walls surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Volumes $fluid_mesh_size [GiD_EntitiesGroups get Fluid volumes] escape escape

    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get SpheresInlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Volumes 0.1 {*}[GiD_EntitiesGroups get Spheres volumes] escape escape

    # Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}



# Tree assign

proc FluidDEM::examples::TreeAssignationCylinderInFlow3D {args} {
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
    Fluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 1} true "6*y*(1-y)*sin(pi*t*0.5)"
    Fluid::xml::CreateNewInlet Inlet {new true name inlet2 ini 1 end End} true "6*y*(1-y)"

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list hydrostatic_outlet true]
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

proc ::FluidDEM::examples::AssignToTree { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e6 PARTICLE_MATERIAL 2 ]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEM-DefaultMaterial' \]"]
    foreach {prop val} $props {
        set propnode [$material_node selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Material $prop"
        }
    }

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Spheres]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    foreach {prop val} $props {
        set propnode [$DEMPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Parts $prop"
        }
    }

    # DEM FEM Walls
    set DEMConditions [spdAux::getRoute "DEMConditions"]
    set walls "$DEMConditions/condition\[@n='DEM-FEM-Wall'\]"
    set wallsNode [customlib::AddConditionGroupOnXPath $walls No_Slip_Walls]
    $wallsNode setAttribute ov surface
    set props [list ]
    foreach {prop val} $props {
        set propnode [$wallsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Outlet $prop"
        }
    }

    # Inlet
    set DEMInlet "$DEMConditions/condition\[@n='Inlet'\]"
    set inletNode [customlib::AddConditionGroupOnXPath $DEMInlet "SpheresInlet"]
    $inletNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial" NumberOfParticles 10000 ParticleDiameter 0.01 VelocityModulus 2 Interval "Total" DirectionVector "1.0,0.0,0.0"]
    foreach {prop val} $props {
        set propnode [$inletNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Inlet $prop"
        }
    }



    # General data
    # Time parameters
    set change_list [list EndTime 20 DeltaTime 1e-5 DEMDeltaTime 1e-6 NeighbourSearchFrequency 20]
    set xpath [spdAux::getRoute FDEMTimeParameters]
    foreach {name value} $change_list {
        set node [[customlib::GetBaseRoot] selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check SpheresDrop script"
        }
    }

    spdAux::RequestRefresh
}

proc FluidDEM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}

