namespace eval ::PfemThermic::examples::ThermicSloshingConvection {
    namespace path ::PfemThermic::examples
    Kratos::AddNamespace [namespace current]

}
proc ::PfemThermic::examples::ThermicSloshingConvection::Init {args} {
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
proc PfemThermic::examples::ThermicSloshingConvection::DrawGeometry {args} {
    ## Layer ##
	set layer PfemThermic
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer

    ## Points ##
    set points_inner [list 0 0 0 1.0 0 0 1.0 0.3 0 0 0.7 0]
    foreach {x y z} $points_inner {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_outer [list 0 1.0 0 1.0 1.0 0]
    foreach {x y z} $points_outer {
        GiD_Geometry create point append $layer $x $y $z
    }
	
	## Lines ##
    set lines_inner [list 1 2 2 3 3 4 4 1]
    foreach {p1 p2} $lines_inner {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    set lines_outer [list 4 5 5 6 6 3]
    foreach {p1 p2} $lines_outer {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 1 escape escape
}

# Group assign
proc PfemThermic::examples::ThermicSloshingConvection::AssignGroups {args} {
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1
	
	GiD_Groups create Bottom_Wall
    GiD_Groups edit color Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Bottom_Wall lines {1}
	
	GiD_Groups create Top_Wall
    GiD_Groups edit color Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Top_Wall lines {6}
	
	GiD_Groups create Right_Wall
    GiD_Groups edit color Right_Wall "#e0210fff"
    GiD_EntitiesGroups assign Right_Wall lines {2 7}
	
	GiD_Groups create Left_Wall
    GiD_Groups edit color Left_Wall "#e0210fff"
    GiD_EntitiesGroups assign Left_Wall lines {4 5}

}

# Tree assign
proc PfemThermic::examples::ThermicSloshingConvection::TreeAssignation {args} {
    # Physics
	spdAux::SetValueOnTreeItem v "Fluids" PFEMFLUID_DomainType
	
	# Create bodies
	set bodies_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]"
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[2\]" {name FluidBody}
	gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[3\]" {name BottomWallBody}
	gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[4\]" {name RightWallBody}
	gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[5\]" {name TopWallBody}
	gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[6\]" {name LeftWallBody}
	gid_groups_conds::setAttributesF $bodies_xpath {state hidden}
	
	# Fluid body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='FluidBody'\]/value\[@n='BodyType'\]" {v Fluid}
    set fluid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='FluidBody'\]/condition\[@n='Parts'\]"
    set fluidNode [customlib::AddConditionGroupOnXPath $fluid_part_xpath Fluid]
    set props [list ConstitutiveLaw NewtonianTemperatureDependent2DLaw DENSITY 1000 CONDUCTIVITY 5000 SPECIFIC_HEAT 5000 DYNAMIC_VISCOSITY 0.01 BULK_MODULUS 1000000000]
    spdAux::SetValuesOnBaseNode $fluidNode $props
	# Add table
	set filePath [file join [file join [apps::getMyDir "PfemThermic"] examples] tables]
	set fileName ThermicSloshingConvection_DENSITY.txt
	set fullName [file join $filePath $fileName]
	spdAux::UpdateFileField $fullName [$fluidNode selectNodes "./value\[@n = 'TEMPERATURE_vs_DENSITY'\]"]
	
	# Rigid bodies
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='BottomWallBody'\]/value\[@n='BodyType'\]" {v Rigid}
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='BottomWallBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='BottomWallBody'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Bottom_Wall]
    $rigidNode setAttribute ov line
	
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='RightWallBody'\]/value\[@n='BodyType'\]" {v Rigid}
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='RightWallBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='RightWallBody'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Right_Wall]
    $rigidNode setAttribute ov line
	
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='TopWallBody'\]/value\[@n='BodyType'\]" {v Rigid}
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='TopWallBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='TopWallBody'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Top_Wall]
    $rigidNode setAttribute ov line
	
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='LeftWallBody'\]/value\[@n='BodyType'\]" {v Rigid}
	gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='LeftWallBody'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='LeftWallBody'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Left_Wall]
    $rigidNode setAttribute ov line
	
	# Velocity BC
    set fixVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    [customlib::AddConditionGroupOnXPath $fixVelocity "Bottom_Wall"] setAttribute ov line
    [customlib::AddConditionGroupOnXPath $fixVelocity "Right_Wall"]  setAttribute ov line
    [customlib::AddConditionGroupOnXPath $fixVelocity "Top_Wall"]    setAttribute ov line
    [customlib::AddConditionGroupOnXPath $fixVelocity "Left_Wall"]   setAttribute ov line
	
	# Temperature BC
    set fixTemperature "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
	
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Bottom_Wall"]
	set props [list value 373.65 Interval Total constrained 1]
    $fixTemperatureNode setAttribute ov line
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Top_Wall"]
    set props [list value 373.65 Interval Total constrained 1]
	$fixTemperatureNode setAttribute ov line
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Right_Wall"]
    set props [list value 372.65 Interval Total constrained 1]
	$fixTemperatureNode setAttribute ov line
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Left_Wall"]
    set props [list value 372.65 Interval Total constrained 1]
	$fixTemperatureNode setAttribute ov line
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
	# Temperature IC
	set thermalICnode [customlib::AddConditionGroupOnXPath $fixTemperature "Fluid"]
	set props [list value 373.15 Interval Initial constrained 1]
	$thermalICnode setAttribute ov surface
    spdAux::SetValuesOnBaseNode $thermalICnode $props
	
	# Time parameters
    set time_parameters [list StartTime 0.0 EndTime 10.0 DeltaTime 0.005 UseAutomaticDeltaTime No]
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
