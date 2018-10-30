# Project Parameters
proc FSI::write::getParametersDict { } {
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

proc FSI::write::writeParametersEvent { } {
   set projectParametersDict [getParametersDict]
   write::SetParallelismConfiguration
   write::WriteJSON $projectParametersDict
}

proc FSI::write::GetProblemDataDict { } {
    # Copy the section from the Fluid, who owns the time parameters of the model
    set problem_data_dict [dict get $FSI::write::fluid_project_parameters problem_data]
    return $problem_data_dict
}
proc FSI::write::GetSolverSettingsDict { } {
    
}

proc FSI::write::GetProcessesDict { } {
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

proc FSI::write::GetOutputProcessesDict { } {
    set output_processes_dict [dict create]
    set gid_output_list [list ]

    # Structure
    lappend gid_output_list [lindex [dict get $FSI::write::structure_project_parameters output_processes gid_output] 0]
    
    # Fluid
    lappend gid_output_list [lindex [dict get $FSI::write::fluid_project_parameters output_processes gid_output] 0]
    
    dict set output_processes_dict gid_output $gid_output_list
    return $output_processes_dict
}

proc FSI::write::UpdateUniqueNames { appid } {
    set unList [list "Results"]
    foreach un $unList {
         set current_un [apps::getAppUniqueName $appid $un]
         spdAux::setRoute $un [spdAux::getRoute $current_un]
    }
}

proc FSI::write::GetMappingSettingsList { } {
    set mappingsList [list ]

    set fluid_interface_name FluidNoSlipInterface$::Model::SpatialDimension
    set structural_interface_name StructureInterface$::Model::SpatialDimension
    set structuralInterface [lindex [write::GetSubModelPartFromCondition STLoads $structural_interface_name] 0]
    foreach fluid_interface [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute FLBC]/condition\[@n = '$fluid_interface_name'\]/group" ] {
        set map [dict create]
        set mapper_face [write::getValueByNode [$fluid_interface selectNodes ".//value\[@n='mapper_face']"] ]
        dict set map mapper_face $mapper_face
        dict set map fluid_interface_submodelpart_name [write::getSubModelPartId $fluid_interface_name [get_domnode_attribute $fluid_interface n]]
        dict set map structure_interface_submodelpart_name $structuralInterface
        lappend mappingsList $map
    }

    return $mappingsList
}

# {
#     "mapper_face" : "Unique" (otherwise "Positive" or "Negative")
#     "fluid_interface_submodelpart_name" : "FluidNoSlipInterface2D_FluidInterface",
#     "structure_interface_submodelpart_name" : "StructureInterface2D_StructureInterface"
# }

proc FSI::write::InitExternalProjectParameters { } {
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