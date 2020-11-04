namespace eval ::PfemThermic::write {
    
}

proc ::PfemThermic::write::Init { } {
    PfemFluid::write::Init
	ConvectionDiffusion::write::Init
	
	PfemFluid::write::SetAttribute materials_file PFEMThermicMaterials.json
	ConvectionDiffusion::write::SetAttribute materials_file PFEMThermicMaterials.json
}

# MDPA event
proc PfemThermic::write::writeModelPartEvent { } {
    PfemFluid::write::writeModelPartEvent
}

# Custom files event
proc PfemThermic::write::writeCustomFilesEvent { } {
	PfemThermic::write::writePropertiesJsonFile "PFEMThermicMaterials.json" True [PfemFluid::write::GetAttribute model_part_name]
    write::CopyFileIntoModel [file join "python" "MainKratos.py"]
}

# Write material file
proc PfemThermic::write::writePropertiesJsonFile { {fname "materials.json"} {write_claw_name "True"} {model_part_name ""}} {
    set mats_json [dict create properties [list ] ]
    foreach parts_un [PfemFluid::write::GetPartsUN] {
        foreach property [dict get [PfemThermic::write::getPropertiesList $parts_un $write_claw_name $model_part_name] properties ] {
            if {$property ne "\[\]"} {
                dict lappend mats_json properties $property
            }
        }
    }
    write::OpenFile $fname
    write::WriteJSON $mats_json
    write::CloseFile
}

proc PfemThermic::write::getPropertiesList {parts_un {write_claw_name "True"} {model_part_name ""}} {
    set mat_dict [write::getMatDict]
    set props_dict [dict create]
    set props [list]
    set doc $gid_groups_conds::doc
    set root [$doc documentElement]

    set xp1 "[spdAux::getRoute $parts_un]/group"
    if {[llength [$root selectNodes $xp1]] < 1} {
        set xp1 "[spdAux::getRoute $parts_un]/condition/group"
    }
    foreach gNode [$root selectNodes $xp1] {
        set group [get_domnode_attribute $gNode n]
        set cond_id [get_domnode_attribute [$gNode parent] n]
        set sub_model_part [write::getSubModelPartId $cond_id $group]
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
				set tableList [list "TEMPERATURE_vs_DENSITY" "TEMPERATURE_vs_CONDUCTIVITY" "TEMPERATURE_vs_SPECIFIC_HEAT" "TEMPERATURE_vs_VISCOSITY"]
                set variables_dict [dict create]
				set tables_dict [dict create]
                foreach prop [dict keys [dict get $mat_dict $group] ] {
                    if {$prop ni $exclusionList && $prop ni $tableList} {
                        dict set variables_list $prop [write::getFormattedValue [dict get $mat_dict $group $prop]]
                    }
					if {$prop in $tableList} {
						set fileName [write::getFormattedValue [dict get $mat_dict $group $prop]]
						if {$fileName ne "- No file"} {
						    dict set tables_dict $prop [PfemThermic::write::GetTable $prop $fileName]
						}
                    }
                }
                set material_dict [dict create]

                if {$write_claw_name eq "True"} {
                    set constitutive_law_name [$constitutive_law getKratosName]
                    dict set material_dict constitutive_law [dict create name $constitutive_law_name]
                }
				
                dict set material_dict Variables $variables_list
                dict set material_dict Tables $tables_dict				
                dict set prop_dict Material $material_dict

                lappend props $prop_dict
            }
        }
    }

    dict set props_dict properties $props
    return $props_dict
}

proc PfemThermic::write::GetTable { prop fileName } {
	set table [dict create]
    dict set table input_variable "TEMPERATURE"
	
	if {$prop eq "TEMPERATURE_vs_DENSITY"} {
        dict set table output_variable "DENSITY"
    } elseif {$prop eq "TEMPERATURE_vs_CONDUCTIVITY"} {
        dict set table output_variable "CONDUCTIVITY"
    } elseif {$prop eq "TEMPERATURE_vs_SPECIFIC_HEAT"} {
        dict set table output_variable "SPECIFIC_HEAT"
    } else {
        dict set table output_variable "DYNAMIC_VISCOSITY"
    }
    
	set fp [open $fileName r]
    set file_data [read $fp]
    close $fp
	
	set points {}
    set data [split $file_data "\n"]
    foreach line $data {
        if {[scan $line %f%f a b] == 2} {
			lappend points [list $a $b]
		}
    }
	dict set table data $points
	
	return $table
}

PfemThermic::write::Init