
# Modify the tree: field newValue UniqueName OptionalChild
proc spdAux::SetValueOnTreeItem { field value name {it "" } } {

    set root [customlib::GetBaseRoot]
    #W "$field $value $name $it"
    set node ""

    set xp [getRoute $name]
    if {$xp ne ""} {
        set node [$root selectNodes $xp]
        if {$it ne ""} {set node [$node find n $it]}
    }

    if {$node ne ""} {
        gid_groups_conds::setAttributes [$node toXPath] [list $field $value]
    } {
        error "$name $it not found - Check GetFromXML.tcl file"
    }
}

proc spdAux::ListToValues {lista} {
    set res ""
    foreach elem $lista {
        append res $elem
        append res ","
    }
    return [string range $res 0 end-1]
}

proc spdAux::injectSolvers {basenode args} {

    # Get all solvers params
    set paramspuestos [list ]
    set paramsnodes ""
    set params [::Model::GetAllSolversParams]
    foreach {parname par} $params {
        if {$parname ni $paramspuestos} {
            lappend paramspuestos $parname
            set pn [$par getPublicName]
            set type [$par getType]
            set dv [$par getDv]
            if {$dv ni [list "1" "0"]} {
                if {[write::isBooleanFalse $dv]} {set dv No}
                if {[write::isBooleanTrue $dv]} {set dv Yes}
            }
            append paramsnodes "<value n='$parname' pn='$pn' state='\[SolverParamState\]' v='$dv' "
            if {$type eq "bool"} {
                append paramsnodes " values='Yes,No' "
            }
            if {$type eq "combo"} {
                append paramsnodes " values='\[GetSolverParameterValues\]' "
                append paramsnodes " dict='\[GetSolverParameterDict\]' "
            }

            append paramsnodes "/>"
        }
    }
    set contnode [$basenode parent]

    # Get All SolversEntry
    set ses [list ]
    foreach st [::Model::GetSolutionStrategies {*}$args] {
        lappend ses $st [$st getSolversEntries]
    }

    # One container per solverEntry
    foreach {st ss} $ses {
        foreach se $ss {
            set stn [$st getName]
            set n [$se getName]
            set pn [$se getPublicName]
            set help [$se getHelp]
            set appid [GetAppIdFromNode [$basenode parent]]
            set un [apps::getAppUniqueName $appid "$stn$n"]
            set container "<container help='$help' n='$n' pn='$pn' un='$un' state='\[SolverEntryState\]' solstratname='$stn' open_window='0' icon='solver'>"
            set defsolver [lindex [$se getDefaultSolvers] 0]
            append container "<value n='Solver' pn='Solver' v='$defsolver' values='\[GetSolversValues\]' dict='\[GetSolvers\]' actualize='1' update_proc='UpdateTree'/>"
            #append container "<dependencies node='../value' actualize='1'/>"
            #append container "</value>"
            append container $paramsnodes
            append container "</container>"
            $contnode appendXML $container
        }
    }
    $basenode delete
}

proc spdAux::injectSolStratParams {basenode args} {
    set contnode [$basenode parent]
    set params [::Model::GetSolStratParams {*}$args]
    foreach {parname par} $params {
        #W "$parname [$contnode find n $parname]"
        if {[$contnode find n $parname] eq ""} {
            set pn [$par getPublicName]
            set type [$par getType]
            set dv [$par getDv]
            if {$type eq "bool"} {set dv [GetBooleanForTree $dv]}
            set helptext [$par getHelp]
            set actualize [$par getActualize]
            set node "<value n='$parname' pn='$pn' state='\[SolStratParamState\]' v='$dv' help='$helptext' "

            if {$actualize} {
                append node "actualize_tree='1'"
            }

            if {$type eq "bool"} {

                append node " values='Yes,No' "
            }
            if {$type eq "combo"} {
                set values [$par getValues]
                set vs [join [$par getValues] ,]
                set pvalues [$par getPValues]

                set pv ""
                for {set i 0} {$i < [llength $values]} {incr i} {
                    lappend pv [lindex $values $i]
                    lappend pv [lindex $pvalues $i]
                }
                set pv [join $pv ,]
                #W " values='$vs' dict='$pv' "
                append node " values='$vs' dict='$pv' "
            }
            append node "/>"

            $contnode appendXML $node
            set orig [$contnode lastChild]
            set new [$orig cloneNode]
            $orig delete
            $contnode insertBefore $new $basenode
        }
    }

    set params [::Model::GetSchemesParams {*}$args]

    foreach {parname par} $params {
        #W "$parname [$contnode find n $parname]"
        if {[$contnode find n $parname] eq ""} {
            set pn [$par getPublicName]
            set type [$par getType]
            set dv [$par getDv]
            if {$type eq "bool"} {set dv [GetBooleanForTree $dv]}
            set helptext [$par getHelp]
            set node "<value n='$parname' pn='$pn' state='\[SchemeParamState\]' v='$dv' help='$helptext' "
            if {$type eq "bool"} {
                append node " values='Yes,No' "
            }
            append node "/>"
            $contnode appendXML $node
        }
    }
    $basenode delete
}



