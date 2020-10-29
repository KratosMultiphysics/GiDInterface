namespace eval PfemThermic::xml {
    # Namespace variables declaration
    variable dir
}

proc PfemThermic::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $PfemThermic::dir
	
	Model::ForgetConstitutiveLaws
    Model::getConstitutiveLaws ConstitutiveLaws.xml
}

proc PfemThermic::xml::getUniqueName {name} {
    return ${::PfemThermic::prefix}${name}
}

proc PfemThermic::xml::CustomTree { args } {
    PfemFluid::xml::CustomTree
	ConvectionDiffusion::xml::CustomTree
	
    spdAux::SetValueOnTreeItem values Fluid     PFEMFLUID_DomainType
	spdAux::SetValueOnTreeItem values transient CNVDFFSolStrat
	spdAux::SetValueOnTreeItem state  disabled  CNVDFFSolStrat
	
	set root [customlib::GetBaseRoot]
	
	set result_node [$root selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'ParallelType'\]"]
	if { $result_node ne "" } {$result_node delete}
	
	set result_node [$root selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'BodyForce'\]"]
	if { $result_node ne "" } {$result_node delete}
	
	set result_node [$root selectNodes "[spdAux::getRoute CNVDFFSolutionParameters]/container\[@n = 'TimeParameters'\]"]
	if { $result_node ne "" } {$result_node delete}
}

proc PfemThermic::xml::ProcGetBodyTypeValues {domNode args} {
    set values "Fluid,Rigid"
    return $values
}

proc PfemThermic::xml::ProcCheckNodalConditionState {domNode args} {
    set fluid_exclusive_conditions [list "VELOCITY" "INLET" "PRESSURE"]
    set current_condition [$domNode @n]
	if {$current_condition ni $fluid_exclusive_conditions} {
        return hidden
    }
    return normal
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
