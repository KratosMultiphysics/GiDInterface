# Project Parameters
proc FSI::write::getParametersDict { } {
    # Init the Fluid and Structural dicts
    InitExternalProjectParameters

   set projectParametersDict [dict create]

   # Problem data
   set problem_data_dict [GetProblemDataDict]
   dict set FSIParametersDict problem_data $problem_data_dict

   # Solver settings
   set solver_settings_dict [GetSolverSettingsDict]
   dict set FSIParametersDict solver_settings $solver_settings_dict
   
   # Processes settings
   set processes_dict [GetProcessesDict]
   dict set FSIParametersDict processes $processes_dict

   # Output processes settings
   set processes_dict [GetOutputProcessesDict]
   dict set FSIParametersDict processes $output_processes

   return $projectParametersDict
}

proc FSI::write::writeParametersEvent { } {
   set projectParametersDict [getParametersDict]
   write::SetParallelismConfiguration
   write::WriteJSON $projectParametersDict
}

proc FSI::write::GetProblemDataDict { } {
    # Initialize dict
    set problem_data_dict [dict create]

    # TODO: Problem name

    # Parallelism data
    set paralleltype [write::getValue ParallelType]
    dict set problem_data_dict parallel_type $paralleltype

    # TODO: Echo level
    # TODO: Start time
    # TODO: End time

    return $problem_data_dict
}
proc FSI::write::GetSolverSettingsDict { } {
    
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
    write::initWriteConfiguration [Structure::write::GetAttributes]
    set FSI::write::structure_project_parameters [Structure::write::getParametersDict]
}