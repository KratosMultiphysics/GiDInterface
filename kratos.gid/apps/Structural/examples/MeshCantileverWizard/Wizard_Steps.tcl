
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
    ::Structural::examples::MeshCantileverTest::Wizard::FluidTypeChange
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

proc ::Structural::examples::MeshCantileverTest::Wizard::FluidTypeChange { } {
    variable curr_win

    set type [ smart_wizard::GetProperty Material ConstitutiveLaw,value]
    if {[GiDVersionCmp 14.1.3d] >= 0} {
        switch $type {
            "Newtonian" {
                smart_wizard::SetProperty Material YIELD_STRESS,state hidden
                smart_wizard::SetProperty Material POWER_LAW_K,state hidden
                smart_wizard::SetProperty Material POWER_LAW_N,state hidden
            }
            "HerschelBulkley" {
                smart_wizard::SetProperty Material YIELD_STRESS,state normal
                smart_wizard::SetProperty Material POWER_LAW_K,state normal
                smart_wizard::SetProperty Material POWER_LAW_N,state normal
            }
        }
        smart_wizard::AutoStep $curr_win Material
    }
    
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Fluid { win } {
    smart_wizard::AutoStep $win Fluid
    smart_wizard::SetWindowSize 450 450
}
proc ::Structural::examples::MeshCantileverTest::Wizard::NextFluid { } {
    # Inlet
    Fluid::xml::ClearInlets true
    Fluid::xml::CreateNewInlet Inlet {new false name Total} false [smart_wizard::GetProperty Fluid Inlet,value]

    # Outlet
    gid_groups_conds::delete {container[@n='Fluid']/container[@n='BoundaryConditions']/condition[@n='Outlet3D']/group}
    set where {container[@n='Fluid']/container[@n='BoundaryConditions']/condition[@n='Outlet3D']}
    set gnode [customlib::AddConditionGroupOnXPath $where "Outlet"]
    set propnode [$gnode selectNodes "./value\[@n = 'value'\]"]
    $propnode setAttribute v [smart_wizard::GetProperty Fluid Outlet,value]
    
    gid_groups_conds::delete {container[@n='Fluid']/container[@n='BoundaryConditions']/condition[@n='NoSlip3D']/group}
    set where {container[@n='Fluid']/container[@n='BoundaryConditions']/condition[@n='NoSlip3D']}
    set gnode [customlib::AddConditionGroupOnXPath $where "NoSlip"]
    spdAux::RequestRefresh
}


proc ::Structural::examples::MeshCantileverTest::Wizard::Simulation { win } {
    smart_wizard::AutoStep $win Simulation
    smart_wizard::SetWindowSize 450 600
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Mesh { } {
    LastStep
    ::Structural::examples::MeshCantileverTest::Wizard::UnregisterDrawCuts
    if {[lindex [GiD_Info Mesh] 0]>0} {
        #GiD_Process Mescape Meshing reset Yes
        GiD_Process Mescape Meshing CancelMesh PreserveFrozen Yes
    }
    
    set mesh [smart_wizard::GetProperty Simulation MeshSize,value]
    set meshinner [smart_wizard::GetProperty Simulation CentralMesh,value]
    GiD_Process Mescape Meshing AssignSizes Surfaces $meshinner 6 9 escape escape
    #  GiD_Process Mescape Meshing Generate $mesh MeshingParametersFrom=Preferences Mescape Meshing MeshView
    MeshGenerationOKDo $mesh
}
proc ::Structural::examples::MeshCantileverTest::Wizard::Save { } {
    LastStep
    GiD_Process Mescape Files Save 
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Run { } {
  # set root [customlib::GetBaseRoot]
  # set solstrat_un [apps::getCurrentUniqueName SolStrat]
  # #W $solstrat_un
  # if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] v] eq ""} {
  #     get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] dict
  # }
  # set solstrat_un [apps::getCurrentUniqueName Scheme]
  # #W $solstrat_un
  # if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] v] eq ""} {
  #     get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] dict
  # }
    LastStep
    GiD_Process Mescape Utilities Calculate
}

proc ::Structural::examples::MeshCantileverTest::Wizard::LastStep { } {
    set initial [smart_wizard::GetProperty Simulation InitialTime,value]
    set end [smart_wizard::GetProperty Simulation EndTime,value]
    set delta [smart_wizard::GetProperty Simulation DeltaTime,value]
    
    gid_groups_conds::setAttributesF {container[@n='Fluid']/container[@n='SolutionStrat']/container[@n='TimeParameters']/value[@n='StartTime']} "v $initial"
    gid_groups_conds::setAttributesF {container[@n='Fluid']/container[@n='SolutionStrat']/container[@n='TimeParameters']/value[@n='EndTime']} "v $end"
    gid_groups_conds::setAttributesF {container[@n='Fluid']/container[@n='SolutionStrat']/container[@n='TimeParameters']/value[@n='DeltaTime']} "v $delta"
    

    PlaceCutPlanes
    
    #gid_groups_conds::setAttributesF {container[@n='Fluid']/container[@n='SolutionStrat']/container[@n='velocity_linear_solver_settings']/value[@n='Solver']} {v Conjugate_gradient}
    #gid_groups_conds::setAttributesF {container[@n='Fluid']/container[@n='SolutionStrat']/container[@n='pressure_linear_solver_settings']/value[@n='Solver']} {v Conjugate_gradient}
    spdAux::RequestRefresh
    
}

proc ::Structural::examples::MeshCantileverTest::Wizard::PlaceCutPlanes { } {
    set ncuts [smart_wizard::GetProperty Simulation Cuts,value]
    set length [smart_wizard::GetProperty Geometry Length,value]
    set delta [expr double($length)/(double($ncuts)+1.0)]
    set orig_x [ expr $length*-0.5]
    
    set angle [smart_wizard::GetProperty Simulation Bending,value]

    # Cut planes    
    set cuts_enabled 1
    if {$cuts_enabled} {
        spdAux::ClearCutPlanes
        set cutplane_xp "[spdAux::getRoute CutPlanes]/blockdata\[1\]"
        
        for {set i 1} {$i <= $ncuts} {incr i} {
            set x [expr $orig_x + ($i * $delta)]
            set x [expr double(round(100*$x))/100]
            gid_groups_conds::copyNode $cutplane_xp [spdAux::getRoute CutPlanes]
            set cutplane "[spdAux::getRoute CutPlanes]/blockdata\[@n='CutPlane'\]\[[expr $i +1]\]"
            gid_groups_conds::setAttributesF $cutplane "name CutPlane$i"

            set coords [list [objarray new doublearray -values [list $x $x $x]] [objarray new doublearray -values {0.0 1.0 0.0}] [objarray new doublearray -values {0.0 0.0 1.0}]]           
            set new_nodes [::Structural::examples::MeshCantileverTest::Wizard::BendNodes $orig_x $length [expr $angle/2] $coords]
            set o [list [objarray get [lindex $new_nodes 0] 0] [objarray get [lindex $new_nodes 1] 0] [objarray get [lindex $new_nodes 2] 0] ]
            set p1 [list [objarray get [lindex $new_nodes 0] 1] [objarray get [lindex $new_nodes 1] 1] [objarray get [lindex $new_nodes 2] 1] ]
            set p2 [list [objarray get [lindex $new_nodes 0] 2] [objarray get [lindex $new_nodes 1] 2] [objarray get [lindex $new_nodes 2] 2] ]
            set v1 [math::linearalgebra::sub $p1 $o]
            set v2 [math::linearalgebra::sub $p2 $o]
            set v_norm [::math::linearalgebra::crossproduct $v1 $v2]
            gid_groups_conds::setAttributesF "$cutplane/value\[@n='normal'\]" "v [join $v_norm {,}]"
            gid_groups_conds::setAttributesF "$cutplane/value\[@n='point'\]" "v [join $o {,}]"
        }
        
        set x 0.0
        set coords [list [objarray new doublearray -values [list $x [expr $x +1] $x]] [objarray new doublearray -values {0.0 0.0 0.0}] [objarray new doublearray -values {0.0 0.0 1.0}]]           
        set new_nodes [::Structural::examples::MeshCantileverTest::Wizard::BendNodes $orig_x $length [expr $angle/2] $coords]
        set o [list [objarray get [lindex $new_nodes 0] 0] [objarray get [lindex $new_nodes 1] 0] [objarray get [lindex $new_nodes 2] 0] ]
       
        set p1 [list [objarray get [lindex $new_nodes 0] 1] [objarray get [lindex $new_nodes 1] 1] [objarray get [lindex $new_nodes 2] 1] ]
        set p2 [list [objarray get [lindex $new_nodes 0] 2] [objarray get [lindex $new_nodes 1] 2] [objarray get [lindex $new_nodes 2] 2] ]
        set v1 [math::linearalgebra::sub $p1 $o]
        set v2 [math::linearalgebra::sub $p2 $o]
        set v_norm [::math::linearalgebra::crossproduct $v1 $v2]
        gid_groups_conds::copyNode $cutplane_xp [spdAux::getRoute CutPlanes]
        set cutplane "[spdAux::getRoute CutPlanes]/blockdata\[@n='CutPlane'\]\[[expr $ncuts +2]\]"
        gid_groups_conds::setAttributesF $cutplane "name CutPlane[expr $ncuts +1]"
        gid_groups_conds::setAttributesF "$cutplane/value\[@n='normal'\]" "v [join $v_norm {,}]"
        gid_groups_conds::setAttributesF "$cutplane/value\[@n='point'\]" "v [join $o {,}]"
    }
    
}

proc Structural::AfterMeshGeneration { fail } {

    GidUtils::CloseWindow MESHPROGRESS
    GiD_Process Mescape Mescape Mescape
    GiD_Process Mescape Files Save 
    ::Structural::examples::MeshCantileverTest::Wizard::PostMeshBend
    GiD_Process Mescape Files Save 
}


proc ::Structural::examples::MeshCantileverTest::Wizard::PostMeshBend { } {

    set length [ smart_wizard::GetProperty Geometry Length,value]
    set orig_x [ expr $length*-0.5]
    set angle [ smart_wizard::GetProperty Simulation Bending,value]
    set angle [expr $angle/2]
    GidUtils::DisableGraphics
    ::Structural::examples::MeshCantileverTest::Wizard::Bend $orig_x $length $angle
    GidUtils::EnableGraphics
    GiD_Process Mescape Meshing MeshView escape 
    GiD_Process 'Redraw 
}

proc ::Structural::examples::MeshCantileverTest::Wizard::Bend { orig_x len angle} {

    lassign [GiD_Info Mesh nodes -array] ids coords
    set moved_nodes [::Structural::examples::MeshCantileverTest::Wizard::BendNodes $orig_x $len $angle $coords]
    lassign $moved_nodes coord_x coord_y coord_z
    set size [objarray length $coord_x]
    for {set i 0} {$i < $size} {incr i} {
        set res_x [objarray get $coord_x $i]
        set res_y [objarray get $coord_y $i]
        set res_z [objarray get $coord_z $i]
        GiD_Mesh edit node [objarray get $ids $i] [list $res_x $res_y $res_z]
    }
}

proc ::Structural::examples::MeshCantileverTest::Wizard::BendNodes {orig_x len angle coords} {
    lassign $coords coord_x coord_y coord_z
    set size [objarray length $coord_x]
    set result_x [objarray new doublearray $size 0.0]
    set result_y [objarray new doublearray $size 0.0]
    set result_z [objarray new doublearray $size 0.0]
    
    for {set i 0} {$i < $size} {incr i} {
        # primera parte 
        set old_val_x [objarray get $coord_x $i]
        set old_val_y [objarray get $coord_y $i]
        set old_val_z [objarray get $coord_z $i]
        set dist_x [expr $old_val_x - $orig_x]
        set ang [expr $angle*$dist_x/$len]
        set ang [expr {double(round(10000*$ang))/10000}]
        set res_x [expr $old_val_x + sin($ang) * $old_val_y]
        set res_y [expr cos($ang) *$old_val_y]
        set res_z $old_val_z
       
        # segunda parte
        set ang2 [expr $angle*($old_val_x - $orig_x)/$len]
        set res_x_tmp $res_x
        set x_rel [expr $res_x_tmp - $orig_x]

        # Store the nodes final position
        objarray set $result_x $i [expr $orig_x + cos($ang2)*($x_rel) + sin($ang2)*$res_y]
        objarray set $result_y $i [expr -sin($ang2)*($x_rel) + cos($ang2)*$res_y]
        objarray set $result_z $i $old_val_z
    }
    return [list $result_x $result_y $result_z]
}

proc ::Structural::examples::MeshCantileverTest::Wizard::UnregisterDrawCuts { } {
    variable draw_cuts_name
    Drawer::Unregister $draw_cuts_name
    GiD_Process 'Redraw 
    smart_wizard::SetProperty Simulation ViewCuts,name "Draw cuts"
}

proc ::Structural::examples::MeshCantileverTest::Wizard::DrawCuts { } {
    variable draw_cuts_name
    variable curr_win
    if {[Drawer::IsRegistered $draw_cuts_name]} {
        ::Structural::examples::MeshCantileverTest::Wizard::UnregisterDrawCuts
    } else {
        set planes [write::GetCutPlanesList]
        set glob_cuts [list ]
        foreach plane $planes {
            set center [dict get $plane point]
            set normal [dict get $plane normal]
            lassign [MathUtils::CalculateLocalAxisFromXAxis $normal] v1 v2

            # set v1 [list [expr -1.0*[lindex $normal 0]] [lindex $normal 1] [lindex $normal 2]]
            # set v2 [list [lindex $normal 0] [lindex $normal 1] 1]
            set c1 [MathUtils::VectorSum $center  [MathUtils::ScalarByVectorProd 30 $v1]]
            set c2 [MathUtils::VectorSum $center  [MathUtils::ScalarByVectorProd 30 $v2]]
            set c3 [MathUtils::VectorSum $center [MathUtils::ScalarByVectorProd -30 $v1]]
            set c4 [MathUtils::VectorSum $center [MathUtils::ScalarByVectorProd -30 $v2]]

            lappend glob_cuts [list $c1 $c2 $c3 $c4]
        }
        Drawer::Register $draw_cuts_name ::Structural::examples::MeshCantileverTest::Wizard::RedrawCuts $glob_cuts
        smart_wizard::SetProperty Simulation ViewCuts,name "End draw cuts"
    }
    GiD_Process 'Redraw 
    ::Structural::examples::MeshCantileverTest::Wizard::Simulation $curr_win
}

proc ::Structural::examples::MeshCantileverTest::Wizard::RedrawCuts { } { 
    variable draw_cuts_name
    # blue
    GiD_OpenGL draw -color "0.0 0.0 1.0"
    foreach cuadrado [Drawer::GetVars $draw_cuts_name] {
        lassign $cuadrado c1 c2 c3 c4
        GiD_OpenGL draw -begin lineloop 
        GiD_OpenGL draw -vertex $c1
        GiD_OpenGL draw -vertex $c2
        GiD_OpenGL draw -vertex $c3
        GiD_OpenGL draw -vertex $c4
        GiD_OpenGL draw -end
    }
}

proc ::Structural::examples::MeshCantileverTest::Wizard::PreviewCurvature {} {
    variable draw_render_name
    variable curr_win
    if {[Drawer::IsRegistered $draw_render_name]} {
        ::Structural::examples::MeshCantileverTest::Wizard::UnregisterDrawPrecurvature
    } else {
        set surfaces [GiD_Geometry -v2 list surface]

        set x [list ]
        set y [list ]
        set z [list ]
        
        foreach surface_id $surfaces {
            lassign [GiD_Geometry get surface $surface_id -force render_mesh] elemtype elementnnodes nodes elements normals uvs
            foreach {cx cy cz} $nodes {
                lappend x $cx
                lappend y $cy
                lappend z $cz
            }
        }
        set coords [list [objarray new doublearray -values $x] [objarray new doublearray -values $y] [objarray new doublearray -values $z]]
        
        set length [ smart_wizard::GetProperty Geometry Length,value]
        set orig_x [ expr $length*-0.5]
        set angle [ smart_wizard::GetProperty Simulation Bending,value]
        set angle [expr $angle/2]
        set nodes [::Structural::examples::MeshCantileverTest::Wizard::BendNodes $orig_x $length $angle $coords]
        
        Drawer::Register $draw_render_name ::Structural::examples::MeshCantileverTest::Wizard::RedrawRenderBended $nodes
        
        smart_wizard::SetProperty Simulation PreviewCurvature,name "End preview curvature"
    }
    GiD_Process 'Redraw 
    ::Structural::examples::MeshCantileverTest::Wizard::Simulation $curr_win
}


proc ::Structural::examples::MeshCantileverTest::Wizard::UnregisterDrawPrecurvature { } {
    variable draw_render_name
    Drawer::Unregister $draw_render_name
    GiD_Process 'Redraw 
    smart_wizard::SetProperty Simulation PreviewCurvature,name "Preview curvature"
}

proc ::Structural::examples::MeshCantileverTest::Wizard::RedrawRenderBended { } { 
    variable draw_render_name
    # blue
    GiD_OpenGL draw -color "0.0 0.0 1.0" -pointsize 3  
    lassign [Drawer::GetVars $draw_render_name] x y z
    GiD_OpenGL draw -begin points 
    foreach cx $x cy $y cz $z {
        GiD_OpenGL draw -vertex [list $cx $cy $cz]
    }
    GiD_OpenGL draw -end
}

::Structural::examples::MeshCantileverTest::Wizard::Init

