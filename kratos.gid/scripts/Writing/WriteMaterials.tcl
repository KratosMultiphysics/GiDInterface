
# This function stores in mat dict all the processed materials, and returns the new ones
proc write::processMaterials { {alt_path ""} {last_assigned_id -1}} {
    variable mat_dict

    set new_mats [dict create ]

    # Prepare paths
    set parts [GetConfigurationAttribute parts_un]
    set materials_un [GetConfigurationAttribute materials_un]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $parts]/group"
    if {[llength [$root selectNodes $xp1]] < 1} {
        set xp1 "[spdAux::getRoute $parts]/condition/group"
    }
    if {$alt_path ne ""} {
        set xp1 $alt_path
    }
    set xp2 ".//value\[@n='Material']"
    set material_number [expr {$last_assigned_id == -1 ? [llength [dict keys $mat_dict] ] : $last_assigned_id }]
    
    # Foreach group applied to parts
    foreach gNode [$root selectNodes $xp1] {
        # Get the application. Important in Mixed apps (multiple inheritance).
        set nodeApp [spdAux::GetAppIdFromNode $gNode]
        # Get the write group name. Used as unique id due to intervals and child tricks.
        set group_name [write::GetWriteGroupName [$gNode @n]]
        # This group nodes are (always) child of condition (by definition), so get the condition is easy.
        set cond_name [[$gNode parent] @n]
        # Using the condition and the group name, we can get the submodelpart id. A submodelpart is always the joint of condition + group.
        set submodelpart_id [write::GetSubModelPartName $cond_name $group_name]
        
        #set material_name "material $material_number".
        if { ![dict exists $mat_dict $submodelpart_id] } {
            # increment the material number. In multi part apps, this material number is passed as variable, in order to keep the numeration.
            incr material_number
            set mid $material_number

            # Init the dictionary with initial data.
            dict set mat_dict $submodelpart_id MID $material_number
            dict set mat_dict $submodelpart_id APPID $nodeApp

            # Get the elements name. Even if it's not used in this section, it's important to call it, so dependencies are applied.
            catch {
                set element_node [$gNode selectNodes ".//value\[@n = 'Element'\]"]
                if {$element_node ne ""} {
                    set element_name [write::getValueByNode $element_node "force"]
                }
                set element_name [write::getValueByNode $element_node "force"]
            }

            # We have 2 ways to get the properties (output type): 
            # A) Defined by all the values available below parts
            # B) (By default) Defined also by the material parameters

            # Get the constitutive law output type
            set output_type Materials
            set claw_node [$gNode selectNodes ".//value\[@n = 'ConstitutiveLaw'\]"]
            if {$claw_node ne ""} {
                set claw [write::getValueByNode $claw_node "force"]
                if {$claw ne "None"} {
                    set const_law [Model::getConstitutiveLaw $claw]
                    set output_type [$const_law getOutputMode]
                }
            }
            # Case A -> By parameters below parts
            if {$output_type eq "Parameters"} {
                set s1 [$gNode selectNodes ".//value"]
            } else {
            # Case B -> Include materials parameters
                set s1 ""
                set matvalueNode [$gNode selectNodes $xp2]
                if {$matvalueNode ne ""} {
                    set real_material_name [write::getValueByNode $matvalueNode "force"]
                    set xp3 "[spdAux::getRoute $materials_un]/blockdata\[@n='material' and @name='$real_material_name']"
                    set matNode [$root selectNodes $xp3]
                    set s1 [join [list [$gNode selectNodes ".//value"] [$matNode selectNodes ".//value"]]]
                } else {
                    set s1 [$gNode selectNodes ".//value"]
                }
            }

            # Once we have all the 'value' nodes, lets get it's value and add them to the list
            foreach valueNode $s1 {
                # Force update, useful in combo with part dependencies
                write::forceUpdateNode $valueNode
                # name and state, useful for filtering
                set name [$valueNode getAttribute n]
                set state [get_domnode_attribute $valueNode state]
                # hidden values and constitutive law are not included in properties
                if {$state ne "hidden" || $name eq "ConstitutiveLaw"} {
                    if {[$valueNode hasAttribute type] && [$valueNode @type] eq "matrix"} {
                        set value [list ]
                        set M [gid_groups_conds::read_matrix_function $valueNode]
                        for {set i 0} {$i < [$valueNode @dimension_function_rows]} {incr i} {
                            set row [list ]
                            set cols [$valueNode @dimension_function_cols]
                            for {set j 0} {$j < $cols} {incr j} {
                                lappend row [expr [lindex $M [expr ($i*$cols)+$j]]]
                            }
                            lappend value $row
                        }
                    } else {
                        # All the introduced values are translated to 'm' and 'kg' with the help of this function
                        set value [gid_groups_conds::convert_value_to_default $valueNode]
                    } 
                    dict set mat_dict $submodelpart_id $name $value
                }
            }
            dict set new_mats $submodelpart_id [dict get $mat_dict $submodelpart_id]
        }
    }
    return $new_mats
}

