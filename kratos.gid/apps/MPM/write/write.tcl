namespace eval MPM::write {
    variable writeAttributes
}

proc MPM::write::Init { } {
    # Namespace variables inicialization
    SetAttribute parts_un MPMParts
    SetAttribute nodal_conditions_un MPMNodalConditions
    # SetAttribute conditions_un FLBC
    # SetAttribute materials_un EMBFLMaterials
    # SetAttribute writeCoordinatesByGroups 0
    # SetAttribute validApps [list "MPM"]
    # SetAttribute main_script_file "KratosFluid.py"
    # SetAttribute materials_file "FluidMaterials.json"
}

# Events
proc MPM::write::writeModelPartEvent { } {
    write::initWriteConfiguration [GetAttributes]
    set filename "[file tail [GiD_Info project ModelName]]"
    
    write::processMaterials

    ## Grid MPDA ##
    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    
    # Materials
    write::writeMaterials

    # Nodal coordinates 
    write::writeNodalCoordinates

    writeGridConnectivities
    
    writeNodalDisplacement
    write::CloseFile
    write::RenameFileInModel "$filename.mdpa" "${filename}_Grid.mdpa"

    ## Body MDPA ##
    write::OpenFile "${filename}_Body.mdpa"

    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Materials
    write::writeMaterials

    # Nodal coordinates
    writeBodyNodalCoordinates

    # Body element connectivities
    writeBodyElementConnectivities

    write::CloseFile
}

proc MPM::write::writeBodyNodalCoordinates { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set body_groups [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem ni [list GRID2D GRID3D]} {
            lappend body_groups [$gNode @n]
        }
    }
    write::writeNodalCoordinatesOnGroups $body_groups
}

proc MPM::write::writeBodyElementConnectivities { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set body_groups [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem ni [list GRID2D GRID3D]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeGridConnectivities { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem in [list GRID2D GRID3D]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeNodalDisplacement { } {
    set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='DISPLACEMENT'\]/group"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [GiD_Groups get parent [$gNode @n] ]
        foreach dim [list X Y Z] {
            set enabled [write::getValueByNode [$gNode selectNodes ".//value\[@n='Enabled_$dim'\]"]]
            if {[write::isBooleanTrue $enabled]} {
                set disp [write::getValueByNode [$gNode selectNodes ".//value\[@n='Displacement$dim'\]"]]
                write::WriteString "Begin NodalData DISPLACEMENT_$dim"
                GiD_WriteCalculationFile nodes [dict create $groupid  "%5d 1 $disp \n"]
                write::WriteString "End NodalData"
                write::WriteString ""
            }
        }
    }
}

# <group n="Displacement Auto1//Total" ov="line" tree_state="close">
#     <value n="Enabled_X" pn="X component" values="Yes,No" help="Enables the X Displacement" state="" v="Yes" tree_state="close"/>
#     <value n="DisplacementX" wn="DISPLACEMENT _X" pn="X Displacement" help="Displacement" state="normal" v="0" tree_state="close"/>
#     <value n="Enabled_Y" pn="Y component" values="Yes,No" help="Enables the Y Displacement" state="" v="Yes" tree_state="close"/>
#     <value n="DisplacementY" wn="DISPLACEMENT _Y" pn="Y Displacement" help="Displacement" state="normal" v="0" tree_state="close"/>
#     <value n="Enabled_Z" pn="Z component" values="Yes,No" help="Enables the Z Displacement" state="[CheckDimension 3D]" v="Yes"/>
#     <value n="DisplacementZ" wn="DISPLACEMENT _Z" pn="Z Displacement" help="Displacement" state="[CheckDimension 3D]" v="0"/>
#     <value n="Interval" pn="Time interval" values="[getIntervals]" help="Displacement" state="" v="Total" tree_state="close"/>
# </group>


proc MPM::write::writeCustomFilesEvent { } {
    # write::CopyFileIntoModel "python/KratosFluid.py"
    # write::RenameFileInModel "KratosFluid.py" "MainKratos.py"
    write::RenameFileInModel "ProjectParameters.json" "ProjectParameters.py"
}

proc MPM::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc MPM::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc MPM::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

MPM::write::Init
