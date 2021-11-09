namespace eval ::PfemMelting::write {
    namespace path ::PfemMelting
    Kratos::AddNamespace [namespace current]

    variable writeAttributes
    variable custom_body_submodelpart
}

proc ::PfemMelting::write::Init { } {
    # Buoyancy::write::Init
}

# Events
proc PfemMelting::write::writeModelPartEvent { } {
    variable custom_body_submodelpart

    Buoyancy::write::writeModelPartEvent
    set custom_body_submodelpart [::write::writeGroupSubModelPart Custom [write::getPartsGroupsId] "Nodes"]
}

proc PfemMelting::write::writeCustomFilesEvent { } {
    Buoyancy::write::writeCustomFilesEvent
    write::SetConfigurationAttribute main_launch_file [::PfemMelting::GetAttribute main_launch_file]
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
