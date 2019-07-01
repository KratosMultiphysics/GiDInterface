# Project Parameters
proc MPMStructure::write::getParametersDict { } {
    # Init the Fluid and Structural dicts
    InitExternalProjectParameters

    set projectParametersDict [dict create]

    dict set projectParametersDict structure $MPMStructure::write::structure_project_parameters
    dict set projectParametersDict mpm $MPMStructure::write::mpm_project_parameters
    dict set projectParametersDict cosimulation [MPMStructure::write::GetCosimulationParametersDict]
    return $projectParametersDict
}

proc MPMStructure::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON [dict get $projectParametersDict cosimulation]
    write::CloseFile
    write::RenameFileInModel ProjectParameters.json ProjectParametersCosimulation.json 
    write::OpenFile ProjectParametersStructure.json 
    write::WriteJSON [dict get $projectParametersDict structure]
    write::CloseFile
    write::OpenFile ProjectParametersMPM.json 
    write::WriteJSON [dict get $projectParametersDict mpm]
    write::CloseFile
}

proc MPMStructure::write::GetProblemDataDict { } {
    # Copy the section from the Fluid, who owns the time parameters of the model
    set problem_data_dict [dict get $MPMStructure::write::fluid_project_parameters problem_data]
    return $problem_data_dict
}

proc MPMStructure::write::InitExternalProjectParameters { } {
    # Structure section
    #UpdateUniqueNames Structure
    apps::setActiveAppSoft Structure
    write::initWriteConfiguration [Structural::write::GetAttributes]
    set MPMStructure::write::structure_project_parameters [Structural::write::getParametersDict]

    # MPM section
    apps::setActiveAppSoft MPM
    write::initWriteConfiguration [MPM::write::GetAttributes]
    set MPMStructure::write::mpm_project_parameters [MPM::write::getParametersDict]
    
    apps::setActiveAppSoft MPMStructure
}

proc MPMStructure::write::GetCosimulationParametersDict { } {
    set propertiesDict [dict create ]

    set problem_data_dict [dict create]
    dict set problem_data_dict start_time 0.0
    dict set problem_data_dict end_time 2.0
    dict set problem_data_dict echo_level 0
    dict set problem_data_dict print_colors true
    dict set propertiesDict problem_data $problem_data_dict

    set solver_settings_dict [dict create]
    dict set solver_settings_dict solver_type gauss_seidel_strong_coupling
    dict set solver_settings_dict echo_level 3
    dict set solver_settings_dict num_coupling_iterations 20
    dict set solver_settings_dict start_coupling_time 0.0
    dict set solver_settings_dict predictor_settings predictor_type linear_derivative_based
    dict set solver_settings_dict predictor_settings data_list [list [dict create solver particle data_name disp derivative_data_name vel]]
    dict set solver_settings_dict convergence_accelerator_settings type mvqn
    dict set solver_settings_dict convergence_accelerator_settings data_list [list [dict create solver particle data_name disp]]
    dict set solver_settings_dict convergence_accelerator_settings data_list [list [dict create solver particle data_name disp abs_tolerance 1e-5 rel_tolerance 1e-5]]
    dict set solver_settings_dict coupling_loop [list ]
    dict lappend solver_settings_dict coupling_loop [dict create name particle input_data_list [list ] output_data_list [list ] ]
    dict lappend solver_settings_dict coupling_loop [dict create name structure \
        input_data_list [list from_solver particle data_name force io_settings [dict create mapper_type nearest_neighbor mapper_args [list conservative]]] \
        output_data_list [list [dict create to_solver particle data_name disp io_settings [dict create mapper_type nearest_neighbor]] \
        [dict create to_solver particle data_name vel io_settings [dict create mapper_type nearest_neighbor] ]  \
        [dict create to_solver particle data_name normal io_settings [dict create mapper_type nearest_neighbor] ]]] 
    
    set solvers_dict [dict create]
    set particle_dict [dict create solver_type kratos_particle input_file ProjectParametersMPM]
    dict set particle_dict data [dict create disp [dict create geometry_name MPM_Coupling_Interface data_identifier DISPLACEMENT data_format kratos_modelpart] \
    vel [dict create geometry_name MPM_Coupling_Interface data_identifier VELOCITY data_format kratos_modelpart] \
    force [dict create geometry_name MPM_Coupling_Interface data_identifier CONTACT_FORCE data_format kratos_modelpart] \
    normal [dict create geometry_name MPM_Coupling_Interface data_identifier NORMAL data_format kratos_modelpart]] 
    dict set solvers_dict particle $particle_dict

    set structure_dict [dict create solver_type kratos_structural input_file ProjectParametersFEM]
    dict set structure_dict data [dict create disp [dict create geometry_name Structure.LineLoad2D_NormalCalculator data_identifier DISPLACEMENT data_format kratos_modelpart] \
    vel [dict create geometry_name Structure.LineLoad2D_NormalCalculator data_identifier VELOCITY data_format kratos_modelpart] \
    force [dict create geometry_name Structure.LineLoad2D_NormalCalculator data_identifier POINT_LOAD type_of_quantity _nodal_point data_format kratos_modelpart] \
    normal [dict create geometry_name Structure.LineLoad2D_NormalCalculator data_identifier NORMAL data_format kratos_modelpart]] 
    dict set solvers_dict structure $structure_dict
    dict set solver_settings_dict solvers $solvers_dict

    dict set propertiesDict solver_settings $solver_settings_dict
    
    return $propertiesDict
}