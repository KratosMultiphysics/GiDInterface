
namespace eval ::Structural::examples::MeshCantileverTest::Wizard {
    namespace path ::Structural::examples::MeshCantileverTest
    Kratos::AddNamespace [namespace current]
    
    # Namespace variables declaration
    variable curr_win
    variable ogl_cuts
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Init { } {
    #W "Carga los pasos"
    variable curr_win
    set curr_win ""
    variable draw_cuts_name
    set draw_cuts_name StenosisWizard_cuts
    variable draw_render_name
    set draw_render_name StenosisWizard_render
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
    GiD_Groups create concrete
    GiD_Groups create steel
    GiD_EntitiesGroups assign concrete surfaces {1 2}
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
    if {[GiD_Groups exists fix_XY]} {
        GiD_Groups delete fix_XY
    }
    GiD_Groups create fix_XY
    GiD_EntitiesGroups assign fix_XY points 8
    GiD_Groups clone fix_XY Total
    GiD_Groups edit parent Total fix_XY
    spdAux::AddIntervalGroup fix_XY "fix_XY//Total"
    GiD_Groups edit state "fix_XY//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "fix_XY//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Point 1 fix in X
    if {[GiD_Groups exists fix_X]} {
        GiD_Groups delete fix_X
    }
    GiD_Groups create fix_X 
    GiD_EntitiesGroups assign fix_X points 1
    GiD_Groups clone fix_X Total
    GiD_Groups edit parent Total fix_X
    spdAux::AddIntervalGroup fix_X "fix_X//Total"
    GiD_Groups edit state "fix_X//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "fix_X//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y Not Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props
    
    # Point load
    # Point 4 load
    if {[GiD_Groups exists point_load]} {
        GiD_Groups delete point_load
    }
    GiD_Groups create point_load
    GiD_EntitiesGroups assign point_load points 4
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='PointLoad2D'\]"
    GiD_Groups clone point_load Total
    GiD_Groups edit parent Total point_load
    spdAux::AddIntervalGroup point_load "point_load//Total"
    GiD_Groups edit state "point_load//Total" hidden
    $structDisplacementNode setAttribute ov point
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "point_load//Total"]
    set point_load_value [smart_wizard::GetProperty Conditions PointLoad,value]
    set props [list ByFunction No modulus $point_load_value value_direction_Y -1 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

    # Line load
    # line load on line 6
    if {[GiD_Groups exists line_load]} {
        GiD_Groups delete line_load
    }
    GiD_Groups create line_load
    GiD_EntitiesGroups assign line_load lines 6
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='LineLoad2D'\]"
    GiD_Groups clone line_load Total
    GiD_Groups edit parent Total line_load
    spdAux::AddIntervalGroup line_load "line_load//Total"
    GiD_Groups edit state "line_load//Total" hidden
    $structDisplacementNode setAttribute ov line
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "line_load//Total"]
    set line_load_value [smart_wizard::GetProperty Conditions LineLoad,value]
    set props [list ByFunction No modulus $line_load_value value_direction_Y -1 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

}

::Structural::examples::MeshCantileverTest::Wizard::Init

