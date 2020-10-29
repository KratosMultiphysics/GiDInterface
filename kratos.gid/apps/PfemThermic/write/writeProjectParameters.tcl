# Parameters event
proc PfemThermic::write::writeParametersEvent { } {
    write::WriteJSON [getNewParametersDict]
}

proc PfemThermic::write::getNewParametersDict { } {
    PfemFluid::write::CalculateMyVariables
    set projectParametersDict [dict create]
	
    dict set projectParametersDict problem_data         [PfemFluid::write::GetPFEM_ProblemDataDict]
	dict set projectParametersDict solver_settings      [PfemThermic::write::GetSolverSettingsDict]
	dict set projectParametersDict problem_process_list [PfemFluid::write::GetPFEM_ProblemProcessList]
	dict set projectParametersDict processes            [PfemThermic::write::GetProcessList]
    dict set projectParametersDict output_configuration [write::GetDefaultOutputGiDDict PfemFluid     [spdAux::getRoute Results]]
    dict set projectParametersDict output_configuration result_file_configuration nodal_results       [write::GetResultsByXPathList [spdAux::getRoute NodalResults]]
    dict set projectParametersDict output_configuration result_file_configuration gauss_point_results [write::GetResultsList ElementResults]
	
    return $projectParametersDict
}

proc PfemThermic::write::GetSolverSettingsDict { } {
    # GENERAL SETTINGS
    set solverSettingsDict [dict create]
	
    dict set solverSettingsDict solver_type        "pfem_fluid_thermally_coupled_solver"
    dict set solverSettingsDict domain_size        [expr [string range [write::getValue nDim] 0 0] ]
	dict set solverSettingsDict materials_filename "PFEMThermicMaterials.json"
	
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
	dict set thermicSolverSettingsDict solver_type               [write::getValue CNVDFFSolStrat]
	dict set thermicSolverSettingsDict analysis_type             [write::getValue CNVDFFAnalysisType]
	dict set thermicSolverSettingsDict time_integration_method   "implicit"
	dict set thermicSolverSettingsDict model_part_name           [ConvectionDiffusion::write::GetAttribute model_part_name]
	dict set thermicSolverSettingsDict computing_model_part_name "thermal_computing_domain"
    dict set thermicSolverSettingsDict domain_size               [expr [string range [write::getValue nDim] 0 0]]
	dict set thermicSolverSettingsDict reform_dofs_at_each_step  "true"
	
	# Import data
	set modelDict     [dict create]
	set materialsDict [dict create]
	
	dict set modelDict     input_type         "use_input_model_part"
    dict set modelDict     input_filename     "unknown_name"
	dict set materialsDict materials_filename [ConvectionDiffusion::write::GetAttribute materials_file]
	
    dict set thermicSolverSettingsDict model_import_settings     $modelDict
    dict set thermicSolverSettingsDict material_import_settings  $materialsDict
	
	# Solution Strategy and Solvers Parameters
	set thermicSolverSettingsDict [dict merge $thermicSolverSettingsDict [write::getSolutionStrategyParametersDict CNVDFFSolStrat CNVDFFScheme CNVDFFStratParams]]
    set thermicSolverSettingsDict [dict merge $thermicSolverSettingsDict [write::getSolversParametersDict ConvectionDiffusion]]
	
	# "problem_domain_sub_model_part_list"
	set parts [list ]
	foreach body_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata"] {
	    if {[get_domnode_attribute $body_node state] ne "hidden" &&
		    [get_domnode_attribute [$body_node selectNodes ".//value\[@n='BodyType'\]"] v] eq "Fluid"} {
			foreach part_node [$body_node selectNodes "./condition/group"] {
                lappend parts [write::getSubModelPartId "Parts" [$part_node @n]]
            }
		}
	}
	dict set thermicSolverSettingsDict problem_domain_sub_model_part_list $parts
	
	# "processes_sub_model_part_list"
	dict set thermicSolverSettingsDict processes_sub_model_part_list [write::getSubModelPartNames [ConvectionDiffusion::write::GetAttribute nodal_conditions_un] [ConvectionDiffusion::write::GetAttribute conditions_un] ]
	
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
	dict set processes constraints_process_list [concat $group_constraints $body_constraints $thermic_constraints]
	
	# "list_other_processes"
	#dict set processes list_other_processes [ConvectionDiffusion::write::getBodyForceProcessDictList]
	
	# "loads_process_list"
	dict set processes loads_process_list [write::getConditionsParametersDict PFEMFLUID_Loads]
	
	# "auxiliar_process_list"
    dict set processes auxiliar_process_list []
	
	return $processes
}
