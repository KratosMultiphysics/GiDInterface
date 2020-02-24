### Project Parameters

proc Dam::write::getParametersDict { } {
    
    variable number_tables
    set number_tables 0
    
    set projectParametersDict [dict create]
    
    ### Problem data
    dict set projectParametersDict problem_data [Dam::write::GetProblemDataDict]
    
    ### Solver data
    dict set projectParametersDict solver_settings [Dam::write::GetSolverSettingsDict]

    ### Output data
    dict set projectParametersDict output_configuration [Dam::write::GetOutputDict]
    
    ### Constraints processes
    dict set projectParametersDict constraints_process_list [Dam::write::ChangeFileNameforTableid [::write::getConditionsParametersDict DamNodalConditions "Nodal"]]
    
    ### Load processes
    set mechanical_load_process_list [::write::getConditionsParametersDict DamLoads]
    set thermal_load_process_list [::write::getConditionsParametersDict DamThermalLoads]
    dict set projectParametersDict loads_process_list [Dam::write::ChangeFileNameforTableid [concat $mechanical_load_process_list $thermal_load_process_list]]
    
    ### Construction processes
    dict set projectParametersDict construction_process [Dam::write::GetConstructionDomainProcessDict]
    
    ### Transfer results processes
    dict set projectParametersDict transfer_results_process [Dam::write::GetTransferResultsDict]
    
    ### Temperature by device
    dict set projectParametersDict temperature_by_device_list [Dam::write::TemperaturebyDevices]
    
    ### Output device
    dict set projectParametersDict output_device_list [Dam::write::DevicesOutput]
    
    return $projectParametersDict
    
}

# This process is the responsible of writing files
proc Dam::write::writeParametersEvent { } {
    
    set projectParametersDict [Dam::write::getParametersDict]
    write::WriteJSON $projectParametersDict
    
    set damSelfweight [write::getValue DamSelfweight ConsiderSelfweight]
    if {$damSelfweight eq "Yes" } {
        
        write::OpenFile "[file tail ProjectParametersSelfWeight].json"
        set projectParametersDictSelfWeight [getParametersSelfWeight]
        write::WriteString [write::tcl2json $projectParametersDictSelfWeight]
        write::CloseFile
        
    }
}

proc Dam::write::GetProblemDataDict { } {
    ### Create section
    set problemDataDict [dict create]
    set damTypeofProblem [write::getValue DamTypeofProblem]
    set paralleltype [write::getValue ParallelType]
    set model_name [file tail [GiD_Info Project ModelName]]
    
    ### Add items to section
    dict set problemDataDict problem_name $model_name
    dict set problemDataDict model_part_name [Dam::write::GetAttribute model_part_name] 
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set problemDataDict domain_size $nDim
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
        
    } else {
        dict set problemDataDict start_time [write::getValue DamTimeParameters StartTime]
        dict set problemDataDict end_time [write::getValue DamTimeParameters EndTime]
        dict set problemDataDict time_step [write::getValue DamTimeParameters DeltaTime]
        dict set problemDataDict time_scale [write::getValue DamTimeParameters TimeScale]
        
        set consider_self_weight [write::getValue DamSelfweight ConsiderSelfweight]
        if {$consider_self_weight eq "Yes"} {
            dict set problemDataDict consider_selfweight true
        } else {
            dict set problemDataDict consider_selfweight false
        }
        
        set consider_construction [write::getValue DamConstructionProcess Activate_construction]
        if {$consider_construction eq "Yes"} {
            dict set problemDataDict consider_construction true
        } else {
            dict set problemDataDict consider_construction false
        }
        
        dict set problemDataDict streamlines_utility [Dam::write::StremalinesUtility]
    }

    return $problemDataDict
}

