namespace eval ::CDEM::write {
}

proc ::CDEM::write::Init { } {

    SetAttribute main_script_file "MainKratos.py"

}

# Events
proc CDEM::write::writeModelPartEvent { } {

    PfemFluid::write::Init
    PfemFluid::write::writeModelPartEvent

    DEM::write::Init
    set DEM::write::delete_previous_mdpa 0
    DEM::write::writeModelPartEvent

}
proc CDEM::write::writeCustomFilesEvent { } {
    SetAttribute main_script_file "MainKratos.py"
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]

}

proc CDEM::write::WriteMaterialsFile { } {

}

proc CDEM::write::SetAttribute {att val} {
    DEM::write::SetAttribute $att $val
}

proc CDEM::write::GetAttribute {att} {
    return [DEM::write::GetAttribute $att]
}

proc CDEM::write::GetAttributes {} {
    return [DEM::write::GetAttributes]
}

proc CDEM::write::AddAttributes {configuration} {
    DEM::write::AddAttributes $configuration
}

proc CDEM::write::AddValidApps {appid} {
    DEM::write::AddAttribute validApps $appid
}

CDEM::write::Init