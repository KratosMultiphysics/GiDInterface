namespace eval ::PfemMelting::write {
    variable writeAttributes
    variable inletProperties
    variable last_property_id
    variable delete_previous_mdpa
}

proc ::PfemMelting::write::Init { } {
    Buoyancy::write::Init
    SetAttribute main_script_file "PfemMeltingAnalysisLauncher.py"
}

# Events
proc PfemMelting::write::writeModelPartEvent { } {
    Buoyancy::write::writeModelPartEvent
}

proc PfemMelting::write::writeCustomFilesEvent { } {
    Buoyancy::write::writeCustomFilesEvent
}

# Attributes block
proc PfemMelting::write::GetAttribute {att} {
    return [Buoyancy::write::GetAttribute $att]
}

proc PfemMelting::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc PfemMelting::write::AddAttributes {configuration} {
    Buoyancy::write::AddAttributes $configuration
}

proc PfemMelting::write::AddValidApps {appid} {
    Buoyancy::write::AddAttribute validApps $appid
}

PfemMelting::write::Init