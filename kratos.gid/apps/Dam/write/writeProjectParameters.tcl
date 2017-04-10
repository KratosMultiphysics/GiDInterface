### Project Parameters
proc Dam::write::getParametersDict { } {
    
    set projectParametersDict [dict create]
    
    ### Problem data
    ### Create section
    set problemDataDict [dict create]
    set damTypeofProblem [write::getValue DamTypeofProblem]
    
    ### Add items to section
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set problemDataDict problem_name $model_name
    dict set problemDataDict model_part_name "MainModelPart"
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set problemDataDict domain_size $nDim
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
    if {$damTypeofProblem eq "Modal-Analysis"} {
        dict set projectParametersDict problem_data $problemDataDict
    } else {
        dict set problemDataDict start_time [write::getValue DamTimeParameters StartTime]
        dict set problemDataDict end_time [write::getValue DamTimeParameters EndTime]
        dict set problemDataDict time_step [write::getValue DamTimeParameters DeltaTime]
        dict set problemDataDict time_scale [write::getValue DamTimeParameters TimeScale]
        dict set problemDataDict streamlines_utility [Dam::write::StremalinesUtility]
        ### Add section to document
        dict set projectParametersDict problem_data $problemDataDict
    }
    ### Solver Data   
    set solversettingsDict [dict create]
    
    ### Preguntar el solver haciendo los ifs correspondientes
    if {$paralleltype eq "OpenMP"} {
                if {$damTypeofProblem eq "Mechanical"} {
                        dict set solversettingsDict solver_type "dam_mechanical_solver"
                } elseif {$damTypeofProblem eq "Thermo-Mechanical"} {
                        dict set solversettingsDict solver_type "dam_thermo_mechanic_solver"
                } elseif {$damTypeofProblem eq "UP_Mechanical"} {
                        dict set solversettingsDict solver_type "dam_UP_mechanical_solver"
                } elseif {$damTypeofProblem eq "UP_Thermo-Mechanical"} {
                        dict set solversettingsDict solver_type "dam_UP_thermo_mechanic_solver"
                } elseif {$damTypeofProblem eq "Acoustic"} {
                        dict set solversettingsDict solver_type "dam_P_solver"
        } else {
                        dict set solversettingsDict solver_type "dam_eigen_solver"
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
                } elseif {$damTypeofProblem eq "Acoustic"} {
                        W "Acoustic Problem in MPI is not yet implemented, please select an OpenMP option"
                } else {
            W "Eigen Analysis in MPI is not yet implemented, please select an OpenMP option"
        }
        }
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename $model_name
    dict set modelDict input_file_label 0
    dict set solversettingsDict model_import_settings $modelDict
    dict set solversettingsDict echo_level 1
    dict set solversettingsDict buffer_size 2
    
    if {$damTypeofProblem eq "Modal-Analysis"} {
        dict set solversettingsDict solution_type [write::getValue DamModalSoluType]
        dict set solversettingsDict analysis_type [write::getValue DamModalAnalysisType]
        set eigensolversetDict [dict create]
        dict set eigensolversetDict solver_type [write::getValue DamModalSolver]
        dict set eigensolversetDict print_feast_output [write::getValue DamModalfeastOutput]
        dict set eigensolversetDict perform_stochastic_estimate [write::getValue DamModalStochastic]
        dict set eigensolversetDict solve_eigenvalue_problem [write::getValue DamModalSolve]
        dict set eigensolversetDict lambda_min [write::getValue DamModalLambdaMin]
        dict set eigensolversetDict lambda_max [write::getValue DamModalLambdaMax]
        dict set eigensolversetDict search_dimension [write::getValue DamModalSearchDimension]
        
        ## Adding Eigen Dictionary
        dict set solversettingsDict eigensolver_settings $eigensolversetDict
        
        # Adding submodel and processes
        dict set solversettingsDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
        dict set solversettingsDict processes_sub_model_part_list [write::getSubModelPartNames "DamNodalConditions" "DamLoads"]
        
    } else {
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
            dict set thermalsettingDict problem_domain_sub_model_part_list [Dam::write::getSubModelPartThermalNames]
            
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
            set UPthermalsettingDict [dict merge $UPthermalsettingDict [::Dam::write::getSolversParametersDict Dam DamSolStratThermUP "DamUP_Thermo-Mechanical-ThermData"] ]
            dict set UPthermalsettingDict problem_domain_sub_model_part_list [Dam::write::getSubModelPartThermalNames]
           
            ## Adding UP thermal solver settings to solver settings
            dict set solversettingsDict thermal_solver_settings $UPthermalsettingDict
            
            ## Resetting Variables for the mechanical problem according to the selected problem
            set MechanicalDataUN "DamUP_Thermo-Mechanical-MechData"
            set MechanicalDataParametersUN "DamUP_Thermo-Mechanical-MechDataParameters"
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
            dict set acousticSolverSettingsDict echo_level [write::getValue DamAcousticSolverEchoLevel]

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
            set UPmechanicalSolverSettingsDict [dict merge $UPmechanicalSolverSettingsDict [Dam::write::DefinitionDomains] ]
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
            if {$damTypeofProblem eq "Thermo-Mechanical" } {
                set typeofDamage [write::getValue DamThermo-Mechanical-MechaDamageType]
                if {$typeofDamage eq "NonLocal"} { 
                    dict set mechanicalSolverSettingsDict nonlocal_damage true
                    dict set mechanicalSolverSettingsDict characteristic_length [write::getValue DamThermo-Mechanical-MechaDamageTypeLength]
                    dict set mechanicalSolverSettingsDict search_neighbours_step [write::getValue DamThermo-Mechanical-MechaDamageTypeSearch]
                } else {
                    dict set mechanicalSolverSettingsDict nonlocal_damage false
                }
            } elseif {$damTypeofProblem eq "UP_Thermo-Mechanical" } {
                set typeofDamage [write::getValue DamUPThermo-Mechanical-MechaDamageType]
                if {$typeofDamage eq "NonLocal"} { 
                    dict set mechanicalSolverSettingsDict nonlocal_damage true
                    dict set mechanicalSolverSettingsDict characteristic_length [write::getValue DamUPThermo-Mechanical-MechaDamageTypeLength]
                    dict set mechanicalSolverSettingsDict search_neighbours_step [write::getValue DamUPThermo-Mechanical-MechaDamageTypeSearch]
                } else {
                    dict set mechanicalSolverSettingsDict nonlocal_damage false
                }
                    
            } else {
                set typeofDamage [write::getValue DamMechaDamageType]
                if {$typeofDamage eq "NonLocal"} { 
                    dict set mechanicalSolverSettingsDict nonlocal_damage true
                    dict set mechanicalSolverSettingsDict characteristic_length [write::getValue DamMechaDamageTypeLength]
                    dict set mechanicalSolverSettingsDict search_neighbours_step [write::getValue DamMechaDamageTypeSearch]
                } else {
                    dict set mechanicalSolverSettingsDict nonlocal_damage false
                }
            }
            ### Adding solvers parameters
            set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [::Dam::write::getSolversParametersDict Dam $MechanicalSolutionStrategyUN $MechanicalDataUN] ]
            ### Add section to document
            set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [Dam::write::DefinitionDomains] ]
            ### Add section to document
            dict set solversettingsDict mechanical_solver_settings $mechanicalSolverSettingsDict
            
        }
    }
    
    dict set projectParametersDict solver_settings $solversettingsDict
    
    dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]
    
    set nodal_process_list [write::getConditionsParametersDict DamNodalConditions "Nodal"]
    set load_process_list [write::getConditionsParametersDict DamLoads ]
    dict set projectParametersDict constraints_process_list [Dam::write::ChangeFileNameforTableid $nodal_process_list]
    set loads [Dam::write::ChangeFileNameforTableid $load_process_list]
    set construction_process [Dam::write::GetConstructionDomainProcessDict]
    if {[llength $construction_process]} {
        set loads [lappend loads [dict create {*}$construction_process]]
        set li [dict get $projectParametersDict solver_settings processes_sub_model_part_list]
        lappend li [dict get $construction_process Parameters model_part_name]
        dict set projectParametersDict solver_settings processes_sub_model_part_list $li
    }
    dict set projectParametersDict loads_process_list $loads
    return $projectParametersDict

}