proc Dam::write::GetSolverSettingsDict { } {
    set solversettingsDict [dict create]

    set damTypeofProblem [write::getValue DamTypeofProblem]
    set paralleltype [write::getValue ParallelType]
    set model_name [file tail [GiD_Info Project ModelName]]
    
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
    
    dict set solversettingsDict processes_sub_model_part_list [write::getSubModelPartNames [Dam::write::GetAttribute nodal_conditions_un] [Dam::write::GetAttribute conditions_un] [Dam::write::GetAttribute thermal_conditions_un]]

    if {$damTypeofProblem eq "Modal-Analysis"} {
        dict set solversettingsDict solution_type [write::getValue DamModalSoluType]
        dict set solversettingsDict analysis_type [write::getValue DamModalAnalysisType]
        set eigensolversetDict [dict create]
        dict set eigensolversetDict solver_type [write::getValue DamModalSolver]
        dict set eigensolversetDict print_feast_output [write::getValue DamModalfeastOutput]
        dict set eigensolversetDict perform_stochastic_estimate [write::getValue DamModalStochastic]
        dict set eigensolversetDict solve_eigenvalue_problem [write::getValue DamModalSolve]
        dict set eigensolversetDict compute_modal_contribution [write::getValue DamModalContribution]
        dict set eigensolversetDict lambda_min [write::getValue DamModalLambdaMin]
        dict set eigensolversetDict lambda_max [write::getValue DamModalLambdaMax]
        dict set eigensolversetDict search_dimension [write::getValue DamModalSearchDimension]
        
        ## Adding Eigen Dictionary
        dict set solversettingsDict eigensolver_settings $eigensolversetDict
        
        # Adding submodel and processes
        dict set solversettingsDict problem_domain_sub_model_part_list [write::getSubModelPartNames [Dam::write::GetAttribute parts_un]]
        
    } else {
        
        ## Default Values
        set MechanicalSolutionStrategyUN "DamSolStrat"
        set MechanicalSchemeUN "DamScheme"
        set MechanicalDataUN "DamMechanicalData"
        set MechanicalDataParametersUN "DamMechanicalDataParameters"
        
        if {$damTypeofProblem eq "Thermo-Mechanical" } {
                        
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
            dict set thermalsettingDict thermal_loads_sub_model_part_list [write::getSubModelPartNames [Dam::write::GetAttribute thermal_conditions_un]]
            
            
            ## Adding thermal solver settings to solver settings
            dict set solversettingsDict thermal_solver_settings $thermalsettingDict
            
            ## Resetting Variables for the mechanical problem according to the selected problem
            set MechanicalDataUN "DamThermo-Mechanical-MechData"
            set MechanicalDataParametersUN "DamThermo-Mechanical-MechDataParameters"
        }
        
        if {$damTypeofProblem eq "UP_Thermo-Mechanical" } {
            
            dict set solversettingsDict reference_temperature [write::getValue DamThermalUPReferenceTemperature]
            dict set solversettingsDict processes_sub_model_part_list [write::getSubModelPartNames "DamNodalConditions" "DamLoads" [Dam::write::GetAttribute thermal_conditions_un]]
            
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
            dict set UPthermalsettingDict thermal_loads_sub_model_part_list [write::getSubModelPartNames [Dam::write::GetAttribute thermal_conditions_un]]
            
            
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
    return $solversettingsDict
}

# This process returns a dict of domains according input parameters in the solvers
proc Dam::write::DefinitionDomains { } {
    
    ### Boundary conditions processes
    set domainsDict [dict create]
    set body_part_list [list ]
    set joint_part_list [list ]
    set mat_dict [write::getMatDict]
    foreach part_name [dict keys $mat_dict] {
        if {[[Model::getElement [dict get $mat_dict $part_name Element]] getAttribute "ElementType"] eq "Solid"} {
            lappend body_part_list [write::getSubModelPartId Parts $part_name]
        }
    }
    dict set domainsDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
    dict set domainsDict body_domain_sub_model_part_list $body_part_list
    dict set domainsDict mechanical_loads_sub_model_part_list [write::getSubModelPartNames "DamLoads"]
    
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


# This process assign a number for the different tables instead of names (this is for matching with .mdpa)
proc Dam::write::ChangeFileNameforTableid { processList } {
    
    # Variable global definida al principio y utilizada para transferir entre procesos el número de tablas existentes
    variable number_tables
    
    set returnList [list ]
    foreach nodalProcess $processList {
        set processName [dict get $nodalProcess process_name]
        set process [::Model::GetProcess $processName]
        set params [$process getInputs]
        
        if {$processName ne "ImposeNodalReferenceTemperatureProcess"} {
            
            foreach {paramName param} $params {
                if {[$param getType] eq "tablefile" && [dict exists $nodalProcess Parameters $paramName] } {
                    set filename [dict get $nodalProcess Parameters $paramName]
                    set value [Dam::write::GetTableidFromFileid $filename]
                    dict set nodalProcess Parameters $paramName $value
                    if {$value != 0} {
                        incr number_tables
                    }
                }
                if {[$param getType] eq "vector" && [$param getAttribute vectorType] eq "tablefile" && [dict exists $nodalProcess Parameters $paramName] } {
                    for {set i 0} {$i < [llength [dict get $nodalProcess Parameters $paramName]]} {incr i} {
                        set filename [lindex [dict get $nodalProcess Parameters $paramName] $i]
                        set value [Dam::write::GetTableidFromFileid $filename]
                        set values_list [dict get $nodalProcess Parameters $paramName]
                        set values_list [lreplace $values_list $i $i $value]
                        dict set nodalProcess Parameters $paramName $values_list
                        if {$value != 0} {
                            incr number_tables
                        }
                        
                    }
                }
            }
        }
        
        lappend returnList $nodalProcess
        
    }
    return $returnList
}


# This process is used to define new list of Output configuratino parameters
proc Dam::write::GetOutputDict { {appid ""} } {
    
    set outputDict [dict create]
    set resultDict [dict create]
    
    set GiDPostDict [dict create]
    dict set GiDPostDict GiDPostMode                [write::getValue Results GiDPostMode]
    dict set GiDPostDict WriteDeformedMeshFlag      [write::getValue Results GiDWriteMeshFlag]
    dict set GiDPostDict WriteConditionsFlag        [write::getValue Results GiDWriteConditionsFlag]
    dict set GiDPostDict MultiFileFlag              [write::getValue Results GiDMultiFileFlag]
    dict set resultDict gidpost_flags $GiDPostDict
    
    set outputCT [write::getValue Results OutputControlType]
    dict set resultDict output_control_type $outputCT
    
    if {$outputCT eq "time_s"} {
        set frequency [write::getValue Results OutputDeltaTime_s]
    } elseif {$outputCT eq "time_h"} {
        set frequency [write::getValue Results OutputDeltaTime_h]
    } elseif {$outputCT eq "time_d"} {
        set frequency [write::getValue Results OutputDeltaTime_d]
    } elseif {$outputCT eq "time_w"} {
        set frequency [write::getValue Results OutputDeltaTime_w]
    }
    
    dict set resultDict output_frequency $frequency
    dict set resultDict start_output_results [write::getValue Results StartOutputResults]
    
    dict set resultDict body_output           [write::getValue Results BodyOutput]
    dict set resultDict node_output           [write::getValue Results NodeOutput]
    dict set resultDict skin_output           [write::getValue Results SkinOutput]
    
    dict set resultDict plane_output [write::GetCutPlanesList Results]
    
    dict set resultDict nodal_results [write::GetResultsList Results OnNodes]
    dict set resultDict gauss_point_results [write::GetResultsList Results OnElement]
    
    dict set outputDict "result_file_configuration" $resultDict
    dict set outputDict "point_data_configuration" [write::GetEmptyList]
    return $outputDict
}


# This process is used for checking if the user is interested on streamlines
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

# This process write the construction in process in case is selected
proc Dam::write::GetConstructionDomainProcessDict { } {
    
    set construction_dict [dict create]
    set data_basenode [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute "DamConstructionProcess"]]
    set activate [get_domnode_attribute [$data_basenode selectNodes "./value\[@n='Activate_construction'\]"] v]
    if {[write::isBooleanTrue $activate]} {
        
        set params [list gravity_direction reservoir_bottom_coordinate_in_gravity_direction lift_height h_0 aging construction_input_file_name ambient_input_file_name activate_soil_part activate_existing_part]
        foreach param $params {
            dict set construction_dict $param [write::getValueByNode [$data_basenode selectNodes "./value\[@n='$param'\]"]]
        }
        
        # Añado guiones bajos a los nombres de los submodelparts activados en el modelo.
        set old_name_soil_part [get_domnode_attribute [$data_basenode selectNodes "./value\[@n='name_soil_part'\]"] v]
        set name_soil_part [string map {" " "_"} $old_name_soil_part]
        
        set old_name_existing_part [get_domnode_attribute [$data_basenode selectNodes "./value\[@n='name_existing_part'\]"] v]
        set name_existing_part [string map {" " "_"} $old_name_existing_part]
        
        dict set construction_dict name_soil_part $name_soil_part
        dict set construction_dict name_existing_part $name_existing_part
        
        set params_check [list activate_check_temperature maximum_temperature_increment maximum_temperature minimum_temperature]
        foreach param_check $params_check {
            dict set construction_dict $param_check [write::getValueByNode [$data_basenode selectNodes "./value\[@n='$param_check'\]"]]
        }
        
        # Añado parámetros específicos del tipo de ley de fuente de calor escogida
        set source_type [get_domnode_attribute [$data_basenode selectNodes "./value\[@n='source_type'\]"] v]
        dict set construction_dict source_type $source_type
        
        if {$source_type eq "Adiabatic"} {
            set data_basenode_noorzai [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute "DamNoorzaiData"]]
            set params [list density specific_heat alpha tmax]
            foreach param $params {
                dict set construction_dict $param [write::getValueByNode [$data_basenode_noorzai selectNodes "./value\[@n='$param'\]"]]
            }
        }
        if {$source_type eq "NonAdiabatic"} {
            set data_basenode_azenha [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute "DamAzenhaData"]]
            set params [list activation_energy gas_constant constant_rate alpha_initial young_inf q_total A B C D]
            foreach param $params {
                dict set construction_dict $param [write::getValueByNode [$data_basenode_azenha selectNodes "./value\[@n='$param'\]"]]
            }
        }
        
    }
    return $construction_dict
}