proc spdAux::injectNodalConditions { basenode args} {
    if {$args eq "{}"} {
        set nodal_conditions [::Model::getAllNodalConditions]
    } {
        set nodal_conditions [::Model::GetNodalConditions {*}$args]
    }
    spdAux::_injectCondsToTree $basenode $nodal_conditions "nodal"
    $basenode delete
}

proc spdAux::injectConditions { basenode args} {
    set conditions [::Model::GetConditions {*}$args]
    spdAux::_injectCondsToTree $basenode $conditions
    set parent [$basenode parent]
    $basenode delete
    spdAux::processDynamicNodes $parent
}

proc spdAux::_injectCondsToTree {basenode cond_list {cond_type "normal"} } {
    set conds [$basenode parent]
    set AppUsesIntervals [apps::ExecuteOnApp [GetAppIdFromNode $conds] GetAttribute UseIntervals]
    if {$AppUsesIntervals eq ""} {set AppUsesIntervals 0}

    foreach cnd $cond_list {
        set n [$cnd getName]
        set pn [$cnd getPublicName]
        set help [$cnd getHelp]
        set etype ""
        if {$cond_type eq "nodal"} {
            set etype [$cnd getOv]
        } else {
            set etype [join [string tolower [$cnd getAttribute ElementType]] ,]
        }
        if {$etype eq ""} {
            if {$::Model::SpatialDimension eq "3D"} {
                set etype "point,line,surface,volume"
            } else {
                set etype "point,line,surface"
            }
        }
        set units [$cnd getAttribute "units"]
        set um [$cnd getAttribute "unit_magnitude"]
        set processName [$cnd getProcessName]

        set process [::Model::GetProcess $processName]
        if {$process eq ""} {error [= "Condition %s can't find its process: %s" $n $processName]}
        set check [$process getAttribute "check"]
        if {$check eq ""} {set check "UpdateTree"}
        set state "ConditionState"
        if {$cond_type eq "nodal"} {
            set state [$cnd getAttribute state]
            if {$state eq ""} {set state "CheckNodalConditionState"}
        }
        set node "<condition n='$n' pn='$pn' ov='$etype' ovm='' icon='shells16' help='$help' state='\[$state\]' update_proc='\[OkNewCondition\]' check='$check'>"
        set symbol_data [$cnd getSymbol]
        if { [llength $symbol_data] } {
            set txt "<symbol"
            foreach {attribute value} $symbol_data {
                append txt " $attribute='$value'"
            }
            append txt "/>"
            append node $txt
        }
        set inputs [concat [$process getInputs] [$cnd getInputs] ]
        foreach {inName in} $inputs {
            set forcedParams [list cnd_v [$cnd getDefault $inName v] n $n units $units um $um base $process]
            foreach key [$cnd getDefaults $inName] {
                lappend forcedParams $key [$cnd getDefault $inName $key]
            }
            append node [GetParameterValueString $in $forcedParams $cnd]
        }
        set CondUsesIntervals [$cnd getAttribute "Interval"]
        if {$AppUsesIntervals && $CondUsesIntervals ne "False"} {
            append node "<value n='Interval' pn='Time interval' v='$CondUsesIntervals' values='\[getIntervals\]'  help='$help'/>"
        }
        append node "</condition>"
        $conds appendXML $node
    }

}

