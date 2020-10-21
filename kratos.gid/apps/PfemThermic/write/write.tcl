namespace eval ::PfemThermic::write {
}

proc ::PfemThermic::write::Init { } {    
    
    SetAttribute main_script_file "MainKratos.py"
}

# Events
proc PfemThermic::write::writeModelPartEvent { } {

    PfemFluid::write::Init
    PfemFluid::write::writeModelPartEvent

    ConvectionDiffusion::write::Init
    set ConvectionDiffusion::write::delete_previous_mdpa 0
    ConvectionDiffusion::write::writeModelPartEvent
}

proc PfemThermic::write::writeCustomFilesEvent { } {
    SetAttribute main_script_file "MainKratos.py"
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
}

proc PfemThermic::write::WriteMaterialsFile { } {
    
}

proc PfemThermic::write::SetAttribute {att val} {
    ConvectionDiffusion::write::SetAttribute $att $val
}

proc PfemThermic::write::GetAttribute {att} {
    return [ConvectionDiffusion::write::GetAttribute $att]
}

proc PfemThermic::write::GetAttributes {} {
    return [ConvectionDiffusion::write::GetAttributes]
}

proc PfemThermic::write::AddAttributes {configuration} {
    ConvectionDiffusion::write::AddAttributes $configuration
}

proc PfemThermic::write::AddValidApps {appid} {
    ConvectionDiffusion::write::AddAttribute validApps $appid
}

PfemThermic::write::Init