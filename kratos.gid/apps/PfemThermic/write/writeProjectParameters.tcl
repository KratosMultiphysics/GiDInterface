# Parameters event
proc PfemThermic::write::writeParametersEvent { } {
    write::WriteJSON [getNewParametersDict]
}

proc PfemThermic::write::getNewParametersDict { } {
    PfemFluid::write::CalculateMyVariables
    set projectParametersDict [dict create]
	
    dict set projectParametersDict problem_data         [PfemFluid::write::GetPFEM_ProblemDataDict]
	dict set projectParametersDict solver_settings      [PfemThermic::write::GetSolverSettingsDict]
	dict set projectParametersDict problem_process_list [PfemFluid::write::GetPFEM_ProblemProcessList [PfemThermic::write::GetFreeSurfaceHeatFluxParts] [PfemThermic::write::GetFreeSurfaceThermalFaceParts]]
	dict set projectParametersDict processes            [PfemThermic::write::GetProcessList]
    dict set projectParametersDict output_configuration [write::GetDefaultOutputGiDDict PfemFluid     [spdAux::getRoute Results]]
    dict set projectParametersDict output_configuration result_file_configuration nodal_results       [write::GetResultsByXPathList [spdAux::getRoute NodalResults]]
    dict set projectParametersDict output_configuration result_file_configuration gauss_point_results [write::GetResultsList ElementResults]
	
    return $projectParametersDict
}

proc PfemThermic::write::GetSolverSettingsDict { } {
    # GENERAL SETTINGS
    set solverSettingsDict [dict create]
	
    dict set solverSettingsDict solver_type "pfem_fluid_thermally_coupled_solver"
    dict set solverSettingsDict domain_size [expr [string range [write::getValue nDim] 0 0] ]
	
	# "time_stepping"
    set timeSteppingDict [dict create]
    if {[write::getValue PFEMFLUID_TimeParameters UseAutomaticDeltaTime] eq "Yes"} {
        dict set timeSteppingDict automatic_time_step "true"
     } else {
        dict set timeSteppingDict automatic_time_step "false"
    }
    dict set timeSteppingDict time_step [write::getValue PFEMFLUID_TimeParameters [dict get $::PfemFluid::write::Names DeltaTime]]
    dict set solverSettingsDict time_stepping $timeSteppingDict
	
	# FLUID / THERMIC SETTINGS
	dict set solverSettingsDict fluid_solver_settings   [PfemFluid::write::GetPFEM_SolverSettingsDict]
	dict set solverSettingsDict thermal_solver_settings [PfemThermic::write::GetThermicSolverSettingsDict]
}

proc PfemThermic::write::GetThermicSolverSettingsDict { } {
    set thermicSolverSettingsDict [dict create]
	
	# General data
	dict set thermicSolverSettingsDict solver_type               "transient"
	dict set thermicSolverSettingsDict analysis_type             [write::getValue CNVDFFAnalysisType]
	dict set thermicSolverSettingsDict time_integration_method   "implicit"
	dict set thermicSolverSettingsDict model_part_name           [ConvectionDiffusion::write::GetAttribute model_part_name]
    dict set thermicSolverSettingsDict domain_size               [expr [string range [write::getValue nDim] 0 0]]
	dict set thermicSolverSettingsDict reform_dofs_at_each_step  "true"
	
	# Import data
	set materialsDict [dict create]
	dict set materialsDict materials_filename [ConvectionDiffusion::write::GetAttribute materials_file]
    dict set thermicSolverSettingsDict material_import_settings  $materialsDict
	
	# Solution Strategy and Solvers Parameters
	set thermicSolverSettingsDict [dict merge $thermicSolverSettingsDict [write::getSolutionStrategyParametersDict CNVDFFSolStrat CNVDFFScheme CNVDFFStratParams]]
    set thermicSolverSettingsDict [dict merge $thermicSolverSettingsDict [write::getSolversParametersDict ConvectionDiffusion]]
	
	# "problem_domain_sub_model_part_list"
	set parts [list ]
	foreach body_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata"] {
	    if {[get_domnode_attribute $body_node state] ne "hidden"} {
			foreach part_node [$body_node selectNodes "./condition/group"] {
                lappend parts [write::getSubModelPartId "Parts" [$part_node @n]]
            }
		}
	}
	dict set thermicSolverSettingsDict problem_domain_sub_model_part_list $parts
	
	# "processes_sub_model_part_list"
	dict set thermicSolverSettingsDict processes_sub_model_part_list [write::getSubModelPartNames "PFEMFLUID_NodalConditions" "PFEMFLUID_Loads"]
	
	return $thermicSolverSettingsDict
}

