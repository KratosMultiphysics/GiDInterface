##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::spdAux {
    Kratos::AddNamespace [namespace current]

    # Namespace variables declaration
    variable uniqueNames
    variable initwind
    
    variable currentexternalfile
    variable refreshTreeTurn
    
    variable TreeVisibility
    variable UseStages
    variable GroupsEdited

    variable must_open_init_window
    variable must_open_dim_window

    variable list_of_windows
}

proc spdAux::Init { } {
    # Namespace variables inicialization
    variable uniqueNames
    variable initwind
    variable currentexternalfile
    variable refreshTreeTurn
    variable TreeVisibility
    variable UseStages
    variable ToolbarVisibility
    variable GroupsEdited
    variable must_open_init_window
    variable must_open_dim_window
    variable list_of_windows
    
    set uniqueNames ""
    dict set uniqueNames "dummy" 0
    set initwind ""
    set currentexternalfile ""
    set refreshTreeTurn 0
    set TreeVisibility 0
    set UseStages 0
    set ToolbarVisibility 0
    set GroupsEdited [dict create]
    set must_open_init_window 1
    set must_open_dim_window 1
    
    set list_of_windows [list ]
}

proc spdAux::StartAsNewProject { } {
    spdAux::processIncludes
    spdAux::parseRoutes
    update
    spdAux::LoadModelFiles
}

proc spdAux::RequestRefresh {} {
    variable refreshTreeTurn
    set refreshTreeTurn 1
}

proc spdAux::TryRefreshTree { } {
    variable refreshTreeTurn
    #W "HI"
    update
    update idletasks
    if {$refreshTreeTurn} {
        #W "there"
        catch {
            set foc [focus]
            set ::spdAux::refreshTreeTurn 0
            gid_groups_conds::actualize_conditions_window
            gid_groups_conds::actualize_conditions_window
            
            gid_groups_conds::check_dependencies
            focus -force $foc
        }
        set ::spdAux::refreshTreeTurn 0
    }
    after 750 {catch {spdAux::TryRefreshTree}}
}

proc spdAux::OpenTree { } {
    variable TreeVisibility
    if {$TreeVisibility} {
        if {[gid_groups_conds::open_conditions window_type] ne "menu"} {
            gid_groups_conds::open_conditions menu
        }
    }
}

proc spdAux::EndRefreshTree { } {
    variable refreshTreeTurn
    set refreshTreeTurn 0
    after cancel {catch {spdAux::TryRefreshTree}}
}

# Includes
proc spdAux::processIncludes { } {
    customlib::UpdateDocument
    set root [customlib::GetBaseRoot]
    spdAux::processAppIncludes $root
    spdAux::processDynamicNodes $root
    spdAux::parseRoutes
}

proc spdAux::processDynamicNodes { root } {
    foreach elem [$root getElementsByTagName "dynamicnode"] {
        set func [$elem getAttribute command]
        set ar [$elem getAttribute args]
        ${func} $elem $ar
    }
}

proc spdAux::processAppIncludes { root } {
    foreach elem [$root getElementsByTagName "appLink"] {
        set active [$elem getAttribute "active"]
        set appid [$elem getAttribute "appid"]
        set pn [$elem getAttribute "pn"]
        set prefix [$elem getAttribute "prefix"]
        set public 0
        if {[$elem hasAttribute "public"]} {set public [$elem getAttribute "public"]}
        set app [apps::NewApp $appid $pn $prefix]
        $app setPublic $public

        # set the app as production ready if the attribute is present
        if {[$elem hasAttribute "production"] && [$elem getAttribute "production"] eq "1"} {
            # W "Setting app $appid as production ready = [$elem getAttribute "production"]"
            $app setProductionReady 1
        } else {
            # W "Setting app $appid as production ready = 0"
            $app setProductionReady 0
        }
        
        if {[$elem hasAttribute "is_tool"] } {$app setIsTool [$elem getAttribute "is_tool"]}

        if {$active} {
            set dir $::Kratos::kratos_private(Path)
            set f [file join $dir apps $appid xml Main.spd]
            set processedAppnode [customlib::ProcessIncludesRecurse $f $dir]
            $root insertBefore $processedAppnode $elem
            $elem delete
        }
    }
}

