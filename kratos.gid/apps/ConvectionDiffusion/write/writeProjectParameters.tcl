# Project Parameters
proc ::ConvectionDiffusion::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # First section -> Problem data
    set problemDataDict [dict create]
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set problemDataDict problem_name $model_name

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    dict set problemDataDict "parallel_type" $paralleltype

    # Write the echo level in the problem data section
    set echo_level [write::getValue Results EchoLevel]
    dict set problemDataDict echo_level $echo_level

    # Time Parameters
    if {[write::getValue CNVDFFSolStrat] eq "transient"} {
        dict set problemDataDict start_time [write::getValue CNVDFFTimeParameters StartTime]
        dict set problemDataDict end_time [write::getValue CNVDFFTimeParameters EndTime]
    } else {
        dict set problemDataDict start_time 0.0
        dict set problemDataDict end_time 0.99
    }

    # Set the problem data section
    dict set projectParametersDict problem_data $problemDataDict

    # Output configuration
    dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]

    # Restart options
    set restartDict [dict create]
    dict set restartDict SaveRestart False
    dict set restartDict RestartFrequency 0
    dict set restartDict LoadRestart False
    dict set restartDict Restart_Step 0
    dict set projectParametersDict restart_options $restartDict

    # Solver settings
    set solverSettingsDict [dict create]
    set currentStrategyId [write::getValue CNVDFFSolStrat]
    set currentAnalysisTypeId [write::getValue CNVDFFAnalysisType]
    dict set solverSettingsDict solver_type $currentStrategyId
    dict set solverSettingsDict analysis_type $currentAnalysisTypeId
    dict set solverSettingsDict model_part_name "ThermalModelPart"
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solverSettingsDict domain_size $nDim

    # Model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename $model_name
    dict set solverSettingsDict model_import_settings $modelDict

    set materialsDict [dict create]
    dict set materialsDict materials_filename [GetAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict ConvectionDiffusion] ]

    # Parts
    dict set solverSettingsDict problem_domain_sub_model_part_list [write::getSubModelPartNames [GetAttribute parts_un]]
    dict set solverSettingsDict processes_sub_model_part_list [write::getSubModelPartNames [GetAttribute nodal_conditions_un] [GetAttribute conditions_un] ]

    # Time stepping settings
    set timeSteppingDict [dict create]
    if {[write::getValue CNVDFFSolStrat] eq "transient"} {
        dict set timeSteppingDict "time_step" [write::getValue CNVDFFTimeParameters DeltaTime]
    } else {
        dict set timeSteppingDict time_step 1.0
    }
    dict set solverSettingsDict time_stepping $timeSteppingDict

    dict set projectParametersDict solver_settings $solverSettingsDict

    # Boundary conditions processes
    dict set projectParametersDict initial_conditions_process_list [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    dict set projectParametersDict constraints_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    # dict set projectParametersDict fluxes_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    dict set projectParametersDict list_other_processes [list [getBodyForceProcessDict] ]

    return $projectParametersDict
}

proc ConvectionDiffusion::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

# Body force SubModelParts and Process collection
proc ConvectionDiffusion::write::getBodyForceProcessDict {} {
    set root [customlib::GetBaseRoot]

    set value [write::getValue CNVDFFBodyForce BodyForceValue]
    set pdict [dict create]
    dict set pdict "python_module" "assign_scalar_variable_process"
    dict set pdict "kratos_module" "KratosMultiphysics"
    dict set pdict "process_name" "AssignScalarVariableProcess"
    set params [dict create]
    set partgroup [write::getPartsSubModelPartId]
    dict set params "model_part_name" [concat [lindex $partgroup 0]]
    dict set params "variable_name" "HEAT_FLUX"
    dict set params "value" $value
    dict set params "constrained" false
    dict set pdict "Parameters" $params

    return $pdict
}
