namespace eval ::FreeSurface::write {
    namespace path ::FreeSurface::write
    Kratos::AddNamespace [namespace current]

    variable writeAttributes
}

proc ::FreeSurface::write::Init { } {
}

# Events
proc ::FreeSurface::write::writeModelPartEvent { } {

}

proc ::FreeSurface::write::writeCustomFilesEvent { } {
    # Materials
    #FreeSurface::write::WriteMaterialsFile True
    #write::SetConfigurationAttribute main_launch_file [ConvectionDiffusion::write::GetAttribute main_launch_file]
}


proc ::FreeSurface::write::GetModelPartName { } {
    return [Fluid::GetWriteProperty model_part_name]
}

proc ::FreeSurface::write::GetAttribute {att} {
    return [Fluid::write::GetAttribute $att]
}

proc ::FreeSurface::write::GetAttributes {} {
    return [Fluid::write::GetAttributes]
}

proc ::FreeSurface::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::FreeSurface::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}