proc Dam::write::DefinitionDomains { } {
    
 ### Boundary conditions processes
    set domainsDict [dict create]
 
    set body_part_list [list ]
    set joint_part_list [list ]
    set mat_dict [write::getMatDict]
    foreach part_name [dict keys $mat_dict] {
        if {[[Model::getElement [dict get $mat_dict $part_name Element]] getAttribute "ElementType"] eq "Solid"} {
            lappend body_part_list [write::getMeshId Parts $part_name]
            #~ W $body_part_list
        }
    }
    dict set domainsDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
    dict set domainsDict body_domain_sub_model_part_list $body_part_list

    set strategytype [write::getValue DamSolStrat]
    if {$strategytype eq "Arc-length"} {
        dict set domainsDict loads_sub_model_part_list [write::getSubModelPartNames DamLoads]
        dict set domainsDict loads_variable_list [Dam::write::getVariableNameList DamLoads]
    } {
        set loads_sub_model_part_list [list]
        set loads_variable_list [list]
        dict set domainsDict loads_sub_model_part_list $loads_sub_model_part_list
        dict set domainsDict loads_variable_list $loads_variable_list
    }
    
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
            if {[$param getType] eq "vector" && [$param getAttribute vectorType] eq "tablefile" && [dict exists $nodalProcess Parameters $paramName] } {
                for {set i 0} {$i < [llength [dict get $nodalProcess Parameters $paramName]]} {incr i} {
                    set filename [lindex [dict get $nodalProcess Parameters $paramName] $i]
                    set value [Dam::write::GetTableidFromFileid $filename]
                    set values_list [dict get $nodalProcess Parameters $paramName]
                    set values_list [lreplace $values_list $i $i $value]
                    dict set nodalProcess Parameters $paramName $values_list
                }
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

proc Dam::write::StremalinesUtility {} {

    set nodalList [write::GetResultsList NodalResults]
    if {[lsearch $nodalList Vi_POSITIVE] >= 0 || [lsearch $nodalList Viii_POSITIVE] >= 0} {
        set streamlines true
    } {
        set streamlines false
    }
    return $streamlines
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
                    set param_node [$base_node selectNodes "./value\[@n='$n'\]"]
                    write::forceUpdateNode $param_node
                    if {[$in getType] ni [list "bool" "integer" "double"]} {
                        set v ""
                        catch {set v [write::getValueByNode $param_node]}
                        if {$v eq ""} {set v [write::getValueByNode $param_node]}
                        dict set solverEntryDict $n $v
                    } {
                        dict set solverEntryDict $n [write::getValueByNode $param_node]
                    }
                }
                dict set solverSettingsDict [$se getName] $solverEntryDict
            }
        }
        unset solverEntryDict
    }
    return $solverSettingsDict
}

proc Dam::write::GetConstructionDomainProcessDict { } {
    set construction_dict [dict create]
    set data_basenode [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute "DamConstructionProcess"]]
    set activate [get_domnode_attribute [$data_basenode selectNodes "./value\[@n='Activate_construction'\]"] v]
    if {[write::isBooleanTrue $activate]} {
        dict set construction_dict "python_module" "dam_construction_process"
        dict set construction_dict "kratos_module" "KratosMultiphysics.DamApplication"
        dict set construction_dict "process_name" "DamConstructionProcess"
        set params_dict [dict create]
            dict set params_dict mesh_id 0
            dict set params_dict model_part_name [write::getMeshId Parts [get_domnode_attribute [$data_basenode selectNodes "./value\[@n='Construction_part'\]"] v]]
            set params [list Gravity_Direction Reservoir_Bottom_Coordinate_in_Gravity_Direction Height_Dam Number_of_phases]
            foreach param $params {
                dict set params_dict $param [write::getValueByNode [$data_basenode selectNodes "./value\[@n='$param'\]"]]
            }
        dict set construction_dict Parameters $params_dict
    }
    return $construction_dict
}
