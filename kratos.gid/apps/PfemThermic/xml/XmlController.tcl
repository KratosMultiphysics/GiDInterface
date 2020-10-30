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
	
	
	
	
	
	
	
	
	foreach node [$root getElementsByTagName container] { if {[$node hasAttribute prefix] && [$node getAttribute prefix] eq "PFEMFLUID_"} {set root $node; break} }
	
	foreach node [$root getElementsByTagName value]     { $node setAttribute icon data }
	foreach node [$root getElementsByTagName container] { if {[$node hasAttribute solstratname]} {$node setAttribute icon folder} }
	
	spdAux::SetValueOnTreeItem icon sheets Intervals
	foreach node [[$root parent] selectNodes "[spdAux::getRoute Intervals]/blockdata"] { $node setAttribute icon select } 
	spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEMTHERMIC_NodalConditions VELOCITY
    spdAux::SetValueOnTreeItem state \[CheckNodalConditionStatePFEM\] PFEMTHERMIC_NodalConditions PRESSURE
	foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMTHERMIC_NodalConditions]/condition" ] { 
        $node setAttribute icon select
	    $node setAttribute groups_icon groupCreated }
	if {[spdAux::getRoute PFEMFLUID_Loads] ne ""} {
        spdAux::SetValueOnTreeItem icon setLoad PFEMFLUID_Loads 
        foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_Loads]/condition" ] { 
            $node setAttribute icon select
            $node setAttribute groups_icon groupCreated } }
    
	foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_Materials]/blockdata" ]                                              { $node setAttribute icon select }
    foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'linear_solver_settings'\]" ]          { $node setAttribute icon select }
    foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'velocity_linear_solver_settings'\]" ] { $node setAttribute icon select }   
    foreach node [[$root parent] selectNodes "[spdAux::getRoute PFEMFLUID_StratSection]/container\[@n = 'pressure_linear_solver_settings'\]" ] { $node setAttribute icon select }
	foreach node [[$root parent] selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]" ] { $node setAttribute icon select }
    foreach node [[$root parent] selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'linear_solver_settings'\]" ] { $node setAttribute icon data }
	foreach node [[$root parent] selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'StratParams'\]" ] { $node setAttribute icon data }
	
	[[$root parent] selectNodes "/Kratos_data/blockdata\[@n = 'units'\]"] setAttribute icon setUnits
	
	#spdAux::SetValueOnTreeItem v Yes NodalResults VELOCITY
    #spdAux::SetValueOnTreeItem v Yes NodalResults PRESSURE
    #spdAux::SetValueOnTreeItem v No  NodalResults DISPLACEMENT
    #spdAux::SetValueOnTreeItem v No  NodalResults VELOCITY_REACTION
    #spdAux::SetValueOnTreeItem v No  NodalResults DISPLACEMENT_REACTION
	
	set inlet_result_node [[$root parent] selectNodes "[spdAux::getRoute NodalResults]/value\[@n = 'INLET'\]"]
	if { $inlet_result_node ne "" } { $inlet_result_node delete }
	
	spdAux::SetValueOnTreeItem icon doRestart Restart     
    spdAux::SetValueOnTreeItem icon select Restart RestartOptions
	
	if {$Model::SpatialDimension eq "3D"} {
        catch {
            spdAux::SetValueOnTreeItem v -9.81 PFEMFLUID_Gravity Cy  
            spdAux::SetValueOnTreeItem v  0.0  PFEMFLUID_Gravity Cz } }
    
	################################################
	
	ConvectionDiffusion::xml::CustomTree
	
	spdAux::SetValueOnTreeItem v      linear    CNVDFFAnalysisType
	spdAux::SetValueOnTreeItem values transient CNVDFFSolStrat
	spdAux::SetValueOnTreeItem state  disabled  CNVDFFSolStrat
	Model::ForgetSolutionStrategy stationary
	
	set result_node [$root selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
	set result_node [$root selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'BodyForce'\]"]
	if { $result_node ne "" } {$result_node delete}
	set result_node [$root selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'TimeParameters'\]"]
	if { $result_node ne "" } {$result_node delete}
	set result_node [$root selectNodes "[spdAux::getRoute CNVDFFStratParams]/value\[@n='line_search'\]"]
	if { $result_node ne "" } {$result_node delete}
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

proc PfemThermic::xml::ProcGetConstitutiveLaws {domNode args} {
    set Elementname [$domNode selectNodes {string(../value[@n='Element']/@v)}]
    set Claws [::Model::GetAvailableConstitutiveLaws $Elementname]
	
    if {[llength $Claws] == 0} {
        set names [list "None"]
    } {
        set names [list ]
        foreach cl $Claws {
		    lappend names [$cl getName]
        }
    }
	
    set values [join $names ","]
	
    if {[get_domnode_attribute $domNode v] eq "" || [get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
    
    return $values
}

PfemThermic::xml::Init