proc spdAux::GetParameterValueString { param {forcedParams ""} {base ""}} {
    set node ""

    set inName [$param getName]
    set pn [$param getPublicName]
    set type [$param getType]
    set v [$param getDv]
    set help [$param getHelp]
    set cnd_v ""
    set units ""
    set um ""
    set n ""
    set special_command [$param getAttribute "special_command"]

    if {$special_command ne ""} {
        set params [$param getAttribute "args"]
        set node [$special_command $param $params]
    } else {
        # set state [$in getAttribute "state"]
        # set cnd_state [$cnd getDefault $inName state]
        # if {$cnd_state ne ""} {set state $cnd_state}
        # if {$state eq ""} {set state "normal"}
        set state {[ConditionParameterState]}

        # Set forced values -> Caution when debugging
        foreach {key value} $forcedParams {
            set $key $value
        }
        if {$cnd_v ne ""} {set v $cnd_v}

        set has_units [$param getAttribute "has_units"]
        if {$has_units ne ""} {
            set has_units "units='$units'  unit_magnitude='$um'"
        } else {
            set param_units [$param getAttribute "units"]
            set param_unitm [$param getAttribute "unit_magnitude"]
            if {$param_units ne "" && $param_unitm ne ""} {
                set has_units "units='$param_units'  unit_magnitude='$param_unitm'"
            }
        }
        switch $type {
            "inline_vector" {
                set ndim [string index $::Model::SpatialDimension 0]
                # TODO: Add units when Compassis enables units in vectors
                #append node "<value n='$inName' pn='$pn' v='$v' fieldtype='vector' $has_units  dimensions='$ndim'  help='$help'  state='$state' />"
                append node "<value n='$inName' pn='$pn' v='$v' fieldtype='vector' dimensions='$ndim'  help='$help'  state='$state' />"
            }
            "vector" {
                set vector_type [$param getAttribute "vectorType"]
                lassign [split $v ","] vX vY vZ
                if {$vector_type eq "bool"} {
                    set zstate "\[CheckDimension 3D\]"
                    if {$state eq "hidden"} {set zstate hidden}
                    append node "
                        <value n='${inName}X' wn='[concat $n "_X"]' pn='X ${pn}' v='$vX' values='1,0' help='' state='$state'/>
                        <value n='${inName}Y' wn='[concat $n "_Y"]' pn='Y ${pn}' v='$vY' values='1,0' help='' state='$state'/>
                        <value n='${inName}Z' wn='[concat $n "_Z"]' pn='Z ${pn}' v='$vZ' values='1,0' help='' state='$zstate'/>"
                } else {
                    foreach i [list "X" "Y" "Z"] {
                        set fname "function_$inName"
                        set nodev "../value\[@n='${inName}$i'\]"
                        set nodef "../value\[@n='$i$fname'\]"
                        set zstate ""
                        if {$i eq "Z"} { set zstate "state='\[CheckDimension 3D\]'"}
                        if {[$param getAttribute "enabled"] in [list "1" "0"]} {
                            set val [expr [$param getAttribute "enabled"] ? "Yes" : "No"]
                            #if {$i eq "Z"} { set val "No" }
                            append node "<value n='Enabled_$i' pn='$i component' v='$val' values='Yes,No'  help='Enables the $i ${inName}' $zstate >"
                            append node "<dependencies value='No' node=\""
                            append node $nodev
                            append node "\" att1='state' v1='hidden'/>"
                            append node "<dependencies value='Yes' node=\""
                            append node $nodev
                            append node "\" att1='state' v1='normal'/>"
                            if {[$param getAttribute "function"] eq "1"} {
                                set fname "${i}function_$inName"
                                set nodef "../value\[@n='$fname'\]"
                                set nodeb "../value\[@n='ByFunction$i'\]"
                                append node "<dependencies value='No' node=\""
                                append node $nodef
                                append node "\" att1='state' v1='hidden'/>"
                                append node "<dependencies value='No' node=\""
                                append node $nodeb
                                append node "\" att1='state' v1='hidden'/>"
                                append node "<dependencies value='Yes' node=\""
                                append node $nodeb
                                append node "\" att1='state' v1='normal'/>"
                            }
                            append node "</value>"
                        }
                        if {[$param getAttribute "function"] eq "1"} {
                            set fname "${i}function_$inName"
                            append node "<value n='ByFunction$i' pn='by function -> f(x,y,z,t)' v='No' values='Yes,No'  actualize_tree='1'  $zstate >
                                <dependencies value='No' node=\""
                            append node $nodev
                            append node "\" att1='state' v1='normal'/>
                                <dependencies value='Yes'  node=\""
                            append node $nodev
                            append node "\" att1='state' v1='hidden'/>
                                <dependencies value='No' node=\""
                            append node $nodef
                            append node "\" att1='state' v1='hidden'/>
                                <dependencies value='Yes'  node=\""
                            append node $nodef
                            append node "\" att1='state' v1='normal'/>
                                </value>"
                            append node "<value n='$fname' pn='$i function' v='' help='$help'  $zstate />"
                        }
                        set v "v$i"
                        if { $vector_type eq "file" || $vector_type eq "tablefile" } {
                            if {[set $v] eq ""} {set $v "- No file"}
                            append node "<value n='${inName}$i' wn='[concat $n "_$i"]' pn='$i ${pn}' v='[set $v]' values='\[GetFilesValues\]' update_proc='AddFile' help='$help'  $zstate  type='$vector_type'/>"
                        } else {
                            append node "<value n='${inName}$i' wn='[concat $n "_$i"]' pn='$i ${pn}' v='[set $v]' $has_units help='$help'  $zstate />"
                        }
                    }
                }

            }
            "combo" {
                set values [$param getValues]
                set pvalues [$param getPValues]
                set pv ""
                for {set i 0} {$i < [llength $values]} {incr i} {
                    lappend pv [lindex $values $i]
                    lappend pv [lindex $pvalues $i]
                }
                set values [join [$param getValues] ","]
                set pvalues [join $pv ","]
                append node "<value n='$inName' pn='$pn' v='$v' values='$values'"
                if {[llength $pv]} {
                    append node " dict='$pvalues' "
                }
                if {[$param getActualize]} {
                    append node "  actualize_tree='1'  "
                }
                append node " state='$state' help='$help'>"
                if {$base ne ""} { append node [_insert_cond_param_dependencies $base $inName] }
                append node "</value>"
            }
            "bool" {
                set values "true,false"
                if {$v == 1} {set v true}
                if {$v == 0} {set v false}
                append node "<value n='$inName' pn='$pn' v='$v' values='$values'  help='$help'"
                if {[$param getActualize]} {
                    append node "  actualize_tree='1'  "
                }
                append node " state='$state'>"
                if {$base ne ""} {append node [_insert_cond_param_dependencies $base $inName]}
                append node "</value>"
            }
            "file" -
            "tablefile" {
                append node "<value n='$inName' pn='$pn' v='$v' values='\[GetFilesValues\]' update_proc='AddFile' help='$help' state='$state' type='$type'/>"
            }
            "integer" {
                append node "<value n='$inName' pn='$pn' v='$v' $has_units  help='$help' string_is='integer'/>"
            }
            default {
                if {[$param getAttribute "function"] eq "1"} {
                    set fname "function_$inName"
                    set nodev "../value\[@n='$inName'\]"
                    set nodef "../value\[@n='$fname'\]"
                    append node "<value n='ByFunction' pn='by function -> f(x,y,z,t)' v='No' values='Yes,No'  actualize_tree='1' state='$state'>
                        <dependencies value='No' node=\""
                    append node $nodev
                    append node "\" att1='state' v1='normal'/>
                        <dependencies value='Yes'  node=\""
                    append node $nodev
                    append node "\" att1='state' v1='hidden'/>
                        <dependencies value='No' node=\""
                    append node $nodef
                    append node "\" att1='state' v1='hidden'/>
                        <dependencies value='Yes'  node=\""
                    append node $nodef
                    append node "\" att1='state' v1='normal'/>
                        </value>"

                    append node "<value n='$fname' pn='Function' v='' help='$help'  state='$state'/>"
                }
                append node "<value n='$inName' pn='$pn' v='$v' $has_units  help='$help' string_is='double'  state='$state'/>"
            }
        }
    }
    return $node
}

