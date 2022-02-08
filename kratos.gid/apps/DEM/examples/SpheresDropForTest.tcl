namespace eval ::DEM::examples::SpheresDropForTest {
    namespace path ::DEM::examples
    Kratos::AddNamespace [namespace current]

}

proc ::DEM::examples::SpheresDropForTest::Init {args} {
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
}

proc ::DEM::examples::SpheresDropForTest::DrawGeometry { } {
    Kratos::ResetModel

    # Draw floor surface
    GiD_Process Mescape Geometry Create Object Rectangle -5 -5 0 5 5 0 escape
    # Draw inlet surface
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 5 2 2 5 escape
    # Draw the cluster inlet
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 6 2 2 6 escape
    # Draw the volume meshed with spheres
    GiD_Process Mescape Geometry Create Object Sphere 0 0 2 1 escape escape
    GiD_Process Mescape Geometry Create Object Sphere -3 -2 2 1 escape escape

    # Group creation
    GiD_Groups create "Floor"
    # GiD_Groups create "Inlet"
    GiD_Groups create "Top"
    #GiD_Groups create "ClusterInlet"
    GiD_Groups create "Object_1"
    GiD_Groups create "Object_2"

    # Group assignation
    GiD_EntitiesGroups assign "Floor" surfaces 1
    GiD_EntitiesGroups assign "Top" surfaces 2
    #GiD_EntitiesGroups assign "ClusterInlet" surfaces 3
    GiD_EntitiesGroups assign "Object_1" volumes 1
    GiD_EntitiesGroups assign "Object_2" volumes 2
}

proc ::DEM::examples::SpheresDropForTest::AssignToTree { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e6]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEM-DefaultMaterial' \]"]
    spdAux::SetValuesOnBaseNode $material_node $props

    ####### DParts
    set DEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_DEM'\]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Object_1]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    set DEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_DEM'\]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Object_2]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props


    # BC over particles
    set object_BC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='DEMVelocity']}
    #Velocity over walls is the name on the tree (pn)
    set object_BCNode [customlib::AddConditionGroupOnXPath $object_BC Object_1]
    $object_BCNode setAttribute ov surface
    set props [list Constraints true,true,true selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $object_BCNode $props


    ###### WallParts
    set FEMParts_floor [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_FEM'\]
    set FEMParts_floorNode [customlib::AddConditionGroupOnXPath $FEMParts_floor Floor]
    $FEMParts_floorNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $FEMParts_floorNode $props

    # BC over floor
    set FloorBC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='FEMVelocity']}
    #Velocity over walls is the name on the tree (pn)
    set FloorBCNode [customlib::AddConditionGroupOnXPath $FloorBC Floor]
    $FloorBCNode setAttribute ov surface
    set props [list selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $FloorBCNode $props


    set FEMParts_top [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_FEM'\]
    set FEMParts_topNode [customlib::AddConditionGroupOnXPath $FEMParts_top Top]
    $FEMParts_topNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $FEMParts_topNode $props

    # BC over top
    set topBC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='FEMVelocity']}
    set topBCNode [customlib::AddConditionGroupOnXPath $topBC Top]
    $topBCNode setAttribute ov surface
    set props [list Constraints false,true,true selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 2.0 selector_component_Z ByValue value_component_Z 2.0 Interval Total]
    spdAux::SetValuesOnBaseNode $topBCNode $props




    # # InletPart  - No inlets de moment
    # set FEMParts_inlet [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_Inlet-FEM'\]
    # set FEMParts_inletNode [customlib::AddConditionGroupOnXPath $FEMParts_inlet Inlet]
    # $FEMParts_inletNode setAttribute ov surface
    # set props [list Material "DEM-DefaultMaterial"]
    # spdAux::SetValuesOnBaseNode $FEMParts_inletNode $props

    # BC over Inlet
    # set InletBC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='FEMVelocity']}
    # #Velocity over walls is the name on the tree (pn)
    # set InletBCNode [customlib::AddConditionGroupOnXPath $InletBC Inlet]
    # $InletBCNode setAttribute ov surface
    # set props [list selector_component_X ByValue value_component_X 2.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    # spdAux::SetValuesOnBaseNode $InletBCNode $props

    # # Inlet
    # set InletVars {container[@n='DEM']/container[@n='Injectors']/condition[@n='DEMInlet']}
    # set InletVarsNode [customlib::AddConditionGroupOnXPath $InletVars Inlet]
    # $InletVarsNode setAttribute ov surface
    # set props [list Material "DEM-DefaultMaterial" ParticleDiameter 0.13 InVelocityModulus 2.3 InDirectionVector "0.0,0.0,-1.0"]
    # spdAux::SetValuesOnBaseNode $InletVarsNode $props



    # # ClusterInlet
    # set DEMClusterInlet "$DEMConditions/condition\[@n='Inlet'\]"
    # set inletNode [customlib::AddConditionGroupOnXPath $DEMClusterInlet "ClusterInlet"]
    # $inletNode setAttribute ov surface
    # set props [list Material "DEM-DefaultMaterial" InletElementType "Cluster3D" ClusterType "Rock1Cluster3D" ParticleDiameter 0.13 InVelocityModulus 2.3 InDirectionVector "0.0,0.0,1.0"]

    # spdAux::SetValuesOnBaseNode $inletNode $props

    # # DEM custom submodelpart
    # set custom_dem "$DEMConditions/condition\[@n='DEM-CustomSmp'\]"
    # set customNode [customlib::AddConditionGroupOnXPath $custom_dem Object_1]
    # $customNode setAttribute ov volume

    # # General data
    # # Time parameters
    # set change_list [list EndTime 5 DeltaTime 1e-5 NeighbourSearchFrequency 50]
    # set xpath [spdAux::getRoute DEMTimeParameters]
    # spdAux::SetValuesOnBasePath $xpath $change_list

    spdAux::RequestRefresh
}

proc ::DEM::examples::SpheresDropForTest::AssignMeshSize { } {
    GiD_Process Mescape Meshing ElemType Sphere Volumes 1 escape
    GiD_Process Mescape Meshing AssignSizes Volumes 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 0.2 1:end escape escape escape
}

