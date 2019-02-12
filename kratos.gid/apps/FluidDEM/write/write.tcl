namespace eval ::FluidDEM::write {
}

proc ::FluidDEM::write::Init { } {    
    
    SetAttribute main_script_file "MainKratos.py"

}

# Events
proc FluidDEM::write::writeModelPartEvent { } {

    Fluid::write::Init
    Fluid::write::writeModelPartEvent

    DEM::write::Init
    set DEM::write::delete_previous_mdpa 0
    DEM::write::writeModelPartEvent
    
}
proc FluidDEM::write::writeCustomFilesEvent { } {
    SetAttribute main_script_file "MainKratos.py"
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    
}

proc FluidDEM::write::WriteMaterialsFile { } {
    
}

proc FluidDEM::write::SetAttribute {att val} {
    DEM::write::SetAttribute $att $val
}

proc FluidDEM::write::GetAttribute {att} {
    return [DEM::write::GetAttribute $att]
}

proc FluidDEM::write::GetAttributes {} {
    return [DEM::write::GetAttributes]
}

proc FluidDEM::write::AddAttributes {configuration} {
    DEM::write::AddAttributes $configuration
}

proc FluidDEM::write::AddValidApps {appid} {
    DEM::write::AddAttribute validApps $appid
}

FluidDEM::write::Init