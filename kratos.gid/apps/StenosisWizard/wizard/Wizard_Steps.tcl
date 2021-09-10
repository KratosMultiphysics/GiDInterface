
namespace eval ::StenosisWizard::Wizard {
    namespace path ::StenosisWizard
    # Namespace variables declaration
    variable curr_win
    variable ogl_cuts
}

proc StenosisWizard::Wizard::Init { } {
    #W "Carga los pasos"
    variable curr_win
    set curr_win ""
    variable draw_cuts_name
    set draw_cuts_name StenosisWizard_cuts
    variable draw_render_name
    set draw_render_name StenosisWizard_render
}

proc StenosisWizard::Wizard::Geometry { win } {
    variable curr_win
    set curr_win $win
    smart_wizard::AutoStep $curr_win Geometry
    smart_wizard::SetWindowSize 650 500
}

proc StenosisWizard::Wizard::GeometryTypeChange { } {
    variable curr_win

    set type [ smart_wizard::GetProperty Geometry Type,value]
    if {[GiDVersionCmp 14.1.3d] >= 0} {
        switch $type {
            "Circular" {
                smart_wizard::SetProperty Geometry Length,value 200
                smart_wizard::SetProperty Geometry Delta,value 3.18
                smart_wizard::SetProperty Geometry Precision,state normal
                smart_wizard::SetProperty Geometry SphRadius,state hidden
                smart_wizard::SetProperty Geometry Tpoly,state hidden
                smart_wizard::SetProperty Geometry ImageGeom,value Geometry.png
            }
            "Triangular" {
                smart_wizard::SetProperty Geometry Length,value 300
                smart_wizard::SetProperty Geometry Delta,value 16.9
                smart_wizard::SetProperty Geometry Precision,state hidden
                smart_wizard::SetProperty Geometry SphRadius,state hidden
                smart_wizard::SetProperty Geometry Tpoly,state hidden
                smart_wizard::SetProperty Geometry ImageGeom,value GeometryTriangular.png
            }
            "Polygonal" {
                smart_wizard::SetProperty Geometry Length,value 300
                smart_wizard::SetProperty Geometry Delta,value 16.9
                smart_wizard::SetProperty Geometry Tpoly,state normal
                smart_wizard::SetProperty Geometry Tpoly,value 25.4
                smart_wizard::SetProperty Geometry Precision,state hidden
                smart_wizard::SetProperty Geometry SphRadius,state hidden
                smart_wizard::SetProperty Geometry ImageGeom,value GeometryPolygonal.png
            }
            "Spherical" {
                smart_wizard::SetProperty Geometry Length,value 300
                smart_wizard::SetProperty Geometry Delta,value 17.5
                smart_wizard::SetProperty Geometry Precision,state hidden
                smart_wizard::SetProperty Geometry SphRadius,state normal
                smart_wizard::SetProperty Geometry Tpoly,state hidden
                smart_wizard::SetProperty Geometry ImageGeom,value GeometrySpherical.png
            }
        }
        smart_wizard::AutoStep $curr_win Geometry
    }
    
}
proc StenosisWizard::Wizard::NextGeometry { } {
    
}

proc StenosisWizard::Wizard::DrawGeometry {} {
    Kratos::ResetModel
    
    set err [StenosisWizard::Wizard::ValidateDraw]
    if {$err ne 0} {
        return ""
    }
    # Get the parameters
    set type [ smart_wizard::GetProperty Geometry Type,value]
    set length [ smart_wizard::GetProperty Geometry Length,value]
    set radius [ smart_wizard::GetProperty Geometry Radius,value]
    set start [expr [ smart_wizard::GetProperty Geometry Z,value] *-1.0]
    set end [ smart_wizard::GetProperty Geometry Z,value]
    set delta [ smart_wizard::GetProperty Geometry Delta,value]
    set precision [ smart_wizard::GetProperty Geometry Precision,value]
    set sphradius [ smart_wizard::GetProperty Geometry SphRadius,value] 
    set tpoly [ smart_wizard::GetProperty Geometry Tpoly,value] 

    switch $type {
        "Circular" {
            DrawCircular $length $radius $start $end $delta $precision
        }   
        "Triangular" {
            DrawTriangular $length $radius $start $end $delta
        }
       "Polygonal" {
            DrawPolygonal $length $radius $start $end $delta $tpoly
        }
        "Spherical" {
            DrawSpherical $length $radius $start $end $delta $sphradius
        }
    }
    
    # Update the groups window to show the created groups
    GidUtils::UpdateWindow GROUPS
    # Zoom frame to center the view
    GiD_Process 'Zoom Frame escape

}

