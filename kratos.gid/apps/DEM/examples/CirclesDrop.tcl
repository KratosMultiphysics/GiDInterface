namespace eval ::DEM::examples::CirclesDrop {

}
proc ::DEM::examples::CirclesDrop::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to discard your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    DrawGeometry
    AssignToTree
    AssignMeshSize

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame

}

proc ::DEM::examples::CirclesDrop::DrawGeometry { } {
    Kratos::ResetModel

    GiD_Groups create "Box"
    GiD_Groups create "Sand"
    GiD_Groups create "LowPart"

    GiD_Process Mescape Geometry Create Line -10 10 0 -10 0 0 escape escape
    GiD_Process Mescape Geometry Create Line -9.75 0 0 9.75 0 0 escape escape
    GiD_Process Mescape Geometry Create Line 10 0 0 10 10 0 escape escape
    GiD_EntitiesGroups assign "Box" lines 1
    GiD_EntitiesGroups assign "Box" lines 2
    GiD_EntitiesGroups assign "Box" lines 3

    GiD_Process Mescape Geometry Create Object Rectangle -8 1 0 8 4 0 escape
    GiD_EntitiesGroups assign "Sand" surfaces 1

    GiD_Process Mescape Geometry Create Object Rectangle -5 5 0 5 10 0 escape
    GiD_EntitiesGroups assign "LowPart" surfaces 2

}


proc ::DEM::examples::CirclesDrop::AssignToTree { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e7 ]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEM-DefaultMaterial' \]"]
    spdAux::SetValuesOnBaseNode $material_node $props

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts LowPart]
    $DEMPartsNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Sand]
    $DEMPartsNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    # DEM FEM Walls
    set DEMConditions [spdAux::getRoute "DEMConditions"]
    set box "$DEMConditions/condition\[@n='DEM-FEM-Wall2D'\]"
    set wallsNode [customlib::AddConditionGroupOnXPath $box Box]
    $wallsNode setAttribute ov line

    # General data
    # Time parameters
    set change_list [list EndTime 5 DeltaTime 5e-5 NeighbourSearchFrequency 50]
    set xpath [spdAux::getRoute DEMTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $change_list

    spdAux::RequestRefresh
}

proc ::DEM::examples::CirclesDrop::AssignMeshSize { } {
    GiD_Process Mescape Meshing AssignSizes Surfaces 0.6 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 0.6 1:end escape escape escape
}
