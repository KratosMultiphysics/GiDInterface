proc ::PfemThermic::examples::ThermicConvection {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawThermicConvectionGeometry$::Model::SpatialDimension
    AssignGroupsThermicConvectionGeometry$::Model::SpatialDimension
    TreeAssignationThermicConvection$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

# Draw Geometry
proc PfemThermic::examples::DrawThermicConvectionGeometry2D {args} {
    ## Layer ##
	set layer PfemThermic
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer

    ## Points ##
    set coordinates [list -0.5 -0.5 0 0.5 -0.5 0 0.5 0.5 0 -0.5 0.5 0]
    set fluidPoints [list ]
    foreach {x y z} $coordinates {
        lappend fluidPoints [GiD_Geometry create point append Fluid $x $y $z]
    }

    ## Lines ##
    set fluidLines [list ]
    set initial [lindex $fluidPoints 0]
    foreach point [lrange $fluidPoints 1 end] {
        lappend fluidLines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }
    lappend fluidLines [GiD_Geometry create line append stline Fluid $initial [lindex $fluidPoints 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$fluidLines escape escape
}

proc PfemThermic::examples::DrawThermicConvectionGeometry3D {args} {
    # To be implemented
}

# Group assign
proc PfemThermic::examples::AssignGroupsThermicConvectionGeometry2D {args} {
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Rigid_Walls
    GiD_Groups edit color Rigid_Walls "#e0210fff"
    GiD_EntitiesGroups assign Rigid_Walls lines {1 2 3 4}
	
	GiD_Groups create Heat_Walls
    GiD_Groups edit color Heat_Walls "#e0210fff"
    GiD_EntitiesGroups assign Heat_Walls lines {1}
	
	GiD_Groups create Cold_Walls
    GiD_Groups edit color Cold_Walls "#e0210fff"
    GiD_EntitiesGroups assign Cold_Walls lines {3}

}
proc PfemThermic::examples::AssignGroupsThermicConvectionGeometry3D {args} {
    # To be implemented
}

# Tree assign
proc PfemThermic::examples::TreeAssignationThermicConvection2D {args} {
    # Physics
	spdAux::SetValueOnTreeItem v "Fluids" PFEMFLUID_DomainType
	
	# Create bodies
	set bodies_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]"
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[2\]" {name Body2}
	gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[3\]" {name Body3}
	gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[4\]" {name Body4}
	
	# Fluid body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/value\[@n='BodyType'\]" {v Fluid}
    set fluid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/condition\[@n='Parts'\]"
    set fluidNode [customlib::AddConditionGroupOnXPath $fluid_part_xpath Fluid]
    set props [list ConstitutiveLaw NewtonianTemperatureDependent2DLaw DENSITY 1000 TEMPERATURE_vs_DENSITY "temp_vs_dens.txt" CONDUCTIVITY 1000.0 SPECIFIC_HEAT 10.0 DYNAMIC_VISCOSITY 0.01 BULK_MODULUS 2100000000.0]
    spdAux::SetValuesOnBaseNode $fluidNode $props
	
	# Rigid body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='BodyType'\]" {v Rigid}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Rigid_Walls]
    $rigidNode setAttribute ov line
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    
	# Heat body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body3'\]/value\[@n='BodyType'\]" {v Rigid}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body3'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Heat_Walls]
    $rigidNode setAttribute ov line
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body3'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
	
	# Cold body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body4'\]/value\[@n='BodyType'\]" {v Rigid}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body4'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Cold_Walls]
    $rigidNode setAttribute ov line
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body4'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
	
    # Velocity BC
    GiD_Groups clone Rigid_Walls Total
    GiD_Groups edit parent Total Rigid_Walls
    spdAux::AddIntervalGroup Rigid_Walls "Rigid_Walls//Total"
    GiD_Groups edit state "Rigid_Walls//Total" hidden
    set fixVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    set fixVelocityNode [customlib::AddConditionGroupOnXPath $fixVelocity "Rigid_Walls//Total"]
    $fixVelocityNode setAttribute ov line
	
	# Temperature BC
	GiD_Groups clone Heat_Walls TotalH
    GiD_Groups edit parent TotalH Heat_Walls
    spdAux::AddIntervalGroup Heat_Walls "Heat_Walls//TotalH"
    GiD_Groups edit state "Heat_Walls//TotalH" hidden
    set fixTemperature "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Heat_Walls//TotalH"]
    $fixTemperatureNode setAttribute ov line
	set props [list value 373.65 Interval Total]
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
	GiD_Groups clone Cold_Walls TotalC
    GiD_Groups edit parent TotalC Cold_Walls
    spdAux::AddIntervalGroup Cold_Walls "Cold_Walls//TotalC"
    GiD_Groups edit state "Cold_Walls//TotalC" hidden
    set fixTemperature "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Cold_Walls//TotalH"]
    $fixTemperatureNode setAttribute ov line
	set props [list value 372.65 Interval Total]
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
	# Temperature IC
	GiD_Groups clone Fluid Initial
    GiD_Groups edit parent Initial Fluid
	spdAux::AddIntervalGroup Fluid "Fluid//Initial"
	GiD_Groups edit state "Fluid//Initial" hidden
	set thermalIC "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
	set thermalICnode [customlib::AddConditionGroupOnXPath $thermalIC "Fluid//Initial"]
	$thermalICnode setAttribute ov surface
	set props [list value 373.15 Interval Initial]
    spdAux::SetValuesOnBaseNode $thermalICnode $props
	
	# Time parameters
    set time_parameters [list StartTime 0.0 EndTime 120.00 DeltaTime 0.005 UseAutomaticDeltaTime No]
    set time_params_path [spdAux::getRoute "PFEMFLUID_TimeParameters"]
    spdAux::SetValuesOnBasePath $time_params_path $time_parameters
	
	# Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 1]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters
	
    spdAux::RequestRefresh
}

proc PfemThermic::examples::TreeAssignationThermicConvection3D {args} {
    # To be implemented
}

proc PfemThermic::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}