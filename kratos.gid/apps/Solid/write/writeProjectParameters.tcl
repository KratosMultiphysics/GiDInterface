# Project Parameters

proc Solid::write::getParametersDict { } {
    set model_name "Solid_Domain"
    set projectParametersDict [dict create]

    # Problem data
    set problemDataDict [dict create] 
    
    # Add items
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set problemDataDict problem_name $model_name

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    #dict set problemDataDict "parallel_type" $paralleltype
    if {$paralleltype eq "OpenMP"} {
        #set nthreads [write::getValue Parallelization OpenMPNumberOfThreads]
        #dict set problemDataDict NumberofThreads $nthreads
    } else {
        #set nthreads [write::getValue Parallelization MPINumberOfProcessors]
        #dict set problemDataDict NumberofProcessors $nthreads
    }

    set echo_level [write::getValue Results EchoLevel]
    dict set problemDataDict echo_level $echo_level

    # Add ProblemData to Parameters
    dict set projectParametersDict problem_data $problemDataDict

    # Time settings
    set timeDataDict [dict create]
    dict set timeDataDict time_step [write::getValue SLTimeParameters DeltaTime]
    dict set timeDataDict start_time [write::getValue SLTimeParameters StartTime]
    dict set timeDataDict end_time [write::getValue SLTimeParameters EndTime]

    dict set projectParametersDict time_settings $timeDataDict
    
    # Model data
    # Create section
    set modelDataDict [dict create]

    # Add items
    dict set modelDataDict model_name $model_name
    set nDim [expr [string range [write::getValue nDim] 0 0] ]
    dict set modelDataDict dimension $nDim

    dict set modelDataDict domain_parts_list [write::getSubModelPartNames "SLParts"]
    dict set modelDataDict processes_parts_list [write::getSubModelPartNames "SLNodalConditions" "SLLoads"]
   
    # Add model import settings
    set importDataDict [dict create]
    #dict set importDataDict type "mdpa"
    dict set importDataDict name $model_name
    #dict set importDataDict label 0
    dict set modelDataDict input_file_settings $importDataDict
    
    # Add ModelData to Parameters
    dict set projectParametersDict model_settings $modelDataDict
    
    # Solver settings
    set solverDataDict [dict create]

    set currentStrategyId [write::getValue SLSolStrat]
    set strategy_write_name [[::Model::GetSolutionStrategy $currentStrategyId] getAttribute "python_module"]
    dict set solverDataDict solver_type $strategy_write_name

    # Solver parameters
    set solverParametersDict [dict create]

    # Time integration settings
    set integrationDataDict [dict create]

    dict set integrationDataDict solution_type [write::getValue SLSoluType]

    set solutiontype [write::getValue SLSoluType]
    if {$solutiontype ne "Dynamic"} {
	dict set integrationDataDict integration_method "Static"
	dict set integrationDataDict analysis_type [write::getValue SLAnalysisType]
    } else {
	dict set integrationDataDict time_integration [write::getValue SLSolStrat]
        dict set integrationDataDict integration_method [write::getValue SLScheme]
    }

    # Solving strategy settings
    set strategyDataDict [dict create]
    
    # Solution strategy parameters and Solvers   
    set strategyDataDict [dict merge $strategyDataDict [write::getSolutionStrategyParametersDict] ]

    # Get integration order as term for the integration settings
    set exist_time_integration [dict exists $strategyDataDict time_integration_order]
    if {$exist_time_integration eq 1} {
	dict set integrationDataDict time_integration_order [dict get $strategyDataDict time_integration_order]
	dict unset strategyDataDict time_integration_order
    }
    
    dict set solverParametersDict time_integration_settings $integrationDataDict

    # Get convergence criterion settings
    set convergenceDataDict [dict create]
    set exist_convergence_criterion [dict exists $strategyDataDict convergence_criterion]
    if {$exist_convergence_criterion eq 1} {
	dict set convergenceDataDict convergence_criterion [dict get $strategyDataDict convergence_criterion]
	dict unset strategyDataDict convergence_criterion
	set exist_variable_tolerances [dict exists $strategyDataDict variable_relative_tolerance]
	if {$exist_variable_tolerances eq 1} {
	    dict set convergenceDataDict variable_relative_tolerance [dict get $strategyDataDict variable_relative_tolerance]
	    dict set convergenceDataDict variable_absolute_tolerance [dict get $strategyDataDict variable_absolute_tolerance]
	    dict unset strategyDataDict variable_relative_tolerance
	    dict unset strategyDataDict variable_absolute_tolerance
	}
	set exist_residual_tolerances [dict exists $strategyDataDict residual_relative_tolerance]
	if {$exist_residual_tolerances eq 1} {
	    dict set convergenceDataDict residual_relative_tolerance [dict get $strategyDataDict residual_relative_tolerance]
	    dict set convergenceDataDict residual_absolute_tolerance [dict get $strategyDataDict residual_absolute_tolerance]
	    dict unset strategyDataDict residual_relative_tolerance
	    dict unset strategyDataDict residual_absolute_tolerance	    
	}
    }
    
    dict set solverParametersDict convergence_criterion_settings $convergenceDataDict
    
    set strategy_data_size [dict size $strategyDataDict]
    if { $strategy_data_size ne 0 } {
	dict set solverParametersDict solving_strategy_settings $strategyDataDict
    }
    
    # Linear solver settings
    set solverParametersDict [dict merge $solverParametersDict [write::getSolversParametersDict Solid] ]
   
    # Add Dofs
    dict set solverParametersDict dofs [list {*}[DofsInElements] ]

    dict set solverDataDict Parameters $solverParametersDict

    dict set projectParametersDict solver_settings $solverDataDict

    # Lists of processes
    set nodal_conditions_dict [write::getConditionsParametersDict SLNodalConditions "Nodal"] 
    dict set projectParametersDict constraints_process_list $nodal_conditions_dict

    dict set projectParametersDict loads_process_list [write::getConditionsParametersDict SLLoads]

    # GiD output configuration
    dict set projectParametersDict output_configuration [Solid::write::GetDefaultOutputDict]

    # restart options
    set restartDict [dict create ]
    dict set restartDict SaveRestart false
    dict set restartDict RestartFrequency 0
    dict set restartDict LoadRestart false
    dict set restartDict Restart_Step 0
    #dict set projectParametersDict restart_options $restartDict
        
    return $projectParametersDict
}

proc Solid::write::DofsInElements { } {
    set dofs [list ]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute SLParts]/group/value\[@n='Element'\]"
    set elements [$root selectNodes $xp1]
    foreach element_node $elements {
        set elemid [$element_node @v]
        set elem [Model::getElement $elemid]
        foreach dof [split [$elem getAttribute "Dofs"] ","] {
            if {$dof ni $dofs} {lappend dofs $dof}
        }
    }
    return {*}$dofs
}

proc Solid::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]
    write::SetParallelismConfiguration
}
