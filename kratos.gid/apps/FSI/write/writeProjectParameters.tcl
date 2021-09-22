# Project Parameters
proc ::FSI::write::getParametersDict { } {
    # Init the Fluid and Structural dicts
    InitExternalProjectParameters

    set projectParametersDict [dict create]

    # Problem data
    set problem_data_dict [GetProblemDataDict]
    dict set projectParametersDict problem_data $problem_data_dict

    # Solver settings
    set solver_settings_dict [GetSolverSettingsDict]
    dict set projectParametersDict solver_settings $solver_settings_dict
    
    # Processes settings
    set processes_dict [GetProcessesDict]
    dict set projectParametersDict processes $processes_dict

    # Output processes settings
    set output_processes [GetOutputProcessesDict]
    dict set projectParametersDict output_processes $output_processes

    return $projectParametersDict
}

proc ::FSI::write::writeParametersEvent { } {
   set projectParametersDict [getParametersDict]
   write::SetParallelismConfiguration
   write::WriteJSON $projectParametersDict
}

proc ::FSI::write::GetProblemDataDict { } {
    # Copy the section from the Fluid, who owns the time parameters of the model
    set problem_data_dict [dict get $FSI::write::fluid_project_parameters problem_data]
    return $problem_data_dict
}

proc ::FSI::write::GetSolverSettingsDict { } {
    variable mdpa_names

    set solver_settings_dict [dict create]
    set currentStrategyId [write::getValue FSISolStrat]
    set currentCouplingSchemeId [write::getValue FSIScheme]

    dict set solver_settings_dict solver_type $currentStrategyId
    dict set solver_settings_dict coupling_scheme $currentCouplingSchemeId
    # TODO: place an echo level in coupling
    dict set solver_settings_dict echo_level 1

    dict set solver_settings_dict structure_solver_settings [dict get $FSI::write::structure_project_parameters solver_settings]
    dict set solver_settings_dict fluid_solver_settings [dict get $FSI::write::fluid_project_parameters solver_settings]

    # TODO: place an echo level in meshing
    set mesh_settings_dict [dict create ]
    dict set mesh_settings_dict echo_level 0
    dict set mesh_settings_dict domain_size [string index $::Model::SpatialDimension 0]
    dict set mesh_settings_dict model_part_name [Fluid::write::GetAttribute model_part_name]
    dict set mesh_settings_dict solver_type [write::getValue FSIALEParams MeshSolver]
    dict set solver_settings_dict mesh_solver_settings $mesh_settings_dict

    # coupling settings

    # Mapper settings
    dict set solver_settings_dict coupling_settings [write::getSolutionStrategyParametersDict] 
    dict set solver_settings_dict coupling_settings mapper_settings [GetMappingSettingsList]

    dict set solver_settings_dict coupling_settings coupling_strategy_settings [dict get [write::getSolversParametersDict FSI] coupling_strategy]

    
    # structure interface
    set structure_interfaces_list [list ]
    set structure_interfaces_list_raw [write::GetSubModelPartFromCondition STLoads StructureInterface2D]
    lappend structure_interfaces_list_raw {*}[write::GetSubModelPartFromCondition STLoads StructureInterface3D]
    foreach interface $structure_interfaces_list_raw {
        lappend structure_interfaces_list [Structural::write::GetAttribute model_part_name].$interface
    }
    dict set solver_settings_dict coupling_settings structure_interfaces_list $structure_interfaces_list

    # Fluid interface
    set fluid_interface_uniquename FluidNoSlipInterface$::Model::SpatialDimension
    set fluid_interfaces_list [list ]
    set fluid_interfaces_list_raw [write::GetSubModelPartFromCondition FLBC $fluid_interface_uniquename]
    foreach interface $fluid_interfaces_list_raw {
        lappend fluid_interfaces_list [Fluid::write::GetAttribute model_part_name].$interface
    }
    dict set solver_settings_dict coupling_settings fluid_interfaces_list $fluid_interfaces_list
    
    # Change the input_filenames
    dict set solver_settings_dict structure_solver_settings model_import_settings input_filename [dict get $mdpa_names Structural]
    dict set solver_settings_dict fluid_solver_settings model_import_settings input_filename [dict get $mdpa_names Fluid]

    # Add the MESH_DISPLACEMENT to the gid_output process
    # set gid_output [lindex [dict get $FluidParametersDict output_processes gid_output] 0]
    # set nodalresults [dict get $gid_output Parameters postprocess_parameters result_file_configuration nodal_results]
    # lappend nodalresults "MESH_DISPLACEMENT"
    # dict set gid_output Parameters postprocess_parameters result_file_configuration nodal_results $nodalresults
 

}

