namespace eval ::Structural::examples::SolidContact {
    namespace path ::Structural::examples
    Kratos::AddNamespace [namespace current]

}

proc ::Structural::examples::SolidContact::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawGeometry$::Model::SpatialDimension
    if {0} {
        AssignGroups$::Model::SpatialDimension
        AssignMeshSizes$::Model::SpatialDimension
        TreeAssignation$::Model::SpatialDimension
    }
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::Structural::examples::SolidContact::DrawGeometry2D {args} {
    GiD_Layers create Structure1
    GiD_Layers edit to_use Structure1
    GiD_Layers create Structure2
    GiD_Layers edit to_use Structure2

    # Geometry creation
    ## Points ##
    set coordinates1 [list 0 0 0 1 0 0 1 0.25 0 0 0.25 0]
    set structurePoints1 [list ]
    foreach {x y z} $coordinates1 {
        lappend structurePoints1 [GiD_Geometry create point append Structure1 $x $y $z]
    }

    set coordinates2 [list 0 0.255 0 1 0.255 0 1 0.505 0 0 0.505 0]
    set structurePoints2 [list ]
    foreach {x y z} $coordinates2 {
        lappend structurePoints2 [GiD_Geometry create point append Structure2 $x $y $z]
    }



    ## Lines ##
    # join points 1 2 3 4 in a line and 5 6 7 8 in another line
    set line1Points [lrange $structurePoints1 0 3]
    set prevpoint [lindex $line1Points 0]
    foreach point $line1Points {
        lappend structureLines1 [GiD_Geometry create line append stline Structure1 $prevpoint $point]
        set prevpoint $point
    }
    lappend structureLines1 [GiD_Geometry create line append stline Structure1 $prevpoint [lindex $line1Points 0]]

    set line2Points [lrange $structurePoints2 0 3]
    set prevpoint [lindex $line2Points 0]
    foreach point $line2Points {
        lappend structureLines2 [GiD_Geometry create line append stline Structure2 $prevpoint $point]
        set prevpoint $point
    }
    lappend structureLines2 [GiD_Geometry create line append stline Structure2 $prevpoint [lindex $line2Points 0]]

    ## Surface ##
    GiD_Layers edit to_use Structure1
    GiD_Process Mescape Geometry Create NurbsSurface {*}$structureLines1 escape escape
    GiD_Layers edit to_use Structure2
    GiD_Process Mescape Geometry Create NurbsSurface {*}$structureLines2 escape escape
}

proc ::Structural::examples::SolidContact::AssignGroups2D {args} {
    # Group creation
    GiD_Groups create Structure
    GiD_Groups create Ground
    GiD_Groups create InterfaceStructure
    
    GiD_EntitiesGroups assign Structure surfaces 1
    GiD_EntitiesGroups assign Ground lines 4
    GiD_EntitiesGroups assign InterfaceStructure lines {1 2 3}
}

proc ::Structural::examples::SolidContact::AssignMeshSizes2D {args} {
    set structure_mesh_size 5.0
    GiD_Process Mescape Meshing ElemType Quadrilateral [GiD_EntitiesGroups get Structure surfaces] escape
    GiD_Process Mescape Meshing Structured Surfaces Size {*}[GiD_EntitiesGroups get Structure surfaces] escape $structure_mesh_size {*}[GiD_EntitiesGroups get InterfaceStructure lines] escape escape escape escape
}

