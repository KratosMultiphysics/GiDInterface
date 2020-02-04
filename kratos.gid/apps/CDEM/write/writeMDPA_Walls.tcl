proc DEM::write::WriteMDPAWalls { } {
    # Headers
    write::writeModelPartData

    # Material
    set wall_properties [WriteWallProperties]

    # Nodal coordinates (only for Walls <inefficient> )
    write::writeNodalCoordinatesOnGroups [DEM::write::GetWallsGroups]
    write::writeNodalCoordinatesOnGroups [GetWallsGroupsSmp]

    # Nodal conditions and conditions
    DEM::write::writeConditions $wall_properties

    # SubmodelParts
    DEM::write::writeWallConditionMeshes

    # CustomSubmodelParts
    WriteWallCustomSmp
}


proc CDEM::write::WriteWallCustomSmp { } {
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    set i $DEM::write::last_property_id
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        incr i
        set groupid [$group @n]
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        if {$destination_mdpa == "FEM"} {
            write::WriteString  "Begin SubModelPart $groupid \/\/ Custom SubModelPart. Group name: $groupid"
            write::WriteString  "Begin SubModelPartData // DEM-FEM-Wall. Group name: $groupid"
            write::WriteString  "End SubModelPartData"
            write::WriteString  "Begin SubModelPartNodes"
            GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $groupid] [subst "%10i\n"]]
            write::WriteString  "End SubModelPartNodes"
            write::WriteString  "End SubModelPart"
            write::WriteString  ""
        }
    }
}

proc DEM::write::DefineMaterialTestConditions {group_node} {
    set material_analysis [write::getValue DEMTestMaterial Active]
    if {$material_analysis == "true"} {
        set is_material_test [write::getValueByNode [$group_node selectNodes "./value\[@n='MaterialTest'\]"]]
        if {$is_material_test == "true"} {
            set as_condition [write::getValueByNode [$group_node selectNodes "./value\[@n='DefineTopBot'\]"]]
            if {$as_condition eq "top"} {
                write::WriteString "    TOP 1"
                write::WriteString "    BOTTOM 0"
            } else {
                write::WriteString "    TOP 0"
                write::WriteString "    BOTTOM 1"}
        }
    } else {
            write::WriteString "    TOP 0"
            write::WriteString "    BOTTOM 0"}
    set GraphPrint [write::getValueByNode [$group_node selectNodes "./value\[@n='GraphPrint'\]"]]
    if {$GraphPrint == "true" || $material_analysis == "true"} {
        set GraphPrintval 1
    } else {
        set GraphPrintval 0
    }
    write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
}