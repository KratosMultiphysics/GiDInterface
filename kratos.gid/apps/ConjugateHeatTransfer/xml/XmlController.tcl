namespace eval ::ConjugateHeatTransfer::xml {
    namespace path ::ConjugateHeatTransfer
    # Namespace variables declaration
    variable dir
}

proc ConjugateHeatTransfer::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $ConjugateHeatTransfer::dir

    Model::getConditions Conditions.xml
    Model::getMaterials "../../ConvectionDiffusion/xml/Materials.xml"
    Model::getConstitutiveLaws "../../ConvectionDiffusion/xml/ConstitutiveLaws.xml"
}

proc ConjugateHeatTransfer::xml::getUniqueName {name} {
    return [::ConjugateHeatTransfer::GetAttribute prefix]${name}
}

proc ::ConjugateHeatTransfer::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
        #::Structural::xml::MultiAppEvent init
   }
}

proc ConjugateHeatTransfer::xml::CustomTree { args } {
    # Calling to the Buoyancy custom tree event
    apps::setActiveAppSoft Buoyancy
    Buoyancy::xml::CustomTree

    apps::setActiveAppSoft ConjugateHeatTransfer

    # Remove the solid thermal interface condition in the fluid domain section of the tree
    set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute Buoyancy_CNVDFFBC]/condition\[@n = 'SolidThermalInterface2D'\]"]
    if {$result_node ne "" } {$result_node delete}
    set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute Buoyancy_CNVDFFBC]/condition\[@n = 'SolidThermalInterface3D'\]"]
    if {$result_node ne "" } {$result_node delete}

    # Remove the fluid thermal interface condition in the solid domain section of the tree
    set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute CNVDFFBC]/condition\[@n = 'FluidThermalInterface2D'\]"]
    if {$result_node ne "" } {$result_node delete}
    set result_node [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute CNVDFFBC]/condition\[@n = 'FluidThermalInterface3D'\]"]
    if {$result_node ne "" } {$result_node delete}
}