
namespace eval ::Structural::examples::MeshCantileverTest::Wizard {
    namespace path ::Structural::examples::MeshCantileverTest
    Kratos::AddNamespace [namespace current]
    
    # Namespace variables declaration
    variable curr_win
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Init { } {
    #W "Carga los pasos"
    variable curr_win
    set curr_win ""
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Geometry { win } {
    variable curr_win
    set curr_win $win
    smart_wizard::AutoStep $curr_win Geometry
    smart_wizard::SetWindowSize 650 500
}

proc ::Structural::examples::MeshCantileverTest::Wizard::NextGeometry { } {
    
}

proc ::Structural::examples::MeshCantileverTest::Wizard::DrawGeometry {} {
    Kratos::ResetModel
    
    # Points 
    set points [list {0 0} {1 0} {1 5} {5.5 5} {12 5} {12 6} {1 6} {0 6} {0 5}]
    foreach point $points {
        set coords [split $point " "]
        set x [lindex $coords 0]
        set y [lindex $coords 1]
        GiD_Geometry create point append Layer0 $x $y 0
    }
    # Lines
    set lines [list {1 2} {2 3} {3 4} {4 5} {5 6} {6 7} {7 8} {8 9} {9 1} {7 3} {9 3}]
    foreach line $lines {
        set coords [split $line " "]
        set p1 [lindex $coords 0]
        set p2 [lindex $coords 1]
        GiD_Geometry create line append stline Layer0 $p1 $p2
    }
    # surfaces
    set surfaces [list {1 2 11 9} {7 8 11 10} {3 4 5 6 10}]
    foreach surface $surfaces {
        # GiD_Geometry -v2 create surface append nurbssurface Layer0 -interpolate $surface
        GiD_Process Mescape Geometry Create NurbsSurface {*}$surface escape escape
    }

    # Create the groups
    if {[GiD_Groups exists Structure]} {
        GiD_Groups delete Structure
    }
    GiD_Groups create concrete
    GiD_EntitiesGroups assign concrete surfaces {1 2}

    if {[GiD_Groups exists steel]} {
        GiD_Groups delete steel
    }
    GiD_Groups create steel
    GiD_EntitiesGroups assign steel surfaces 3
    


    # Update the groups window to show the created groups
    GidUtils::UpdateWindow GROUPS
    # Zoom frame to center the view
    GiD_Process 'Zoom Frame escape

}


proc ::Structural::examples::MeshCantileverTest::Wizard::ValidateDraw { } {
    return 0
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Material { win } {
    smart_wizard::AutoStep $win Material
    smart_wizard::SetWindowSize 300 450
}

proc ::Structural::examples::MeshCantileverTest::Wizard::CreatePartsMaterial { } {
    # Quitar parts existentes
    set parts [spdAux::getRoute "STParts"]
    gid_groups_conds::delete "${parts}/group"

    # Crear una part con los datos que toquen
    set gnode_concrete [customlib::AddConditionGroupOnXPath $parts/condition\[@n='Parts_Solid'\] "concrete"]
    set gnode_steel [customlib::AddConditionGroupOnXPath $parts/condition\[@n='Parts_Solid'\] "steel"]

    set parts [list concrete steel]
    set props [list ConstitutiveLaw DENSITY YOUNG_MODULUS POISSON_RATIO]
    foreach part $parts {
        foreach prop $props {
            set gnode_var_name gnode_$part
            set propnode [[set $gnode_var_name] selectNodes "./value\[@n = '$prop'\]"]
            if {$propnode ne "" } {
                $propnode setAttribute v [smart_wizard::GetProperty Material ${part}_${prop},value]
            }
        }
    }
    spdAux::RequestRefresh
}


proc ::Structural::examples::MeshCantileverTest::Wizard::Conditions { win } {
    smart_wizard::AutoStep $win Conditions
    smart_wizard::SetWindowSize 650 500
}

proc ::Structural::examples::MeshCantileverTest::Wizard::CreateBoundaryConditions { } {
    # Fix displacements

    # Point 8 fix in X and Y
    set fix_XY_group "fix_XY"
    if {[GiD_Groups exists $fix_XY_group]} {
        GiD_Groups delete $fix_XY_group
    }
    GiD_Groups create $fix_XY_group
    GiD_EntitiesGroups assign $fix_XY_group points 8
    GiD_Groups clone $fix_XY_group Total
    GiD_Groups edit parent Total $fix_XY_group
    spdAux::AddIntervalGroup $fix_XY_group "$fix_XY_group//Total"
    GiD_Groups edit state "$fix_XY_group//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "$fix_XY_group//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Point 1 fix in X
    set fix_X_group "fix_X"
    if {[GiD_Groups exists $fix_X_group]} {
        GiD_Groups delete $fix_X_group
    }
    GiD_Groups create $fix_X_group
    GiD_EntitiesGroups assign $fix_X_group points 1
    GiD_Groups clone $fix_X_group Total
    GiD_Groups edit parent Total $fix_X_group
    spdAux::AddIntervalGroup $fix_X_group "$fix_X_group//Total"
    GiD_Groups edit state "$fix_X_group//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "$fix_X_group//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y Not Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props
    
    # Point load
    # Point 4 load
    set point_load_group "point_load"
    if {[GiD_Groups exists $point_load_group]} {
        GiD_Groups delete $point_load_group
    }
    GiD_Groups create $point_load_group
    GiD_EntitiesGroups assign $point_load_group points 4
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='PointLoad2D'\]"
    GiD_Groups clone $point_load_group Total
    GiD_Groups edit parent Total $point_load_group
    spdAux::AddIntervalGroup $point_load_group "$point_load_group//Total"
    GiD_Groups edit state "$point_load_group//Total" hidden
    $structDisplacementNode setAttribute ov point
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "$point_load_group//Total"]
    set point_load_value [smart_wizard::GetProperty Conditions PointLoad,value]
    set props [list ByFunction No modulus $point_load_value value_direction_Y -1 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

    # Line load
    # line load on line 6
    set line_load_group "line_load"
    if {[GiD_Groups exists $line_load_group]} {
        GiD_Groups delete $line_load_group
    }
    GiD_Groups create $line_load_group
    GiD_EntitiesGroups assign $line_load_group lines 6
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='LineLoad2D'\]"
    GiD_Groups clone $line_load_group Total
    GiD_Groups edit parent Total $line_load_group
    spdAux::AddIntervalGroup $line_load_group "$line_load_group//Total"
    GiD_Groups edit state "$line_load_group//Total" hidden
    $structDisplacementNode setAttribute ov line
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "$line_load_group//Total"]
    set line_load_value [smart_wizard::GetProperty Conditions LineLoad,value]
    set props [list ByFunction No modulus $line_load_value value_direction_Y -1 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

    # Self weight on groups concrete and steel
    set selfweight_condition "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='SelfWeight2D'\]"
    GiD_Groups clone concrete Total
    GiD_Groups edit parent Total concrete
    spdAux::AddIntervalGroup concrete "concrete//Total"
    set selfweight_node [customlib::AddConditionGroupOnXPath $selfweight_condition "concrete//Total"]
    $selfweight_node setAttribute ov surface
    set props [list ByFunction No modulus 9.81 value_direction_Y -1 Interval Total]
    spdAux::SetValuesOnBaseNode $selfweight_node $props

    GiD_Groups clone steel Total
    GiD_Groups edit parent Total steel
    spdAux::AddIntervalGroup steel "steel//Total"
    set selfweight_node [customlib::AddConditionGroupOnXPath $selfweight_condition "steel//Total"]
    $selfweight_node setAttribute ov surface
    set props [list ByFunction No modulus 9.81 value_direction_Y -1 Interval Total]
    spdAux::SetValuesOnBaseNode $selfweight_node $props

}

proc ::Structural::examples::MeshCantileverTest::Wizard::Mesh { win } {
    variable curr_win
    set curr_win $win
    
    smart_wizard::AutoStep $win Mesh
    smart_wizard::SetWindowSize 650 500
}

proc ::Structural::examples::MeshCantileverTest::Wizard::UpdateMeshType { } {
    variable curr_win

    set mesh_type [smart_wizard::GetProperty Mesh MeshType,value]
    
    if {$mesh_type eq "Structured"} {
        smart_wizard::SetProperty Mesh ElementSize,state hidden
        smart_wizard::SetProperty Mesh HorizontalDivisions,state normal
        smart_wizard::SetProperty Mesh VerticalDivisions,state normal
    } else {
        smart_wizard::SetProperty Mesh ElementSize,state normal
        smart_wizard::SetProperty Mesh HorizontalDivisions,state hidden
        smart_wizard::SetProperty Mesh VerticalDivisions,state hidden
    }

    ::Structural::examples::MeshCantileverTest::Wizard::UpdateMeshImage

    smart_wizard::AutoStep $curr_win Mesh
}

proc ::Structural::examples::MeshCantileverTest::Wizard::UpdateElementType { } {
    variable curr_win

    ::Structural::examples::MeshCantileverTest::Wizard::UpdateMeshImage
    smart_wizard::AutoStep $curr_win Mesh
}

proc ::Structural::examples::MeshCantileverTest::Wizard::UpdateMeshImage { } {
    set mesh_type [smart_wizard::GetProperty Mesh MeshType,value]
    set element_type [smart_wizard::GetProperty Mesh ElementType,value]

    set image_name "MeshCantilever${mesh_type}${element_type}.png"

    smart_wizard::SetProperty Mesh ImageGeom,v $image_name
}

proc ::Structural::examples::MeshCantileverTest::Wizard::CreateMesh { } {
    GiD_MeshData reset
    
    set mesh_type [smart_wizard::GetProperty Mesh MeshType,value]
    set element_type [smart_wizard::GetProperty Mesh ElementType,value]

    if {$mesh_type eq "Structured"} {
        set horizontal_divisions [smart_wizard::GetProperty Mesh HorizontalDivisions,value]
        set vertical_divisions [smart_wizard::GetProperty Mesh VerticalDivisions,value]
        set element_type [smart_wizard::GetProperty Mesh ElementType,value]
    } else {
        set element_type [smart_wizard::GetProperty Mesh ElementType,value]
        set element_size [smart_wizard::GetProperty Mesh ElementSize,value]
    }
}

::Structural::examples::MeshCantileverTest::Wizard::Init

