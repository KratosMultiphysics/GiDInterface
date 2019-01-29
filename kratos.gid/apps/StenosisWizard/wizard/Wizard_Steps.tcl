
namespace eval StenosisWizard::Wizard {
    # Namespace variables declaration
    
}

proc StenosisWizard::Wizard::Init { } {
    #W "Carga los pasos"
}

proc StenosisWizard::Wizard::Geometry { win } {
    smart_wizard::AutoStep $win Geometry
    smart_wizard::SetWindowSize 650 500
}

proc StenosisWizard::Wizard::NextGeometry { } {
    
}

proc StenosisWizard::Wizard::DrawGeometry {} {
    Kratos::ResetModel
    
    set err [ValidateDraw]
    if {$err ne 0} {
        return ""
    }
    # Get the parameters
    set length [ smart_wizard::GetProperty Geometry Length,value]
    set radius [ smart_wizard::GetProperty Geometry Radius,value]
    set start [expr [ smart_wizard::GetProperty Geometry Z,value] *-1.0]
    set end [ smart_wizard::GetProperty Geometry Z,value]
    set delta [ smart_wizard::GetProperty Geometry Delta,value]
    set precision [ smart_wizard::GetProperty Geometry Precision,value]
    #W "Drawing tube: \nLength $length \nStart $start \nEnd $end \nDelta $delta \nPrecision $precision"
    set points [list]
    
    set layer [GiD_Info Project LayerToUse]
    GiD_Process 'Layers Color $layer 153036015 Transparent $layer 255 escape 
    
    set zona [expr $end - $start]
    set delta_z [expr double($zona) / double($precision)]
    
    # Initial point
    lappend points [list -$length $radius 0]
    GiD_Geometry create point 1 $layer -$length $radius 0
    
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
    GiD_Geometry create point 2 $layer $length $radius 0
    lappend points [list $length $radius 0]
    
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
    
    GidUtils::UpdateWindow GROUPS
    
    GiD_Process 'Zoom Frame escape
    
    # Partimos las superficies para refinar el mallado en el centro
    GiD_Process Mescape Geometry Edit DivideSurf NumDivisions 2 USense 3 escape escape
    GiD_Process Mescape Geometry Edit DivideSurf NumDivisions 1 USense 3 escape escape
    
}

proc ValidateDraw { } {
    return 0
}

proc StenosisWizard::Wizard::Material { win } {
    smart_wizard::AutoStep $win Material
    smart_wizard::SetWindowSize 300 450
}

proc StenosisWizard::Wizard::NextMaterial { } {
    # Quitar parts existentes
    gid_groups_conds::delete {container[@n='StenosisWizard']/condition[@n='Parts']/group}
    
    # Crear una part con los datos que toquen
    set where {container[@n='StenosisWizard']/condition[@n='Parts']} 
    set gnode [customlib::AddConditionGroupOnXPath $where "Fluid"]
    
    set props [list ConstitutiveLaw DENSITY VISCOSITY YIELD_STRESS POWER_LAW_K POWER_LAW_N]
    foreach prop $props {
        set propnode [$gnode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v [smart_wizard::GetProperty Material ${prop},value]
        }
    }
    spdAux::RequestRefresh
}

proc StenosisWizard::Wizard::ChangeFluidType {win} {
    W "Hey $win"
}


proc StenosisWizard::Wizard::Fluid { win } {
    smart_wizard::AutoStep $win Fluid
    smart_wizard::SetWindowSize 450 450
}
proc StenosisWizard::Wizard::NextFluid { } {
    # Inlet
    Fluid::xml::CreateNewInlet Inlet {new false name Total} false [smart_wizard::GetProperty Fluid Inlet,value]

    # Outlet
    gid_groups_conds::delete {container[@n='StenosisWizard']/container[@n='BoundaryConditions']/condition[@n='Outlet3D']/group}
    set where {container[@n='StenosisWizard']/container[@n='BoundaryConditions']/condition[@n='Outlet3D']}
    set gnode [customlib::AddConditionGroupOnXPath $where "Outlet"]
    set propnode [$gnode selectNodes "./value\[@n = 'value'\]"]
    $propnode setAttribute v [smart_wizard::GetProperty Fluid Outlet,value]
    
    gid_groups_conds::delete {container[@n='StenosisWizard']/container[@n='BoundaryConditions']/condition[@n='NoSlip3D']/group}
    set where {container[@n='StenosisWizard']/container[@n='BoundaryConditions']/condition[@n='NoSlip3D']}
    set gnode [customlib::AddConditionGroupOnXPath $where "NoSlip"]
    spdAux::RequestRefresh
}


