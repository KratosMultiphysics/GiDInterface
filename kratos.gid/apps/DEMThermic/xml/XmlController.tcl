namespace eval DEMThermic::xml {
    # Namespace variables declaration
    variable dir
}

proc DEMThermic::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $DEMThermic::dir
	
	DEM::xml::Init
	
	Model::ForgetConditions
    Model::getConditions "../../DEM/xml/Conditions.xml"
	
	Model::ForgetMaterials
	Model::getMaterials "../../DEMThermic/xml/Materials.xml"
}

proc DEMThermic::xml::getUniqueName {name} {
    return ${::DEMThermic::prefix}${name}
}

proc DEMThermic::xml::CustomTree { args } {
    DEM::xml::CustomTree
}

proc DEMThermic::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames DEM ${::DEMThermic::prefix}
    }
}

DEMThermic::xml::Init