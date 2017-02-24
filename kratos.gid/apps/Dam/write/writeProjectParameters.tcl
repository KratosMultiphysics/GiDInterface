### Project Parameters
proc Dam::write::getParametersDict { } {
    
    set projectParametersDict [dict create]
    
    ### Problem data
    ### Create section
    set problemDataDict [dict create]
    
    ### Add items to section
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set problemDataDict problem_name $model_name
    dict set problemDataDict model_part_name "MainModelPart"
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set problemDataDict domain_size $nDim
    dict set problemDataDict start_time [write::getValue DamTimeParameters StartTime]
    dict set problemDataDict end_time [write::getValue DamTimeParameters EndTime]
    dict set problemDataDict time_step [write::getValue DamTimeParameters DeltaTime]
    set paralleltype [write::getValue ParallelType]
    dict set generalDataDict "parallel_type" $paralleltype
    if {$paralleltype eq "OpenMP"} {
        set nthreads [write::getValue Parallelization OpenMPNumberOfThreads]
        dict set problemDataDict parallel_type "OpenMP"
        dict set problemDataDict number_of_threads $nthreads
    } else {
        dict set problemDataDict parallel_type "MPI"
        dict set problemDataDict number_of_threads 1
    }
    dict set problemDataDict time_scale [write::getValue DamTimeParameters TimeScale]
    
    ### Add section to document
    dict set projectParametersDict problem_data $problemDataDict
    
    ### Solver Data   
    set solversettingsDict [dict create]
    
    ### Preguntar el solver haciendo los ifs correspondientes
    set damTypeofProblem [write::getValue DamTypeofProblem]
    if {$paralleltype eq "OpenMP"} {
		if {$damTypeofProblem eq "Mechanical"} {
			dict set solversettingsDict solver_type "dam_mechanical_solver"
		} elseif {$damTypeofProblem eq "Thermo-Mechanical"} {
			dict set solversettingsDict solver_type "dam_thermo_mechanic_solver"
		} elseif {$damTypeofProblem eq "UP_Mechanical"} {
			dict set solversettingsDict solver_type "dam_UP_mechanical_solver"
		} elseif {$damTypeofProblem eq "UP_Thermo-Mechanical"} {
			dict set solversettingsDict solver_type "dam_UP_thermo_mechanic_solver"
		} else {
			dict set solversettingsDict solver_type "dam_P_solver"
		}
	} else {
		if {$damTypeofProblem eq "Mechanical"} {
			dict set solversettingsDict solver_type "dam_MPI_mechanical_solver"
		} elseif {$damTypeofProblem eq "Thermo-Mechanical"} {
			dict set solversettingsDict solver_type "dam_MPI_thermo_mechanic_solver"
		} elseif {$damTypeofProblem eq "UP_Mechanical"} {
			dict set solversettingsDict solver_type "dam_MPI_UP_mechanical_solver"
		} elseif {$damTypeofProblem eq "UP_Thermo-Mechanical"} {
			dict set solversettingsDict solver_type "dam_MPI_thermo_mechanic_solver"
		} else {
			dict set solversettingsDict solver_type "dam_MPI_P_solver"
		}
	}
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename $model_name
    dict set modelDict input_file_label 0
    dict set solversettingsDict model_import_settings $modelDict
    dict set solversettingsDict echo_level 1
	dict set solversettingsDict buffer_size 2
    dict set solversettingsDict processes_sub_model_part_list [write::getSubModelPartNames "DamNodalConditions" "DamLoads"]
    
    ## Default Values
    set MechanicalSolutionStrategyUN "DamSolStrat"
    set MechanicalSchemeUN "DamScheme"
    set MechanicalDataUN "DamMechanicalData"
    set MechanicalDataParametersUN "DamMechanicalDataParameters"
    
    if {$damTypeofProblem eq "Thermo-Mechanical" } {
        
		dict set solversettingsDict reference_temperature [write::getValue DamThermalReferenceTemperature]
		dict set solversettingsDict processes_sub_model_part_list [write::getSubModelPartNames "DamNodalConditions" "DamLoads"]
	
		set thermalsettingDict [dict create]
		dict set thermalsettingDict echo_level [write::getValue DamThermalEcholevel]
		dict set thermalsettingDict reform_dofs_at_each_step [write::getValue DamThermalReformsSteps]
		dict set thermalsettingDict clear_storage [write::getValue DamThermalClearStorage]
		dict set thermalsettingDict compute_reactions [write::getValue DamThermalComputeReactions]
		dict set thermalsettingDict move_mesh_flag [write::getValue DamThermalMoveMeshFlag]
		dict set thermalsettingDict compute_norm_dx_flag [write::getValue DamThermalComputeNormDx]
		dict set thermalsettingDict theta_scheme [write::getValue DamThermalScheme]
        dict set thermalsettingDict block_builder [write::getValue DamThermalBlockBuilder]
		
        ## Adding linear solver for thermal part
		set thermalsettingDict  [dict merge $thermalsettingDict [::Dam::write::getSolversParametersDict Dam DamSolStratTherm "DamThermo-Mechanical-ThermData"] ]
        dict set thermalsettingDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
        
        ## Adding thermal solver settings to solver settings
        dict set solversettingsDict thermal_solver_settings $thermalsettingDict
        
        ## Resetting Variables for the mechanical problem according to the selected problem
        set MechanicalDataUN "DamThermo-Mechanical-MechData"
        set MechanicalDataParametersUN "DamThermo-Mechanical-MechDataParameters"
	}
	
	if {$damTypeofProblem eq "UP_Thermo-Mechanical" } {
        
    	dict set solversettingsDict reference_temperature [write::getValue DamThermalUPReferenceTemperature]
		dict set solversettingsDict processes_sub_model_part_list [write::getSubModelPartNames "DamNodalConditions" "DamLoads"]
	
		set UPthermalsettingDict [dict create]
		dict set UPthermalsettingDict echo_level [write::getValue DamThermalUPEcholevel]
		dict set UPthermalsettingDict reform_dofs_at_each_step [write::getValue DamThermalUPReformsSteps]
		dict set UPthermalsettingDict clear_storage [write::getValue DamThermalUPClearStorage]
		dict set UPthermalsettingDict compute_reactions [write::getValue DamThermalUPComputeReactions]
		dict set UPthermalsettingDict move_mesh_flag [write::getValue DamThermalUPMoveMeshFlag]
		dict set UPthermalsettingDict compute_norm_dx_flag [write::getValue DamThermalUPComputeNormDx]
		dict set UPthermalsettingDict theta_scheme [write::getValue DamThermalUPScheme]
        dict set UPthermalsettingDict block_builder [write::getValue DamThermalUPBlockBuilder]

        ## Adding linear solver for thermal part
		set UPthermalsettingDict  [dict merge $UPthermalsettingDict [::Dam::write::getSolversParametersDict Dam DamSolStratThermUP "DamUPThermo-Mechanical-ThermData"] ]
        dict set UPthermalsettingDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
       
        ## Adding UP thermal solver settings to solver settings
        dict set solversettingsDict thermal_solver_settings $UPthermalsettingDict
        
        ## Resetting Variables for the mechanical problem according to the selected problem
        set MechanicalDataUN "DamUPThermo-Mechanical-MechData"
        set MechanicalDataParametersUN "DamUPThermo-Mechanical-MechDataParameters"
	}
	 
	if {$damTypeofProblem eq "Acoustic"} {  
        
		### Acostic Settings
		set acousticSolverSettingsDict [dict create]
		dict set acousticSolverSettingsDict strategy_type "Newton-Raphson"
		dict set acousticSolverSettingsDict scheme_type "Newmark"
		dict set acousticSolverSettingsDict convergence_criterion [write::getValue DamAcousticConvergencecriterion]
		dict set acousticSolverSettingsDict residual_relative_tolerance [write::getValue DamAcousticRelTol]
		dict set acousticSolverSettingsDict residual_absolute_tolerance [write::getValue DamAcousticAbsTol]
		dict set acousticSolverSettingsDict max_iteration [write::getValue DamAcousticMaxIteration]
		dict set acousticSolverSettingsDict move_mesh_flag [write::getValue DamAcousticMoveMeshFlag]
		
		set acousticlinearDict [dict create]
		dict set acousticlinearDict solver_type [write::getValue DamAcousticSolver]
		dict set acousticlinearDict max_iteration [write::getValue DamAcousticMaxIter]
		dict set acousticlinearDict tolerance [write::getValue DamAcousticTolerance]
		dict set acousticlinearDict verbosity [write::getValue DamAcousticVerbosity]
		dict set acousticlinearDict GMRES_size [write::getValue DamAcousticGMRESSize]
        
		## Adding linear solver settings to acoustic solver
		dict set acousticSolverSettingsDict linear_solver_settings $acousticlinearDict

        ## Adding Acoustic solver settings to solver settings
		dict set solversettingsDict acoustic_solver_settings $acousticSolverSettingsDict
        
    } elseif {$damTypeofProblem eq "UP_Mechanical"} {
        
        ### UP Mechanical Settings
		set UPmechanicalSolverSettingsDict [dict create]
		dict set UPmechanicalSolverSettingsDict solution_type [write::getValue DamUPMechaSoluType]
		dict set UPmechanicalSolverSettingsDict strategy_type [write::getValue DamSolStrat]
		dict set UPmechanicalSolverSettingsDict scheme_type [write::getValue DamScheme]
		set UPmechanicalSolverSettingsDict [dict merge $UPmechanicalSolverSettingsDict [::write::getSolutionStrategyParametersDict $MechanicalSolutionStrategyUN $MechanicalSchemeUN "DamUP_MechanicalDataParameters"] ]
        ### Damage Variables
        set typeofDamage [write::getValue DamUPMechaDamageType]
        if {$typeofDamage eq "NonLocal"} { 
            dict set UPmechanicalSolverSettingsDict nonlocal_damage true
            dict set UPmechanicalSolverSettingsDict characteristic_length [write::getValue DamUPMechaDamageTypeLength]
            dict set UPmechanicalSolverSettingsDict search_neighbours_step [write::getValue DamUPMechaDamageTypeSearch]
        } else {
            dict set UPmechanicalSolverSettingsDict nonlocal_damage false
        }
        
        ### Adding solvers parameters
        set UPmechanicalSolverSettingsDict [dict merge $UPmechanicalSolverSettingsDict [::Dam::write::getSolversParametersDict Dam $MechanicalSolutionStrategyUN "DamUP_MechanicalData"] ]
        ### Adding domains to the problem
        set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [Dam::write::DefinitionDomains] ]
		### Add section to document
        dict set solversettingsDict mechanical_solver_settings $UPmechanicalSolverSettingsDict 
        
    } else {
	    ### Mechanical Settings
		set mechanicalSolverSettingsDict [dict create]
		dict set mechanicalSolverSettingsDict solution_type [write::getValue DamMechaSoluType]
		dict set mechanicalSolverSettingsDict strategy_type [write::getValue DamSolStrat]
		dict set mechanicalSolverSettingsDict scheme_type [write::getValue DamScheme]
		set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [::write::getSolutionStrategyParametersDict $MechanicalSolutionStrategyUN $MechanicalSchemeUN $MechanicalDataParametersUN] ]
        ### Damage Variables
        set typeofDamage [write::getValue DamMechaDamageType]
        if {$typeofDamage eq "NonLocal"} { 
            dict set mechanicalSolverSettingsDict nonlocal_damage true
            dict set mechanicalSolverSettingsDict characteristic_length [write::getValue DamMechaDamageTypeLength]
            dict set mechanicalSolverSettingsDict search_neighbours_step [write::getValue DamMechaDamageTypeSearch]
        } else {
            dict set mechanicalSolverSettingsDict nonlocal_damage false
        }
        
        ### Adding solvers parameters
        set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [::Dam::write::getSolversParametersDict Dam $MechanicalSolutionStrategyUN $MechanicalDataUN] ]
		### Add section to document
        set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [Dam::write::DefinitionDomains] ]
        ### Add section to document
		dict set solversettingsDict mechanical_solver_settings $mechanicalSolverSettingsDict
        
	}
    dict set projectParametersDict solver_settings $solversettingsDict
    
    ### GiD output configuration
    dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]
    
    set nodal_process_list [write::getConditionsParametersDict DamNodalConditions "Nodal"]
    set load_process_list [write::getConditionsParametersDict DamLoads ]
    dict set projectParametersDict constraints_process_list [Dam::write::ChangeFileNameforTableid $nodal_process_list]
    dict set projectParametersDict loads_process_list [Dam::write::ChangeFileNameforTableid $load_process_list]
       
    return $projectParametersDict

}
    #~ set damTypeofProblem [write::getValue DamTypeofProblem]
    #~ if {$damTypeofProblem eq "Thermo-Mechanical"} {
        #~ set diffusionSolverSettingsDict [dict create]
        #~ set variablesDict [dict create] 
        #~ dict set variablesDict unknown_variable "KratosMultiphysics.TEMPERATURE"
        #~ dict set variablesDict diffusion_variable "KratosMultiphysics.CONDUCTIVITY"
        #~ dict set variablesDict specific_heat_variable "KratosMultiphysics.SPECIFIC_HEAT"
        #~ dict set variablesDict density_variable "KratosMultiphysics.DENSITY"
        #~ dict set diffusionSolverSettingsDict variables $variablesDict
        #~ set thermal_sol_strat [write::getValue DamSolStratTherm]
        #~ dict set diffusionSolverSettingsDict temporal_scheme [write::getValue DamMechanicalSchemeTherm]
        #~ dict set diffusionSolverSettingsDict reference_temperature [write::getValue DamReferenceTemperature]
        
    #~ ### Add section to document
    #~ dict set projectParametersDict diffusion_settings $diffusionSolverSettingsDict
    #~ }     
       
    ### Mechanical Settings
    #~ set mechanicalSolverSettingsDict [dict create]
    #~ dict set mechanicalSolverSettingsDict solver_type "dam_new_mechanical_solver"
    #~ set modelDict [dict create]
    #~ dict set modelDict input_type "mdpa"
    #~ dict set modelDict input_filename $model_name
    #~ dict set mechanicalSolverSettingsDict model_import_settings $modelDict
    #~ dict set mechanicalSolverSettingsDict solution_type [write::getValue DamSoluType]
    #~ dict set mechanicalSolverSettingsDict analysis_type [write::getValue DamAnalysisType]
    #~ dict set mechanicalSolverSettingsDict strategy_type [write::getValue DamSolStrat]
    #~ dict set mechanicalSolverSettingsDict scheme_type [write::getValue DamScheme]
    #~ set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [write::getSolutionStrategyParametersDict] ]
    #~ dict set mechanicalSolverSettingsDict type_of_builder [write::getValue DamTypeofbuilder]
    #~ dict set mechanicalSolverSettingsDict type_of_solver [write::getValue DamTypeofsolver]
    #~ set typeofsolver [write::getValue DamTypeofsolver]
    #~ if {$typeofsolver eq "Direct"} {
        #~ dict set mechanicalSolverSettingsDict solver_class [write::getValue DamDirectsolver]
    #~ } elseif {$typeofsolver eq "Iterative"} {
        #~ dict set mechanicalSolverSettingsDict solver_class [write::getValue DamIterativesolver]
    #~ }
    #~ ### Add section to document
    #~ dict set projectParametersDict mechanical_settings $mechanicalSolverSettingsDict
    
    ### Boundary conditions processes
    #~ set body_part_list [list ]
    #~ set joint_part_list [list ]
    #~ set mat_dict [write::getMatDict]
    #~ foreach part_name [dict keys $mat_dict] {
        #~ if {[[Model::getElement [dict get $mat_dict $part_name Element]] getAttribute "ElementType"] eq "Joint"} {
            #~ lappend joint_part_list [write::getMeshId Parts $part_name]
        #~ } {
            #~ lappend body_part_list [write::getMeshId Parts $part_name]
        #~ }
    #~ }
    #~ dict set projectParametersDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
    #~ dict set projectParametersDict problem_domain_body_sub_model_part_list $body_part_list
    #~ dict set projectParametersDict problem_domain_joint_sub_model_part_list $joint_part_list
    #~ dict set projectParametersDict processes_sub_model_part_list [write::getSubModelPartNames "DamNodalConditions" "DamLoads"]
    #~ set nodal_process_list [write::getConditionsParametersDict DamNodalConditions "Nodal"]
    #~ set load_process_list [write::getConditionsParametersDict DamLoads ]
    
    #~ dict set projectParametersDict nodal_processes_sub_model_part_list [Dam::write::ChangeFileNameforTableid $nodal_process_list]
    #~ dict set projectParametersDict load_processes_sub_model_part_list [Dam::write::ChangeFileNameforTableid $load_process_list]
    #~ set strategytype [write::getValue DamSolStrat]
    #~ if {$strategytype eq "Arc-length"} {
        #~ dict set projectParametersDict loads_sub_model_part_list [write::getSubModelPartNames "DamLoads"]
        #~ dict set projectParametersDict loads_variable_list [Dam::write::getVariableParametersDict DamLoads]
    #~ }
    #~ ### GiD output configuration
    #~ dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]
    #~ return $projectParametersDict