# This process write the transfer results process in case is selected
proc Dam::write::GetTransferResultsDict { } {
    set transfer_results_dict [dict create]
    set consider_save_intermediate_variables [write::getValue DamSaveResults SaveIntermediateResults]
    if {$consider_save_intermediate_variables eq "Yes"} {
        set damStepSaveResults [write::getValue DamSaveResults SaveIntermediateStep]
        set damTypeofProblem [write::getValue DamTypeofProblem]
        if {$damTypeofProblem eq "Mechanical"} {
            dict set transfer_results_dict save_intermediate_mechanical_variables true
            dict set transfer_results_dict save_intermediate_thermal_variables false
            dict set transfer_results_dict save_intermediate_variables_step $damStepSaveResults
        } else {
            dict set transfer_results_dict save_intermediate_mechanical_variables true
            dict set transfer_results_dict save_intermediate_thermal_variables true
            dict set transfer_results_dict save_intermediate_variables_step $damStepSaveResults
        }
    } else {
        dict set transfer_results_dict save_intermediate_mechanical_variables false
        dict set transfer_results_dict save_intermediate_thermal_variables false
        dict set transfer_results_dict save_intermediate_variables_step 0
    }
    
    set consider_save_final_variables [write::getValue DamSaveResults SaveFinalResults]
    if {$consider_save_final_variables eq "Yes"} {
        set damTypeofProblem [write::getValue DamTypeofProblem]
        if {$damTypeofProblem eq "Mechanical"} {
            dict set transfer_results_dict save_final_mechanical_variables true
            dict set transfer_results_dict save_final_thermal_variables false
        } else {
            dict set transfer_results_dict save_final_mechanical_variables true
            dict set transfer_results_dict save_final_thermal_variables true
        }
    } else {
        dict set transfer_results_dict save_final_mechanical_variables false
        dict set transfer_results_dict save_final_thermal_variables false
    }
    
    set consider_add_previous_results [write::getValue DamPreviousResults AddPreviousResults]
    if {$consider_add_previous_results eq "Yes"} {
        set damTypeofResults [write::getValue DamPreviousResults TypeResults]
        if {$damTypeofResults eq "Mechanical"} {
            set damAddDisplacement [write::getValue DamAddResultsData DisplacementResults]
            set damAddStress [write::getValue DamAddResultsData StressResults]
            if {$damAddDisplacement eq "Yes"} {
                set add_displacement true
            } else {
                set add_displacement false
            }
            if {$damAddStress eq "Yes"} {
                set add_stress true
            } else {
                set add_stress false
            }
            set add_temperature false
            set add_reference_temperature false
        } elseif {$damTypeofResults eq "Thermal"} {
            set damAddTemperature [write::getValue DamAddResultsData TemperatureResults]
            set damAddRefTemperature [write::getValue DamAddResultsData RefTemperatureResults]
            if {$damAddTemperature eq "Yes"} {
                set add_temperature true
            } else {
                set add_temperature false
            }
            if {$damAddRefTemperature eq "Yes"} {
                set add_reference_temperature true
            } else {
                set add_reference_temperature false
            }
            set add_displacement false
            set add_stress false
        } elseif {$damTypeofResults eq "Thermo-Mechanical"} {
            set damAddDisplacement [write::getValue DamAddResultsData DisplacementResults]
            set damAddStress [write::getValue DamAddResultsData StressResults]
            set damAddTemperature [write::getValue DamAddResultsData TemperatureResults]
            set damAddRefTemperature [write::getValue DamAddResultsData RefTemperatureResults]
            if {$damAddDisplacement eq "Yes"} {
                set add_displacement true
            } else {
                set add_displacement false
            }
            if {$damAddStress eq "Yes"} {
                set add_stress true
            } else {
                set add_stress false
            }
            if {$damAddTemperature eq "Yes"} {
                set add_temperature true
            } else {
                set add_temperature false
            }
            if {$damAddRefTemperature eq "Yes"} {
                set add_reference_temperature true
            } else {
                set add_reference_temperature false
            }
        }
    } else {
        set add_displacement false
        set add_stress false
        set add_temperature false
        set add_reference_temperature false
    }
    
    dict set transfer_results_dict add_previous_results [write::getValue DamPreviousResults AddPreviousResults]
    dict set transfer_results_dict type_of_results [write::getValue DamPreviousResults TypeResults]
    dict set transfer_results_dict add_displacement $add_displacement
    dict set transfer_results_dict add_stress $add_stress
    dict set transfer_results_dict add_temperature $add_temperature
    dict set transfer_results_dict add_reference_temperature $add_reference_temperature
    dict set transfer_results_dict file_name_mechanical [write::getValue DamPreviousResults FileNameMechanical]
    dict set transfer_results_dict file_name_thermal [write::getValue DamPreviousResults FileNameThermal]
    return $transfer_results_dict
}


