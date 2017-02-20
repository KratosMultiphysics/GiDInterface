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
    if {$damTypeofProblem eq "Thermo-Mechanical"}{
        set solver_type 
    }   
    
        
    #~ dict set solversettingsDict solver_type $solver_type 
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename $model_name
    dict set modelDict input_file_label 0
    dict set solversettingsDict model_import_settings $modelDict
    dict set solversettingsDict echo_level
    dict set solversettingsDict buffer_size
    dict set solversettingsDict reference_temperature
    dict set solversettingsDict processes_sub_model_part_list [write::getSubModelPartNames "DamNodalConditions" "DamLoads"]
    
    set thermalsettingDict [dict create]
    dict set thermalsettingDict echo_level
    dict set thermalsettingDict reform_dofs_at_each_step
    dict set thermalsettingDict clear_storage
    dict set thermalsettingDict compute_reactions
    dict set thermalsettingDict move_mesh_flag
    dict set thermalsettingDict compute_norm_dx_flag
    dict set thermalsettingDict theta_scheme
    
    set thermallinearDict [dict create]
    dict set thermallinearDict solver_type
    dict set thermalsettingDict linear_solver_settings $thermallinearDict
    dict set thermalsettingDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
    
    set mechanicalsettingDict [dict create]
    dict set mechanicalsettingDict solution_type [write::getValue DamSoluType]
    dict set mechanicalsettingDict strategy_type [write::getValue DamSolStrat]
    set mechanicalsettingDict [dict merge $mechanicalsettingDict [write::getSolutionStrategyParametersDict] ]

    foreach part_name [dict keys $mat_dict] {
        if {[[Model::getElement [dict get $mat_dict $part_name Element]] getAttribute "ElementType"] eq "Joint"} {
            lappend joint_part_list [write::getMeshId Parts $part_name]
        } {
            lappend body_part_list [write::getMeshId Parts $part_name]
        }
    }
    dict set mechanicalsettingDict problem_domain_sub_model_part_list [write::getSubModelPartNames "DamParts"]
    dict set mechanicalsettingDict body_domain_sub_model_part_list $body_part_list
    dict set mechanicalsettingDict problem_domain_joint_sub_model_part_list $joint_part_list
    set strategytype [write::getValue DamSolStrat]
    if {$strategytype eq "Arc-length"} {
        dict set projectParametersDict loads_sub_model_part_list [write::getSubModelPartNames "DamLoads"]
        dict set projectParametersDict loads_variable_list [Dam::write::getVariableParametersDict DamLoads]
    }{
        dict set projectParametersDict loads_sub_model_part_list []
        dict set projectParametersDict loads_variable_list []
    }
    
    ### GiD output configuration
    dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]

    set constraints_process_list [write::getConditionsParametersDict DamNodalConditions "Nodal"]
    set loads_process_list [write::getConditionsParametersDict DamLoads ]

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
    #~ write::SetEnvironmentVariable OMP_NUM_THREADS [write::getValue DamNumThreads]
    #write::SetParallelismConfiguration DamNumThreads ""
}

proc write::GetDefaultOutputDict {} {
    set outputDict [dict create]
    set resultDict [dict create]
    
    set GiDPostDict [dict create]
    dict set GiDPostDict GiDPostMode                [write::getValue Results GiDPostMode]
    dict set GiDPostDict WriteDeformedMeshFlag      [write::getValue Results GiDWriteMeshFlag]
    dict set GiDPostDict WriteConditionsFlag        [write::getValue Results GiDWriteConditionsFlag]
    dict set GiDPostDict MultiFileFlag              [write::getValue Results GiDMultiFileFlag]
    dict set resultDict gidpost_flags $GiDPostDict
    
    dict set resultDict output_frequency [write::getValue Results OutputDeltaTime]   
    dict set resultDict nodal_results [GetResultsList NodalResults]
    dict set resultDict gauss_point_results [GetResultsList ElementResults]
    
    dict set outputDict "result_file_configuration" $resultDict
    return $outputDict
}