proc StenosisWizard::Wizard::DrawTriangular {length radius start end delta } {
    GidUtils::DisableGraphics

    set origin_x [expr double($length)/-2]
    set end_x [expr double($length)/2]

    set layer [GiD_Info Project LayerToUse]
    GiD_Process 'Layers Color $layer 153036015 Transparent $layer 255 escape Mescape

    GiD_Process Geometry Create Line $origin_x,0 $end_x,0 escape Mescape
    GiD_Process Geometry Create Line $origin_x,$radius $end_x,$radius escape Mescape

    GiD_Process Utilities Copy Lines DoExtrude Surfaces MaintainLayers Rotation FJoin 1 FJoin 2 360 2 escape Mescape 
    GiD_Process Geometry Create Object Cone 0.0 -$radius 0.0 0.0 1.0 0.0 $end $delta escape Mescape 
    GiD_Process Geometry Delete Volumes 1 escape MEscape 
    GiD_Process Geometry Create IntMultSurfs 1 2 3 4 5 escape Mescape 
    GiD_Process Geometry Delete Surfaces 7 9 10 13 15 18 19 20 21 escape Mescape
    GiD_Process Geometry Delete Lines 1 9 13 15 17 18 20 24 25 26 escape Mescape 
    GiD_Process Geometry Create NurbsSurface 3 escape Mescape
    GiD_Process Geometry Create NurbsSurface 4 escape Mescape 
    GiD_Process Geometry Create volume 8 11 14 16 17 18 escape Mescape
    GiD_Process Utilities Collapse Model Yes escape Mescape 
    GiD_Process Geometry Delete points 1: escape Mescape 
    GiD_Process Geometry Delete lines 1: escape Mescape 
    GiD_Process Geometry Delete surfaces 1: escape Mescape 


    GiD_Groups create Inlet
    GiD_EntitiesGroups assign Inlet surfaces 17
    GiD_Groups create Outlet
    GiD_EntitiesGroups assign Outlet surfaces 18
    GiD_Groups create NoSlip
    GiD_EntitiesGroups assign NoSlip surfaces {8 11 14 16}
    GiD_Groups create Fluid
    GiD_EntitiesGroups assign Fluid volumes 1

    GidUtils::EnableGraphics
}

proc StenosisWizard::Wizard::DrawSpherical {length radius start end delta sphradius  } {
    GidUtils::DisableGraphics

    set origin_x [expr double($length)/-2]
    set end_x [expr double($length)/2]
    
    set hdelta [expr double($delta) - double($radius)]
    set ycenter [expr double ($hdelta) - double($sphradius)]

    set layer [GiD_Info Project LayerToUse]
    GiD_Process 'Layers Color $layer 153036015 Transparent $layer 255 escape Mescape
        
    GiD_Process Mescape Geometry Create Line $origin_x,0 $end_x,0 escape Mescape
    GiD_Process Mescape Geometry Create Line $origin_x,$radius $end_x,$radius escape Mescape 
    GiD_Process Mescape Utilities Copy Lines DoExtrude Surfaces MaintainLayers Rotation FJoin 1 FJoin 2 360 2 escape Mescape 

    GiD_Process Mescape Geometry Create Object Sphere 0.0 $ycenter 0.0 $sphradius escape Mescape 
    GiD_Process Mescape Geometry Delete Volumes 1 escape Mescape 
    
        GiD_Process Mescape Geometry Create IntMultSurfs 1 2 3 4 5  escape Mescape 
        GiD_Process Mescape Geometry Delete Surfaces 7 9 12 15 18 escape Mescape
        GiD_Process Mescape Geometry Delete Lines 1 10 12 15 18 escape Mescape 
        GiD_Process Mescape Geometry Create NurbsSurface 3 escape Mescape
        GiD_Process Mescape Geometry Create NurbsSurface 4 escape Mescape 
        GiD_Process Mescape Geometry Create volume 8 10 13 16 17 18 19 escape Mescape
    
    GiD_Process Mescape Utilities Collapse Model Yes escape Mescape 
    #GiD_Process Mescape Geometry Delete surfaces 1: escape Mescape 
    #GiD_Process Mescape Geometry Delete lines 1: escape Mescape 
    #GiD_Process Mescape Geometry Delete points 1: escape Mescape 
     
    GiD_Groups create Inlet
        GiD_EntitiesGroups assign Inlet surfaces 18
    GiD_Groups create Outlet
        GiD_EntitiesGroups assign Outlet surfaces 19
    GiD_Groups create NoSlip
        GiD_EntitiesGroups assign NoSlip surfaces {8 10 13 16 17}
    GiD_Groups create Fluid
        GiD_EntitiesGroups assign Fluid volumes 1

    GidUtils::EnableGraphics

}