proc ::FSI::write::GetProcessesDict { } {
    set processes_dict [dict create]
    
    # Fluid
    dict set processes_dict fluid_initial_conditions_process_list [dict get $FSI::write::fluid_project_parameters processes initial_conditions_process_list]
    dict set processes_dict fluid_boundary_conditions_process_list [dict get $FSI::write::fluid_project_parameters processes boundary_conditions_process_list]
    dict set processes_dict fluid_gravity [dict get $FSI::write::fluid_project_parameters processes gravity]
    dict set processes_dict fluid_auxiliar_process_list [dict get $FSI::write::fluid_project_parameters processes auxiliar_process_list]
    
    # Structure
    dict set processes_dict structure_constraints_process_list [dict get $FSI::write::structure_project_parameters processes constraints_process_list]
    dict set processes_dict structure_loads_process_list [dict get $FSI::write::structure_project_parameters processes loads_process_list]

    return $processes_dict
}

proc ::FSI::write::GetOutputProcessesDict { } {
    set output_processes_dict [dict create]
    set gid_output_list [list ]

    # Set a different output_name for the fluid and structure domains
    set structure_output [lindex [dict get $FSI::write::structure_project_parameters output_processes gid_output] 0]
    dict set structure_output Parameters output_name "[dict get $structure_output Parameters output_name]_structure"
    set fluid_output [lindex [dict get $FSI::write::fluid_project_parameters output_processes gid_output] 0]
    dict set fluid_output Parameters output_name "[dict get $fluid_output Parameters output_name]_fluid"

    # Append the fluid and structure output processes to the output processes dictionary
    lappend gid_output_list $structure_output
    lappend gid_output_list $fluid_output
    
    dict set output_processes_dict gid_output $gid_output_list
    return $output_processes_dict
}

proc ::FSI::write::UpdateUniqueNames { appid } {
    set unList [list "Results"]
    foreach un $unList {
        set current_un [apps::getAppUniqueName $appid $un]
        spdAux::setRoute $un [spdAux::getRoute $current_un]
    }
}

proc ::FSI::write::GetMappingSettingsList { } {
    set mappingsList [list ]

    set fluid_interface_name FluidNoSlipInterface$::Model::SpatialDimension
    set structural_interface_name StructureInterface$::Model::SpatialDimension
    set structuralInterface [lindex [write::GetSubModelPartFromCondition STLoads $structural_interface_name] 0]
    foreach fluid_interface [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute FLBC]/condition\[@n = '$fluid_interface_name'\]/group" ] {
        set map [dict create]
        set mapper_face [write::getValueByNode [$fluid_interface selectNodes ".//value\[@n='mapper_face']"] ]
        dict set map mapper_face $mapper_face
        dict set map fluid_interface_submodelpart_name [Fluid::write::GetAttribute model_part_name].[write::getSubModelPartId $fluid_interface_name [get_domnode_attribute $fluid_interface n]]
        dict set map structure_interface_submodelpart_name [Structural::write::GetAttribute model_part_name].$structuralInterface
        lappend mappingsList $map
    }

    return $mappingsList
}

proc ::FSI::write::InitExternalProjectParameters { } {
    # Fluid section
    UpdateUniqueNames Fluid
    apps::setActiveAppSoft Fluid
    write::initWriteConfiguration [Fluid::write::GetAttributes]
    set FSI::write::fluid_project_parameters [Fluid::write::getParametersDict]

    # Structure section
    UpdateUniqueNames Structure
    apps::setActiveAppSoft Structure
    Structural::write::SetAttribute time_parameters_un FLTimeParameters
    write::initWriteConfiguration [Structural::write::GetAttributes]
    set FSI::write::structure_project_parameters [Structural::write::getParametersDict]
    
    apps::setActiveAppSoft FSI
}