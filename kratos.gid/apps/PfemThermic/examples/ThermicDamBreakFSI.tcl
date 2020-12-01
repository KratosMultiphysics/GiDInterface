proc ::PfemThermic::examples::ThermicDamBreakFSI {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawThermicDamBreakFSIGeometry
    AssignGroupsThermicDamBreakFSIGeometry
    TreeAssignationThermicDamBreakFSI

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

# Draw Geometry
proc PfemThermic::examples::DrawThermicDamBreakFSIGeometry {args} {
    ## Layer ##
	set layer PfemThermic
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer
	
	## Points ##
	set points_fluid [list 0 0 0     0.146 0 0     0.146 0.350 0     0 0.350 0]
    foreach {x y z} $points_fluid {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_solid [list 0.360 0 0     0.360 0.10 0     0.330 0.10 0     0.330 0 0]
    foreach {x y z} $points_solid {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_rigid [list 0 0.596 0     0.596 0.596 0     0.596 0 0 ]
    foreach {x y z} $points_rigid {
        GiD_Geometry create point append $layer $x $y $z
    }
	
    ## Lines ##
    set lines_fluid [list 1 2   2 3   3 4   4 1]
    foreach {p1 p2} $lines_fluid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    set lines_solid [list 5 6   6 7   7 8   8 5]
    foreach {p1 p2} $lines_solid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    set lines_rigid [list 4 9   9 10   10 11   11 5   8 2]
    foreach {p1 p2} $lines_rigid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 1 escape escape
    GiD_Process Mescape Geometry Create NurbsSurface 5 6 7 8 escape escape
}

# Group assign
proc PfemThermic::examples::AssignGroupsThermicDamBreakFSIGeometry {args} {
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Solid
    GiD_Groups edit color Solid "#3b3b3bff"
    GiD_EntitiesGroups assign Solid surfaces 2

    GiD_Groups create Interface
    GiD_Groups edit color Interface "#e0210fff"
    GiD_EntitiesGroups assign Interface lines {5 6 7}

    GiD_Groups create Rigid_Walls
    GiD_Groups edit color Rigid_Walls "#42eb71ff"
    GiD_EntitiesGroups assign Rigid_Walls lines {1 4 9 10 11 12 13}

}

# Tree assign
proc PfemThermic::examples::TreeAssignationThermicDamBreakFSI {args} {
    # Physics
    gid_groups_conds::setAttributesF [spdAux::getRoute PFEMFLUID_DomainType] {v FSI}
    
	# Create bodies
	set bodies_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]"
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[2\]" {name FluidBody}
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[3\]" {name SolidBody}
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[4\]" {name InterfaceBody}
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[5\]" {name RigidWallsBody}
    gid_groups_conds::setAttributesF $bodies_xpath {state hidden}
	
	# Fluid body
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='FluidBody'\]/value\[@n='BodyType'\]" {v Fluid}
	set fluid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='FluidBody'\]/condition\[@n='Parts'\]"
    set fluidNode [customlib::AddConditionGroupOnXPath $fluid_part_xpath Fluid]
    set props [list ConstitutiveLaw NewtonianTemperatureDependent2DLaw DENSITY 1000 CONDUCTIVITY 5000 SPECIFIC_HEAT 5000 DYNAMIC_VISCOSITY 0.01 BULK_MODULUS 1000000000]
    spdAux::SetValuesOnBaseNode $fluidNode $props
	
	# Solid body
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/value\[@n='BodyType'\]" {v Solid}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set solid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/condition\[@n='Parts'\]"
    set solidNode [customlib::AddConditionGroupOnXPath $solid_part_xpath Solid]
    set props [list Element UpdatedLagrangianVSolidElement2D ConstitutiveLaw Hypoelastic DENSITY 2500 YOUNG_MODULUS 1000000 POISSON_RATIO 0 CONDUCTIVITY 10 SPECIFIC_HEAT 1000]
    spdAux::SetValuesOnBaseNode $solidNode $props
	
	# Interface body
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='InterfaceBody'\]/value\[@n='BodyType'\]" {v Interface}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='InterfaceBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set interface_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='InterfaceBody'\]/condition\[@n='Parts'\]"
    set interfaceNode [customlib::AddConditionGroupOnXPath $interface_part_xpath Interface]
    $interfaceNode setAttribute ov line
    
	# Rigid body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='RigidWallsBody'\]/value\[@n='BodyType'\]" {v Rigid}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='RigidWallsBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='RigidWallsBody'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Rigid_Walls]
    $rigidNode setAttribute ov line
	
    # Velocity BC
    set fixVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    [customlib::AddConditionGroupOnXPath $fixVelocity "Rigid_Walls"] setAttribute ov line
	
	# Temperature BC
    set fixTemperature "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Rigid_Walls"]
    set props [list value 330.00 Interval Total constrained 1]
	$fixTemperatureNode setAttribute ov line
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
	# Temperature IC
	set thermalFluidICnode [customlib::AddConditionGroupOnXPath $fixTemperature "Fluid"]
	set thermalSolidICnode [customlib::AddConditionGroupOnXPath $fixTemperature "Solid"]
	set fluidProps [list value 273.15 Interval Initial constrained 0]
	set solidProps [list value 373.15 Interval Initial constrained 0]
	$thermalFluidICnode setAttribute ov surface
	$thermalSolidICnode setAttribute ov surface
    spdAux::SetValuesOnBaseNode $thermalFluidICnode $fluidProps
    spdAux::SetValuesOnBaseNode $thermalSolidICnode $solidProps
	
	# Time parameters
	set time_parameters [list StartTime 0.0 EndTime 5.0 DeltaTime 0.001 UseAutomaticDeltaTime No]
    set time_params_path [spdAux::getRoute "PFEMFLUID_TimeParameters"]
    spdAux::SetValuesOnBasePath $time_params_path $time_parameters
	
	# Parallelism
	set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 1]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters
	
	# Output
	set parameters [list OutputControlType time OutputDeltaTime 0.01]
	set xpath [spdAux::getRoute "Results"]
    spdAux::SetValuesOnBasePath $xpath $parameters
	
	# Others
	spdAux::SetValueOnTreeItem values transient CNVDFFSolStrat
    spdAux::RequestRefresh
}

proc PfemThermic::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}
