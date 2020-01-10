
proc write::processMaterials { {alt_path ""} {last_assigned_id -1}} {
    variable mat_dict

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
    foreach gNode [$root selectNodes $xp1] {
        set nodeApp [spdAux::GetAppIdFromNode $gNode]
        set group [$gNode getAttribute n]
        
        set material_name "material $material_number"
        if { ![dict exists $mat_dict $group] } {
            incr material_number
            set mid $material_number

            dict set mat_dict $group MID $material_number
            dict set mat_dict $group APPID $nodeApp

            catch {
                set element_node [$gNode selectNodes ".//value\[@n = 'Element'\]"]
                if {$element_node ne ""} {
                    set element_name [write::getValueByNode $element_node "force"]
                }
                set element_name [write::getValueByNode $element_node "force"]
            }

            set claw_node [$gNode selectNodes ".//value\[@n = 'ConstitutiveLaw'\]"]
            set claw [write::getValueByNode $claw_node "force"]
            set const_law [Model::getConstitutiveLaw $claw]
            if {$const_law ne ""} {
                set output_type [$const_law getOutputMode]
                if {$output_type eq "Parameters"} {
                    set s1 [$gNode selectNodes ".//value"]
                } else {
                    set s1 ""
                    set matvalueNode [$gNode selectNodes $xp2]
                    if {$matvalueNode ne ""} {
                        set real_material_name [write::getValueByNode $matvalueNode "force"]
                        set xp3 "[spdAux::getRoute $materials_un]/blockdata\[@n='material' and @name='$real_material_name']"
                        set matNode [$root selectNodes $xp3]
                        set s1 [join [list [$gNode selectNodes ".//value"] [$matNode selectNodes ".//value"]]]
                    }
                }

                foreach valueNode $s1 {
                    write::forceUpdateNode $valueNode
                    set name [$valueNode getAttribute n]
                    set state [get_domnode_attribute $valueNode state]
                    if {$state ne "hidden" || $name eq "ConstitutiveLaw"} {
                        # All the introduced values are translated to 'm' and 'kg' with the help of this function
                        set value [gid_groups_conds::convert_value_to_default $valueNode]
                        dict set mat_dict $group $name $value
                    }
                }
            }
        }
    }
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


proc write::writePropertiesJsonFile {{parts_un ""} {fname "materials.json"} {write_claw_name "True"} {model_part_name ""}} {
    if {$parts_un eq ""} {set parts_un [GetConfigurationAttribute parts_un]}
    set mats_json [getPropertiesList $parts_un $write_claw_name $model_part_name]
    write::OpenFile $fname
    write::WriteJSON $mats_json
    write::CloseFile
}

proc write::getPropertiesList {parts_un {write_claw_name "True"} {model_part_name ""}} {
    variable mat_dict
    set props_dict [dict create]
    set props [list ]

    set doc $gid_groups_conds::doc
    set root [$doc documentElement]
    #set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute $parts_un]/group"
    if {[llength [$root selectNodes $xp1]] < 1} {
        set xp1 "[spdAux::getRoute $parts_un]/condition/group"
    }
    foreach gNode [$root selectNodes $xp1] {
        set group [get_domnode_attribute $gNode n]
        set sub_model_part [write::getSubModelPartId Parts $group]
        if {$model_part_name ne ""} {set sub_model_part $model_part_name.$sub_model_part}
        set sub_model_part [string trim $sub_model_part "."]
        if { [dict exists $mat_dict $group] } {
            set mid [dict get $mat_dict $group MID]
            set prop_dict [dict create]
            dict set prop_dict "model_part_name" $sub_model_part
            dict set prop_dict "properties_id" $mid
            set constitutive_law_id ""
            if {[dict exists $mat_dict $group ConstitutiveLaw ]} {set constitutive_law_id [dict get $mat_dict $group ConstitutiveLaw]}
            set constitutive_law [Model::getConstitutiveLaw $constitutive_law_id]
            if {$constitutive_law ne ""} {
                set exclusionList [list "MID" "APPID" "ConstitutiveLaw" "Material" "Element"]
                set variables_dict [dict create]
                foreach prop [dict keys [dict get $mat_dict $group] ] {
                    if {$prop ni $exclusionList} {
                        dict set variables_list $prop [getFormattedValue [dict get $mat_dict $group $prop]]
                    }
                }
                set material_dict [dict create]

                if {$write_claw_name eq "True"} {
                    set constitutive_law_name [$constitutive_law getKratosName]
                    dict set material_dict constitutive_law [dict create name $constitutive_law_name]
                }
                dict set material_dict Variables $variables_list
                dict set material_dict Tables dictnull

                dict set prop_dict Material $material_dict

                lappend props $prop_dict
            }
        }
    }

    dict set props_dict properties $props
    return $props_dict
}