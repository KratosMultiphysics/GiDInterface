namespace eval ::CDEM::write {
    variable writeAttributes
    variable inletProperties
    variable last_property_id
    variable delete_previous_mdpa
}

proc ::CDEM::write::Init { } {
    DEM::write::Init
    SetAttribute partscont_un DEMPartsCont
}

# Events
proc CDEM::write::writeModelPartEvent { } {
    DEM::write::writeModelPartEvent
}

proc CDEM::write::writeCustomFilesEvent { } {
    DEM::write::writeCustomFilesEvent
}

# Attributes block
proc CDEM::write::GetAttribute {att} {
    return [DEM::write::GetAttribute $att]
}

proc CDEM::write::SetAttribute {att val} {
    DEM::write::SetAttribute $att $val
}

proc CDEM::write::AddAttributes {configuration} {
    DEM::write::AddAttributes $configuration
}

proc CDEM::write::AddValidApps {appid} {
    DEM::write::AddAttribute validApps $appid
}

CDEM::write::Init