namespace eval ::Structural::examples::HighRiseBuilding {
    namespace path ::Structural::examples

}

proc ::Structural::examples::HighRiseBuilding::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawGeometry$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    AssignMeshSizes$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::Structural::examples::HighRiseBuilding::DrawGeometry2D {args} {
    GiD_Layers create Structure
    GiD_Layers edit to_use Structure

    # Geometry creation
    ## Points ##
    set coordinates [list -15 0 0 -15 190 0 15 190 0 15 0 0 ]
    set structurePoints [list ]
    foreach {x y z} $coordinates {
        lappend structurePoints [GiD_Geometry create point append Structure $x $y $z]
    }

    ## Lines ##
    set structureLines [list ]
    set initial [lindex $structurePoints 0]
    foreach point [lrange $structurePoints 1 end] {
        lappend structureLines [GiD_Geometry create line append stline Structure $initial $point]
        set initial $point
    }
    lappend structureLines [GiD_Geometry create line append stline Structure $initial [lindex $structurePoints 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$structureLines escape escape
}

proc ::Structural::examples::HighRiseBuilding::AssignGroups2D {args} {
    # Group creation
    GiD_Groups create Structure
    GiD_Groups create Ground
    GiD_Groups create InterfaceStructure
    
    GiD_EntitiesGroups assign Structure surfaces 1
    GiD_EntitiesGroups assign Ground lines 4
    GiD_EntitiesGroups assign InterfaceStructure lines {1 2 3}
}

proc ::Structural::examples::HighRiseBuilding::AssignMeshSizes2D {args} {
    set structure_mesh_size 5.0
    GiD_Process Mescape Meshing ElemType Quadrilateral [GiD_EntitiesGroups get Structure surfaces] escape
    GiD_Process Mescape Meshing Structured Surfaces Size {*}[GiD_EntitiesGroups get Structure surfaces] escape $structure_mesh_size {*}[GiD_EntitiesGroups get InterfaceStructure lines] escape escape escape escape
}


proc ::Structural::examples::HighRiseBuilding::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    # Structural
    gid_groups_conds::setAttributesF {container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStress2DLaw"
    set props [list Element TotalLagrangianElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 7850 YOUNG_MODULUS 206.9e9 POISSON_RATIO 0.29 THICKNESS 0.1]
    spdAux::SetValuesOnBaseNode $structPartsNode $props

    # Structural Displacement
    GiD_Groups clone Ground Total
    GiD_Groups edit parent Total Ground
    spdAux::AddIntervalGroup Ground "Ground//Total"
    GiD_Groups edit state "Ground//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "Ground//Total"]
    $structDisplacementNode setAttribute ov line
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue selector_component_Z Not Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Point load
    GiD_Groups clone InterfaceStructure Total
    GiD_Groups edit parent Total InterfaceStructure
    spdAux::AddIntervalGroup InterfaceStructure "InterfaceStructure//Total"
    GiD_Groups edit state "InterfaceStructure//Total" hidden
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='LineLoad$nd'\]"
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "InterfaceStructure//Total"]
    $LoadNode setAttribute ov line
    set props [list ByFunction No modulus 50 value_direction_X 1 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

    # Structure domain time parameters
    set parameters [list EndTime 25.0 DeltaTime 0.05]
    set xpath [spdAux::getRoute STTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
