proc DEM::write::getDEMMaterialsDict { } {
    
    # Loop over parts, inlets and walls to list the materials to print. For each material used print: DENSITY, YOUNG_MODULUS, POISSON_RATIO
    # print COMPUTE_WEAR as false always, too (temporal fix)
    # While looping, create the assignation_table_list
    set materials_list [DEM::write::GetMaterialsList]
    
    # Loop over the material relations, which is a new menu in the tree linking each possible pair of materials
    set material_relations_list [list ]
    
    
    set assignation_table_list [list ]
    
    
    dict set global_dict "materials" $materials_list
    dict set global_dict "material_relations" $material_relations_list
    dict set global_dict "material_assignation_table" $assignation_table_list
    
    return $global_dict
}

# EXAMPLE
#{
#    "materials":[{
#        "material_name": "mat1",
#        "material_id": 1,
#        "properties":{
#            "PARTICLE_DENSITY": 4000.0,
#            "YOUNG_MODULUS": 10000000.0,
#            "POISSON_RATIO": 0.20
#        }
#    },{
#        "material_name": "mat2",
#        "material_id": 2,
#        "properties":{
#            "YOUNG_MODULUS": 1.0e20,
#            "POISSON_RATIO": 0.25,
#            "COMPUTE_WEAR": false
#        }
#    }],
#    "material_relations":[{
#        "material_names_list":["mat1", "mat1"],
#        "material_ids_list":[1, 1],
#        "properties":{
#            "COEFFICIENT_OF_RESTITUTION": 0.2,
#            "STATIC_FRICTION": 0.577350269189494,
#            "DYNAMIC_FRICTION": 0.577350269189494,
#            "FRICTION_DECAY": 500,
#            "ROLLING_FRICTION": 0.01,
#            "ROLLING_FRICTION_WITH_WALLS": 0.01,
#            "DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME": "DEM_D_Hertz_viscous_Coulomb"
#        }
#    },{
#        "material_names_list":["mat1", "mat2"],
#        "material_ids_list":[1, 2],
#        "properties":{
#            "COEFFICIENT_OF_RESTITUTION": 0.2,
#            "STATIC_FRICTION": 0.577350269189494,
#            "DYNAMIC_FRICTION": 0.577350269189494,
#            "FRICTION_DECAY": 500,
#            "ROLLING_FRICTION": 0.01,
#            "ROLLING_FRICTION_WITH_WALLS": 0.01,
#            "SEVERITY_OF_WEAR": 0.001,
#            "IMPACT_WEAR_SEVERITY": 0.001,
#            "BRINELL_HARDNESS": 200.0,
#            "DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME": "DEM_D_Hertz_viscous_Coulomb"
#        }
#    }],
#    "material_assignation_table":[
#        ["ClusterPart", "mat1"],
#        ["RigidFacePart","mat2"]
#    ]
#}


proc DEM::write::GetMaterialsList { } {
    # Dem needs more material information than default
    set old_properties_exclusion_list $write::properties_exclusion_list
    set write::properties_exclusion_list [list "APPID" "Element"]
    
    # Trick to use the common function, since DEM is the only app with materials inside conditions
    # First we get material information used in Parts
    set parts_un [GetAttribute parts_un]
    set orig_parts_un $parts_un
    write::processMaterials
    set parts_material_dict [write::getPropertiesList $parts_un]
    
    # Then we get material information used in Conditions
    write::SetConfigurationAttribute parts_un [GetAttribute conditions_un]
    write::processMaterials
    set conditions_material_dict [write::getPropertiesList [GetAttribute conditions_un]]

    # And finally we get the material information used in Nodal conditions
    write::SetConfigurationAttribute parts_un [GetAttribute nodal_conditions_un]
    write::processMaterials
    set nodal_conditions_material_dict [write::getPropertiesList [GetAttribute nodal_conditions_un]]

    # Restore original variables
    write::SetConfigurationAttribute parts_un $orig_parts_un
    set write::properties_exclusion_list $old_properties_exclusion_list
    
    # Return the join of the 3 material dicts
    return $parts_material_dict
    set materials [dict merge $parts_material_dict $conditions_material_dict $nodal_conditions_material_dict]
    W $materials
    return $materials
}