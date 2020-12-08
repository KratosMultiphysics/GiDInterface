namespace eval PfemThermic::xml {
    # Namespace variables declaration
    variable dir
}

proc PfemThermic::xml::Init { } {
    variable dir
    Model::InitVariables dir $PfemThermic::dir
	
	Model::ForgetConstitutiveLaws
    Model::getConstitutiveLaws ConstitutiveLaws.xml
	
	Model::ForgetNodalConditions
    Model::getNodalConditions NodalConditions.xml
}

proc PfemThermic::xml::getUniqueName {name} {
    return ${::PfemThermic::prefix}${name}
}

proc PfemThermic::xml::CustomTree { args } {
    set root [customlib::GetBaseRoot]
    spdAux::parseRoutes
	
	########## From PfemFluid custom tree ##########
	foreach node [$root getElementsByTagName container] { if {[$node hasAttribute prefix] && [$node getAttribute prefix] eq "PFEMTHERMIC_"} {set root $node; break} }
	
	foreach node [$root getElementsByTagName value]     { $node setAttribute icon data }
	foreach node [$root getElementsByTagName container] { if {[$node hasAttribute solstratname]} {$node setAttribute icon folder} }
	
	foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMTHERMIC_FreeSurfaceFlux]"]                                                 { $node setAttribute icon select }
	foreach node [[$root parent] selectNodes "[spdAux::getRoute Intervals]/blockdata"]                                                         { $node setAttribute icon select }
	foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_Materials]/blockdata" ]                                              { $node setAttribute icon select }
    foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'linear_solver_settings'\]" ]          { $node setAttribute icon select }
    foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'velocity_linear_solver_settings'\]" ] { $node setAttribute icon select }   
    foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'pressure_linear_solver_settings'\]" ] { $node setAttribute icon select }
    foreach node [[$root parent] selectNodes "[spdAux::getRoute CNVDFFStratSection]/container\[@n = 'linear_solver_settings'\]" ]              { $node setAttribute icon data   }
	foreach node [[$root parent] selectNodes "[spdAux::getRoute CNVDFFStratSection]/container\[@n = 'StratParams'\]" ]                         { $node setAttribute icon data   }
	foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition" ]                                        { $node setAttribute icon select
	                                                                                                                                             $node setAttribute groups_icon groupCreated }
	if {[spdAux::getRoute PFEMFLUID_Loads] ne ""} {
        spdAux::SetValueOnTreeItem icon setLoad PFEMFLUID_Loads 
        foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_Loads]/condition" ] { $node setAttribute icon select $node setAttribute groups_icon groupCreated } }
	
	set inlet_result_node [[$root parent] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'INLET'\]"]
	if { $inlet_result_node ne "" } { $inlet_result_node delete }
	
	if {$Model::SpatialDimension eq "3D"} {
        catch {
            spdAux::SetValueOnTreeItem v -9.81 PFEMFLUID_Gravity Cy  
            spdAux::SetValueOnTreeItem v  0.0  PFEMFLUID_Gravity Cz } }
	
	[[$root parent] selectNodes "/Kratos_data/blockdata\[@n = 'units'\]"] setAttribute icon setUnits
	
	spdAux::SetValueOnTreeItem icon sheets Intervals
	spdAux::SetValueOnTreeItem icon doRestart Restart     
    spdAux::SetValueOnTreeItem icon select Restart RestartOptions
	
	spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEMFLUID_NodalConditions VELOCITY
    spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEMFLUID_NodalConditions PRESSURE
	
	spdAux::SetValueOnTreeItem v Yes NodalResults VELOCITY
	spdAux::SetValueOnTreeItem v No  NodalResults VELOCITY_REACTION
    spdAux::SetValueOnTreeItem v Yes NodalResults PRESSURE
	spdAux::SetValueOnTreeItem v No  NodalResults PRESSURE_REACTION
	spdAux::SetValueOnTreeItem v No  NodalResults DISPLACEMENT
	spdAux::SetValueOnTreeItem v No  NodalResults DISPLACEMENT_REACTION
	
	set heatFlux_result_node [[$root parent] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'HeatFlux2D'\]"]
	if { $heatFlux_result_node ne "" } { $heatFlux_result_node delete }
	set heatSource_result_node [[$root parent] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'HEAT_FLUX'\]"]
	if { $heatSource_result_node ne "" } { $heatSource_result_node delete }
	################################################
	
	ConvectionDiffusion::xml::CustomTree
	
	spdAux::SetValueOnTreeItem v      linear     CNVDFFAnalysisType
	spdAux::SetValueOnTreeItem values transient  CNVDFFSolStrat
	spdAux::SetValueOnTreeItem state  disabled   CNVDFFSolStrat
	spdAux::SetValueOnTreeItem v      No         CNVDFFStratParams line_search
	spdAux::SetValueOnTreeItem state  hidden     CNVDFFStratParams line_search
	spdAux::SetValueOnTreeItem v      1          CNVDFFStratParams echo_level
}

proc PfemThermic::xml::ProcGetElementsValues {domNode args} {
    set names [list ]
    set blockNode [PfemFluid::xml::FindMyBlocknode $domNode]
    set BodyType [get_domnode_attribute [$blockNode selectNodes "value\[@n='BodyType'\]"] v]
    set argums [list ElementType $BodyType]
    set elems [PfemFluid::xml::GetElements $domNode $args]
	
    foreach elem $elems {
        if {[$elem cumple $argums] && [$elem getName] ne "RigidLagrangianElement2D3N"} {
			lappend names [$elem getName]
        }
    }
	
    set values [join $names ","]
    
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]}
    
    return $values
}

PfemThermic::xml::Init
