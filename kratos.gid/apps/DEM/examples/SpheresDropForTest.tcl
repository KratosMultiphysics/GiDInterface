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
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 5 2 2 5 escape
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 6 2 2 6 escape
    GiD_Process Mescape Geometry Create Object Rectangle -12 -2 5 -8 2 5 escape
    GiD_Process Mescape Geometry Create Object Rectangle -12 -2 6 -8 2 6 escape

    GiD_Process Mescape Geometry Create Object Rectangle -7 10 6 -2 4 6 escape


    # Draw the volumes meshed with spheres
    GiD_Process Mescape Geometry Create Object Sphere 0 0 2 1 escape escape
    GiD_Process Mescape Geometry Create Object Sphere -3 2 2 1 escape escape
    GiD_Process Mescape Geometry Create Object Sphere -7 -2 2 1 escape escape
    GiD_Process Mescape Geometry Create Object Sphere -11 -2 2 1 escape escape


    # Group creation
    GiD_Groups create "f1"
    GiD_Groups create "f2"
    GiD_Groups create "f3"
    GiD_Groups create "f4"

    GiD_Groups create "d1"
    GiD_Groups create "d2"
    GiD_Groups create "d3"
    GiD_Groups create "d4"
    GiD_Groups create "f2d"

    # Group assignation
    GiD_EntitiesGroups assign "f1" surfaces 1
    GiD_EntitiesGroups assign "f2" surfaces 2
    GiD_EntitiesGroups assign "f3" surfaces 3
    GiD_EntitiesGroups assign "f4" surfaces 4
    GiD_EntitiesGroups assign "f2d" surfaces 5

    #GiD_EntitiesGroups assign "ClusterInlet" surfaces 3
    GiD_EntitiesGroups assign "d1" volumes 1
    GiD_EntitiesGroups assign "d2" volumes 2
    GiD_EntitiesGroups assign "d3" volumes 3
    GiD_EntitiesGroups assign "d4" volumes 4
}

proc ::DEM::examples::SpheresDropForTest::AssignToTree { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e6]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEM-DefaultMaterial' \]"]
    spdAux::SetValuesOnBaseNode $material_node $props

    ####### DEM-Parts
    set DEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_DEM'\]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts d1]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    set DEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_DEM'\]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts d2]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    set DEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_DEM'\]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts d3]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props

    set DEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_DEM'\]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts d4]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props


    set DEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_DEM'\]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts f2d]
    $DEMPartsNode setAttribute ov volume
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props
    set props_extra [list AdvancedMeshingFeatures Yes AdvancedMeshingFeaturesAlgorithmType FEMtoDEM FEMtoDEM AttheNodes Diameter 0.5 ProbabilityDistribution NormalDistribution StandardDeviation 0.1]
    spdAux::SetValuesOnBaseNode $DEMPartsNode $props_extra



    ###### FEM-Parts
    set FEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_FEM'\]
    set FEMPartsNode [customlib::AddConditionGroupOnXPath $FEMParts f1]
    $FEMPartsNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $FEMPartsNode $props

    set FEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_FEM'\]
    set FEMPartsNode [customlib::AddConditionGroupOnXPath $FEMParts f2]
    $FEMPartsNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $FEMPartsNode $props

    set FEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_FEM'\]
    set FEMPartsNode [customlib::AddConditionGroupOnXPath $FEMParts f3]
    $FEMPartsNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $FEMPartsNode $props

    set FEMParts [spdAux::getRoute "DEMParts"]/condition\[@n='Parts_FEM'\]
    set FEMPartsNode [customlib::AddConditionGroupOnXPath $FEMParts f4]
    $FEMPartsNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial"]
    spdAux::SetValuesOnBaseNode $FEMPartsNode $props





    # Velocity over particles
    set object_BC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='DEMVelocity']}
    set object_BCNode [customlib::AddConditionGroupOnXPath $object_BC d1]
    $object_BCNode setAttribute ov volume
    set props [list Constraints true,true,true selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $object_BCNode $props

    # angular Velocity over particles
    set object_BC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='DEMAngular']}
    set object_BCNode [customlib::AddConditionGroupOnXPath $object_BC d2]
    $object_BCNode setAttribute ov volume
    set props [list Constraints true,true,true selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 1.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $object_BCNode $props


    # Velocity over fem
    set femBC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='FEMVelocity']}
    set femBCNode [customlib::AddConditionGroupOnXPath $femBC f1]
    $femBCNode setAttribute ov surface
    set props [list selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 1.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $femBCNode $props


    # Angular Velocity over fem
    set femBC {container[@n='DEM']/container[@n='BoundaryConditions']/condition[@n='FEMAngular']}
    set femBCNode [customlib::AddConditionGroupOnXPath $femBC f2]
    $femBCNode setAttribute ov surface
    set props [list selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 1.0 Interval Total]
    spdAux::SetValuesOnBaseNode $femBCNode $props



    # force over particles
    set object_BC {container[@n='DEM']/container[@n='Loads']/condition[@n='DEMForce']}
    set object_BCNode [customlib::AddConditionGroupOnXPath $object_BC d3]
    $object_BCNode setAttribute ov volume
    set props [list Constraints true,true,true selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 2.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $object_BCNode $props

    # torque over particles
    set object_BC {container[@n='DEM']/container[@n='Loads']/condition[@n='DEMTorque']}
    set object_BCNode [customlib::AddConditionGroupOnXPath $object_BC d4]
    $object_BCNode setAttribute ov volume
    set props [list Constraints true,true,true selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 2.0 Interval Total]
    spdAux::SetValuesOnBaseNode $object_BCNode $props


     # force over particles
    set object_BC {container[@n='DEM']/container[@n='Loads']/condition[@n='FEMForce']}
    set object_BCNode [customlib::AddConditionGroupOnXPath $object_BC f3]
    $object_BCNode setAttribute ov volume
    set props [list Constraints true,true,true selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 2.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $object_BCNode $props

    # torque over particles
    set object_BC {container[@n='DEM']/container[@n='Loads']/condition[@n='FEMTorque']}
    set object_BCNode [customlib::AddConditionGroupOnXPath $object_BC f4]
    $object_BCNode setAttribute ov volume
    set props [list Constraints true,true,true selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 2.0 Interval Total]
    spdAux::SetValuesOnBaseNode $object_BCNode $props



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
    GiD_Process Mescape Meshing AssignSizes Volumes 1 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 1 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 1 1:end escape escape escape
}