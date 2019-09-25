
proc write::GetRestartProcess { {un ""} {name "" } } {
    
    set root [customlib::GetBaseRoot]
    
    set resultDict [dict create ]
    if {$un eq ""} {set un "Restart"}
    if {$name eq ""} {set name "RestartOptions"}
    
    dict set resultDict "python_module" "restart_process"
    dict set resultDict "kratos_module" "KratosMultiphysics.SolidMechanicsApplication"
    dict set resultDict "help" "This process writes restart files"
    dict set resultDict "process_name" "RestartProcess"
    
    set params [dict create]
    set saveValue [write::getStringBinaryValue $un SaveRestart]
    
    dict set resultDict "process_name" "RestartProcess"
    set model_name [Kratos::GetModelName]
    dict set params "model_part_name" [write::GetModelPartNameWithParent $model_name]
    dict set params "save_restart" $saveValue
    dict set params "restart_file_name" $model_name
    set xp1 "[spdAux::getRoute $un]/container\[@n = '$name'\]/value"
    set file_label [getValue $un RestartFileLabel]
    dict set params "restart_file_label" $file_label
    set output_control [getValue $un RestartControlType]
    dict set params "output_control_type" $output_control
    if {$output_control eq "time"} {dict set params "output_frequency" [getValue $un RestartDeltaTime]} {dict set params "output_frequency" [getValue $un RestartDeltaStep]}
    set jsonoutput [write::getStringBinaryValue $un json_output]
    dict set params "json_output" $jsonoutput
    
    dict set resultDict "Parameters" $params
    return $resultDict
}

proc write::GetProcessHeader {group process condition {groupId ""}} {
    set processDict [dict create]
    if {$groupId eq ""} {
        set groupName [$group @n]
        set cid [[$group parent] @n]
        set groupName [write::GetWriteGroupName $groupName]
        set groupId [::write::getSubModelPartId $cid $groupName]
    }
    set paramDict [dict create ]
    dict set paramDict model_part_name [write::GetModelPartNameWithParent $groupId]
    
    set process_attributes [$process getAttributes]
    
    dict set process_attributes process_name [dict get $process_attributes n]
    dict unset process_attributes n
    dict unset process_attributes pn
    if {[dict exists $process_attributes help]} {dict unset process_attributes help}
    if {[dict exists $process_attributes process_name]} {dict unset process_attributes process_name}
    if {[dict exists $process_attributes write_command]} {dict unset process_attributes write_command}
    
    set processDict [dict merge $processDict $process_attributes]
    if {[$condition hasAttribute VariableName]} {
        set variable_name [$condition getAttribute VariableName]
        # "lindex" is a rough solution. Look for a better one.
        if {$variable_name ne ""} {dict set paramDict variable_name [lindex $variable_name 0]}
    }
    
    if {[$group find n Interval] ne ""} {dict set paramDict interval [write::getInterval [get_domnode_attribute [$group find n Interval] v]] }
    dict set processDict Parameters $paramDict
    return $processDict
}

proc write::ProcessAxisToVectorComponents { groupNode condition process} {
    set processDict [write::GetProcessHeader $groupNode $process $condition]
    
    set axis [write::getValueByXPath [$groupNode toXPath] Axis]
    set const [write::GetInputValue $groupNode [$process getInputPn constrained]]
    set val [write::GetInputValue $groupNode [$process getInputPn value]]
    foreach i [list "X" "Y" "Z"] {
        if {[string first $i $axis] eq -1} {
            lappend constrained false
            lappend value null
        } {
            lappend constrained $const
            lappend value $val
        }
    }
    
    dict set processDict Parameters constrained $constrained
    dict set processDict Parameters value $value
    
    return $processDict
}

proc write::ProcessVectorFunctionComponents { groupNode condition process} {
    set processDict [write::GetProcessHeader $groupNode $process $condition]
    set val [write::GetInputValue $groupNode [$process getInputPn component]]
    foreach i $val {
        if {$i == "null"} {
            lappend constrained false
            lappend value null
        } {
            lappend constrained true
            lappend value $i
        }
    }
    
    dict set processDict Parameters constrained $constrained
    dict set processDict Parameters value $value
    
    return $processDict
}

