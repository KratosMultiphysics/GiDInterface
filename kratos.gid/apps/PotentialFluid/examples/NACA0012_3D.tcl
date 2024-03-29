namespace eval ::PotentialFluid::examples::NACA0012_3D {
    namespace path ::PotentialFluid::examples
    Kratos::AddNamespace [namespace current]
}

proc ::PotentialFluid::examples::NACA0012_3D::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry
    AssignGroups
    AssignMeshSizes
    TreeAssignation

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
    
}

# Draw Geometry
proc ::PotentialFluid::examples::NACA0012_3D::DrawGeometry {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Airfoil
    GiD_Process 'Rotate Angle 270 0
    GiD_Process Mescape Geometry Create NurbsLine 1.000000 0 0.000000 0.998459 0 0.000224 0.993844 0 0.000891 0.986185 0 0.001990 0.975528 0 0.003501 0.961940 0 0.005399 0.945503 0 0.007651 0.926320 0 0.010221 0.904508 0 0.013071 0.880203 0 0.016158 0.853553 0 0.019438 0.824724 0 0.022869 0.793893 0 0.026405 0.761249 0 0.030000 0.726995 0 0.033610 0.691342 0 0.037188 0.654508 0 0.040686 0.616723 0 0.044055 0.578217 0 0.047242 0.539230 0 0.050196 0.500000 0 0.052862 0.460770 0 0.055184 0.421783 0 0.057108 0.383277 0 0.058582 0.345492 0 0.059557 0.308658 0 0.059988 0.273005 0 0.059841 0.238751 0 0.059088 0.206107 0 0.057712 0.175276 0 0.055708 0.146447 0 0.053083 0.119797 0 0.049854 0.095492 0 0.046049 0.073680 0 0.041705 0.054497 0 0.036867 0.038060 0 0.031580 0.024472 0 0.025893 0.013815 0 0.019854 0.006156 0 0.013503 0.001541 0 0.006877 0.000000 0 0.000000 0.001541 0 -0.006877 0.006156 0 -0.013503 0.013815 0 -0.019854 0.024472 0 -0.025893 0.038060 0 -0.031580 0.054497 0 -0.036867 0.073680 0 -0.041705 0.095492 0 -0.046049 0.119797 0 -0.049854 0.146447 0 -0.053083 0.175276 0 -0.055708 0.206107 0 -0.057712 0.238751 0 -0.059088 0.273005 0 -0.059841 0.308658 0 -0.059988 0.345492 0 -0.059557 0.383277 0 -0.058582 0.421783 0 -0.057108 0.460770 0 -0.055184 0.500000 0 -0.052862 0.539230 0 -0.050196 0.578217 0 -0.047242 0.616723 0 -0.044055 0.654508 0 -0.040686 0.691342 0 -0.037188 0.726995 0 -0.033610 0.761249 0 -0.030000 0.793893 0 -0.026405 0.824724 0 -0.022869 0.853553 0 -0.019438 0.880203 0 -0.016158 0.904508 0 -0.013071 0.926320 0 -0.010221 0.945503 0 -0.007651 0.961940 0 -0.005399 0.975528 0 -0.003501 0.986185 0 -0.001990 0.993844 0 -0.000891 0.998459 0 -0.000224 Join 1 escape escape escape escape escape escape escape escape Escape
    #GiD_Process Mescape Geometry Create NurbsLine 1.000000 0 0.000000 1.5 0 0 1 0 0.1 0.5 0 0.1 Join 1 escape escape escape escape escape escape escape escape Escape
    GiD_Process Mescape Geometry Edit DivideLine Multiple NumDivisions 2 1 escape escape escape
    set AOA 5

    GiD_Process Mescape Utilities Move AllTypes Duplicate MaintainLayers Rotation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,1.0,0.0 $AOA points 1 2 lines 2 3 surfaces volumes dimensions escape Mescape

    ## Points ##
    set coordinates [list 50 0 25 -50 0 25 -50 0 -25 50 0 -25]
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
    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,10.0,0.0 1 escape Mescape
    GiD_Process 'Zoom Frame


}

# Group assign
proc ::PotentialFluid::examples::NACA0012_3D::AssignGroups {args} {
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid volumes 1

    GiD_Groups create FarField
    GiD_Groups edit color FarField "#e0210fff"
    GiD_EntitiesGroups assign FarField surfaces {1 4 5 6 7 8}

    GiD_Groups create Body
    GiD_Groups edit color Body "#42eb71ff"
    GiD_EntitiesGroups assign Body surfaces {2 3}

    GiD_Groups create BodyLines
    GiD_Groups edit color BodyLines "#42eb71ff"
    GiD_EntitiesGroups assign BodyLines lines {2 3 8 9 14 15}

    GiD_Groups create BodyPoints
    GiD_Groups edit color BodyPoints "#42eb71ff"
    GiD_EntitiesGroups assign BodyPoints points {1 2 7 8}

    GiD_Groups create Wake
    GiD_Groups edit color Wake "#e0210fff"
    GiD_EntitiesGroups assign Wake lines {14}

    GiD_Groups create WingTips
    GiD_Groups edit color WingTips "#e0210fff"
    GiD_EntitiesGroups assign WingTips points {1 7}
}

proc ::PotentialFluid::examples::NACA0012_3D::AssignMeshSizes {args} {
    #set fluid_mesh_size 2.0
    set wing_lines_mesh_size 0.1
    # set wing_points_mesh_size 0.1
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.3 escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $airfoil_mesh_size {*}[GiD_EntitiesGroups get UpperSurface lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $airfoil_mesh_size {*}[GiD_EntitiesGroups get LowerSurface lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $wing_lines_mesh_size {*}[GiD_EntitiesGroups get BodyLines lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Points $wing_points_mesh_size {*}[GiD_EntitiesGroups get Body points] escape escape
    # GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    #Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}

proc ::PotentialFluid::examples::NACA0012_3D::TreeAssignation {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element PotentialFlowElement$nd ConstitutiveLaw Inviscid DENSITY 1.225]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions [spdAux::getRoute "FLBC"]
    ErasePreviousIntervals

    # Far field
    set fluidFarField "$fluidConditions/condition\[@n='PotentialWallCondition$nd'\]"
    set farFieldNode [customlib::AddConditionGroupOnXPath $fluidFarField FarField]
    $farFieldNode setAttribute ov $condtype
    set props [list angle_of_attack 0.0 mach_infinity 0.03 speed_of_sound 340.0]
    spdAux::SetValuesOnBaseNode $farFieldNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Body$nd'\]" Body] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Wake$nd'\]" Wake] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Tip$nd'\]" WingTips] setAttribute ov $condtype

    # Parallelism
    set time_parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set time_params_path [spdAux::getRoute "Parallelization"]
    foreach {n v} $time_parameters {
        [$root selectNodes "$time_params_path/value\[@n = '$n'\]"] setAttribute v $v
    }

    spdAux::RequestRefresh
}