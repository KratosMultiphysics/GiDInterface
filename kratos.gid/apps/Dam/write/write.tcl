namespace eval Dam::write {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable TableDict

    variable ThermalSubModelPartDict

    # Variable global definida al principio y utilizada para transferir entre procesos el número de tablas existentes
    variable number_tables
}

proc Dam::write::Init { } {
    # Namespace variables inicialization
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]

    variable TableDict
    catch {unset TableDict}
    set TableDict [dict create]

    SetAttribute parts_un DamParts
    SetAttribute nodal_conditions_un DamNodalConditions
    SetAttribute conditions_un DamLoads
    SetAttribute thermal_conditions_un DamThermalLoads
    SetAttribute materials_un DamMaterials
    SetAttribute results_un Results
    SetAttribute time_parameters_un DamTimeParameters
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "Dam"]
    SetAttribute main_script_file "MainKratosDam.py"
    SetAttribute properties_location mdpa
    SetAttribute model_part_name "MainModelPart"
}

proc Dam::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/MainKratosDam.py"
    write::RenameFileInModel "MainKratosDam.py" "MainKratos.py"
}

# MDPA Blocks
proc Dam::write::writeModelPartEvent { } {
    # Init data
    write::initWriteConfiguration [GetAttributes]

    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    Dam::write::UpdateMaterials
    write::writeMaterials
    Dam::write::writeTables
    Dam::write::writeTables_dev
    write::writeNodalCoordinates
    write::writeElementConnectivities

    set damTypeofProblem [write::getValue DamTypeofProblem]
    if {$damTypeofProblem eq "Thermo-Mechanical" || $damTypeofProblem eq "UP_Thermo-Mechanical"} {
        Dam::write::writeThermalElements
    }

    Dam::write::writeConditions
    Dam::write::writeMeshes
}

proc Dam::write::UpdateMaterials { } {
    set matdict [write::getMatDict]
    foreach {mat props} $matdict {
        set constlaw [dict get $props ConstitutiveLaw]
        # Modificar la ley constitutiva
        set newconstlaw $constlaw
        if {$constlaw eq "BilinearCohesive2DPlaneStress"} {set newconstlaw "BilinearCohesive2DLaw"}
        if {$constlaw eq "BilinearCohesive2DPlaneStrain"} {
            dict set matdict $mat THICKNESS  1.0000E+00
            set newconstlaw "BilinearCohesive2DLaw"
        }

        dict set matdict $mat CONSTITUTIVE_LAW_NAME $newconstlaw
    }
    write::setMatDict $matdict
}

proc Dam::write::writeConditions { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [write::writeConditions "DamLoads"]
    set pairs [lsort -increasing -index end [dict values $ConditionsDictGroupIterators] ]
    set index [lindex [lindex [lsort -integer -index 0 $pairs] end] end]
    if {$index eq ""} {
        set index 0
    }

    set ThermalConditionGroups [write::writeConditions "DamThermalLoads" $index]
    set ConditionsDictGroupIterators [dict merge $ConditionsDictGroupIterators $ThermalConditionGroups]

    set SelfweightConditionGroups [write::writeConditions "DamSelfweight" $index]
    set ConditionsDictGroupIterators [dict merge $ConditionsDictGroupIterators $SelfweightConditionGroups]
}

proc Dam::write::writeMeshes { } {

    write::writePartSubModelPart

    set damTypeofProblem [write::getValue DamTypeofProblem]
    if {$damTypeofProblem eq "Thermo-Mechanical" || $damTypeofProblem eq "UP_Thermo-Mechanical"} {
        Dam::write::ThermalSubModelPart
    }

    # Solo Malla , no en conditions
    writeNodalConditions "DamNodalConditions"

    # A Condition y a meshes-> salvo lo que no tenga topologia
    writeLoads "DamLoads"
    writeLoads "DamThermalLoads"
    writeLoads "DamSelfweight"
}



proc Dam::write::writeNodalConditions { keyword } {
    variable TableDict
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $keyword]/condition/group"
    set groups [$root selectNodes $xp1]
    if {$groups eq ""} {
        set xp1 "[spdAux::getRoute $keyword]/group"
        set groups [$root selectNodes $xp1]
    }
    foreach group $groups {
        set condid [[$group parent] @n]
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        set tableid [list ]
        if {[dict exists $TableDict $condid $groupid]} {
            set groupdict [dict get $TableDict $condid $groupid]
            foreach valueid [dict keys $groupdict] {
                lappend tableid [dict get $groupdict $valueid tableid]
            }
        }
        ::write::writeGroupSubModelPart $condid $groupid "nodal" "" $tableid
    }
}