proc StenosisWizard::Wizard::DrawPolygonal {length radius start end delta tpoly } {
    GidUtils::DisableGraphics
    set origin_x [expr double($length)/-2]
    set end_x [expr double($length)/2]
    
    set halfpoly [expr double($tpoly)/2]
    set hdelta [expr $delta - $radius]
    
    set origin_poly [expr double($start) - double($halfpoly)]
    set end_poly [expr double($end) + double($halfpoly)]

    set doubleradius [expr double($radius) * 2.0]

    set layer [GiD_Info Project LayerToUse]
    GiD_Process 'Layers Color $layer 153036015 Transparent $layer 255 escape Mescape

    GiD_Process Geometry Create Line $origin_x,0 $end_x,0 escape Mescape
    GiD_Process Geometry Create Line $origin_x,$radius $end_x,$radius escape Mescape 
    GiD_Process Utilities Copy Lines DoExtrude Surfaces MaintainLayers Rotation FJoin 1 FJoin 2 360 2 escape Mescape 

    GiD_Process Geometry Create Line $origin_x,-$radius $origin_poly,-$radius -$halfpoly,$hdelta $halfpoly,$hdelta $end_poly,-$radius $end_x,-$radius escape Mescape

    GiD_Process Geometry Create Line $origin_x,-$doubleradius $end_x,-$doubleradius escape Mescape
    GiD_Process Utilities Copy Lines DoExtrude Surfaces MaintainLayers Rotation FJoin 11 FJoin 12 360 5 6 7 8 9 escape Mescape 
    
    GiD_Process Geometry Create IntMultSurfs 1 2 3 4 5 6 escape Mescape 
    
    
    GiD_Process Geometry Delete Surfaces 2 4 6 10 14 18 20 escape Mescape 
    GiD_Process Geometry Delete Lines 1 10 11 12 15 16 23 29 escape Mescape
    GiD_Process Geometry Delete Points 11 12 escape Mescape

    GiD_Process Geometry Create NurbsSurface 17 18 escape Mescape 
    GiD_Process Geometry Create NurbsSurface 34 33 escape Mescape 
    GiD_Process Geometry Create volume 8 9 12 13 16 17 21 22 23 24 escape Mescape 
    GiD_Process Utilities Collapse Model Yes escape Mescape 
    # GiD_Process Geometry Delete Lines 1: escape Mescape
    # GiD_Process Geometry Delete Points 1: escape Mescape

    GiD_Groups create Inlet
    GiD_EntitiesGroups assign Inlet surfaces {23}
    GiD_Groups create Outlet
    GiD_EntitiesGroups assign Outlet surfaces {24}
    GiD_Groups create NoSlip
    GiD_EntitiesGroups assign NoSlip surfaces {8 9 12 13 16 17 21 22}
    GiD_Groups create Fluid
    GiD_EntitiesGroups assign Fluid volumes {1}

    GidUtils::EnableGraphics
}