proc write::GetInputValue {group in_obj} {
    set return_value ""
    set inputName [$in_obj getName]
    set in_type [$in_obj getType]
    if {$in_type eq "vector"} {
        set vector_type [$in_obj getAttribute "vectorType"]
        if {$vector_type eq "bool"} {
            set ValX [expr [get_domnode_attribute [$group find n ${inputName}X] v] ? True : False]
            set ValY [expr [get_domnode_attribute [$group find n ${inputName}Y] v] ? True : False]
            set ValZ [expr False]
            if {[$group find n ${inputName}Z] ne ""} {set ValZ [expr [get_domnode_attribute [$group find n ${inputName}Z] v] ? True : False]}
        } elseif {$vector_type eq "double"} {
            
            foreach i [list "X" "Y" "Z"] {
                set printed 0
                if {[$in_obj getAttribute "function"] eq "1"} {
                    set selector_name "selector_${inputName}_$i"
                    set selector_value [get_domnode_attribute [$group find n $selector_name] v]
                    switch $selector_value {
                        "ByFunction" {
                            set function_component "function_${inputName}_${i}"
                            set value [write::getValueByNode [$group find n $function_component] ]
                            set Val$i $value
                            set printed 1
                        } 
                        "ByValue" {
                            
                        }
                        "Not" {
                            set Val$i null
                            set printed 1
                        }
                    }
                    
                }
                if {!$printed} {
                    set value_component "value_${inputName}_${i}"
                    set value [expr [gid_groups_conds::convert_value_to_default [$group find n $value_component] ] ]
                    set Val$i $value
                }
            }
            
        } elseif {$vector_type eq "tablefile" || $vector_type eq "file"} {
            set ValX "[get_domnode_attribute [$group find n ${inputName}X] v]"
            set ValY "[get_domnode_attribute [$group find n ${inputName}Y] v]"
            set ValZ "0"
            if {[$group find n ${inputName}Z] ne ""} {set ValZ "[get_domnode_attribute [$group find n ${inputName}Z] v]"}
        } else {
            set ValX [expr [gid_groups_conds::convert_value_to_default [$group find n "value_${inputName}_X"] ] ]
            set ValY [expr [gid_groups_conds::convert_value_to_default [$group find n "value_${inputName}_Y"] ] ]
            set ValZ [expr 0.0]
            if {[$group find n "value_${inputName}_Z"] ne ""} {set ValZ [expr [gid_groups_conds::convert_value_to_default [$group find n "value_${inputName}_Z"] ]]}
        }
        set return_value [list $ValX $ValY $ValZ]
    } elseif {$in_type eq "inline_vector"} {
        set value [gid_groups_conds::convert_value_to_default [$group find n $inputName]]
        lassign [split $value ","] ValX ValY ValZ
        if {$ValZ eq ""} {set ValZ 0.0}
        set return_value [list [expr $ValX] [expr $ValY] [expr $ValZ]]
    } elseif {$in_type eq "double" || $in_type eq "integer"} {
        set printed 0
        if {[$in_obj getAttribute "function"] eq "1"} {
            if {[get_domnode_attribute [$group find n "ByFunction"] v]  eq "Yes"} {
                set funcinputName "function_$inputName"
                set value [get_domnode_attribute [$group find n $funcinputName] v]
                set return_value $value
                set printed 1
            }
        }
        if {!$printed} {
            set value [gid_groups_conds::convert_value_to_default [$group find n $inputName]]
            #set value [get_domnode_attribute [$group find n $inputName] v]
            set return_value [expr $value]
        }
    } elseif {$in_type eq "bool"} {
        set value [get_domnode_attribute [$group find n $inputName] v]
        set value [expr $value ? True : False]
        set return_value [expr $value]
    } elseif {$in_type eq "tablefile"} {
        set value [get_domnode_attribute [$group find n $inputName] v]
        set return_value $value
    } else {
        if {[get_domnode_attribute [$group find n $inputName] state] ne "hidden" } {
            set value [get_domnode_attribute [$group find n $inputName] v]
            set return_value $value
        }
    }
    return $return_value
}