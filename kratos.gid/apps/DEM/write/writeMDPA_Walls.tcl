proc ::DEM::write::WriteMDPAWalls { } {
    # Headers
    write::writeModelPartData

    # Process FEM materials
    DEM::write::processRigidWallMaterials

    # Write Properties into mdpa
    #TODO: This is legacy, no Properties are being written here.
    WriteRigidWallProperties

    # Nodal coordinates (only for Walls <inefficient> )
    set fem_groups_list [list]
    foreach group_node [::DEM::write::GetFEMPartGroupNodes] {lappend fem_groups_list [$group_node @n]}

    write::writeNodalCoordinatesOnGroups $fem_groups_list
    if {$::Model::SpatialDimension ne "2D"} {
	    write::writeNodalCoordinatesOnGroups [DEM::write::GetWallsGroupsSmp]
    }

    # Nodal conditions and conditions
    writeConditions

    # SubmodelParts
    writeWallConditionMeshes

    # CustomSubmodelParts
    WriteWallCustomSmp
}

proc ::DEM::write::processRigidWallMaterials { } {
    write::processMaterials "[spdAux::getRoute [::DEM::write::GetAttribute parts_un]]/condition\[@n='Parts_FEM'\]/group"

    # It defines the associated properties of the corresponding Part (mass, inertia,..).
    variable wallsProperties
    set wallsProperties [write::getPropertiesListByConditionXPath "[spdAux::getRoute [::DEM::write::GetAttribute parts_un]]/condition\[@n='Parts_FEM'\]" 0 RigidFacePart]
}

proc ::DEM::write::WriteRigidWallProperties { } {
    # Legacy proc. Current properties are located in the Materials.json file
    write::WriteString "Begin Properties 0 // Check materials.json"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc ::DEM::write::writeConditions {  } {
    # foreach fem part
    foreach group_node [::DEM::write::GetFEMPartGroupNodes] {
        set elem [write::getValueByNode [$group_node selectNodes ".//value\[@n='Element']"] ]
        # write as condition (check element WriteAsBlock)
        write::writeGroupElementConnectivities $group_node $elem
    }

}

proc ::DEM::write::writeWallConditionMeshes { } {
    variable wallsProperties

    foreach group_node [::DEM::write::GetFEMPartGroupNodes] {
        set group [$group_node @n]
        set mid [write::AddSubmodelpart Parts_FEM $group]
        set props [DEM::write::FindPropertiesBySubmodelpart $wallsProperties $mid]
        writeWallConditionMesh Parts_FEM $group $props
    }
}

# Print the submodelpart based on the parts -> FEM
proc ::DEM::write::writeWallConditionMesh { condition group props } {

    set mid [write::AddSubmodelpart $condition $group]

    write::WriteString "Begin SubModelPart $mid // $condition - group identifier: $group"
    write::WriteString "  Begin SubModelPartData // $condition. Group name: $group"
    if {$props ne ""} {
	set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/condition\[@n = 'Parts_FEM'\]/group\[@n = '$group'\]"
	set group_node [[customlib::GetBaseRoot] selectNodes $xp1]
	write::WriteString "    RIGID_BODY_OPTION 1"

	set mass [dict get $props Material Variables MASS]
	write::WriteString "    RIGID_BODY_MASS $mass"

	lassign [dict get $props Material Variables CENTER] cX cY cZ
	if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    RIGID_BODY_CENTER_OF_ROTATION \[3\] ($cX,$cY,0.0)"
	} else {write::WriteString "    RIGID_BODY_CENTER_OF_ROTATION \[3\] ($cX,$cY,$cZ)"}

	set inertias [dict get $props Material Variables INERTIA]
	if {$::Model::SpatialDimension eq "2D"} {
	    set iX $inertias
	    write::WriteString "    RIGID_BODY_INERTIAS \[3\] (0.0,0.0,$iX)"
	} else {
	    lassign $inertias iX iY iZ
	    write::WriteString "    RIGID_BODY_INERTIAS \[3\] ($iX,$iY,$iZ)"
	}

	lassign [dict get $props Material Variables ORIENTATION] oX oY oZ
	write::WriteString "    ORIENTATION \[4\] ($oX,$oY,$oZ, 0.0)"

	write::WriteString "    IDENTIFIER [write::transformGroupName $group]"
	DEM::write::DefineFEMExtraConditions $props
    } else {W "Error - Properties empty for submodelpart $condition $group"}
    write::WriteString "  End SubModelPartData"

    write::WriteString "  Begin SubModelPartNodes"
    GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
    write::WriteString "  End SubModelPartNodes"

    write::WriteString "Begin SubModelPartConditions"
    set gdict [dict create]
    set f "%10i\n"
    set f [subst $f]
    dict set gdict $group $f
    GiD_WriteCalculationFile elements -sorted $gdict
    write::WriteString "End SubModelPartConditions"
    write::WriteString ""
    write::WriteString "End SubModelPart"
    write::WriteString ""
}

proc ::DEM::write::DefineFEMExtraConditions {props} {
    return
    set GraphPrint [dict get $props Material Variables GraphPrint]
    set GraphPrintval 0
    if {[write::isBooleanTrue $GraphPrint]} {
        set GraphPrintval 1
    }
    write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
}

proc ::DEM::write::GetFEMPartGroupNodes { } {
    return [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute [::DEM::write::GetAttribute parts_un]]/condition\[@n='Parts_FEM'\]/group"]
}

proc ::DEM::write::GetWallsGroupsSmp { } {
    set groups [list ]
    set xp2 "[spdAux::getRoute DEMCustom]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp2] {
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        if {$destination_mdpa == "FEM"} {
            set groupid [$group @n]
            lappend groups [write::GetWriteGroupName $groupid]
        }
    }
    return $groups
}

proc ::DEM::write::WriteWallCustomSmp { } {
    set condition_name "DEM-CustomSmp"
    set xp1 "[spdAux::getRoute DEMCustom]/condition\[@n = 'DEM-CustomSmp'\]/group"

    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {

        set groupid [$group @n]
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        if {$destination_mdpa == "FEM"} {
            set mid [write::AddSubmodelpart $condition_name $groupid]
            write::WriteString  "Begin SubModelPart $mid \/\/ Custom SubModelPart. Group name: $groupid"
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