proc StenosisWizard::Wizard::DrawCircular {length radius start end delta precision } {
    
    #W "Drawing tube: \nLength $length \nStart $start \nEnd $end \nDelta $delta \nPrecision $precision"
    set points [list]
    
    set layer [GiD_Info Project LayerToUse]
    GiD_Process 'Layers Color $layer 153036015 Transparent $layer 255 escape 
    
    set zona [expr $end - $start]
    set delta_z [expr double($zona) / double($precision)]
    set origin_x [expr double($length)/-2]
    set end_x [expr double($length)/2]

    # Initial point
    lappend points [list $origin_x $radius 0]
    GiD_Geometry create point 1 $layer $origin_x $radius 0
    
    # first cut
    lappend points [list $start $radius 0]
    #W $points
    
    for {set i [expr $start + $delta_z]} {$i < [expr $end - $delta_z]} {set i [expr $i + $delta_z]} {
        set y $radius
        set y [expr double($radius)-((double($delta)/2.0)*(1.0+cos($MathUtils::PI*$i/double($end))))]
        #W "$i $y"
        lappend points [list $i $y 0]
    }
    
    # last cut
    lappend points [list $end $radius 0]
    # Final point
    GiD_Geometry create point 2 $layer $end_x $radius 0
    lappend points [list $end_x $radius 0]
    
    set line [GiD_Geometry create line append nurbsline $layer 1 2 -interpolate [llength $points] {*}$points -tangents {1 0 0} {1 0 0}]
    
    # Time to Revolute!
    GiD_Process Mescape Utilities Id $line escape escape Mescape Utilities Copy Lines DoExtrude Surfaces MaintainLayers MCopy 2 Rotation FNoJoin -$length,0.0,0.0 FNoJoin $length,0.0,0.0 180 1 escape
    
    # Closing tapas!
    GiD_Process Mescape Geometry Create NurbsSurface 3 5 escape 6 4 escape escape 
    
    # Volumenizando!
    GiD_Process Mescape Geometry Create volume 1 2 3 4 escape 
    
    # Agrupando
    GiD_Groups create Inlet
    GiD_EntitiesGroups assign Inlet surfaces {3}
    
    GiD_Groups create Outlet
    GiD_EntitiesGroups assign Outlet surfaces {4}
    
    GiD_Groups create NoSlip
    GiD_EntitiesGroups assign NoSlip surfaces {1 2}
    
    GiD_Groups create Fluid
    GiD_EntitiesGroups assign Fluid volumes {1}
    
    # Partimos las superficies para refinar el mallado en el centro
    GiD_Process Mescape Geometry Edit DivideSurf NumDivisions 2 USense 3 escape escape
    GiD_Process Mescape Geometry Edit DivideSurf NumDivisions 1 USense 3 escape escape
    
}


proc StenosisWizard::Wizard::ValidateDraw { } {
    return 0
}

proc StenosisWizard::Wizard::Material { win } {
    smart_wizard::AutoStep $win Material
    smart_wizard::SetWindowSize 300 450
    StenosisWizard::Wizard::FluidTypeChange
}

proc StenosisWizard::Wizard::NextMaterial { } {
    # Quitar parts existentes
    set fluidParts [spdAux::getRoute "FLParts"]
    gid_groups_conds::delete "${fluidParts}/group"
    
    # Crear una part con los datos que toquen
    set gnode [customlib::AddConditionGroupOnXPath $fluidParts "Fluid"]
    
    set props [list ConstitutiveLaw DENSITY DYNAMIC_VISCOSITY YIELD_STRESS POWER_LAW_K POWER_LAW_N]
    foreach prop $props {
        set propnode [$gnode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v [smart_wizard::GetProperty Material ${prop},value]
        }
    }
    spdAux::RequestRefresh
}

