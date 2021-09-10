namespace eval ::PfemThermic::examples::ThermicFluidDrop {
    namespace path ::PfemThermic::examples
    Kratos::AddNamespace [namespace current]

}
proc ::PfemThermic::examples::ThermicFluidDrop::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawGeometry
    AssignGroups
    TreeAssignation

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

# Draw Geometry
proc PfemThermic::examples::ThermicFluidDrop::DrawGeometry {args} {
    ## Layer ##
	set layer PfemThermic
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer
	
	## Points ##
	set points_solid [list 0.00 1.00 0.00   0.00 0.00 0.00   1.00 0.00 0.00   1.00 1.00 0.00   0.90 1.00 0.00   0.90 0.10 0.00   0.10 0.10 0.00   0.10 1.00 0.00]
    foreach {x y z} $points_solid {
        GiD_Geometry create point append $layer $x $y $z
    }
	set points_fluid [list 0.25 0.15 0.00   0.75 0.15 0.00   0.75 0.65 0.00   0.25 0.65 0.00]
    foreach {x y z} $points_fluid {
        GiD_Geometry create point append $layer $x $y $z
    }
	
    ## Lines ##
	set lines_solid [list 1 2   2 3   3 4   4 5   5 6   6 7   7 8   8 1]
    foreach {p1 p2} $lines_solid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    set lines_fluid [list 9 10   10 11   11 12   12 9]
    foreach {p1 p2} $lines_fluid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
	GiD_Process Mescape Geometry Create NurbsSurface 9 10 11 12 escape escape
    GiD_Process Mescape Geometry Create NurbsSurface 1 2 3 4 5 6 7 8 escape escape
}

# Group assign
proc PfemThermic::examples::ThermicFluidDrop::AssignGroups {args} {
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1
	
	GiD_Groups create Solid
    GiD_Groups edit color Solid "#3b3b3bff"
    GiD_EntitiesGroups assign Solid surfaces 2
	
	GiD_Groups create Interface
    GiD_Groups edit color Interface "#e0210fff"
    GiD_EntitiesGroups assign Interface lines {1 2 3 4 5 6 7 8}
}

# Tree assign
proc PfemThermic::examples::ThermicFluidDrop::TreeAssignation {args} {
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
	
    gid_groups_conds::setAttributesF $bodies_xpath {state hidden}
	
	# Fluid body
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='FluidBody'\]/value\[@n='BodyType'\]" {v Fluid}
	set fluid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='FluidBody'\]/condition\[@n='Parts'\]"
    set fluidNode [customlib::AddConditionGroupOnXPath $fluid_part_xpath Fluid]
    set props [list ConstitutiveLaw NewtonianTemperatureDependent2DLaw DENSITY 1000 CONDUCTIVITY 5000 SPECIFIC_HEAT 100 DYNAMIC_VISCOSITY 0.01 BULK_MODULUS 1000000000]
    spdAux::SetValuesOnBaseNode $fluidNode $props
	
	# Solid body
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/value\[@n='BodyType'\]" {v Solid}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set solid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='SolidBody'\]/condition\[@n='Parts'\]"
    set solidNode [customlib::AddConditionGroupOnXPath $solid_part_xpath Solid]
    set props [list Element UpdatedLagrangianVSolidElement2D ConstitutiveLaw Hypoelastic DENSITY 2500 YOUNG_MODULUS 1000000 POISSON_RATIO 0 CONDUCTIVITY 7000 SPECIFIC_HEAT 100]
    spdAux::SetValuesOnBaseNode $solidNode $props
	
	# Interface body
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='InterfaceBody'\]/value\[@n='BodyType'\]" {v Interface}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='InterfaceBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set interface_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='InterfaceBody'\]/condition\[@n='Parts'\]"
    set interfaceNode [customlib::AddConditionGroupOnXPath $interface_part_xpath Interface]
    $interfaceNode setAttribute ov line
	
	# Velocity BC
    set fixSurfaceVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    [customlib::AddConditionGroupOnXPath $fixSurfaceVelocity "Interface"] setAttribute ov line
	
	# Temperature IC
	set InitTemperature "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
	set thermalFluidICnode [customlib::AddConditionGroupOnXPath $InitTemperature "Fluid"]
	set thermalSolidICnode [customlib::AddConditionGroupOnXPath $InitTemperature "Solid"]
	set fluidProps [list value 310.00 Interval Initial constrained 1]
	set solidProps [list value 290.00 Interval Initial constrained 1]
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