proc write::writeMaterials { {appid ""} {const_law_write_name ""}} {
    variable mat_dict
    variable current_mdpa_indent_level

    set exclusionList [list "MID" "APPID" "Material" "Element"]
    if {$const_law_write_name eq ""} {lappend exclusionList "ConstitutiveLaw"}

    # We print all the material data directly from the saved dictionary
    foreach material [dict keys $mat_dict] {
        set matapp [dict get $mat_dict $material APPID]
        if {$appid eq "" || $matapp in $appid} {
            set s [mdpaIndent]
            WriteString "${s}Begin Properties [dict get $mat_dict $material MID]"
            incr current_mdpa_indent_level
            set s [mdpaIndent]
            foreach prop [dict keys [dict get $mat_dict $material] ] {
                if {$prop ni $exclusionList} {
                    if {${prop} eq "ConstitutiveLaw"} {
                        set propname $const_law_write_name
                        set value [[Model::getConstitutiveLaw [dict get $mat_dict $material $prop]] getKratosName]
                    } else {
                        set propname [expr { ${prop} eq "ConstitutiveLaw" ? $const_law_write_name : $prop}]
                        set value [dict get $mat_dict $material $prop]
                    }
                    WriteString "${s}$propname $value"
                }
            }
            incr current_mdpa_indent_level -1
            set s [mdpaIndent]
            WriteString "${s}End Properties"
            WriteString ""
        }
    }
}

proc write::getPropertiesJson {{parts_un ""} {write_claw_name "True"} {model_part_name ""}} {
    if {$parts_un eq ""} {set parts_un [GetConfigurationAttribute parts_un]}
    set mats_json [getPropertiesList $parts_un $write_claw_name $model_part_name]
    return $mats_json
}

proc write::writePropertiesJsonFile {{parts_un ""} {fname "materials.json"} {write_claw_name "True"} {model_part_name ""}} {
    write::writePropertiesJsonFileDone $fname [write::getPropertiesJson $parts_un $write_claw_name $model_part_name]
}
proc write::writePropertiesJsonFileDone {fname json} {
    write::OpenFile $fname
    write::WriteJSON $json
    write::CloseFile
}

proc write::getPropertiesListByConditionXPath {cnd_xpath {write_claw_name "True"} {model_part_name ""}} {
    variable mat_dict
    variable properties_exclusion_list
    set exclusionList $properties_exclusion_list
    set props_dict [dict create]
    set props [list ]

    # first property
    set first [dict create "model_part_name" $model_part_name "properties_id" 0 "Material" [dict create Variables [dict create]]]
    lappend props $first

    set doc $gid_groups_conds::doc
    set root [$doc documentElement]
    
    # iterate over the groups of the conditions
    foreach gNode [$root selectNodes "$cnd_xpath/group"] {
        # Group name
        set group [get_domnode_attribute $gNode n]
        # Condition name
        set cond_id [get_domnode_attribute [$gNode parent] n]
        # We get the submodelpart name and the modelpart.submodelpart
        set submodelpart_id [write::GetSubModelPartName $cond_id $group]
        set submodelpart_fullname $submodelpart_id
        if {$model_part_name ne ""} {set submodelpart_fullname $model_part_name.$submodelpart_id}
        set submodelpart_id [string trim $submodelpart_id "."]
        if { [dict exists $mat_dict $submodelpart_id] } {
            set mid [dict get $mat_dict $submodelpart_id MID]
            set prop_dict [dict create]
            dict set prop_dict "model_part_name" $submodelpart_fullname
            dict set prop_dict "properties_id" $mid
            set constitutive_law_id ""
            if {[dict exists $mat_dict $submodelpart_id ConstitutiveLaw ]} {
                set constitutive_law_id [dict get $mat_dict $submodelpart_id ConstitutiveLaw]
            }
            set constitutive_law [Model::getConstitutiveLaw $constitutive_law_id]
            
            set variables_dict [dict create]
            foreach prop [dict keys [dict get $mat_dict $submodelpart_id] ] {
                if {$prop ni $exclusionList} {
                    dict set variables_dict $prop [getFormattedValue [dict get $mat_dict $submodelpart_id $prop]]
                }
            }
            set material_dict [dict create]

            if {$constitutive_law ne "" && $write_claw_name eq "True"} {
                set constitutive_law_name [$constitutive_law getKratosName]
                dict set material_dict constitutive_law [dict create name $constitutive_law_name]
            }
            dict set material_dict Variables $variables_dict
            dict set material_dict Tables dictnull

            dict set prop_dict Material $material_dict

            lappend props $prop_dict
            
        }
    }

    dict set props_dict properties $props
    return $props_dict
}

proc write::getPropertiesList {unique_name {write_claw_name "True"} {model_part_name ""}} {

    set doc $gid_groups_conds::doc
    set root [$doc documentElement]

    set xp1 "[spdAux::getRoute $unique_name]"
    if {[llength [$root selectNodes $xp1/group]] < 1} {
        set xp1 "[spdAux::getRoute $unique_name]/condition"
    }
    return [write::getPropertiesListByConditionXPath $xp1 $write_claw_name $model_part_name]
}