proc spdAux::_insert_cond_param_dependencies {base param_name} {
    set dep_list [list ]
    foreach {pn param} [$base getInputs] {
        if {[$param getDepN] eq $param_name} {
            lappend dep_list [$param getName] [$param getDepV]
        }
    }
    set ret ""
    foreach {name value} $dep_list {
        set values [split $value ","]
        foreach v $values {
            lappend ins "@v='$v'"
            lappend out "@v!='$v'"
        }
        set in_string [join $ins " or "]
        set out_string [join $out " and "]
        set nodev "../value\[@n='$name'\]"
        append ret " <dependencies condition=\"$in_string\" node=\""
        append ret $nodev
        append ret "\"  att1='state' v1='normal'/>"
        append ret " <dependencies condition=\"$out_string\" node=\""
        append ret $nodev
        append ret "\"  att1='state' v1='hidden'/>"
    }
    return $ret
}
proc spdAux::injectPartInputs { basenode {inputs ""} } {
    set base [$basenode parent]
    set processeds [list ]
    spdAux::injectLocalAxesButton $basenode
    foreach obj [concat [Model::GetElements] [Model::GetConstitutiveLaws]] {
        set inputs [$obj getInputs]
        foreach {inName in} $inputs {
            if {$inName ni $processeds} {
                lappend processeds $inName
                set forcedParams [list state {[PartParamState]} ]
                if {[$in getActualize]} { lappend forcedParams base $obj }
                set node [GetParameterValueString $in $forcedParams $obj]

                $base appendXML $node
                set orig [$base lastChild]
                set new [$orig cloneNode -deep]
                $orig delete
                $base insertBefore $new $basenode
            }
        }
    }
    $basenode delete
}