# This process writes a dictionary for creating new projectparameters exclusively for solving selfweight problem
proc Dam::write::getParametersSelfWeight { } {
    
    set projectParametersDictSelfWeight [dict create]
    set solversettingsDict [dict create]
    dict set solversettingsDict solver_type "dam_selfweight_solver"
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set modelDict input_filename $model_name
    dict set modelDict input_file_label 0
    dict set solversettingsDict model_import_settings $modelDict
    dict set solversettingsDict echo_level 1
    dict set solversettingsDict buffer_size 2
    
    # We are only interested in Displacements
    set nodal_part_names [write::getSubModelPartNames "DamNodalConditions" "DamSelfweight"]
    set nodal_names [list ]
    foreach name $nodal_part_names {
        if {[string first DISPLACEMENT $name] != -1} {
            lappend nodal_names $name
        }
        if {[string first SelfWeight $name] != -1} {
            lappend nodal_names $name
        }
    }
    dict set solversettingsDict processes_sub_model_part_list $nodal_names
    
    set mechanicalSolverSettingsDict [dict create]
    # Adding predefined values for selfweight problem
    set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [Dam::write::predefinedParametersSelfWeight] ]
    # Adding domain definitions
    set mechanicalSolverSettingsDict [dict merge $mechanicalSolverSettingsDict [Dam::write::DefinitionDomains] ]
    # Combination in solversetting dict
    dict set solversettingsDict mechanical_solver_settings $mechanicalSolverSettingsDict
    # Adding solver_settings to global dict
    dict set projectParametersDictSelfWeight solver_settings $solversettingsDict
    
    # Adding constrains dict
    set nodal_process_list [::write::getConditionsParametersDict DamNodalConditions "Nodal"]
    set nodal_process_list_table_number [Dam::write::ChangeFileNameforTableid $nodal_process_list]
    dict set projectParametersDictSelfWeight constraints_process_list [Dam::write::filteringConstraints $nodal_process_list_table_number]
    
    # Adding selfweight loads dict
    set selfweight_process_list [::write::getConditionsParametersDict DamSelfweight]
    set selfweight_process_list_table_number [Dam::write::ChangeFileNameforTableid $selfweight_process_list]
    dict set projectParametersDictSelfWeight loads_process_list $selfweight_process_list_table_number
    
    return $projectParametersDictSelfWeight
}