proc spdAux::CustomTreeCommon { } {
    set app_uses_intervals [[apps::getActiveApp] getPermission "intervals"]
    if {$app_uses_intervals eq ""} {set app_uses_intervals 0}
    if {!$app_uses_intervals} {
        if {[getRoute Intervals] ne ""} {
            catch {spdAux::SetValueOnTreeItem state hidden Intervals}
        }
    }
    
}

# FORCEPS
proc spdAux::ForceTreePreload { } {
    foreach node [[customlib::GetBaseRoot] getElementsByTagName value] { 
        if {[$node hasAttribute "values"] } {
            get_domnode_attribute $node values
        }
    }
}

# No workea
proc spdAux::ForceExtremeLoad { } {
    
    set root [customlib::GetBaseRoot]
    foreach contNode [$root getElementsByTagName "container"] {
        W "Opening $contNode [$contNode  @n]"
        $contNode setAttribute tree_state "open"
    }
    gid_groups_conds::actualize_conditions_window
}

proc spdAux::getImagePathDim { dim } {
    set imagepath ""
    set imagepath [apps::getImgPathFrom [apps::getActiveAppId] "$dim.gif"]
    if {[file exists $imagepath]} {return $imagepath}
    set imagepath [apps::getImgPathFrom [apps::getActiveAppId] "$dim.png"]
    if {[file exists $imagepath]} {return $imagepath}
    set imagepath [file nativename [file join $::Model::dir images "$dim.png"] ]
    return $imagepath
}
proc spdAux::DestroyWindows {} {
    if { [GidUtils::IsTkDisabled] } {
        return 0
    }
    variable list_of_windows
    foreach window $list_of_windows {
        if {[winfo exists $window]} {
            destroy $window    
        }
    }
    set list_of_windows [list ]
}

# Routes
proc spdAux::getRoute {name {domNode ""}} {
    variable uniqueNames
    variable UseStages
    set v ""
    if {[dict exists $uniqueNames $name]} {
        set v [dict get $uniqueNames $name]
    }
    if {$domNode ne "" && [write::isBooleanTrue $UseStages]} {
        set stage_node [GetStageNodeFromNode $domNode]
        set stage_xpath [$stage_node toXPath]
        set number -1
        regexp {.blockdata\[(\d+)\]$} $stage_xpath match number
        if {$number ne -1} {
            set new_string "/blockdata\[$number\]"
            set number_block -1
            regexp {.blockdata\[(\d+)\]} $v match number_block
            if {$number_block eq -1} {
                set v [string map [list "/blockdata" $new_string] $v]
            } else {
                set v [string map [list $match $new_string ] $v]
            }
        }
    }
    return $v
}

proc spdAux::setRoute {name route} {
    variable uniqueNames
    #if {[dict exists $uniqueNames $name]} {W "Warning: Unique name $name already exists.\n    Previous value: [dict get $uniqueNames $name],\n    Updated value: $route"}
    set uniqueNames [dict set uniqueNames $name $route]
    set uniqueNames [dict remove $uniqueNames dummy]
    #W "Add $name $route"
    # 
    # set root [customlib::GetBaseRoot]
    # W "checking [[$root selectNodes $route] asXML]"
}

proc spdAux::parseRoutes { } {
    set root [customlib::GetBaseRoot]
    parseRecurse $root
}

proc spdAux::parseRecurse { root } {
    foreach node [$root childNodes] {
        if {[$node nodeType] eq "ELEMENT_NODE"} {
            if {[$node hasAttribute un]} {
                foreach u [split [$node getAttribute un] ","] {
                    setRoute $u [$node toXPath]
                }
            }
            if {[$node hasChildNodes]} {
                parseRecurse $node
            }
        }
    }
}