proc spdAux::injectMaterials { basenode args } {
    set base [$basenode parent]
    set materials [Model::GetMaterials {*}$args]
    foreach mat $materials {
        set matname [$mat getName]
        set mathelp [$mat getAttribute help]
        set inputs [$mat getInputs]
        set matnode "<blockdata n='material' name='$matname' sequence='1' editable_name='unique' icon='material16' help='Material definition'  morebutton='0'>"
        foreach {inName in} $inputs {
            set node [spdAux::GetParameterValueString $in [list base $mat state [$in getAttribute state]] $mat]
            append matnode $node
        }
        append matnode "</blockdata> \n"
        $base appendXML $matnode
    }
    $basenode delete
}

proc spdAux::injectLocalAxesButton { basenode } {
    # set base [$basenode parent]
    # set node "<value n='Local_axes' pn='Local axes' v='Automatic' values='Automatic' editable='0' local_axes='disabled' help='If the direction to define is not coincident with the global axes, it is possible to define a set of local axes and prescribe the displacements related to that local axes'>
    # <dependencies node='.' att1='local_axes' v1='normal' value='1'/>
    # <dependencies node='.' att1='local_axes' v1='disabled' not_value='1'/>
    # </value>"
    # $base appendXML $node
    # W [$base asXML]


    # GiD_Process MEscape Data Conditions AssignCond line_Local_axes change -Automatic- 1 escape escape

}

proc spdAux::injectElementOutputs { basenode args} {
    set args {*}$args
    return [spdAux::injectElementOutputs_do $basenode $args]
}
proc spdAux::injectElementOutputs_do { basenode args} {
    set base [$basenode parent]
    set args {*}$args

    set outputs [::Model::GetAllElemOutputs $args]
    foreach in [dict keys $outputs] {
        set pn [[dict get $outputs $in] getPublicName]
        set v [GetBooleanForTree [[dict get $outputs $in] getDv]]
        set node "<value n='$in' pn='$pn' state='\[ElementOutputState\]' v='$v' values='Yes,No' />"

        $base appendXML $node
        set orig [$base lastChild]
        set new [$orig cloneNode]
        $orig delete
        $base insertBefore $new $basenode

    }
    $basenode delete
}

proc spdAux::injectNodalConditionsOutputs { basenode args} {
    set args {*}$args
    return [spdAux::injectNodalConditionsOutputs_do $basenode $args]
}
proc spdAux::injectNodalConditionsOutputs_do { basenode args} {
    set base [$basenode parent]
    set args {*}$args

    if {$args eq ""} {
        set nodal_conditions [::Model::getAllNodalConditions]
    } {
        set nodal_conditions [::Model::GetNodalConditions $args]
    }
    foreach nc $nodal_conditions {
        set n [$nc getName]
        set pn [$nc getPublicName]
        set v [$nc getAttribute v]
        if {$v eq ""} {set v "Yes"}

        set state [$nc getAttribute state]
        if {$state eq ""} {set state "CheckNodalConditionState"}
        set node "<value n='$n' pn='$pn' v='$v' values='Yes,No' state='\[$state $n\]'/>"
        $base appendXML $node
        foreach {n1 output} [$nc getOutputs] {
            set nout [$output getName]
            set pn [$output getPublicName]
            set v [$output getAttribute v]
            if {$v eq ""} {set v "Yes"}
            set node "<value n='$nout' pn='$pn' v='$v' values='Yes,No' state='\[CheckNodalConditionOutputState $n\]'/>"
            $base appendXML $node
        }
    }
    $basenode delete
}

