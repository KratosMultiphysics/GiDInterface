
namespace eval ::FreeSurface::examples::Box2D {
    namespace path ::FreeSurface::examples
    Kratos::AddNamespace [namespace current]
}

proc ::FreeSurface::examples::Box2D::Init {args} {
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
}


# Draw Geometry
proc ::FreeSurface::examples::Box2D::DrawGeometry {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list {-3.91362 -3.3393 0} {-2.91362 -3.3393 0} {-2.91362 -3.1393 0} {-2.91362 -2.7393 0} {-2.71362 -2.7393 0} ]
    lappend coordinates {*}[list {-2.71362 -2.5393 0} {-3.91362 -2.5393 0} {-3.91362 -3.1393 0} {-4.11362 -3.1393 0} {-4.11362 -3.3393 0} ]
    set fluidPoints [list ]
    foreach point $coordinates {
        lassign $point x y z
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

    ## Points ##
    set coordinates [list {-3.91362 -3.5393 0} {-2.91362 -3.5393 0} ]
    set fluidPoints [list ]
    foreach point $coordinates {
        lassign $point x y z
        lappend fluidPoints [GiD_Geometry create point append Fluid $x $y $z]
    }

    ## Lines ##
    set fluidLines [list ]
    set initial 1
    foreach point [list {*}$fluidPoints 2] {
        lappend fluidLines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 1 {*}$fluidLines escape escape

    GiD_Process 'Zoom Frame
}

# Group assign
proc ::FreeSurface::examples::Box2D::AssignGroups {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces {1 2}

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet lines 9

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet lines {5 12}

    GiD_Groups create Slip_Walls
    GiD_Groups edit color Slip_Walls "#3b3b3bff"
    GiD_EntitiesGroups assign Slip_Walls lines {2 3 4 6 7 8 10 11 13}

    GiD_Groups create Surface_Bottom
    GiD_Groups edit color Surface_Bottom "#3b3b3bff"
    GiD_EntitiesGroups assign Surface_Bottom surfaces 2
}

proc ::FreeSurface::examples::Box2D::AssignMeshSizes {args} {

    set fluid_mesh_size 0.05
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $fluid_mesh_size 1:end escape escape escape
    ##Kratos::BeforeMeshGeneration $fluid_mesh_size
}

# Tree assign
proc ::FreeSurface::examples::Box2D::TreeAssignation {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]

    set fluidConditions [spdAux::getRoute "FLNodalConditions"]
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='DISTANCE'\]" Inlet] setAttribute ov line
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='DISTANCE'\]" Surface_Bottom] setAttribute ov surface
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='LIN_DARCY_COEF'\]" Surface_Bottom] setAttribute ov surface
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NONLIN_DARCY_COEF'\]" Surface_Bottom] setAttribute ov surface
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='POROSITY'\]" Surface_Bottom] setAttribute ov surface

    set fluidConditions [spdAux::getRoute "FLBC"]
    ::Fluid::examples::ErasePreviousIntervals

    # Fluid Inlet
    Fluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end End} true "1"

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Slip_Walls] setAttribute ov $condtype

    # Time Parameters
    set parameters [list EndTime 5 DeltaTime 0.1]
    set xpath [spdAux::getRoute "FLTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType time OutputDeltaTime 0.1]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters


}
