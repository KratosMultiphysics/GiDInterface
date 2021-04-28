proc DEM::write::getDEMMaterialsDict { } {
    
    # Loop over parts, inlets and walls to list the materials to print. For each material used print: DENSITY, YOUNG_MODULUS, POISSON_RATIO
    # print COMPUTE_WEAR as false always, too (temporal fix)
    # While looping, create the assignation_table_list
    set materials_node_list [DEM::write::GetMaterialsNodeList]

    set materials_list [list ]
    set processed_mats [list ]
    foreach mat_node $materials_node_list {
        set mat_name [write::getValueByNode $mat_node]
        if {$mat_name ni $processed_mats} {
            set mat [dict create]
            dict set mat material_name $mat_name
            set material_xp "[spdAux::getRoute [GetAttribute materials_un]]/blockdata\[@name='$mat_name'\]"
            foreach param [[customlib::GetBaseRoot] selectNodes "$material_xp/value"] {
                dict set mat properties [$param @n] [write::getValueByNode $param]
            }
            lappend materials_list $mat
            lappend processed_mats $mat_name
        }
    }
    
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


proc DEM::write::GetMaterialsNodeList { } {
    # Dem needs more material information than default
    set materials [list ]

    set root [customlib::GetBaseRoot]

    foreach mat [$root selectNodes "//value\[@n='material'\]"] {
        lappend materials $mat
    }
    return $materials
}