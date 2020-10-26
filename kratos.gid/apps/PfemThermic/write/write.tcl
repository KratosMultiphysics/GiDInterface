namespace eval ::PfemThermic::write {
    
}

proc ::PfemThermic::write::Init { } {
    
}

# MDPA event
proc PfemThermic::write::writeModelPartEvent { } {
    PfemFluid::write::Init
    PfemFluid::write::writeModelPartEvent
}

# Custom files event
proc PfemThermic::write::writeCustomFilesEvent { } {
	PfemFluid::write::writePropertiesJsonFile "PFEMThermicMaterials.json" True [PfemFluid::write::GetAttribute model_part_name]
    write::CopyFileIntoModel [file join "python" "MainKratos.py"]
}

PfemThermic::write::Init