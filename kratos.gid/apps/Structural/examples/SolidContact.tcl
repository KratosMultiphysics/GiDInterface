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
    
    AssignMeshSizes$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension
    
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
    lappend structureLines1 [GiD_Geometry create line append stline Structure1 1 2]
    lappend structureLines1 [GiD_Geometry create line append stline Structure1 2 3]
    lappend structureLines1 [GiD_Geometry create line append stline Structure1 3 4]
    lappend structureLines1 [GiD_Geometry create line append stline Structure1 4 1]

    lappend structureLines2 [GiD_Geometry create line append stline Structure2 5 6]
    lappend structureLines2 [GiD_Geometry create line append stline Structure2 6 7]
    lappend structureLines2 [GiD_Geometry create line append stline Structure2 7 8]
    lappend structureLines2 [GiD_Geometry create line append stline Structure2 8 5]


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
    GiD_EntitiesGroups assign Ground lines 1
    GiD_Groups create Top
    GiD_EntitiesGroups assign Top lines 7

    # Contact interface
    GiD_Groups create InterfaceStructure1
    GiD_EntitiesGroups assign InterfaceStructure1 lines 3
    GiD_Groups create InterfaceStructure2
    GiD_EntitiesGroups assign InterfaceStructure2 lines 5
    
}

proc ::Structural::examples::SolidContact::AssignMeshSizes2D {args} {
    GiD_Process Mescape Meshing ElemType Quadrilateral 1 escape
    GiD_Process Mescape Meshing ElemType Quadrilateral 2 escape
    

    GiD_MeshData structured surfaces 2 num_divisions 25 7
    GiD_MeshData structured surfaces 2 num_divisions 8 8
    GiD_MeshData structured surfaces 1 num_divisions 23 1
    GiD_MeshData structured surfaces 1 num_divisions 8 4
}

proc ::Structural::examples::SolidContact::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    # Structural
    gid_groups_conds::setAttributesF {container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Quasi-static}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure1]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStrain${nd}Law"
    set props [list Element SmallDisplacementElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 7850 YOUNG_MODULUS 206.9e9 POISSON_RATIO 0.29]
    spdAux::SetValuesOnBaseNode $structPartsNode $props
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure2]
    $structPartsNode setAttribute ov surface
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
    
    GiD_Groups clone Top Total
    GiD_Groups edit parent Total Top
    spdAux::AddIntervalGroup Top "Top//Total"
    GiD_Groups edit state "Top//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "Top//Total"]
    $structDisplacementNode setAttribute ov line
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByFunction function_component_Y "-5e-3*t" selector_component_Z Not Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    spdAux::AddIntervalGroup InterfaceStructure1 "InterfaceStructure1"
    set master_contact "container\[@n='Structural'\]/container\[@n='Boundary Conditions'\]/condition\[@n='CONTACT_SLAVE'\]"
    set master_node [customlib::AddConditionGroupOnXPath $master_contact "InterfaceStructure1"]
    $master_node setAttribute ov line
    set props [list pair 0]
    spdAux::SetValuesOnBaseNode $master_node $props
    
    GiD_Groups clone InterfaceStructure2 Total
    GiD_Groups edit parent Total InterfaceStructure2
    spdAux::AddIntervalGroup InterfaceStructure2 "InterfaceStructure2//Total"
    GiD_Groups edit state "InterfaceStructure2//Total" hidden
    set master_contact "container\[@n='Structural'\]/container\[@n='Boundary Conditions'\]/condition\[@n='CONTACT'\]"
    set master_node [customlib::AddConditionGroupOnXPath $master_contact "InterfaceStructure2//Total"]
    $master_node setAttribute ov line
    set props [list pair 0 Interval Total]
    spdAux::SetValuesOnBaseNode $master_node $props

    # Structure domain time parameters
    [$root selectNodes "[spdAux::getRoute STTimeParameters]/value\[@n = 'EndTime'\]"] setAttribute v 10
    [$root selectNodes "[spdAux::getRoute STTimeParameters]/container\[@n = 'TimeStep'\]/blockdata\[1\]/value\[@n = 'DeltaTime'\]"] setAttribute v 0.1

    # turn off results on nodes for Contact
    # [$root selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'CONTACT'\]"] setAttribute v No
    # [$root selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'CONTACT_SLAVE'\]"] setAttribute v No
    
    [$root selectNodes "[spdAux::getRoute GiDOptions]/value\[@n = 'GiDWriteConditionsFlag'\]"] setAttribute v WriteElementsOnly

    # disable VTK
    [$root selectNodes "[spdAux::getRoute VtkOutput]/value\[@n = 'EnableVtkOutput'\]"] setAttribute v No
     
    spdAux::RequestRefresh
}
