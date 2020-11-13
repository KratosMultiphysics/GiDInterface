proc ::PfemThermic::examples::ThermicCubeDrop {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawThermicCubeDropGeometry
    AssignGroupsThermicCubeDropGeometry
    TreeAssignationThermicCubeDrop

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

# Draw Geometry
proc PfemThermic::examples::DrawThermicCubeDropGeometry {args} {
    ## Layer ##
	set layer PfemThermic
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer
	
	## Points ##
	set points_fluid [list 0.0 0.0 0.0   1.0 0.0 0.0   1.0 0.5 0.0   0.0 0.5 0.0]
    foreach {x y z} $points_fluid {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_solid [list 0.35 0.7 0.0   0.65 0.7 0.0   0.65 1.0 0.0   0.35 1.0 0.0]
    foreach {x y z} $points_solid {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_rigid [list 0.0 1.2 0.0   1.0 1.2 0.0 ]
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
    set lines_rigid [list 4 9   9 10   10 3]
    foreach {p1 p2} $lines_rigid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 1 escape escape
    GiD_Process Mescape Geometry Create NurbsSurface 5 6 7 8 escape escape
}

# Group assign
proc PfemThermic::examples::AssignGroupsThermicCubeDropGeometry {args} {
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Solid
    GiD_Groups edit color Solid "#3b3b3bff"
    GiD_EntitiesGroups assign Solid surfaces 2

    GiD_Groups create Interface
    GiD_Groups edit color Interface "#e0210fff"
    GiD_EntitiesGroups assign Interface lines {5 6 7 8}

    GiD_Groups create Rigid_Walls
    GiD_Groups edit color Rigid_Walls "#42eb71ff"
    GiD_EntitiesGroups assign Rigid_Walls lines {1 2 4 9 10 11}
}

# Tree assign
proc PfemThermic::examples::TreeAssignationThermicCubeDrop {args} {
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
    set props [list ConstitutiveLaw NewtonianTemperatureDependent2DLaw DENSITY 1000 CONDUCTIVITY 5000 SPECIFIC_HEAT 1000 DYNAMIC_VISCOSITY 0.01 BULK_MODULUS 1000000000]
    spdAux::SetValuesOnBaseNode $fluidNode $props
	
	# Solid body
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/value\[@n='BodyType'\]" {v Solid}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set solid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/condition\[@n='Parts'\]"
    set solidNode [customlib::AddConditionGroupOnXPath $solid_part_xpath Solid]
    set props [list Element UpdatedLagrangianVSolidElement2D ConstitutiveLaw Hypoelastic DENSITY 700 YOUNG_MODULUS 1000000 POISSON_RATIO 0 CONDUCTIVITY 10 SPECIFIC_HEAT 1000]
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
	GiD_Groups clone Rigid_Walls TotalV
    GiD_Groups edit parent TotalV Rigid_Walls
    spdAux::AddIntervalGroup Rigid_Walls "Rigid_Walls//TotalV"
    GiD_Groups edit state "Rigid_Walls//TotalV" hidden
    set fixVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    set fixVelocityNode [customlib::AddConditionGroupOnXPath $fixVelocity "Rigid_Walls//TotalV"]
    $fixVelocityNode setAttribute ov line
	
	# Temperature BC
	GiD_Groups clone Rigid_Walls TotalTR
    GiD_Groups edit parent TotalTR Rigid_Walls
    spdAux::AddIntervalGroup Rigid_Walls "Rigid_Walls//TotalTR"
    GiD_Groups edit state "Rigid_Walls//TotalTR" hidden
    set fixTemperature "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Rigid_Walls//TotalTR"]
    $fixTemperatureNode setAttribute ov line
	set props [list value 300.00 Interval Total constrained 1]
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
	# Temperature IC
	GiD_Groups clone Fluid InitialTF
    GiD_Groups edit parent InitialTF Fluid
	spdAux::AddIntervalGroup Fluid "Fluid//InitialTF"
	GiD_Groups edit state "Fluid//InitialTF" hidden
	set thermalFluidIC "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
	set thermalFluidICnode [customlib::AddConditionGroupOnXPath $thermalFluidIC "Fluid//InitialTF"]
	$thermalFluidICnode setAttribute ov surface
	set fluidProps [list value 300.00 Interval Initial constrained 0]
    spdAux::SetValuesOnBaseNode $thermalFluidICnode $fluidProps
	
	GiD_Groups clone Solid InitialTS
    GiD_Groups edit parent InitialTS Solid
	spdAux::AddIntervalGroup Solid "Solid//InitialTS"
	GiD_Groups edit state "Solid//InitialTS" hidden
	set thermalSolidIC "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
	set thermalSolidICnode [customlib::AddConditionGroupOnXPath $thermalSolidIC "Solid//InitialTS"]
	$thermalSolidICnode setAttribute ov surface
	set solidProps [list value 380.00 Interval Initial constrained 0]
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