proc PfemThermic::write::GetProcessList { } {
	set processes [dict create]
	
	# "initial_conditions_process_list"
	dict set processes initial_conditions_process_list [write::getConditionsParametersDict [ConvectionDiffusion::write::GetAttribute nodal_conditions_un] "Nodal"]
	
	# "constraints_process_list"
	set group_constraints   [write::getConditionsParametersDict PFEMFLUID_NodalConditions "Nodal"]
    set body_constraints    [PfemFluid::write::getBodyConditionsParametersDict PFEMFLUID_NodalConditions "Nodal"]
	set thermic_constraints [write::getConditionsParametersDict [ConvectionDiffusion::write::GetAttribute conditions_un]]
	set other_constraints   [write::getConditionsParametersDict PFEMFLUID_NodalConditions]
	dict set processes constraints_process_list [concat $group_constraints $body_constraints $thermic_constraints $other_constraints]
	
	# "list_other_processes"
	#dict set processes list_other_processes [ConvectionDiffusion::write::getBodyForceProcessDictList]
	
	# "loads_process_list"
	dict set processes loads_process_list [write::getConditionsParametersDict PFEMFLUID_Loads]
	
	# "auxiliar_process_list"
    #dict set processes auxiliar_process_list [PfemThermic::write::getFreeSurfaceFluxProcessDictList]
	
	return $processes
}

proc PfemThermic::write::GetFreeSurfaceHeatFluxParts {} {
    set root [customlib::GetBaseRoot]
    set listOfProcessedGroups [list ]
    set groups [list ]
    set xp1 "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition/group"
    set xp2 "[spdAux::getRoute PFEMFLUID_NodalConditions]/group"
    set grs [$root selectNodes $xp1]
    if {$grs ne ""} {lappend groups {*}$grs}
    set grs [$root selectNodes $xp2]
    if {$grs ne ""} {lappend groups {*}$grs}
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        if {[Model::getNodalConditionbyId $cid] ne "" || [Model::getCondition $cid] ne "" || [string first Parts $cid] >= 0 } {
			if {$cid eq "FreeSurfaceHeatFlux2D" || $cid eq "FreeSurfaceHeatFlux3D"} {
				set gname [::write::getSubModelPartId $cid $groupName]
				if {$gname ni $listOfProcessedGroups} {lappend listOfProcessedGroups $gname}
			}
        }
    }
    return $listOfProcessedGroups
}

proc PfemThermic::write::GetFreeSurfaceThermalFaceParts {} {
    set root [customlib::GetBaseRoot]
    set listOfProcessedGroups [list ]
    set groups [list ]
    set xp1 "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition/group"
    set xp2 "[spdAux::getRoute PFEMFLUID_NodalConditions]/group"
    set grs [$root selectNodes $xp1]
    if {$grs ne ""} {lappend groups {*}$grs}
    set grs [$root selectNodes $xp2]
    if {$grs ne ""} {lappend groups {*}$grs}
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        if {[Model::getNodalConditionbyId $cid] ne "" || [Model::getCondition $cid] ne "" || [string first Parts $cid] >= 0 } {
			if {$cid eq "FreeSurfaceThermalFace2D" || $cid eq "FreeSurfaceThermalFace3D"} {
				set gname [::write::getSubModelPartId $cid $groupName]
				if {$gname ni $listOfProcessedGroups} {lappend listOfProcessedGroups $gname}
			}
        }
    }
    return $listOfProcessedGroups
}

proc PfemThermic::write::getFreeSurfaceFluxProcessDictList {} {
    set ret [list ]
	set value [write::getValue PFEMTHERMIC_FreeSurfaceFlux]
	if {$value != 0.0} {
		set model_part_name [PfemFluid::write::GetAttribute model_part_name]
		
		set pdict [dict create]
		dict set pdict "python_module" "assign_scalar_variable_process"
		dict set pdict "kratos_module" "KratosMultiphysics"
		dict set pdict "process_name" "AssignScalarVariableProcess"
		
		set params [dict create]
		# Free_Surface is a tag name chosen to represent the free surface;
		# It must be the same name of the modelpart written in the sub_model_part_list of update_conditions_on_free_surface
		set group_name  "Free_Surface"
		dict set params "model_part_name" $model_part_name.$group_name
		dict set params "variable_name" "FACE_HEAT_FLUX"
		dict set params "constrained" false
		dict set params "value" $value
		dict set pdict  "Parameters" $params
		
		lappend ret $pdict
     } else {
        set ret "[]"
    }
	return $ret
}