proc Dam::write::DefinitionDomains { } {
    
 ### Boundary conditions processes
    set domainsDict [dict create]
 
    set body_part_list [list ]
    set joint_part_list [list ]
    set mat_dict [write::getMatDict]
    foreach part_name [dict keys $mat_dict] {
        if {[[Model::getElement [dict get $mat_dict $part_name Element]] getAttribute "ElementType"] eq "Joint"} {
            lappend joint_part_list [write::getMeshId Parts $part_name]
        } {
            lappend body_part_list [write::getMeshId Parts $part_name]
        }
    }
    dict set domainsDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
    dict set domainsDict body_domain_sub_model_part_list $body_part_list
    #~ dict set domainsDict problem_domain_joint_sub_model_part_list $joint_part_list
    
    set loads_sub_model_part_list [list]
    set loads_variable_list [list]
    set strategytype [write::getValue DamSolStrat]
    if {$strategytype eq "Arc-length"} {
        #~ dict set projectParametersDict loads_sub_model_part_list [write::getSubModelPartNames "DamLoads"]
        #~ dict set projectParametersDict loads_variable_list [Dam::write::getVariableParametersDict DamLoads]
       lappend loads_sub_model_part_list [write::getSubModelPartNames "DamLoads"]
       lappend loads_variable_list [Dam::write::getVariableParametersDict DamLoads]
    }
    
    dict set domainsDict loads_sub_model_part_list $loads_sub_model_part_list
    dict set domainsDict loads_variable_list $loads_variable_list
    
    return $domainsDict
    
}

