
proc ::FluidDEM::examples::SpheresDrop {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    DrawGeometry
    AssignToTree
    AssignMeshSize

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc ::FluidDEM::examples::DrawGeometry { } {
    Kratos::ResetModel

    GiD_Process Mescape Geometry Create Object Rectangle -5 -5 0 5 5 0 escape
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 5 2 2 5 escape
    GiD_Process Mescape Geometry Create Object Rectangle -5 -5 10 5 5 10 escape
    GiD_Process Mescape Geometry Create Object Sphere 0 0 2 1 escape escape

    GiD_Process Mescape Geometry Create Object Cylinder 0.0 0.0 0.0 0.0 0.0 1.0 1 10 escape escape

    GiD_Groups create "Floor"
    GiD_Groups create "Inlet"
    GiD_Groups create "Spheres"
    GiD_Groups create "FluidInlet"
    GiD_Groups create "FluidOutlet"

    GiD_Layers create "Floor"
    GiD_Layers create "Inlet"
    GiD_Layers create "Spheres"
    GiD_Layers create "FluidInlet"
    GiD_Layers create "FluidOutlet"

    GiD_EntitiesGroups assign "Floor" surfaces 1
    GiD_EntitiesGroups assign "Inlet" surfaces 2
    GiD_EntitiesGroups assign "Spheres" volumes 1

    GiD_EntitiesGroups assign "FluidInlet" surfaces 3
    GiD_EntitiesGroups assign "FluidOutlet" surfaces 1


    GiD_EntitiesLayers assign "Floor" -also_lower_entities surfaces 1
    GiD_EntitiesLayers assign "Inlet" -also_lower_entities surfaces 2
    GiD_EntitiesLayers assign "Spheres" -also_lower_entities volumes 1

    GiD_EntitiesLayers assign "FluidInlet" -also_lower_entities surfaces 3
    GiD_EntitiesLayers assign "FluidOutlet" -also_lower_entities surfaces 2


}

proc ::FluidDEM::examples::AssignToTree { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e6 PARTICLE_MATERIAL 2 ]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEM-DefaultMaterial' \]"]
    spdAux::SetValuesOnBaseNode $material_node $props

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Spheres]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    # DEM FEM Walls
    set DEMConditions [spdAux::getRoute "DEMConditions"]
    set walls "$DEMConditions/condition\[@n='DEM-FEM-Wall'\]"
    set wallsNode [customlib::AddConditionGroupOnXPath $walls Floor]
    $wallsNode setAttribute ov surface

    # Inlet
    set DEMInlet "$DEMConditions/condition\[@n='Inlet'\]"
    set inlets [list Total 2]
    ErasePreviousIntervals
    foreach {interval_name modulus} $inlets {
        GiD_Groups create "Inlet//$interval_name"
        GiD_Groups edit state "Inlet//$interval_name" hidden
        spdAux::AddIntervalGroup Inlet "Inlet//$interval_name"
        set inletNode [customlib::AddConditionGroupOnXPath $DEMInlet "Inlet//$interval_name"]
        $inletNode setAttribute ov surface
        set props [list Material "DEM-DefaultMaterial" ParticleDiameter 0.1 VelocityModulus $modulus Interval $interval_name DirectionVector "0.0,0.0,-1.0"]
        spdAux::SetValuesOnBaseNode $inletNode $props
    }

    # General data
    # Time parameters
    set change_list [list EndTime 20 DeltaTime 1e-5 NeighbourSearchFrequency 20]
    set xpath [spdAux::getRoute DEMTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $change_list

    # Bounding box
    set change_list [list UseBB true MinZ -1.0]
    set xpath [spdAux::getRoute Boundingbox]
    spdAux::SetValuesOnBasePath $xpath $change_list

    spdAux::RequestRefresh
}

proc FluidDEM::examples::AssignMeshSize { } {
    GiD_Process Mescape Meshing AssignSizes Volumes 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 0.2 1:end escape escape escape
}


proc FluidDEM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}