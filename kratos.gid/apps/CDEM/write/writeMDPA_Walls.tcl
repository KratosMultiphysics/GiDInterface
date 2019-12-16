proc DEM::write::WriteMDPAWalls { } {
    # Headers
    write::writeModelPartData

    # Material
    set wall_properties [WriteWallProperties]

    # Nodal coordinates (only for Walls <inefficient> )
    write::writeNodalCoordinatesOnGroups [DEM::write::GetWallsGroups]
    write::writeNodalCoordinatesOnGroups [GetWallsGroupsSmp]
    write::writeNodalCoordinatesOnGroups [GetNodesForGraphs]

    # Nodal conditions and conditions
    CDEM::write::writeConditions $wall_properties

    # SubmodelParts
    if {$::Model::SpatialDimension eq "2D"} {DEM::write::writeWallConditionMeshes2D
    } else {DEM::write::writeWallConditionMeshes}

    # CustomSubmodelParts
    WriteWallCustomSmp
    WriteWallGraphsFlag
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

proc CDEM::write::WriteWallGraphsFlag { } {
    set xp1 "[spdAux::getRoute [GetAttribute graphs_un]]/group"
    #set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	    write::WriteString  "Begin SubModelPart $groupid \/\/ Custom SubModelPart. Group name: $groupid"
	    write::WriteString  "Begin SubModelPartData // DEM-FEM-Wall. Group name: $groupid"
	    write::WriteString  "FORCE_INTEGRATION_GROUP 1"
	    write::WriteString  "End SubModelPartData"
	    write::WriteString  "Begin SubModelPartNodes"
	    GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $groupid] [subst "%10i\n"]]
	    write::WriteString  "End SubModelPartNodes"
	    write::WriteString  "End SubModelPart"
	    write::WriteString  ""
    }
}

proc CDEM::write::GetNodesForGraphs { } {
    set groups [list ]
    #set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
    #set xp1 "[spdAux::getRoute [GetAttribute graphs_un]]/condition\[@n = 'Graphs'\]/group"
    set xp1 "[spdAux::getRoute [GetAttribute graphs_un]]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

# TODO: SHOULD NO LONGER BE REQUIRED SINCE NEW PROC IN DEM::
proc CDEM::write::writeConditions { wall_properties } {
    foreach group [DEM::write::GetWallsGroups] {
        set mid [dict get $wall_properties $group]
        if {$::Model::SpatialDimension eq "2D"} {
            set rigid_type "RigidEdge3D2N"
            set format [write::GetFormatDict $group $mid 2]
        } else {
            set rigid_type "RigidFace3D3N"
            set format [write::GetFormatDict $group $mid 3]
        }
        write::WriteString "Begin Conditions $rigid_type // GUI DEM-FEM-Wall group identifier: $group"
        GiD_WriteCalculationFile connectivities $format
        write::WriteString "End Conditions"
        write::WriteString ""
    }
}