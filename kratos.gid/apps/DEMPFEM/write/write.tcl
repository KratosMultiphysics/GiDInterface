namespace eval ::DEMPFEM::write {
}

proc ::DEMPFEM::write::Init { } {    
    
    SetAttribute main_script_file [GetAttribute main_script_file]

}

# Events
proc DEMPFEM::write::writeModelPartEvent { } {

    PfemFluid::write::Init
    PfemFluid::write::writeModelPartEvent

    DEM::write::Init
    set DEM::write::delete_previous_mdpa 0
    DEM::write::writeModelPartEvent
    
}

proc DEMPFEM::write::SetAttribute {att val} {
    DEM::write::SetAttribute $att $val
}

proc DEMPFEM::write::GetAttribute {att} {
    return [DEM::write::GetAttribute $att]
}

proc DEMPFEM::write::GetAttributes {} {
    return [DEM::write::GetAttributes]
}

proc DEMPFEM::write::AddAttributes {configuration} {
    DEM::write::AddAttributes $configuration
}

proc DEMPFEM::write::AddValidApps {appid} {
    DEM::write::AddAttribute validApps $appid
}

DEMPFEM::write::Init