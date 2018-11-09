namespace eval ConjugateHeatTransfer::xml {
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
    return ${::ConjugateHeatTransfer::prefix}${name}
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

    
    # It seems that we do not need to call the custom tree for the Convection diffusion because
    # Buoyancy calls it, and it only modifies something in the result section, wich is moved into coupling.

    # Time intervals only in coupling 

}

ConjugateHeatTransfer::xml::Init