proc spdAux::ExploreAllRoutes { } {
    variable uniqueNames
    
    set root [customlib::GetBaseRoot]
    W [dict keys $uniqueNames]
    foreach routeName [dict keys $uniqueNames] {
        set route [getRoute $routeName]
        W "Route $routeName $route"
        set node [$root selectNodes $route]
        W "Node $node"
    }   
}

proc spdAux::GetAppIdFromNode {domNode} {
    set prefix ""
    set prevDomNodeName ""
    while {$prefix eq "" && [$domNode @n] != $prevDomNodeName} {
        set prevDomNode [$domNode @n]
        set domNode [$domNode parent]
        if {[$domNode hasAttribute prefix]} {set prefix [$domNode @prefix]}
    }
    return [$domNode @n]
}
proc spdAux::GetStageNodeFromNode {domNode} {
    while {![$domNode hasAttribute is_stage]} {
        set domNode [$domNode parent]
    }
    return $domNode
}

# Dependencies
proc spdAux::insertDependencies { baseNode originUN } {
    
    set root [customlib::GetBaseRoot]
    
    set insertxpath [spdAux::getRoute $originUN $baseNode]
    set insertonnode [$root selectNodes $insertxpath]
    if {$insertonnode ne ""} {
        # a lo bestia, cambiar cuando sepamos inyectar la dependencia, abajo esta a medias
        $insertonnode setAttribute "actualize" 1
        $insertonnode setAttribute "actualize_tree" 1
    }
    ## Aun no soy capaz de insertar y que funcione
    #set ready 1
    #foreach c [$insertonnode getElementsByTagName "dependencies"] {
        #    if {[$c getAttribute "node"] eq $originxpath} {set ready 0; break}
        #}
    #
    #if {$ready} {
        #    set str "<dependencies node='$originxpath' actualize='1'/>"
        #    W $str
        #    W $insertxpath
        #    $insertonnode appendChild [[dom parse $str] documentElement]
        #    W [$insertonnode asXML]
        #}
}
proc spdAux::insertDependenciesSoft { originxpath relativepath n attn attv} {
    
    set root [customlib::GetBaseRoot]
    set insertonnode [$root selectNodes $originxpath]
    
    # Aun no soy capaz de insertar y que funcione
    set ready 1
    foreach c [$insertonnode getElementsByTagName "dependencies"] {
        if {[$c getAttribute "node"] eq $originxpath} {set ready 0; break}
    }
    if {$ready} {
        set str "<dependencies n='$n' node='$relativepath' att1='$attn' v1='$attv' actualize='1'/>"
        $insertonnode appendChild [[dom parse $str] documentElement]
    }
}

proc spdAux::CheckSolverEntryState {domNode} {
    set appid [GetAppIdFromNode $domNode]
    set kw [apps::getAppUniqueName $appid SolStrat]
    set nodo [$domNode selectNodes [getRoute $kw $domNode]]
    get_domnode_attribute $nodo dict
    set currentSolStrat [get_domnode_attribute $nodo v]
    set mySolStrat [get_domnode_attribute $domNode solstratname]
    set ret [expr [string compare $currentSolStrat $mySolStrat] == 0]
    if {$ret} {
        set st [::Model::GetSolutionStrategy $mySolStrat] 
        foreach se [$st getSolversEntries] {
            if {[get_domnode_attribute $domNode n] == [$se getName]} {
                set filter [$se getAttribute filter]
                foreach {k v} $filter {
                    set real [get_domnode_attribute [$domNode selectNodes [getRoute $k $domNode]] v]
                    if {$real ni $v} {
                        set ret false
                        break;
                    }
                }
            }
        }
    }
    
    return $ret
}

proc spdAux::chk_loads_function_time { domNode load_name } {
    set loads [list [list scalar]]
    lappend loads [list interpolator_func x x T]
    return [join $loads ,]
}

proc spdAux::ViewDoc {} {
    W [[customlib::GetBaseRoot] asXML]
}


