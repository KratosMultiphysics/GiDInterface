namespace eval ::Structural::examples::SolidContact {
    namespace path ::Structural::examples
    Kratos::AddNamespace [namespace current]

}

proc ::Structural::examples::SolidContact::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawGeometry$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    if {0} {
        AssignMeshSizes$::Model::SpatialDimension
        TreeAssignation$::Model::SpatialDimension
    }
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::Structural::examples::SolidContact::DrawGeometry2D {args} {
    GiD_Layers create Structure1
    GiD_Layers edit to_use Structure1
    GiD_Layers create Structure2
    GiD_Layers edit to_use Structure2

    # Geometry creation
    ## Points ##
    set coordinates1 [list 0 0 0 1 0 0 1 0.25 0 0 0.25 0]
    set structurePoints1 [list ]
    foreach {x y z} $coordinates1 {
        lappend structurePoints1 [GiD_Geometry create point append Structure1 $x $y $z]
    }

    set coordinates2 [list 0 0.255 0 1 0.255 0 1 0.505 0 0 0.505 0]
    set structurePoints2 [list ]
    foreach {x y z} $coordinates2 {
        lappend structurePoints2 [GiD_Geometry create point append Structure2 $x $y $z]
    }

    ## Lines ##
    # join points 1 2 3 4 in a line and 5 6 7 8 in another line
    set line1Points [lrange $structurePoints1 0 3]
    set prevpoint [lindex $line1Points 0]
    foreach point $line1Points {
        lappend structureLines1 [GiD_Geometry create line append stline Structure1 $prevpoint $point]
        set prevpoint $point
    }
    lappend structureLines1 [GiD_Geometry create line append stline Structure1 $prevpoint [lindex $line1Points 0]]

    set line2Points [lrange $structurePoints2 0 3]
    set prevpoint [lindex $line2Points 0]
    foreach point $line2Points {
        lappend structureLines2 [GiD_Geometry create line append stline Structure2 $prevpoint $point]
        set prevpoint $point
    }
    lappend structureLines2 [GiD_Geometry create line append stline Structure2 $prevpoint [lindex $line2Points 0]]

    ## Surface ##
    GiD_Layers edit to_use Structure1
    GiD_Process Mescape Geometry Create NurbsSurface {*}$structureLines1 escape escape
    GiD_Layers edit to_use Structure2
    GiD_Process Mescape Geometry Create NurbsSurface {*}$structureLines2 escape escape

}

proc ::Structural::examples::SolidContact::AssignGroups2D {args} {
    # Group creation
    GiD_Groups create Structure1
    GiD_Groups create Structure2
    ## Layers to groups
    
    GiD_EntitiesGroups assign Structure1 surfaces 1
    GiD_EntitiesGroups assign Structure2 surfaces 2

    # Displacement boundary conditions
    GiD_Groups create Ground
    GiD_EntitiesGroups assign Ground lines 2
    GiD_Groups create Top
    GiD_EntitiesGroups assign Top lines 9

    # Contact interface
    GiD_Groups create InterfaceStructure1
    GiD_EntitiesGroups assign InterfaceStructure1 lines 4
    GiD_Groups create InterfaceStructure2
    GiD_EntitiesGroups assign InterfaceStructure2 lines 7
    
}

proc ::Structural::examples::SolidContact::AssignMeshSizes2D {args} {
    set structure_mesh_size 5.0
    GiD_Process Mescape Meshing ElemType Quadrilateral [GiD_EntitiesGroups get Structure surfaces] escape
    GiD_Process Mescape Meshing Structured Surfaces Size {*}[GiD_EntitiesGroups get Structure surfaces] escape $structure_mesh_size {*}[GiD_EntitiesGroups get InterfaceStructure lines] escape escape escape escape
}


proc ::Structural::examples::SolidContact::TreeAssignation2D {args} {
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
    [$root selectNodes "[spdAux::getRoute STTimeParameters]/value\[@n = 'EndTime'\]"] setAttribute v 25.0
    [$root selectNodes "[spdAux::getRoute STTimeParameters]/container\[@n = 'TimeStep'\]/blockdata\[1\]/value\[@n = 'DeltaTime'\]"] setAttribute v 0.05
     
    spdAux::RequestRefresh
}
