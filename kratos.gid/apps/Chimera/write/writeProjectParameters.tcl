# Project Parameters
proc ::Chimera::write::getParametersDict { } {
    set param_dict [Fluid::write::getParametersDict]

    # Check https://github.com/KratosMultiphysics/Kratos/blob/ChimeraApplication-development_2.0/applications/ChimeraApplication/tests/flow_over_cross_monolithic/flow_over_cross_monolithic.json 
    # in branch ChimeraApplication-development_2.0

    set bound_condid ChimeraInternalBoundary${Model::SpatialDimension}
    set chimera_settings_dict [dict create ]

    # General parameters
    dict set chimera_settings_dict chimera_echo_level 1
    dict set chimera_settings_dict reformulate_chimera_every_step true

    # Chimera parts
    #set chimera_parts_dict [dict create ]
    set chimera_parts_list [list ]
    foreach patch_xml [Chimera::write::GetPatchParts] {
        set patch_name [write::GetWriteGroupName [$patch_xml @n]]
        set patch_name_write [write::transformGroupName $patch_name]
        set overlap_distance [write::getValueByXPath "[$patch_xml toXPath]/value\[@n = 'overlap_distance'\]"]
        set patch_dict [dict create ]
        dict set patch_dict model_part_name FluidModelPart.${patch_name_write}
        dict set patch_dict overlap_distance $overlap_distance
        dict set patch_dict model_import_settings input_type mdpa
        dict set patch_dict model_import_settings input_filename ${patch_name_write}
        
        # Internal boundaries
        set internal_parts_for_chimera_list [list ]
        foreach internal_boundary [Chimera::write::GetInternalBoundaries $patch_name name] {
            set internal_boundary_write_name "${bound_condid}_[write::transformGroupName ${internal_boundary}]"
            lappend internal_parts_for_chimera_list FluidModelPart.$internal_boundary_write_name
        }
        dict set patch_dict internal_parts_for_chimera $internal_parts_for_chimera_list

        set patch_list [list]
        lappend patch_list $patch_dict
        lappend chimera_parts_list $patch_list
    }
    dict set chimera_settings_dict chimera_parts $chimera_parts_list

    dict set param_dict solver_settings chimera_settings $chimera_settings_dict
    return $param_dict
}

proc Chimera::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