proc Dam::write::writeLoads { baseUN } {
    variable TableDict
    variable ConditionsDictGroupIterators
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $baseUN]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set condid [get_domnode_attribute [$group parent] n]
        set groupid [get_domnode_attribute $group n]
        set groupid [write::GetWriteGroupName $groupid]
        set tableid [list ]
        if {[dict exists $TableDict $condid $groupid]} {
            set groupdict [dict get $TableDict $condid $groupid]
            foreach valueid [dict keys $groupdict] {
                lappend tableid [dict get $groupdict $valueid tableid]
            }
        }
        if {$groupid in [dict keys $ConditionsDictGroupIterators]} {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "Conditions" [dict get $ConditionsDictGroupIterators $groupid] $tableid
        } else {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "nodal" "" $tableid
        }
    }
}

proc Dam::write::getVariableNameList {un {condition_type "Condition"}} {
    set xp1 "[spdAux::getRoute $un]/condition/group"
    set groups [[customlib::GetBaseRoot] selectNodes $xp1]

    set variable_list [list ]
    foreach group $groups {
        set groupName [$group @n]
        #W "GROUP $groupName"
        set cid [[$group parent] @n]
        set groupId [::write::getSubModelPartId $cid $groupName]
        set condId [[$group parent] @n]
        if {$condition_type eq "Condition"} {
            set condition [::Model::getCondition $condId]
        } {
            set condition [::Model::getNodalConditionbyId $condId]
        }
        set variable_name [$condition getAttribute VariableName]
        if {$variable_name ne ""} {lappend variable_list [lindex $variable_name 0]}
    }
    return $variable_list
}

proc Dam::write::GetTableidFromFileid { filename } {
    variable TableDict
    foreach condid [dict keys $TableDict] {
        foreach groupid [dict keys [dict get $TableDict $condid]] {
            foreach valueid [dict keys [dict get $TableDict $condid $groupid]] {
                if {[dict get $TableDict $condid $groupid $valueid fileid] eq $filename} {
                    return [dict get $TableDict $condid $groupid $valueid tableid]
                }
            }
        }
    }
    return 0
}

proc Dam::write::writeTables { } {
    variable TableDict
    set printed_tables [list ]
    foreach table [GetPrinTables] {
        lassign $table tableid fileid condid groupid valueid
        dict set TableDict $condid $groupid $valueid tableid $tableid
        dict set TableDict $condid $groupid $valueid fileid $fileid
        if {$tableid ni $printed_tables} {
            lappend printed_tables $tableid
            write::WriteString "Begin Table $tableid TIME VALUE"
            if {[string index $fileid 0] eq "."} {
                set modelname [GiD_Info project ModelName]
                set filename [string range $fileid 2 end]
                set fileid [file join "$modelname.gid" $filename]
            }
            set data [GidUtils::ReadFile $fileid]
            write::WriteString [string map {; { }} $data]
            write::WriteString "End Table"
            write::WriteString ""
        }
    }
}

proc Dam::write::writeTables_dev { } {

    set printed_tables [list ]
    foreach table [GetPrinTables_dev] {
        lassign $table tableid fileid
        if {$tableid ni $printed_tables} {
            lappend printed_tables $tableid
            write::WriteString "Begin Table $tableid TIME VALUE"
            if {[string index $fileid 0] eq "."} {
                set modelname [GiD_Info project ModelName]
                set filename [string range $fileid 2 end]
                set fileid [file join "$modelname.gid" $filename]
            }
            set data [GidUtils::ReadFile $fileid]
            write::WriteString [string map {; { }} $data]
            write::WriteString "End Table"
            write::WriteString ""
        }
    }
}