proc spdAux::ConvertAllUniqueNames {oldPrefix newPrefix} {
    variable uniqueNames
    set root [customlib::GetBaseRoot]
    
    foreach routeName [dict keys $uniqueNames] {
        if {[string first $oldPrefix $routeName] eq 0} {
            set route [getRoute $routeName]
            set newrouteName [string map [list $oldPrefix $newPrefix] $routeName]
            set node [$root selectNodes $route]
            set uns [split [get_domnode_attribute $node un] ","]
            if {$newrouteName ni $uns} {
                lappend uns $newrouteName
                $node setAttribute un [ListToValues $uns]
            }
        }
    }
    
    spdAux::parseRoutes
}


proc spdAux::MergeGroups {result_group_name group_list} {
    GiD_Groups create $result_group_name

    foreach group $group_list {
        foreach entity [list points lines surfaces volumes nodes elements faces] {
            GiD_EntitiesGroups assign $result_group_name $entity [GiD_EntitiesGroups get $group $entity]
        }
    }
}


proc spdAux::GetUsedElements {{alt_un ""}} {
    set lista [list ]
    set root [customlib::GetBaseRoot]

    set un $alt_un
    if {$un eq ""} {set un [apps::ExecuteOnCurrentApp write::GetAttribute parts_un]}

    if {$un ne ""} {

        set xp1 "[spdAux::getRoute $un]/group"
        foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
            set name [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element']"] ]
            if {$name ni $lista} {lappend lista $name}
        }
    }
    return $lista
}

proc spdAux::LoadIntervalGroups { {root ""} } {
    customlib::UpdateDocument
    variable GroupsEdited
    
    if {$root eq "" } {
        set root [customlib::GetBaseRoot]
    }

    foreach elem [$root getElementsByTagName "interval_group"] {
        dict lappend GroupsEdited [$elem @parent] [$elem @child]
    }
}
proc spdAux::AddIntervalGroup { parent child } {
    variable GroupsEdited
    dict lappend GroupsEdited $parent $child
    customlib::UpdateDocument
    gid_groups_conds::addF {container[@n='interval_groups']} interval_group [list parent ${parent} child ${child}]
}
proc spdAux::RemoveIntervalGroup { parent child } {
    variable GroupsEdited
    dict set GroupsEdited $parent [lsearch -inline -all -not -exact [dict get $GroupsEdited $parent] $child]
    customlib::UpdateDocument
    gid_groups_conds::delete "container\[@n='interval_groups'\]/interval_group\[@parent='$parent' and @child='$child'\]"
}

proc spdAux::RenameIntervalGroup { oldname newname } {
    variable GroupsEdited
    if {[dict exists $GroupsEdited $oldname]} {
        set list_of_subgroups [dict get $GroupsEdited $oldname]
        foreach group $list_of_subgroups {
            set child [lrange [GidUtils::Split $group "//"] 1 end]
            set fullname [join [list $newname $child] "//"]
            RemoveIntervalGroup $oldname $group
            AddIntervalGroup $newname $fullname
            gid_groups_conds::rename_group $group $fullname
        }
        set GroupsEdited [dict remove $GroupsEdited $oldname]
    }
}

proc spdAux::GetListOfSubModelParts { {stage ""} } {
    set root [customlib::GetBaseRoot]
    if {$stage ne ""} {set root $stage}
    set all_raw [$root selectNodes ".//condition/group"]

    return $all_raw
}

proc spdAux::GetAppliedGroups { {root ""} } {
    customlib::UpdateDocument
    
    if {$root eq "" } {
        set root [customlib::GetBaseRoot]
    }
    set group_list [list ]
    foreach group_node [$root getElementsByTagName "group"] {
        set parent [[$group_node parent] nodeName]
        if {$parent eq "condition"} {
            lappend group_list [write::GetWriteGroupName [$group_node @n]]
        }
    }
    return [lsort -unique $group_list]
}

proc spdAux::RegisterWindow {window_name} {
    variable list_of_windows
    lappend list_of_windows $window_name
}


spdAux::Init