proc StenosisWizard::Wizard::FluidTypeChange { } {
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

proc StenosisWizard::Wizard::Fluid { win } {
    smart_wizard::AutoStep $win Fluid
    smart_wizard::SetWindowSize 450 450
}
proc StenosisWizard::Wizard::NextFluid { } {
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


proc StenosisWizard::Wizard::Simulation { win } {
    smart_wizard::AutoStep $win Simulation
    smart_wizard::SetWindowSize 450 600
}

proc StenosisWizard::Wizard::Mesh { } {
    LastStep
    StenosisWizard::Wizard::UnregisterDrawCuts
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
proc StenosisWizard::Wizard::Save { } {
    LastStep
    GiD_Process Mescape Files Save 
}

proc StenosisWizard::Wizard::Run { } {
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

proc StenosisWizard::Wizard::LastStep { } {
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

proc StenosisWizard::Wizard::PlaceCutPlanes { } {
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
            set new_nodes [StenosisWizard::Wizard::BendNodes $orig_x $length [expr $angle/2] $coords]
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
        set new_nodes [StenosisWizard::Wizard::BendNodes $orig_x $length [expr $angle/2] $coords]
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

proc StenosisWizard::AfterMeshGeneration { fail } {

    GidUtils::CloseWindow MESHPROGRESS
    GiD_Process Mescape Mescape Mescape
    GiD_Process Mescape Files Save 
    StenosisWizard::Wizard::PostMeshBend
    GiD_Process Mescape Files Save 
}


proc StenosisWizard::Wizard::PostMeshBend { } {

    set length [ smart_wizard::GetProperty Geometry Length,value]
    set orig_x [ expr $length*-0.5]
    set angle [ smart_wizard::GetProperty Simulation Bending,value]
    set angle [expr $angle/2]
    GidUtils::DisableGraphics
    StenosisWizard::Wizard::Bend $orig_x $length $angle
    GidUtils::EnableGraphics
    GiD_Process Mescape Meshing MeshView escape 
    GiD_Process 'Redraw 
}

proc StenosisWizard::Wizard::Bend { orig_x len angle} {

    lassign [GiD_Info Mesh nodes -array] ids coords
    set moved_nodes [StenosisWizard::Wizard::BendNodes $orig_x $len $angle $coords]
    lassign $moved_nodes coord_x coord_y coord_z
    set size [objarray length $coord_x]
    for {set i 0} {$i < $size} {incr i} {
        set res_x [objarray get $coord_x $i]
        set res_y [objarray get $coord_y $i]
        set res_z [objarray get $coord_z $i]
        GiD_Mesh edit node [objarray get $ids $i] [list $res_x $res_y $res_z]
    }
}

proc StenosisWizard::Wizard::BendNodes {orig_x len angle coords} {
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

proc StenosisWizard::Wizard::UnregisterDrawCuts { } {
    variable draw_cuts_name
    Drawer::Unregister $draw_cuts_name
    GiD_Process 'Redraw 
    smart_wizard::SetProperty Simulation ViewCuts,name "Draw cuts"
}

proc StenosisWizard::Wizard::DrawCuts { } {
    variable draw_cuts_name
    variable curr_win
    if {[Drawer::IsRegistered $draw_cuts_name]} {
        StenosisWizard::Wizard::UnregisterDrawCuts
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
        Drawer::Register $draw_cuts_name StenosisWizard::Wizard::RedrawCuts $glob_cuts
        smart_wizard::SetProperty Simulation ViewCuts,name "End draw cuts"
    }
    GiD_Process 'Redraw 
    StenosisWizard::Wizard::Simulation $curr_win
}

proc StenosisWizard::Wizard::RedrawCuts { } { 
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

proc StenosisWizard::Wizard::PreviewCurvature {} {
    variable draw_render_name
    variable curr_win
    if {[Drawer::IsRegistered $draw_render_name]} {
        StenosisWizard::Wizard::UnregisterDrawPrecurvature
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
        set nodes [StenosisWizard::Wizard::BendNodes $orig_x $length $angle $coords]
        
        Drawer::Register $draw_render_name StenosisWizard::Wizard::RedrawRenderBended $nodes
        
        smart_wizard::SetProperty Simulation PreviewCurvature,name "End preview curvature"
    }
    GiD_Process 'Redraw 
    StenosisWizard::Wizard::Simulation $curr_win
}


proc StenosisWizard::Wizard::UnregisterDrawPrecurvature { } {
    variable draw_render_name
    Drawer::Unregister $draw_render_name
    GiD_Process 'Redraw 
    smart_wizard::SetProperty Simulation PreviewCurvature,name "Preview curvature"
}

proc StenosisWizard::Wizard::RedrawRenderBended { } { 
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

StenosisWizard::Wizard::Init