proc Dam::write::GetPrinTables {} {

    set root [customlib::GetBaseRoot]
    FileSelector::CopyFilesIntoModel [file join [GiD_Info project ModelName] ".gid"]
    set listaTablas [list ]
    set listaFiles [list ]
    set num 0
    set origins [list "DamLoads" "DamThermalLoads" "DamNodalConditions" "DamSelfweight"]
    foreach unique_name $origins {
        set xpathCond "[spdAux::getRoute $unique_name]/condition/group/value\[@type='tablefile'\]"
        foreach node [$root selectNodes $xpathCond] {
            set fileid [get_domnode_attribute $node v]
            set valueid [get_domnode_attribute $node n]
            set groupid [get_domnode_attribute [$node parent] n]
            set condid [get_domnode_attribute [[$node parent] parent] n]
            #W $condid
            if {$fileid ni [list "" "- No file"]} {
                if {$fileid ni $listaFiles} {
                    lappend listaFiles $fileid
                    incr num
                    set tableid $num
                } else {
                    set tableid 0
                    foreach table $listaTablas {
                        lassign $table tableid2 fileid2 condid2 groupid2 valueid2
                        if {$fileid2 eq $fileid} {set tableid $tableid2; break}
                    }
                }
                #W "$tableid $fileid $condid $groupid $valueid"
                lappend listaTablas [list $tableid $fileid $condid $groupid $valueid]
            }
        }
    }
    return $listaTablas
}


proc Dam::write::GetPrinTables_dev { } {

    set root [customlib::GetBaseRoot]
    FileSelector::CopyFilesIntoModel [file join [GiD_Info project ModelName] ".gid"]
    set listaTablas2 [list ]
    set listaFiles2 [list ]
    set num [llength [GetPrinTables]]

    set path_devices "[spdAux::getRoute DamTempDevice]/blockdata\[@n='device'\]"
    set nodes [$root selectNodes $path_devices]

    foreach node $nodes {
        set name [$node @name]
        set table_device "[spdAux::getRoute DamTempDevice]/blockdata\[@name='$name'\]/value\[@n='table'\]"
        set node_table_device [$root selectNodes $table_device]
        set fileid [write::getValueByNode $node_table_device]

        if {$fileid ni [list "" "- No file"]} {
            if {$fileid ni $listaFiles2} {
                lappend listaFiles2 $fileid
                incr num
                set tableid $num
            } else {
                set tableid 0
                foreach table $listaTablas2 {
                    lassign $table tableid2 fileid2
                    if {$fileid2 eq $fileid} {set tableid $tableid2; break}
                }
            }
            #W "$tableid $fileid $condid $groupid $valueid"
            lappend listaTablas2 [list $tableid $fileid]
        }
    }
    return $listaTablas2
}


#-------------------------------------------------------------------------------

proc Dam::write::writeThermalElements {} {

    set ThermalGroups [list]

    foreach node_part [GetDamPartGroupNodes] {
        set element_id [write::getValueByNode [$node_part selectNodes "./value\[@n='Element'\]"] ]
        set element [Model::getElement $element_id]
        set element_type [$element getAttribute "ElementType"]
        if {$element_type eq "Solid"} {
            lappend ThermalGroups [$node_part @n]
        }
    }

    set ElementId [GiD_Info Mesh MaxNumElements]
    variable ThermalSubModelPartDict
    set ThermalSubModelPartDict [dict create]

    for {set i 0} {$i < [llength $ThermalGroups]} {incr i} {

        set ElementList [list]

        # EulerianConvDiff2D
        Dam::write::writeThermalConnectivities [lindex $ThermalGroups $i] triangle EulerianConvDiff2D "Dam::write::Triangle2D3Connectivities" ElementId ElementList
        # EulerianConvDiff2D4N
        Dam::write::writeThermalConnectivities [lindex $ThermalGroups $i] quadrilateral EulerianConvDiff2D4N "Dam::write::Quadrilateral2D4Connectivities" ElementId ElementList
        # EulerianConvDiff3D
        Dam::write::writeThermalConnectivities [lindex $ThermalGroups $i] tetrahedra EulerianConvDiff3D "Dam::write::Quadrilateral2D4Connectivities" ElementId ElementList
        # EulerianConvDiff3D8N
        Dam::write::writeThermalConnectivities [lindex $ThermalGroups $i] hexahedra EulerianConvDiff3D8N "Dam::write::Hexahedron3D8Connectivities" ElementId ElementList

        dict set ThermalSubModelPartDict [lindex $ThermalGroups $i] Elements $ElementList
        # Añado guiones bajos donde hay espacios en los nombres de los submodelparts.
        set old_name_SubModelPart "Thermal_[lindex $ThermalGroups $i]"
        set new_name_SubModelPart [string map {" " "_"} $old_name_SubModelPart]
        dict set ThermalSubModelPartDict [lindex $ThermalGroups $i] SubModelPartName $new_name_SubModelPart

    }


}

