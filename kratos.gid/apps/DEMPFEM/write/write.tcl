namespace eval ::DEMPFEM::write {
    variable writeAttributes
}

proc ::DEMPFEM::write::Init { } {    
    
}

# Events
proc DEMPFEM::write::writeModelPartEvent { } {

    PfemFluid::write::Init
    PfemFluid::write::writeModelPartEvent

    DEM::write::Init
    set DEM::write::delete_previous_mdpa 0
    DEM::write::writeModelPartEvent
    
}
proc DEMPFEM::write::writeCustomFilesEvent { } {
    
}

proc DEMPFEM::write::WriteMaterialsFile { } {
    
}

proc DEMPFEM::write::GetAttribute {att} {
    return [DEMPFEM::write::GetAttribute $att]
}

proc DEMPFEM::write::GetAttributes {} {
    return [DEMPFEM::write::GetAttributes]
}

proc DEMPFEM::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc DEMPFEM::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

DEMPFEM::write::Init