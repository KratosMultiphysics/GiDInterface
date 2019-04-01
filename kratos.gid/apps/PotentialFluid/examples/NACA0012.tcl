
proc ::PotentialFluid::examples::NACA0012 {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawNACA0012Geometry$::Model::SpatialDimension
    AssignGroupsNACA0012$::Model::SpatialDimension
    AssignNACA0012MeshSizes$::Model::SpatialDimension
    TreeAssignationNACA0012$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc PotentialFluid::examples::DrawNACA0012Geometry3D {args} {
    # To be implemented
}

proc PotentialFluid::examples::DrawNACA0012Geometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Airfoil
    GiD_Process Mescape Geometry Create NurbsLine 1.000000 0.000000 0 0.998459 0.000224 0 0.993844 0.000891 0 0.986185 0.001990 0 0.975528 0.003501 0 0.961940 0.005399 0 0.945503 0.007651 0 0.926320 0.010221 0 0.904508 0.013071 0 0.880203 0.016158 0 0.853553 0.019438 0 0.824724 0.022869 0 0.793893 0.026405 0 0.761249 0.030000 0 0.726995 0.033610 0 0.691342 0.037188 0 0.654508 0.040686 0 0.616723 0.044055 0 0.578217 0.047242 0 0.539230 0.050196 0 0.500000 0.052862 0 0.460770 0.055184 0 0.421783 0.057108 0 0.383277 0.058582 0 0.345492 0.059557 0 0.308658 0.059988 0 0.273005 0.059841 0 0.238751 0.059088 0 0.206107 0.057712 0 0.175276 0.055708 0 0.146447 0.053083 0 0.119797 0.049854 0 0.095492 0.046049 0 0.073680 0.041705 0 0.054497 0.036867 0 0.038060 0.031580 0 0.024472 0.025893 0 0.013815 0.019854 0 0.006156 0.013503 0 0.001541 0.006877 0 0.000000 0.000000 0 0.001541 -0.006877 0 0.006156 -0.013503 0 0.013815 -0.019854 0 0.024472 -0.025893 0 0.038060 -0.031580 0 0.054497 -0.036867 0 0.073680 -0.041705 0 0.095492 -0.046049 0 0.119797 -0.049854 0 0.146447 -0.053083 0 0.175276 -0.055708 0 0.206107 -0.057712 0 0.238751 -0.059088 0 0.273005 -0.059841 0 0.308658 -0.059988 0 0.345492 -0.059557 0 0.383277 -0.058582 0 0.421783 -0.057108 0 0.460770 -0.055184 0 0.500000 -0.052862 0 0.539230 -0.050196 0 0.578217 -0.047242 0 0.616723 -0.044055 0 0.654508 -0.040686 0 0.691342 -0.037188 0 0.726995 -0.033610 0 0.761249 -0.030000 0 0.793893 -0.026405 0 0.824724 -0.022869 0 0.853553 -0.019438 0 0.880203 -0.016158 0 0.904508 -0.013071 0 0.926320 -0.010221 0 0.945503 -0.007651 0 0.961940 -0.005399 0 0.975528 -0.003501 0 0.986185 -0.001990 0 0.993844 -0.000891 0 0.998459 -0.000224 0 Join 1 escape escape escape escape escape escape escape escape Escape
    GiD_Process Mescape Geometry Edit DivideLine Multiple NumDivisions 2 1 escape escape escape

    ## Points ##
    set coordinates [list 50 25 0 -50 25 0 -50 -25 0 50 -25 0]
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

    ## Surface
    # Lines 2,3 (airfoil) and 4,5,6,7 (far field)
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 5 6 7 escape escape
}


# Group assign
proc PotentialFluid::examples::AssignGroupsNACA00122D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create FarField
    GiD_Groups edit color FarField "#e0210fff"
    GiD_EntitiesGroups assign FarField lines 4
    GiD_EntitiesGroups assign FarField lines 5
    GiD_EntitiesGroups assign FarField lines 6
    GiD_EntitiesGroups assign FarField lines 7

    # GiD_Groups create UpperSurface
    # GiD_Groups edit color UpperSurface "#42eb71ff"
    # GiD_EntitiesGroups assign UpperSurface lines 2

    # GiD_Groups create LowerSurface
    # GiD_Groups edit color LowerSurface "#42eb71ff"
    # GiD_EntitiesGroups assign LowerSurface lines 3

    GiD_Groups create Body
    GiD_Groups edit color Body "#42eb71ff"
    GiD_EntitiesGroups assign Body lines {2 3}
}

proc PotentialFluid::examples::AssignGroupsNACA00123D {args} {
    # To be implemented
}

# Mesh sizes
proc PotentialFluid::examples::AssignNACA0012MeshSizes3D {args} {
    # To be implemented
}

proc PotentialFluid::examples::AssignNACA0012MeshSizes2D {args} {
    set fluid_mesh_size 2.0
    set airfoil_mesh_size 0.01
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.3 escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $airfoil_mesh_size {*}[GiD_EntitiesGroups get UpperSurface lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $airfoil_mesh_size {*}[GiD_EntitiesGroups get LowerSurface lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $airfoil_mesh_size {*}[GiD_EntitiesGroups get Body lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    Kratos::BeforeMeshGeneration $fluid_mesh_size
}

# Tree assign
proc PotentialFluid::examples::TreeAssignationNACA00123D {args} {
    TreeAssignationNACA00122D
    AddCuts
}

proc PotentialFluid::examples::TreeAssignationNACA00122D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element PotentialFlowElement$nd ConstitutiveLaw Inviscid DENSITY 1.225]
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

    # Far field
    set fluidFarField "$fluidConditions/condition\[@n='PotentialWallCondition$nd'\]"
    set farFieldNode [customlib::AddConditionGroupOnXPath $fluidFarField FarField]
    $farFieldNode setAttribute ov $condtype
    set props [list inlet_phi 1.0 velocity_infinityX 10.0 velocity_infinityY 0.0 velocity_infinityZ 0.0]
    foreach {prop val} $props {
         set propnode [$farFieldNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find far field property $prop"
        }
    }

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Body$nd'\]" Body] setAttribute ov $condtype

    # Parallelism
    set time_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set time_params_path [spdAux::getRoute "Parallelization"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    spdAux::RequestRefresh
}

proc PotentialFluid::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}

proc PotentialFluid::examples::AddCuts { } {
    # Cuts
    set results [spdAux::getRoute "FLResults"]
    set cp [[customlib::GetBaseRoot] selectNodes "$results/container\[@n = 'CutPlanes'\]/blockdata\[@name = 'CutPlane'\]"]
    [$cp selectNodes "./value\[@n = 'point'\]"] setAttribute v "0.0,0.5,0.0"
}