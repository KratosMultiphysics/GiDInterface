namespace eval ::CDEM::examples::ContSpheresDrop3D {
    namespace path ::CDEM::examples
    Kratos::AddNamespace [namespace current]
}

proc ::CDEM::examples::ContSpheresDrop3D::Init {args} {
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

proc ::CDEM::examples::ContSpheresDrop3D::DrawGeometry { } {
    Kratos::ResetModel

    # Draw floor surface
    GiD_Process Mescape Geometry Create Object Rectangle -5 -5 0 5 5 0 escape
    # Draw inlet surface
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 5 2 2 5 escape
    # Draw the volume meshed with spheres
    GiD_Process Mescape Geometry Create Object Sphere 0 0 2 1 escape escape

    # Group creation
    GiD_Groups create "Floor"
    GiD_Groups create "Inlet"
    GiD_Groups create "Body"

    # Group assignation
    GiD_EntitiesGroups assign "Floor" surfaces 1
    GiD_EntitiesGroups assign "Inlet" -also_lower_entities surfaces 2
    GiD_EntitiesGroups assign "Body" -also_lower_entities volumes 1
}

proc ::CDEM::examples::ContSpheresDrop3D::AssignToTree { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e7 ]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEM-DefaultMaterial' \]"]
    spdAux::SetValuesOnBaseNode $material_node $props

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Body]
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
    set inletNode [customlib::AddConditionGroupOnXPath $DEMInlet "Inlet"]
    $inletNode setAttribute ov surface
    set props [list Material "DEM-DefaultMaterial" ParticleDiameter 0.13 InVelocityModulus 2.3 InDirectionVector "0.0,0.0,-1.0"]
    spdAux::SetValuesOnBaseNode $inletNode $props

    # DEM custom submodelpart
    set custom_dem "$DEMConditions/condition\[@n='DEM-CustomSmp'\]"
    set customNode [customlib::AddConditionGroupOnXPath $custom_dem Body]
    $customNode setAttribute ov volume
    set props [list ]
    foreach {prop val} $props {
        set propnode [$customNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property $prop"
        }
    }

    # cohesive
    set cohesive_spheres "$DEMConditions/condition\[@n='DEM-Cohesive'\]"
    set cohesivenode [customlib::AddConditionGroupOnXPath $cohesive_spheres "Body"]
    $cohesivenode setAttribute ov surface

    # General data
    # Time parameters
    set change_list [list EndTime 3 DeltaTime 1e-5 NeighbourSearchFrequency 50]
    set xpath [spdAux::getRoute DEMTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $change_list

    # Bounding box
    set change_list [list UseBB true MinZ -1.0]
    set xpath [spdAux::getRoute Boundingbox]
    spdAux::SetValuesOnBasePath $xpath $change_list

    # BondElem parameters
    set change_list [list ContactMeshOption "true"]
    set xpath [spdAux::getRoute BondElem]
    spdAux::SetValuesOnBasePath $xpath $change_list

    # AdvOptions parameters
    set change_list [list TangencyAbsoluteTolerance 0.05]
    set xpath [spdAux::getRoute AdvOptions]
    spdAux::SetValuesOnBasePath $xpath $change_list
    
    spdAux::RequestRefresh
}

proc ::CDEM::::examples::ContSpheresDrop3D::AssignMeshSize { } {
    GiD_Process Mescape Meshing AssignSizes Volumes 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 0.2 1:end escape escape escape
}
