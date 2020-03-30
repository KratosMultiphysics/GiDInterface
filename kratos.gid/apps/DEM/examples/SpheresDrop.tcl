
proc ::DEM::examples::SpheresDrop {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to discard your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    DrawGeometrySpheresDrop
    AssignToTreeSpheresDrop
    AssignMeshSizeSpheresDrop

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc ::DEM::examples::DrawGeometrySpheresDrop { } {
    Kratos::ResetModel

    # Draw floor surface
    GiD_Process Mescape Geometry Create Object Rectangle -5 -5 0 5 5 0 escape
    # Draw inlet surface
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 5 2 2 5 escape
    # Draw the cluster inlet
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 6 2 2 6 escape
    # Draw the volume meshed with spheres
    GiD_Process Mescape Geometry Create Object Sphere 0 0 2 1 escape escape

    # Group creation
    GiD_Groups create "Floor"
    GiD_Groups create "Inlet"
    GiD_Groups create "ClusterInlet"
    GiD_Groups create "Body"

    # Group assignation
    GiD_EntitiesGroups assign "Floor" surfaces 1
    GiD_EntitiesGroups assign "Inlet" -also_lower_entities surfaces 2
    GiD_EntitiesGroups assign "ClusterInlet" -also_lower_entities surfaces 3
    GiD_EntitiesGroups assign "Body" -also_lower_entities volumes 1
}

proc ::DEM::examples::AssignToTreeSpheresDrop { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e6 PARTICLE_MATERIAL 2 ]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEM-DefaultMaterial' \]"]
    spdAux::SetValuesOnBaseNode $material_node $props

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Body]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    set DEMConditions [spdAux::getRoute "DEMConditions"]
    # DEM FEM Walls
    set walls "$DEMConditions/condition\[@n='DEM-FEM-Wall'\]"
    set wallsNode [customlib::AddConditionGroupOnXPath $walls Floor]
    $wallsNode setAttribute ov surface
    
    # Inlet
    set DEMInlet "$DEMConditions/condition\[@n='Inlet'\]"
    set inletNode [customlib::AddConditionGroupOnXPath $DEMInlet "Inlet"]
    $inletNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial" ParticleDiameter 0.13 InVelocityModulus 2.3 InDirectionVector "0.0,0.0,-1.0"]
    spdAux::SetValuesOnBaseNode $inletNode $props


    # ClusterInlet
    set DEMClusterInlet "$DEMConditions/condition\[@n='Inlet'\]"
    set inletNode [customlib::AddConditionGroupOnXPath $DEMClusterInlet "ClusterInlet"]
    $inletNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial" InletElementType "Cluster3D" ClusterType "Rock1Cluster3D" ParticleDiameter 0.13 InVelocityModulus 2.3 InDirectionVector "0.0,0.0,1.0"]

    spdAux::SetValuesOnBaseNode $inletNode $props

    # DEM custom submodelpart
    set custom_dem "$DEMConditions/condition\[@n='DEM-CustomSmp'\]"
    set customNode [customlib::AddConditionGroupOnXPath $custom_dem Body]
    $customNode setAttribute ov volume

    # General data
    # Time parameters
    set change_list [list EndTime 5 DeltaTime 1e-5 NeighbourSearchFrequency 50]
    set xpath [spdAux::getRoute DEMTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $change_list

    spdAux::RequestRefresh
}

proc DEM::examples::AssignMeshSizeSpheresDrop { } {
    GiD_Process Mescape Meshing AssignSizes Volumes 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 0.2 1:end escape escape escape
}


proc DEM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}