# <group n="Solid Auto1" ov="surface" tree_state="close">
#           <value n="Element" pn="Element" actualize_tree="1" values="SmallDisplacementElement2D,SmallDisplacementBbarElement2D,TotalLagrangianElement2D,UpdatedLagrangianElement2D" dict="[GetElements ElementType Solid]" state="normal" v="SmallDisplacementElement2D" tree_state="close"/>
#           <value n="ConstitutiveLaw" pn="Constitutive law" actualize_tree="1" values="[GetConstitutiveLaws]" dict="[GetAllConstitutiveLaws]" state="" v="LinearElasticPlaneStrain2DLaw" tree_state="close"/>
#           <value n="Material" pn="Material" editable="0" help="Choose a material from the database" values="[GetMaterialsList]" state="disabled" v="Steel" tree_state="close"/>
#           <value n="DENSITY" pn="Density" unit_magnitude="Density" help="Density" string_is="double" state="[PartParamState]" show_in_window="1" v="7850" units="kg/m^3" tree_state="close"/>
#           <value n="YOUNG_MODULUS" pn="Young Modulus" unit_magnitude="P" help="Young Modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="206.9e9" units="Pa" tree_state="close"/>
#           <value n="POISSON_RATIO" pn="Poisson Ratio" help="Poisson Ratio" string_is="double" state="[PartParamState]" show_in_window="1" v="0.29" tree_state="close"/>
#           <value n="THICKNESS" pn="Thickness" unit_magnitude="L" help="Thickness" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0" units="m"/>
#           <value n="YIELD_STRESS" pn="Yield stress" unit_magnitude="P" help="Yield stress" string_is="double" state="[PartParamState]" show_in_window="1" v="5.5e6" units="Pa"/>
#           <value n="REFERENCE_HARDENING_MODULUS" pn="Kinematic hardening modulus" help="Kinematic hardening modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0"/>
#           <value n="ISOTROPIC_HARDENING_MODULUS" pn="Isotropic hardening modulus" help="Isotropic hardening modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="0.12924"/>
#           <value n="INFINITY_HARDENING_MODULUS" pn="Saturation hardening modulus" help="Saturation hardening modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="0.0"/>
#           <value n="HARDENING_EXPONENT" pn="Hardening exponent" help="Hardening exponent" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0"/>
#           <value n="CROSS_AREA" pn="Cross area" unit_magnitude="Area" help="Cross area" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0" units="m^2"/>
#           <value n="TRUSS_PRESTRESS_PK2" pn="Prestress" unit_magnitude="P" help="Prestress" string_is="double" state="[PartParamState]" show_in_window="1" v="0.0" units="Pa"/>
#           <value n="I33" pn="Inertia 33" unit_magnitude="L^4" help="Inertia 33" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0" units="m^4"/>
#           <value n="FRACTURE_ENERGY" pn="Fracture energy" unit_magnitude="Energy/L^2" help="Fracture energy" string_is="double" state="[PartParamState]" show_in_window="1" v="100" units="J/m^2"/>
#           <value n="SOFTENING_TYPE" pn="Softening type" help="Defines the softening type (linear softening=0, exponential softening=1)" string_is="double" state="[PartParamState]" show_in_window="1" v="0"/>
#         </group>
#         <group n="Solid Auto2" ov="surface" tree_state="close">
#           <value n="Element" pn="Element" actualize_tree="1" values="SmallDisplacementElement2D,SmallDisplacementBbarElement2D,TotalLagrangianElement2D,UpdatedLagrangianElement2D" dict="[GetElements ElementType Solid]" state="normal" v="SmallDisplacementElement2D" tree_state="close"/>
#           <value n="ConstitutiveLaw" pn="Constitutive law" actualize_tree="1" values="[GetConstitutiveLaws]" dict="[GetAllConstitutiveLaws]" state="" v="LinearElasticPlaneStrain2DLaw" tree_state="close"/>
#           <value n="Material" pn="Material" editable="0" help="Choose a material from the database" values="[GetMaterialsList]" state="disabled" v="Steel" tree_state="close"/>
#           <value n="DENSITY" pn="Density" unit_magnitude="Density" help="Density" string_is="double" state="[PartParamState]" show_in_window="1" v="7850" units="kg/m^3" tree_state="close"/>
#           <value n="YOUNG_MODULUS" pn="Young Modulus" unit_magnitude="P" help="Young Modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="206.9e9" units="Pa" tree_state="close"/>
#           <value n="POISSON_RATIO" pn="Poisson Ratio" help="Poisson Ratio" string_is="double" state="[PartParamState]" show_in_window="1" v="0.29" tree_state="close"/>
#           <value n="THICKNESS" pn="Thickness" unit_magnitude="L" help="Thickness" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0" units="m"/>
#           <value n="YIELD_STRESS" pn="Yield stress" unit_magnitude="P" help="Yield stress" string_is="double" state="[PartParamState]" show_in_window="1" v="5.5e6" units="Pa"/>
#           <value n="REFERENCE_HARDENING_MODULUS" pn="Kinematic hardening modulus" help="Kinematic hardening modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0"/>
#           <value n="ISOTROPIC_HARDENING_MODULUS" pn="Isotropic hardening modulus" help="Isotropic hardening modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="0.12924"/>
#           <value n="INFINITY_HARDENING_MODULUS" pn="Saturation hardening modulus" help="Saturation hardening modulus" string_is="double" state="[PartParamState]" show_in_window="1" v="0.0"/>
#           <value n="HARDENING_EXPONENT" pn="Hardening exponent" help="Hardening exponent" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0"/>
#           <value n="CROSS_AREA" pn="Cross area" unit_magnitude="Area" help="Cross area" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0" units="m^2"/>
#           <value n="TRUSS_PRESTRESS_PK2" pn="Prestress" unit_magnitude="P" help="Prestress" string_is="double" state="[PartParamState]" show_in_window="1" v="0.0" units="Pa"/>
#           <value n="I33" pn="Inertia 33" unit_magnitude="L^4" help="Inertia 33" string_is="double" state="[PartParamState]" show_in_window="1" v="1.0" units="m^4"/>
#           <value n="FRACTURE_ENERGY" pn="Fracture energy" unit_magnitude="Energy/L^2" help="Fracture energy" string_is="double" state="[PartParamState]" show_in_window="1" v="100" units="J/m^2"/>
#           <value n="SOFTENING_TYPE" pn="Softening type" help="Defines the softening type (linear softening=0, exponential softening=1)" string_is="double" state="[PartParamState]" show_in_window="1" v="0"/>
#         </group>