proc spdAux::GetBooleanForTree {raw} {
    set goodList [list "Yes" "1" "yes" "ok" "YES" "Ok" "True" "TRUE" "true"]
    if {$raw in $goodList} {return "Yes" } {return "No"}
}

proc spdAux::injectConstitutiveLawOutputs { tempnode  args} {
    set basenode [$tempnode parent]
    set outputs [::Model::GetAllCLOutputs {*}$args]
    foreach in [dict keys $outputs] {
        if {[$basenode find n $in] eq ""} {
            set pn [[dict get $outputs $in] getPublicName]
            set v [GetBooleanForTree [[dict get $outputs $in] getDv]]
            set node "<value n='$in' pn='$pn' state='\[ConstLawOutputState\]' v='$v' values='Yes,No' />"
            $basenode appendXML $node
            set orig [$basenode lastChild]
            set new [$orig cloneNode]
            $orig delete
            $basenode insertBefore $new $tempnode
        }
    }
    $tempnode delete
}

proc spdAux::injectProcs { basenode  args} {
    set appId [apps::getActiveAppId]
    if {$appId ne ""} {
        set f "::$appId"
        append f "::dir"
        set nf [file join [subst $$f] xml Procs.spd]
        set xml [tDOM::xmlReadFile $nf]
        set newnode [dom parse [string trim $xml]]
        set xmlNode [$newnode documentElement]

        foreach in [$xmlNode getElementsByTagName "proc"] {
            # This allows an app to overwrite mandatory procs
            set procn [$in @n]
            set pastnode [[$basenode parent] selectNodes "./proc\[@n='$procn'\]"]
            if {$pastnode ne ""} {gid_groups_conds::delete [$pastnode toXPath]}

            [$basenode parent] appendChild $in
        }
        $basenode delete
    }
}

proc spdAux::CheckConstLawOutputState {outnode} {

    set root [customlib::GetBaseRoot]

    set nodeApp [GetAppIdFromNode $outnode]
    set parts_un [apps::getAppUniqueName $nodeApp Parts]
    set parts_path [getRoute $parts_un]
    set xp1 "$parts_path/group/value\[@n='ConstitutiveLaw'\]"
    set constlawactive [list ]
    foreach gNode [$root selectNodes $xp1] {
        lappend constlawactive [get_domnode_attribute $gNode v]
    }

    set paramName [$outnode @n]
    return [::Model::CheckConstLawOutputState $constlawactive $paramName]
}

proc spdAux::CheckElementOutputState {outnode {parts_uns ""}} {
    set root [customlib::GetBaseRoot]

    if {$parts_uns eq ""} {
        set nodeApp [GetAppIdFromNode $outnode]
        lappend parts_uns [apps::getAppUniqueName $nodeApp Parts]
    }
    set elemsactive [list ]
    foreach parts_un $parts_uns {
        set parts_path [getRoute $parts_un]
        set xp1 "$parts_path/group/value\[@n='Element'\]"
        foreach gNode [$root selectNodes $xp1] {
            lappend elemsactive [get_domnode_attribute $gNode v]
        }
    }
    set paramName [$outnode @n]
    return [::Model::CheckElementOutputState $elemsactive $paramName]
}

proc spdAux::CheckAnyPartState {domNode {parts_uns ""}} {
    set parts [list ]
    if {$parts_uns eq ""} {
        set nodeApp [GetAppIdFromNode $domNode]
        lappend parts_uns [apps::getAppUniqueName $nodeApp Parts]
    }
    foreach parts_un $parts_uns {
        set parts_path [spdAux::getRoute $parts_un]
        if {$parts_path ne ""} {
            lappend parts {*}[$domNode selectNodes "$parts_path/group"]
        }
    }
    if {[llength $parts] > 0} {return true} {return false}
}

proc spdAux::SolStratParamState {outnode} {

    set root [customlib::GetBaseRoot]
    set nodeApp [GetAppIdFromNode $outnode]

    set sol_stratUN [apps::getAppUniqueName $nodeApp SolStrat]

    if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $sol_stratUN]] v] eq ""} {
        get_domnode_attribute [$root selectNodes [spdAux::getRoute $sol_stratUN]] dict
    }
    set SolStrat [::write::getValue $sol_stratUN]

    set paramName [$outnode @n]
    set ret [::Model::CheckSolStratInputState $SolStrat $paramName]
    if {$ret} {
        lassign [Model::GetSolStratParamDep $SolStrat $paramName] depN depV
        foreach node [[$outnode parent] childNodes] {
            if {[$node @n] eq $depN} {
                if {[get_domnode_attribute $node v] ni [split $depV ,]} {
                    set ret 0
                    break
                }
            }
        }
    }
    return $ret
}

