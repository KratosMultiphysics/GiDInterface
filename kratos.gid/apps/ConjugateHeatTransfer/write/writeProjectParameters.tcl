# Project Parameters
proc ::ConjugateHeatTransfer::write::getParametersDict { } {
    InitExternalProjectParameters
    
    set projectParametersDict [dict create]

    # Set the problem data section
    dict set projectParametersDict problem_data [write::GetDefaultProblemDataDict]

    # Solver settings
    dict set projectParametersDict solver_settings [ConjugateHeatTransfer::write::GetSolverSettingsDict]


    return $projectParametersDict
    set processes [dict create]
    # Boundary conditions processes
    dict set processes initial_conditions_process_list [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    dict set processes constraints_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    # dict set processes fluxes_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    dict set processes list_other_processes [list [getBodyForceProcessDict] ]
    
    dict set projectParametersDict processes $processes
    # Output configuration
    dict set projectParametersDict output_processes [GetOutputProcessList]

    # Restart options
    dict set projectParametersDict restart_options [write::GetDefaultRestartDict]


    return $projectParametersDict
}

proc ConjugateHeatTransfer::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

# Body force SubModelParts and Process collection
proc ConjugateHeatTransfer::write::getBodyForceProcessDict {} {
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

proc ConjugateHeatTransfer::write::GetSolverSettingsDict {} {
    set solver_settings_dict [dict create]
    dict set solver_settings_dict solver_type "conjugate_heat_transfer"
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solver_settings_dict domain_size $nDim
    

    dict set solver_settings_dict fluid_domain_solver_settings [dict get $ConjugateHeatTransfer::write::fluid_domain_solver_settings solver_settings]
    dict set solver_settings_dict solid_domain_solver_settings [dict get $ConjugateHeatTransfer::write::solid_domain_solver_settings solver_settings]
    return $solver_settings_dict
}

proc ConjugateHeatTransfer::write::GetOutputProcessList { } {
    set result [dict create ]
    
    set gid_output [list ]
    set res_dict [dict create]
    dict set res_dict python_module gid_output_process
    dict set res_dict kratos_module KratosMultiphysics
    dict set res_dict process_name GiDOutputProcess
    dict set res_dict Parameters postprocess_parameters [write::GetDefaultOutputDict]
    
    set partgroup [write::getPartsSubModelPartId]
    dict set res_dict Parameters "model_part_name" [concat [lindex $partgroup 0]]
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set res_dict Parameters output_name $model_name
    lappend gid_output $res_dict
    dict set result gid_output $gid_output
    return $result
}


proc ConjugateHeatTransfer::write::InitExternalProjectParameters { } {
    # Buoyancy section
    apps::setActiveAppSoft Buoyancy
    write::initWriteConfiguration [Buoyancy::write::GetAttributes]
    set ConjugateHeatTransfer::write::fluid_domain_solver_settings [Buoyancy::write::getParametersDict]

    # Heating section
    apps::setActiveAppSoft ConvectionDiffusion
    write::initWriteConfiguration [ConvectionDiffusion::write::GetAttributes]
    set ConjugateHeatTransfer::write::solid_domain_solver_settings [ConvectionDiffusion::write::getParametersDict]

    apps::setActiveAppSoft ConjugateHeatTransfer
}