proc ::Structural::examples::SolidContact::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    # Structural
    gid_groups_conds::setAttributesF {container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Quasi-static}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Solid'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure1]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStrain${nd}Law"
    set props [list Element SmallDisplacementElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 7850 YOUNG_MODULUS 206.9e9 POISSON_RATIO 0.29]
    spdAux::SetValuesOnBaseNode $structPartsNode $props
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure2]
    $structPartsNode setAttribute ov surface
    spdAux::SetValuesOnBaseNode $structPartsNode $props

    # Structural Displacement
    GiD_Groups clone Ground Total
    GiD_Groups edit parent Total Ground
    spdAux::AddIntervalGroup Ground "Ground//Total"
    GiD_Groups edit state "Ground//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "Ground//Total"]
    $structDisplacementNode setAttribute ov line
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue selector_component_Z Not Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Point load
    GiD_Groups clone InterfaceStructure Total
    GiD_Groups edit parent Total InterfaceStructure
    spdAux::AddIntervalGroup InterfaceStructure "InterfaceStructure//Total"
    GiD_Groups edit state "InterfaceStructure//Total" hidden
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='LineLoad$nd'\]"
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "InterfaceStructure//Total"]
    $LoadNode setAttribute ov line
    set props [list ByFunction No modulus 50 value_direction_X 1 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

    # Structure domain time parameters
    [$root selectNodes "[spdAux::getRoute STTimeParameters]/value\[@n = 'EndTime'\]"] setAttribute v 25.0
    [$root selectNodes "[spdAux::getRoute STTimeParameters]/container\[@n = 'TimeStep'\]/blockdata\[1\]/value\[@n = 'DeltaTime'\]"] setAttribute v 0.05
     
    spdAux::RequestRefresh
}
