namespace eval Dam::write {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable TableDict
    
    variable ThermalSubModelPartDict
}

proc Dam::write::Init { } {
    # Namespace variables inicialization
    
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]
    
    # key = file path
    # value = id table
    variable TableDict
    catch {unset TableDict}
    set TableDict [dict create]
}


proc Dam::write::writeCustomFilesEvent { } {
    
    set damTypeofProblem [write::getValue DamTypeofProblem]
    if {$damTypeofProblem eq "Acoustic"} {
        write::CopyFileIntoModel "python/dam_acoustic_script.py"
        write::RenameFileInModel "dam_acoustic_script.py" "MainKratos.py"
    } elseif {$damTypeofProblem eq "Modal-Analysis" } {
        write::CopyFileIntoModel "python/dam_eigen_script.py"
        write::RenameFileInModel "dam_eigen_script.py" "MainKratos.py"
    } else {
        write::CopyFileIntoModel "python/dam_main.py"
        write::RenameFileInModel "dam_main.py" "MainKratos.py"
    }
    
    #~ write::CopyFileIntoModel "python/dam_main.py"
    #~ write::RenameFileInModel "dam_main.py" "MainKratos.py"
    
}

# MDPA Blocks

proc Dam::write::writeModelPartEvent { } {
    write::initWriteData "DamParts" "DamMaterials"
    
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    
    UpdateMaterials
    write::writeMaterials
    Dam::write:::writeTables
    write::writeNodalCoordinates
    write::writeElementConnectivities

    set damTypeofProblem [write::getValue DamTypeofProblem]
    if {$damTypeofProblem eq "Thermo-Mechanical" || $damTypeofProblem eq "UP_Thermo-Mechanical"} {
        Dam::write::writeThermalElements
    }
    
    writeConditions
    writeMeshes
    
    #writeCustomBlock
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
}

proc Dam::write::writeMeshes { } {
    
    write::writePartMeshes
    
    set damTypeofProblem [write::getValue DamTypeofProblem]
    if {$damTypeofProblem eq "Thermo-Mechanical" || $damTypeofProblem eq "UP_Thermo-Mechanical"} {
        Dam::write::ThermalSubModelPart
    }
    
    # Solo Malla , no en conditions
    writeNodalConditions "DamNodalConditions"
    
    # A Condition y a meshes-> salvo lo que no tenga topologia
    writeLoads
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
        ::write::writeGroupMesh $condid $groupid "nodal" "" $tableid
    }
}

proc Dam::write::writeLoads { } {
    variable TableDict
    variable ConditionsDictGroupIterators
    
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "DamLoads"]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set condid [get_domnode_attribute [$group parent] n]
        set groupid [get_domnode_attribute $group n]
        set groupid [write::GetWriteGroupName $groupid]
        #W "Writing mesh of Load $condid $groupid"
        set tableid [list ]
        if {[dict exists $TableDict $condid $groupid]} {
            set groupdict [dict get $TableDict $condid $groupid]
            foreach valueid [dict keys $groupdict] {
                lappend tableid [dict get $groupdict $valueid tableid]
            }
        }
        #W "table $tableid"
        if {$groupid in [dict keys $ConditionsDictGroupIterators]} {
            ::write::writeGroupMesh [[$group parent] @n] $groupid "Conditions" [dict get $ConditionsDictGroupIterators $groupid] $tableid
        } else {
            ::write::writeGroupMesh [[$group parent] @n] $groupid "nodal" "" $tableid
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
        set groupId [::write::getMeshId $cid $groupName]
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

proc Dam::write::GetPrinTables {} {
    
    set root [customlib::GetBaseRoot]
    FileSelector::CopyFilesIntoModel [file join [GiD_Info project ModelName] ".gid"]
    set listaTablas [list ]
    set listaFiles [list ]
    set num 0
    set origins [list "DamLoads" "DamNodalConditions"]
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

#-------------------------------------------------------------------------------

proc Dam::write::writeThermalElements {} {
    
    set ThermalGroups [list]
    
    set mat_dict [write::getMatDict]
    foreach part_name [dict keys $mat_dict] {
        if {[[Model::getElement [dict get $mat_dict $part_name Element]] getAttribute "ElementType"] eq "Solid"} {
            lappend ThermalGroups $part_name
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
        dict set ThermalSubModelPartDict [lindex $ThermalGroups $i] SubModelPartName "Thermal_Part_Auto_[expr {$i+1}]"
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


Dam::write::Init
