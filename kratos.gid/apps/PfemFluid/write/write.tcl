namespace eval PfemFluid::write {
    variable remesh_domains_dict
    variable bodies_list
    variable Names
    variable ModelPartName
}

proc PfemFluid::write::Init { } {
    variable remesh_domains_dict
    set remesh_domains [dict create ]
    variable bodies_list
    set bodies_list [list ]
    variable Names
    set Names [dict create DeltaTime DeltaTime]
    variable ModelPartName
    set ModelPartName PfemFluidModelPart
}


# Model Part Blocks
proc PfemFluid::write::writeModelPartEvent { } {
    set parts_un_list [GetPartsUN]
    foreach part_un $parts_un_list {
        write::initWriteData $part_un "PFEMFLUID_Materials"
    }
    
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::writeMaterials "PfemFluid"
    
    write::writeNodalCoordinates
    foreach part_un $parts_un_list {
        write::initWriteData $part_un "PFEMFLUID_Materials"
        write::writeElementConnectivities
    }
    PfemFluid::write::writeMeshes
}

proc PfemFluid::write::writeMeshes { } {
    
    foreach part_un [GetPartsUN] {
        write::initWriteData $part_un "PFEMFLUID_Materials"
        write::writePartSubModelPart
    }
    # Solo Malla , no en conditions
    writeNodalConditions "PFEMFLUID_NodalConditions"
    
}


proc PfemFluid::write::writeNodalConditions { keyword } {
    write::writeNodalConditions $keyword
    return ""
    
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $keyword]/container/blockdata"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set cid [[$group parent] @n]
        set groupid [$group @name]
        set groupid [write::GetWriteGroupName $groupid]
        # Aqui hay que gestionar la escritura de los bodies
        # Una opcion es crear un megagrupo temporal con esa informacion, mandar a pintar, y luego borrar el grupo.
        # Otra opcion es no escribir el submodelpart. Ya tienen las parts y el project parameters tiene el conformado de los bodies
        ::write::writeGroupSubModelPart $cid $groupid "nodal"
    }
}

proc PfemFluid::write::GetPartsUN { } {
    customlib::UpdateDocument
    set lista [list ]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata/condition"
    set i 0
    foreach part_node [$root selectNodes $xp1] {
        if {![$part_node hasAttribute "un"]} {
            set un "PFEMFLUID_Part$i"
            while {[spdAux::getRoute $un] ne ""} {
                incr i
                set un "PFEMFLUID_Part$i"
            }
            $part_node setAttribute un $un
            spdAux::setRoute $un [$part_node toXPath]
        }
        lappend lista [get_domnode_attribute $part_node un]
    }
    customlib::UpdateDocument
    return $lista
}

# Custom files (Copy python scripts, write materials file...)
proc PfemFluid::write::writeCustomFilesEvent { } {
    
    write::CopyFileIntoModel "python/RunPFEM.py"
    write::RenameFileInModel "RunPFEM.py" "MainKratos.py"
    
    #write::RenameFileInModel "ProjectParameters.json" "ProjectParameters.py"
}

PfemFluid::write::Init