proc spdAux::SchemeParamState {outnode} {

    set root [customlib::GetBaseRoot]
    set nodeApp [GetAppIdFromNode $outnode]

    set sol_stratUN [apps::getAppUniqueName $nodeApp SolStrat]
    set schemeUN [apps::getAppUniqueName $nodeApp Scheme]

    if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $sol_stratUN]] v] eq ""} {
        get_domnode_attribute [$root selectNodes [spdAux::getRoute $sol_stratUN]] dict
    }
    if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $schemeUN]] v] eq ""} {
        get_domnode_attribute [$root selectNodes [spdAux::getRoute $schemeUN]] dict
    }
    set SolStrat [::write::getValue $sol_stratUN]
    set Scheme [write::getValue $schemeUN]

    set paramName [$outnode @n]
    return [::Model::CheckSchemeInputState $SolStrat $Scheme $paramName]
}

proc spdAux::getIntervals { {un "Intervals"} } {
    set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute $un]/blockdata\[@n='Interval'\]"
    set lista [list ]
    foreach node [$root selectNodes $xp1] {
        lappend lista [$node @name]
    }

    return $lista
}

proc spdAux::CreateInterval {name ini end {un "Intervals"}} {
    if {$name in [getIntervals $un]} {error [= "Interval %s already exists" $name]}
    set root [customlib::GetBaseRoot]
    set interval_path [spdAux::getRoute $un]

    set interval_string "<blockdata n='Interval' pn='Interval' name='$name' sequence='1' editable_name='unique' sequence_type='non_void_disabled' help='Interval'>
        <value n='IniTime' pn='Start time' v='$ini' help='When do the interval starts?'/>
        <value n='EndTime' pn='End time' v='$end' help='When do the interval ends?'/>
        </blockdata>"
    [$root selectNodes $interval_path] appendXML $interval_string
}

proc spdAux::getTimeFunctions {} {

    set root [customlib::GetBaseRoot]
    set functions_un [apps::getCurrentUniqueName Functions]
    set xp1 "[spdAux::getRoute $functions_un]/blockdata\[@n='Function'\]"
    set lista [list ]
    foreach node [$root selectNodes $xp1] {
        lappend lista [$node @name]
    }

    return $lista
}

proc spdAux::getFields {} {

    set root [customlib::GetBaseRoot]
    set fields_un [apps::getCurrentUniqueName Fields]
    set xp1 "[spdAux::getRoute $fields_un]/blockdata\[@n='Field'\]"
    set lista [list ]
    foreach node [$root selectNodes $xp1] {
        lappend lista [$node @name]
    }

    return $lista
}
proc spdAux::InsertMaterialsSimple {domNode args} {
     return "<value n='Material' pn='Material' editable='0' help='Choose a material from the database' values='\[get_materials_list_simple\]' v='DEM-DefaultMaterial' state='normal' />"
}

proc spdAux::ProcGet_materials_list_simple {domNode args} {
    set appid [spdAux::GetAppIdFromNode $domNode]
    set mats_un [apps::getAppUniqueName $appid Materials]
    set xp3 [spdAux::getRoute $mats_un]
    set parentNode [$domNode selectNodes $xp3]
    set const_law_name [get_domnode_attribute [$domNode selectNodes "../value\[@n = 'ConstitutiveLaw'\]"] v]
    set filters [list ]
    if {$const_law_name != ""} {
        set const_law [Model::getConstitutiveLaw $const_law_name]
        if {$const_law != ""} {
            set filters [$const_law getMaterialFilters]
        }
    }
    set materials [Model::GetMaterialsNames $filters]

    set res_raw_list [list ]
    foreach part [$parentNode selectNodes "./blockdata\[@n = 'material'\]"] {
        set name [$part @name]
        if {$name in $materials} {
            lappend res_raw_list $name
        }
    }
    set v [get_domnode_attribute $domNode v]
    if {$v ni $res_raw_list} {$domNode setAttribute v $v}
    return [join $res_raw_list ","]
}