proc StenosisWizard::Wizard::Simulation { win } {
    smart_wizard::AutoStep $win Simulation
    smart_wizard::SetWindowSize 450 500
}

proc StenosisWizard::Wizard::Mesh { } {
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
    GiD_Process Mescape Files Save 
}

proc StenosisWizard::Wizard::Run { } {
    set root [customlib::GetBaseRoot]
    set solstrat_un [apps::getCurrentUniqueName SolStrat]
    #W $solstrat_un
    if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] v] eq ""} {
        get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] dict
    }
    set solstrat_un [apps::getCurrentUniqueName Scheme]
    #W $solstrat_un
    if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] v] eq ""} {
        get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] dict
    }
    LastStep
    GiD_Process Mescape Utilities Calculate
}

proc StenosisWizard::Wizard::LastStep { } {
    set i [smart_wizard::GetProperty Simulation InitialTime,value]
    set e [smart_wizard::GetProperty Simulation EndTime,value]
    set d [smart_wizard::GetProperty Simulation DeltaTime,value]
    
    gid_groups_conds::setAttributesF {container[@n='StenosisWizard']/container[@n='SolutionStrat']/container[@n='TimeParameters']/value[@n='InitialTime']} "v $i"
    gid_groups_conds::setAttributesF {container[@n='StenosisWizard']/container[@n='SolutionStrat']/container[@n='TimeParameters']/value[@n='EndTime']} "v $e"
    gid_groups_conds::setAttributesF {container[@n='StenosisWizard']/container[@n='SolutionStrat']/container[@n='TimeParameters']/value[@n='DeltaTime']} "v $d"
    
    gid_groups_conds::copyNode {container[@n='StenosisWizard']/container[@n='Results']/container[@n='CutPlanes']/blockdata[@n='CutPlane'][1]} {container[@n='StenosisWizard']/container[@n='Results']/container[@n='CutPlanes']}
    
    gid_groups_conds::setAttributesF {container[@n='StenosisWizard']/container[@n='Results']/container[@n='CutPlanes']/blockdata[@n='CutPlane'][2]} {name Main}
    gid_groups_conds::setAttributesF {container[@n='StenosisWizard']/container[@n='Results']/container[@n='CutPlanes']/blockdata[@n='CutPlane'][2]/value[@n='normal']} {v 0.0,1.0,0.0}
    
    set ncuts [smart_wizard::GetProperty Simulation Cuts,value]
    set length [smart_wizard::GetProperty Geometry Length,value]
    set delta [expr 2.0*double($length)/(double($ncuts)+1.0)]
    #W "$length $delta"
    for {set i 1} {$i <= $ncuts} {incr i} {
        set x [expr -$length + ($i * $delta)]
        set x [expr double(round(100*$x))/100]
        gid_groups_conds::copyNode {container[@n='StenosisWizard']/container[@n='Results']/container[@n='CutPlanes']/blockdata[@n='CutPlane'][1]} {container[@n='StenosisWizard']/container[@n='Results']/container[@n='CutPlanes']}
        set cutplane "container\[@n='StenosisWizard'\]/container\[@n='Results'\]/container\[@n='CutPlanes'\]/blockdata\[@n='CutPlane'\]\[[expr $i +2]\]"
        gid_groups_conds::setAttributesF $cutplane "name CutPlane$i"
        gid_groups_conds::setAttributesF "$cutplane/value\[@n='normal'\]" "v 1.0,0.0,0.0"
        gid_groups_conds::setAttributesF "$cutplane/value\[@n='point'\]" "v $x,0.0,0.0"
    }
    
    
    #gid_groups_conds::setAttributesF {container[@n='StenosisWizard']/container[@n='SolutionStrat']/container[@n='velocity_linear_solver_settings']/value[@n='Solver']} {v Conjugate_gradient}
    #gid_groups_conds::setAttributesF {container[@n='StenosisWizard']/container[@n='SolutionStrat']/container[@n='pressure_linear_solver_settings']/value[@n='Solver']} {v Conjugate_gradient}
    spdAux::RequestRefresh
    
}

proc StenosisWizard::AfterMeshGeneration { fail } {
    GidUtils::CloseWindow MESHPROGRESS
    GiD_Process Mescape Mescape Mescape
    GiD_Process Mescape Files Save 
}

StenosisWizard::Wizard::Init