# Predefined solver values for selfweight problem
proc Dam::write::predefinedParametersSelfWeight { } {
    
    set solverSelfParametersDict [dict create]
    dict set solverSelfParametersDict solution_type "Quasi-Static"
    dict set solverSelfParametersDict strategy_type "Newton-Raphson"
    dict set solverSelfParametersDict scheme_type "Newmark"
    dict set solverSelfParametersDict convergence_criterion "And_criterion"
    dict set solverSelfParametersDict displacement_relative_tolerance 0.0001
    dict set solverSelfParametersDict displacement_absolute_tolerance 1e-9
    dict set solverSelfParametersDict residual_relative_tolerance 0.0001
    dict set solverSelfParametersDict residual_absolute_tolerance 1e-9
    dict set solverSelfParametersDict max_iteration 10
    dict set solverSelfParametersDict echo_level 1
    dict set solverSelfParametersDict buffer_size 2
    dict set solverSelfParametersDict compute_reactions false
    dict set solverSelfParametersDict reform_dofs_at_each_step false
    dict set solverSelfParametersDict move_mesh_flag true
    dict set solverSelfParametersDict block_builder true
    dict set solverSelfParametersDict clear_storage false
    dict set solverSelfParametersDict rayleigh_m 0.0
    dict set solverSelfParametersDict rayleigh_k 0.0
    dict set solverSelfParametersDict nonlocal_damage false
    
    set linearSolverSettingsDict [dict create]
    dict set linearSolverSettingsDict solver_type "bicgstab"
    dict set linearSolverSettingsDict max_iteration 200
    dict set linearSolverSettingsDict tolerance 1e-7
    dict set linearSolverSettingsDict preconditioner_type "ilu0"
    dict set linearSolverSettingsDict scaling false
    dict set solverSelfParametersDict linear_solver_settings $linearSolverSettingsDict
    
    return $solverSelfParametersDict
}

