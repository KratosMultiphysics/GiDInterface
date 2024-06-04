namespace eval ::FreeSurface::write {
    namespace path ::FreeSurface::write
    Kratos::AddNamespace [namespace current]

    variable writeAttributes
}

proc ::FreeSurface::write::Init { } {
    ::Fluid::write::Init
    # Fluid has implemented the geometry mode, but we do not use it yet in inherited apps
    ::Fluid::write::SetAttribute write_mdpa_mode [::FreeSurface::GetWriteProperty write_mdpa_mode]
}

# Events
proc ::FreeSurface::write::writeModelPartEvent { } {
    ::Fluid::write::writeModelPartEvent
}

proc ::FreeSurface::write::writeCustomFilesEvent { } {
    # Materials
    #FreeSurface::write::WriteMaterialsFile True
    #write::SetConfigurationAttribute main_launch_file [ConvectionDiffusion::write::GetAttribute main_launch_file]
}


proc ::FreeSurface::write::GetModelPartName { } {
    return [Fluid::write::getFluidModelPartFilename]
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