proc Dam::write::ChangeFileNameforTableid { processList } {
    set returnList [list ]
    foreach nodalProcess $processList {
        set processName [dict get $nodalProcess process_name]
        set process [::Model::GetProcess $processName]
        set params [$process getInputs]
        foreach {paramName param} $params {
            if {[$param getType] eq "tablefile" && [dict exists $nodalProcess Parameters $paramName] } {
                set filename [dict get $nodalProcess Parameters $paramName]
                set value [Dam::write::GetTableidFromFileid $filename]
                dict set nodalProcess Parameters $paramName $value
            }
        }
        lappend returnList $nodalProcess
    }
    return $returnList
}

proc Dam::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::WriteJSON $projectParametersDict
}

proc Dam::write::GetDefaultOutputDict {} {
    set outputDict [dict create]
    set resultDict [dict create]
    
    set GiDPostDict [dict create]
    dict set GiDPostDict GiDPostMode                [write::getValue Results GiDPostMode]
    dict set GiDPostDict WriteDeformedMeshFlag      [write::getValue Results GiDWriteMeshFlag]
    dict set GiDPostDict WriteConditionsFlag        [write::getValue Results GiDWriteConditionsFlag]
    dict set GiDPostDict MultiFileFlag              [write::getValue Results GiDMultiFileFlag]
    dict set resultDict gidpost_flags $GiDPostDict
    
    dict set resultDict file_label [write::getValue Results FileLabel] 
    dict set resultDict output_control_type [write::getValue Results OutputControlType] 
    set output_control [write::getValue DamOutputControlType]
    if {$output_control eq "step"} {
        dict set resultDict output_frequency [write::getValue Results OutputDeltaStep]
    } else {
        dict set resultDict output_frequency [write::getValue Results OutputDeltaTime]
    }
    dict set resultDict body_output [write::getValue Results BodyOutput] 
    dict set resultDict node_output [write::getValue Results NodeOutput] 
    dict set resultDict skin_output [write::getValue Results SkinOutput]
    dict set resultDict plane_output [write::GetResultsList Results CutPlanes]   
    dict set resultDict nodal_results [write::GetResultsList NodalResults]
    dict set resultDict gauss_point_results [write::GetResultsList ElementResults]
    
    dict set outputDict "result_file_configuration" $resultDict
    return $outputDict
}

 # appid Dam solStratUN DamSolStrat problem_base_UN DamMechanicalData