# This process filters Nodal constraints for selfweight problem
proc Dam::write::filteringConstraints { processList} {
    
    set returnList [list ]
    foreach nodalProcess $processList {
        set processName [dict get $nodalProcess process_name]
        if {[string first Constraint $processName] != -1} {
            lappend returnList $nodalProcess
        }
    }
    return $returnList
}

proc Dam::write::DevicesOutput { } {
    
    set output_state [write::getValue DamOutputState]
    set lista [list ]
    
    if { $output_state == True } {
        
        set root [customlib::GetBaseRoot]
        set xp1 "[spdAux::getRoute DamDevices]/blockdata\[@n='device'\]"
        set nodes [$root selectNodes $xp1]
        
        foreach node $nodes {
            
            set deviceDict [dict create]
            dict set deviceDict python_module "point_output_process"
            dict set deviceDict kratos_module "KratosMultiphysics"
            dict set deviceDict help "This process print the selected value according its position"
            dict set deviceDict process_name "PointOutputProcess"
            
            set name [$node @name]
            set extension ".txt"
            
            set xp2 "[spdAux::getRoute DamDevices]/blockdata\[@name='$name'\]/value\[@n='Variable'\]"
            set node_xp2 [$root selectNodes $xp2]
            set variable [get_domnode_attribute $node_xp2 v]
            
            set xp3 "[spdAux::getRoute DamDevices]/blockdata\[@name='$name'\]/value\[@n='XPosition'\]"
            set node_xp3 [$root selectNodes $xp3]
            set xposition [write::getValueByNode $node_xp3]
            
            set xp4 "[spdAux::getRoute DamDevices]/blockdata\[@name='$name'\]/value\[@n='YPosition'\]"
            set node_xp4 [$root selectNodes $xp4]
            set yposition [write::getValueByNode $node_xp4]
            
            set xp5 "[spdAux::getRoute DamDevices]/blockdata\[@name='$name'\]/value\[@n='ZPosition'\]"
            set node_xp5 [$root selectNodes $xp5]
            set zposition [write::getValueByNode $node_xp5]
            
            set parameterDict [dict create]
            set positionList [list ]
            lappend positionList $xposition $yposition $zposition
            dict set parameterDict position $positionList
            dict set parameterDict model_part_name "MainModelPart"
            dict set parameterDict output_file_name $name$extension
            set outputlist [list ]
            lappend outputlist $variable
            dict set parameterDict output_variables $outputlist
            dict set deviceDict Parameters $parameterDict
            
            lappend lista $deviceDict
        }
    }
    
    return $lista
    
}

