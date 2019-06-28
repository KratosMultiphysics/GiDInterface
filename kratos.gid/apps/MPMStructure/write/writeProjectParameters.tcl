# Project Parameters
proc MPMStructure::write::getParametersDict { } {
    # Init the Fluid and Structural dicts
    InitExternalProjectParameters

    set projectParametersDict [dict create]

    dict set projectParametersDict structure $MPMStructure::write::structure_project_parameters
    dict set projectParametersDict mpm $MPMStructure::write::mpm_project_parameters
    dict set projectParametersDict cosimulation [dict create ]

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
    dict set propertiesDict solver_settings $solver_settings_dict
    

    "solver_settings": {

        "convergence_accelerator_settings": {
            "type": "mvqn",
            "data_list": [
                {
                    "solver": "particle",
                    "data_name": "disp"
                }
            ]
        },
        "convergence_criteria_settings": {
            "data_list": [
                {
                    "solver": "particle",
                    "data_name": "disp",
                    "abs_tolerance": 1e-5,
                    "rel_tolerance": 1e-5
                }
            ]
        },
        "coupling_loop": [
            {
                "name": "particle",
                "input_data_list": [],
                "output_data_list": []
            },
            {
                "name": "structure",
                "input_data_list": [
                    {
                        "from_solver": "particle",
                        "data_name": "force",
                        "io_settings": {
                            "mapper_type": "nearest_neighbor",
                            "mapper_args": [
                                "conservative"
                            ]
                        }
                    }
                ],
                "output_data_list": [
                    {
                        "to_solver": "particle",
                        "data_name": "disp",
                        "io_settings": {
                            "mapper_type": "nearest_neighbor"
                        }
                    },
                    {
                        "to_solver": "particle",
                        "data_name": "vel",
                        "io_settings": {
                            "mapper_type": "nearest_neighbor"
                        }
                    },
                    {
                        "to_solver": "particle",
                        "data_name": "normal",
                        "io_settings": {
                            "mapper_type": "nearest_neighbor"
                        }
                    }
                ]
            }
        ],
        "solvers": {
            "particle": {
                "solver_type": "kratos_particle",
                "input_file": "ProjectParametersMPM",
                "data": {
                    "disp": {
                        "geometry_name": "MPM_Coupling_Interface",
                        "data_identifier": "DISPLACEMENT",
                        "data_format": "kratos_modelpart"
                    },
                    "vel": {
                        "geometry_name": "MPM_Coupling_Interface",
                        "data_identifier": "VELOCITY",
                        "data_format": "kratos_modelpart"
                    },
                    "force": {
                        "geometry_name": "MPM_Coupling_Interface",
                        "type_of_quantity": "_nodal_point",
                        "data_identifier": "CONTACT_FORCE",
                        "data_format": "kratos_modelpart"
                    },
                    "normal": {
                        "geometry_name": "MPM_Coupling_Interface",
                        "data_identifier": "NORMAL",
                        "data_format": "kratos_modelpart"
                    }
                }
            },
            "structure": {
                "solver_type": "kratos_structural",
                "input_file": "ProjectParametersFEM",
                "data": {
                    "disp": {
                        "geometry_name": "Structure.LineLoad2D_NormalCalculator",
                        "data_identifier": "DISPLACEMENT",
                        "data_format": "kratos_modelpart"
                    },
                    "vel": {
                        "geometry_name": "Structure.LineLoad2D_NormalCalculator",
                        "data_identifier": "VELOCITY",
                        "data_format": "kratos_modelpart"
                    },
                    "force": {
                        "geometry_name": "Structure.LineLoad2D_NormalCalculator",
                        "data_identifier": "POINT_LOAD",
                        "type_of_quantity": "_nodal_point",
                        "data_format": "kratos_modelpart"
                    },
                    "normal": {
                        "geometry_name": "Structure.LineLoad2D_NormalCalculator",
                        "data_identifier": "NORMAL",
                        "data_format": "kratos_modelpart"
                    }
                }
            }
        }
    }
}
}