proc Dam::write::getSolversParametersDict { {appid "Dam"} {solStratUN ""} {problem_base_UN ""}} {
    #W "Params -> $appid $solStratUN $problem_base_UN"
    set solstratName [write::getValue $solStratUN]
    #W "sol strat name $solstratName"
    set sol [::Model::GetSolutionStrategy $solstratName]
    set solverSettingsDict [dict create]
    foreach se [$sol getSolversEntries] {
        set solverEntryDict [dict create]
        set base_node_path [spdAux::getRoute $problem_base_UN]
        set containers [[[customlib::GetBaseRoot] selectNodes $base_node_path] getElementsByTagName "container"]
        foreach cont $containers {
            #W [$cont @n]
            if {[$cont hasAttribute un]} {
                set cont_un [$cont @un]
                set active_solver_entry [apps::getAppUniqueName $appid "$solstratName[$se getName]"]
                #W "cont_un : $cont_un"
                #W "active_solver_entry : $active_solver_entry"
                if {$cont_un eq $active_solver_entry} {
                    set base_node $cont
                    break
                }
            }
        }
        #W [$base_node asXML]
        #set un [apps::getAppUniqueName $appid "$solstratName[$se getName]"]
        if {$base_node ne ""} {
            set solver_node [$base_node selectNodes "./value\[@n='Solver'\]"]
            set solverName [write::getValueByNode $solver_node]
            if {$solverName ni [list "Default" "AutomaticOpenMP" "AutomaticMPI"]} {
                dict set solverEntryDict solver_type $solverName
                set solver [::Model::GetSolver $solverName]
                foreach {n in} [$solver getInputs] {
                    # JG temporal, para la precarga de combos
                    if {[$in getType] ni [list "bool" "integer" "double"]} {
                        set v ""
                        catch {set v [write::getValueByNode [$base_node selectNodes "./value\[@n='$n'\]"]]}
                        if {$v eq ""} {set v [write::getValueByNode [$base_node selectNodes "./value\[@n='$n'\]"]]}
                        dict set solverEntryDict $n $v
                    } {
                        dict set solverEntryDict $n [write::getValueByNode [$base_node selectNodes "./value\[@n='$n'\]"]]
                    }
                }
                dict set solverSettingsDict [$se getName] $solverEntryDict
            }
        }
        unset solverEntryDict
    }
    return $solverSettingsDict
}
