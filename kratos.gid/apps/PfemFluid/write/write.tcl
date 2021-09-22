namespace eval ::PfemFluid::write {
    namespace path ::PfemFluid
    Kratos::AddNamespace [namespace current]
    
    variable writeAttributes
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


    SetAttribute materials_un [::PfemFluid::GetUniqueName materials]
    SetAttribute nodal_conditions_un [::PfemFluid::GetUniqueName nodal_conditions]
    
    SetAttribute main_launch_file [::PfemFluid::GetAttribute main_launch_file]
    SetAttribute materials_file [::PfemFluid::GetWriteProperty materials_file]
    SetAttribute properties_location [::PfemFluid::GetWriteProperty properties_location]
    SetAttribute model_part_name [::PfemFluid::GetWriteProperty model_part_name]
}


# Model Part Blocks
proc PfemFluid::write::writeModelPartEvent { } {
    # Init data
    write::initWriteConfiguration [GetAttributes]

    set parts_un_list [GetPartsUN]
    foreach part_un $parts_un_list {
        write::initWriteData $part_un [GetAttribute materials_un]
    }

    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    # write::writeMaterials "PfemFluid"

    write::writeNodalCoordinates
    foreach part_un $parts_un_list {
        write::initWriteData $part_un [GetAttribute materials_un]
        write::writeElementConnectivities
    }
    PfemFluid::write::writeMeshes
}

proc PfemFluid::write::writeMeshes { } {

    foreach part_un [GetPartsUN] {
        write::initWriteData $part_un [GetAttribute materials_un]
        write::writePartSubModelPart
    }
    # Solo Malla , no en conditions
    writeNodalConditions [GetAttribute nodal_conditions_un]

}


proc PfemFluid::write::writeNodalConditions { keyword } {
    write::writeNodalConditions $keyword
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
    # Write the fluid materials json file
    PfemFluid::write::WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}

proc PfemFluid::write::WriteMaterialsFile { {write_const_law True} {include_modelpart_name True} } {
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetAttribute model_part_name]}
    PfemFluid::write::writePropertiesJsonFile [GetAttribute materials_file] $write_const_law $model_part_name
}

proc PfemFluid::write::writePropertiesJsonFile { {fname "materials.json"} {write_claw_name "True"} {model_part_name ""}} {
    set mats_json [dict create properties [list ] ]
    foreach parts_un [PfemFluid::write::GetPartsUN] {
        foreach property [dict get [write::getPropertiesList $parts_un $write_claw_name $model_part_name] properties ] {
            if {$property ne "\[\]"} {
                dict lappend mats_json properties $property
            }
        }
    }
    write::OpenFile $fname
    write::WriteJSON $mats_json
    write::CloseFile
}

proc PfemFluid::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc PfemFluid::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc PfemFluid::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc PfemFluid::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc PfemFluid::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}