proc Dam::write::TemperaturebyDevices { } {
    
    # Variable global definida al principio y utilizada para transferir entre procesos el número de tablas existentes
    variable number_tables
    
    set device_temp_state [write::getValue DamTemperatureState]
    set lista [list ]
    set listaFiles [list ]
    
    if { $device_temp_state == True} {
        
        set root [customlib::GetBaseRoot]
        set xp1 "[spdAux::getRoute DamTempDevice]/blockdata\[@n='device'\]"
        set nodes [$root selectNodes $xp1]
        
        set number_devices 0
        
        foreach node $nodes {
            
            set TempdeviceDict [dict create]
            dict set TempdeviceDict  python_module "impose_temperature_by_device_process"
            dict set TempdeviceDict  kratos_module "KratosMultiphysics.DamApplication"
            dict set TempdeviceDict  help "This process assigns a nodal temperature value according the device spatial position"
            dict set TempdeviceDict  process_name "ImposeTemperaturebyDeviceProcess"
            
            set name [$node @name]
            
            set xp2 "[spdAux::getRoute DamTempDevice]/blockdata\[@name='$name'\]/value\[@n='is_fixed'\]"
            set node_xp2 [$root selectNodes $xp2]
            set isfixed [get_domnode_attribute $node_xp2 v]
            
            set xp3 "[spdAux::getRoute DamTempDevice]/blockdata\[@name='$name'\]/value\[@n='value'\]"
            set node_xp3 [$root selectNodes $xp3]
            set value [write::getValueByNode $node_xp3]
            
            set xp4 "[spdAux::getRoute DamTempDevice]/blockdata\[@name='$name'\]/value\[@n='table'\]"
            set node_xp4 [$root selectNodes $xp4]
            set fileid [write::getValueByNode $node_xp4]
            
            set xp5 "[spdAux::getRoute DamTempDevice]/blockdata\[@name='$name'\]/value\[@n='XPosition'\]"
            set node_xp5 [$root selectNodes $xp5]
            set xposition [write::getValueByNode $node_xp5]
            
            set xp6 "[spdAux::getRoute DamTempDevice]/blockdata\[@name='$name'\]/value\[@n='YPosition'\]"
            set node_xp6 [$root selectNodes $xp6]
            set yposition [write::getValueByNode $node_xp6]
            
            set xp7 "[spdAux::getRoute DamTempDevice]/blockdata\[@name='$name'\]/value\[@n='ZPosition'\]"
            set node_xp7 [$root selectNodes $xp7]
            set zposition [write::getValueByNode $node_xp7]
            
            set parameterDict [dict create]
            set positionList [list ]
            dict set parameterDict model_part_name "MainModelPart"
            dict set parameterDict variable_name "TEMPERATURE"
            dict set parameterDict is_fixed $isfixed
            dict set parameterDict value $value
            
            if {$fileid ni [list "" "- No file"]} {
                if {$fileid ni $listaFiles} {
                    lappend listaFiles $fileid
                    incr number_devices
                    dict set parameterDict table [expr $number_tables + $number_devices]
                } else {
                    for {set i 0} {$i < [llength $listaFiles]} {incr i} {
                        if {$fileid eq [lindex $listaFiles $i]} {
                            dict set parameterDict table [expr $number_tables + $i + 1]
                            break
                        }
                    }
                }
            } else {
                dict set parameterDict table 0
            }
            
            lappend positionList $xposition $yposition $zposition
            dict set parameterDict position $positionList
            dict set TempdeviceDict  Parameters $parameterDict
            
            lappend lista $TempdeviceDict
        }
    }
    
    return $lista
}
