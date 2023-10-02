
# Get the dictionary for the preprocess of the stage
proc ::write::getPreprocessForStage {stage {mdpaimporter ""}} {
    set stage_preprocess [dict create ]
    set operation_parameters [dict create ]
    dict set stage_preprocess operations [list [dict create name "user_operation.EmptyOperation" Parameters $operation_parameters]] 

    if { $mdpaimporter ne "" } {
        # Get the modeler parameters
        set modeler [dict create name "Modelers.KratosMultiphysics.ImportMDPAModeler" Parameters $mdpaimporter]  
        dict set stage_preprocess modelers [list $modeler]
    }

    return $stage_preprocess 
}

# Get the dictionary for the postprocess of the stage
proc ::write::getPostprocessForStage {stage} {
    set stage_postprocess [dict create ]
    dict set stage_postprocess operations [list [dict create name "user_operation.EmptyOperation" Parameters [dict create ] ]] 

    return $stage_postprocess 
}

proc ::write::GetOrchestratorDict { stages_names } {
    
    set orchestrator_dict [dict create]
    dict set orchestrator_dict name "MultistageOrchestrators.KratosMultiphysics.SequentialMultistageOrchestrator"
    dict set orchestrator_dict settings echo_level 0
    dict set orchestrator_dict settings execution_list $stages_names
    dict set orchestrator_dict settings stage_checkpoints true
    dict set orchestrator_dict settings stage_checkpoints_folder new_checkpoints
    # dict set orchestrator_dict settings load_from_checkpoint "new_checkpoints/fluid_stage"
    return $orchestrator_dict
}
