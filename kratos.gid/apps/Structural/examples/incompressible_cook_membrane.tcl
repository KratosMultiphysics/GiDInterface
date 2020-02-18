
proc ::Structural::examples::IncompressibleCookMembrane {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawIncompressibleCookMembraneGeometry$::Model::SpatialDimension
    AssignGroupsIncompressibleCookMembrane$::Model::SpatialDimension
    AssignIncompressibleCookMembraneMeshSizes$::Model::SpatialDimension
    TreeAssignationIncompressibleCookMembrane$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    set nd $::Model::SpatialDimension
    if {$nd eq "3D"} {
         GiD_Process 'Rotate Angle 270 90 'Rotate ScrAxes y -45 'Rotate ScrAxes x 45 escape
    }
    GiD_Process 'Zoom Frame
}

proc Structural::examples::DrawIncompressibleCookMembraneGeometry2D {args} {
    GiD_Layers create Structure
    GiD_Layers edit to_use Structure

    # Geometry creation
    ## Points ##
    set coordinates [list 0 0 0 48 44 0 48 60 0 0 44 0 ]
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

proc Structural::examples::DrawIncompressibleCookMembraneGeometry3D {args} {
    # Create layers and draw in plane geometry
    DrawIncompressibleCookMembraneGeometry2D

    # Extrude the xy-plane geometry
    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape Mescape
}

proc Structural::examples::AssignGroupsIncompressibleCookMembrane2D {args} {
    # Group creation
    GiD_Groups create Structure
    GiD_Groups create LeftEdge
    GiD_Groups create RightEdge

    GiD_EntitiesGroups assign Structure surfaces 1
    GiD_EntitiesGroups assign LeftEdge lines 4
    GiD_EntitiesGroups assign RightEdge lines 2
}

proc Structural::examples::AssignGroupsIncompressibleCookMembrane3D {args} {
    # Group creation
    GiD_Groups create Structure
    GiD_Groups create LeftSurface
    GiD_Groups create RightSurface
    GiD_Groups create SideSurfaces

    GiD_EntitiesGroups assign Structure volumes 1
    GiD_EntitiesGroups assign LeftSurface surfaces 5
    GiD_EntitiesGroups assign RightSurface surfaces 3
    GiD_EntitiesGroups assign SideSurfaces surfaces {1 6}
}

proc Structural::examples::AssignIncompressibleCookMembraneMeshSizes2D {args} {
    set edges_divisions 64
    GiD_Process Mescape Meshing Structured Surfaces 1 escape $edges_divisions 1 2 3 4 escape escape escape Mescape Meshing ElemType Quadrilateral 1 escape
}

proc Structural::examples::AssignIncompressibleCookMembraneMeshSizes3D {args} {
    set side_edges_divisions 64
    set thickness_edges_divisions 1
    GiD_Process Mescape Meshing ElemType Hexahedra 1 escape Mescape Meshing Structured Volumes 1 escape $side_edges_divisions 1 3 5 7 2 6 escape $thickness_edges_divisions 11 escape escape escape escape escape escape
}

proc Structural::examples::TreeAssignationIncompressibleCookMembrane2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    # Structural
    gid_groups_conds::setAttributesF {container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Static}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStrain2DLaw"
    set props [list Element SmallDisplacementMixedVolumetricStrainElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 0.0 YOUNG_MODULUS 200.0 POISSON_RATIO 0.4995]
    foreach {prop val} $props {
         set propnode [$structPartsNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    GiD_Groups clone LeftEdge Total
    GiD_Groups edit parent Total LeftEdge
    spdAux::AddIntervalGroup LeftEdge "LeftEdge//Total"
    GiD_Groups edit state "LeftEdge//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "LeftEdge//Total"]
    $structDisplacementNode setAttribute ov line
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue selector_component_Z Not Interval Total]
    #set props [list constrained Yes ByFunction No value 0.0]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Line load
    GiD_Groups clone RightEdge Total
    GiD_Groups edit parent Total RightEdge
    spdAux::AddIntervalGroup RightEdge "RightEdge//Total"
    GiD_Groups edit state "RightEdge//Total" hidden
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='LineLoad$nd'\]"
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "RightEdge//Total"]
    $LoadNode setAttribute ov line
    set props [list ByFunction No modulus 0.00625 value_direction_Y 1 Interval Total]
    foreach {prop val} $props {
         set propnode [$LoadNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    spdAux::RequestRefresh
}

proc Structural::examples::TreeAssignationIncompressibleCookMembrane3D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    # Structural
    gid_groups_conds::setAttributesF {container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Static}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov volume
    set constLawNameStruc "LinearElastic3DLaw"
    set props [list Element SmallDisplacementMixedVolumetricStrainElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 0.0 YOUNG_MODULUS 200.0 POISSON_RATIO 0.4995]
    foreach {prop val} $props {
         set propnode [$structPartsNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    GiD_Groups clone LeftSurface Total
    GiD_Groups edit parent Total LeftSurface
    spdAux::AddIntervalGroup LeftSurface "LeftSurface//Total"
    GiD_Groups edit state "LeftSurface//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "LeftSurface//Total"]
    $structDisplacementNode setAttribute ov surface
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    #set props [list constrained Yes ByFunction No value 0.0]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    GiD_Groups clone SideSurfaces Total
    GiD_Groups edit parent Total SideSurfaces
    spdAux::AddIntervalGroup SideSurfaces "SideSurfaces//Total"
    GiD_Groups edit state "SideSurfaces//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "SideSurfaces//Total"]
    $structDisplacementNode setAttribute ov surface
    set props [list selector_component_X Not selector_component_Y Not selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    #set props [list constrained Yes ByFunction No value 0.0]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Surface load
    GiD_Groups clone RightSurface Total
    GiD_Groups edit parent Total RightSurface
    spdAux::AddIntervalGroup RightSurface "RightSurface//Total"
    GiD_Groups edit state "RightSurface//Total" hidden
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='SurfaceLoad$nd'\]"
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "RightSurface//Total"]
    $LoadNode setAttribute ov surface
    set props [list ByFunction No modulus 0.00625 value_direction_Y 1 Interval Total]
    foreach {prop val} $props {
         set propnode [$LoadNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    spdAux::RequestRefresh
}