proc Dam::write::writeThermalConnectivities {Group ElemType ElemName ConnectivityType ElementId ElementList} {
    set Entities [GiD_EntitiesGroups get $Group elements -element_type $ElemType]
    if {[llength $Entities] > 0} {
        upvar $ElementId MyElementId
        upvar $ElementList MyElementList

        write::WriteString "Begin Elements $ElemName // GUI group identifier: $Group"
        for {set j 0} {$j < [llength $Entities]} {incr j} {
            incr MyElementId
            lappend MyElementList $MyElementId
            write::WriteString "  $MyElementId  0  [$ConnectivityType [lindex $Entities $j]]"
        }
        write::WriteString "End Elements"
        write::WriteString ""
    }
}

proc Dam::write::Triangle2D3Connectivities { ElemId } {

    set ElementInfo [GiD_Mesh get element $ElemId]
    #ElementInfo: <layer> <elemtype> <NumNodes> <N1> <N2> ...
    return "[lindex $ElementInfo 3] [lindex $ElementInfo 4] [lindex $ElementInfo 5]"
}


proc Dam::write::Quadrilateral2D4Connectivities { ElemId } {

    #Note: It is the same for the Tethrahedron3D4

    set ElementInfo [GiD_Mesh get element $ElemId]
    #ElementInfo: <layer> <elemtype> <NumNodes> <N1> <N2> ...
    return "[lindex $ElementInfo 3] [lindex $ElementInfo 4] [lindex $ElementInfo 5]\
        [lindex $ElementInfo 6]"
}

proc Dam::write::Hexahedron3D8Connectivities { ElemId } {

    #It is the same for Quadrilateral2D8

    set ElementInfo [GiD_Mesh get element $ElemId]
    #ElementInfo: <layer> <elemtype> <NumNodes> <N1> <N2> ...
    return "[lindex $ElementInfo 3] [lindex $ElementInfo 4] [lindex $ElementInfo 5]\
        [lindex $ElementInfo 6] [lindex $ElementInfo 7] [lindex $ElementInfo 8]\
        [lindex $ElementInfo 9] [lindex $ElementInfo 10]"
}

#-------------------------------------------------------------------------------


proc Dam::write::ThermalSubModelPart { } {

    variable ThermalSubModelPartDict

    dict for {Group ThermalPart} $ThermalSubModelPartDict {

        write::WriteString "Begin SubModelPart [dict get $ThermalPart SubModelPartName] // Group $Group // Subtree Parts"
        # Nodes
        set ThermalNodes [GiD_EntitiesGroups get $Group nodes]
        write::WriteString "  Begin SubModelPartNodes"
        for {set i 0} {$i < [llength $ThermalNodes]} {incr i} {
            write::WriteString "    [lindex $ThermalNodes $i]"
        }
        write::WriteString "  End SubModelPartNodes"
        # Elements
        set ThermalElements [dict get $ThermalPart Elements]
        write::WriteString "  Begin SubModelPartElements"
        for {set i 0} {$i < [llength $ThermalElements]} {incr i} {
            write::WriteString "    [lindex $ThermalElements $i]"
        }
        write::WriteString "  End SubModelPartElements"
        # Conditions
        write::WriteString "  Begin SubModelPartConditions"
        write::WriteString "  End SubModelPartConditions"
        write::WriteString "End SubModelPart"
        write::WriteString ""
    }
}

#-------------------------------------------------------------------------------

proc Dam::write::getSubModelPartThermalNames { } {

    set submodelThermalPartsNames [list]

    variable ThermalSubModelPartDict
    dict for {Group ThermalPart} $ThermalSubModelPartDict {
        lappend submodelThermalPartsNames [dict get $ThermalPart SubModelPartName]
    }

    return $submodelThermalPartsNames
}

proc Dam::write::GetDamPartGroupNodes { } {
    set nodes [write::getPartsGroupsId node]
    return $nodes
}


proc Dam::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Dam::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Dam::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc Dam::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc Dam::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}


Dam::write::Init
