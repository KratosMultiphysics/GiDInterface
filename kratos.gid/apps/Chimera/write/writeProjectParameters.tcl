# Project Parameters
proc ::Chimera::write::getParametersDict { } {
    set param_dict [Fluid::write::getParametersDict]

    # Check https://github.com/KratosMultiphysics/Kratos/blob/ChimeraApplication-development_2.0/applications/ChimeraApplication/tests/flow_over_cross_monolithic/flow_over_cross_monolithic.json 
    # in branch ChimeraApplication-development_2.0

    set chimera_settings_dict [dict create ]

    # General parameters
    dict set chimera_settings_dict chimera_echo_level 1
    dict set chimera_settings_dict reformulate_chimera_every_step true

    # Internal boundaries
    set internal_parts_for_chimera_list [list ]
    dict set chimera_settings_dict internal_parts_for_chimera $internal_parts_for_chimera_list

    # "chimera_settings":{
    #     "chimera_echo_level" : 1,
    #     "reformulate_chimera_every_step":true,
    #     "chimera_parts": [
    #         [
    #             {
    #                 "model_part_name": "FluidModelPart.GENERIC_background_surface",
    #                 "overlap_distance": 0.01
    #             }
    #         ],
    #         [
    #             {
    #                 "model_part_name": "FluidModelPart.GENERIC_patch_surface",
    #                 "overlap_distance": 0.7
    #             }
    #         ]
    #     ],
    #     "internal_parts_for_chimera":["FluidModelPart.NoSlip2D_cross"]
    # }

    dict set param_dict solver_settings chimera_settings $chimera_settings_dict
    return $param_dict
}

proc Chimera::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
