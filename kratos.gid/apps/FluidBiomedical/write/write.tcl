namespace eval ::FluidBiomedical::write {
    namespace path ::FluidBiomedical::write
    Kratos::AddNamespace [namespace current]

    variable writeAttributes
}

proc ::FluidBiomedical::write::Init { } {
    ::Fluid::write::Init
    # Fluid has implemented the geometry mode, but we do not use it yet in inherited apps
    ::Fluid::write::SetAttribute write_mdpa_mode [::FluidBiomedical::GetWriteProperty write_mdpa_mode]
}

# Events
proc ::FluidBiomedical::write::writeModelPartEvent { } {
    ::Fluid::write::writeModelPartEvent
}

proc ::FluidBiomedical::write::writeCustomFilesEvent { } {
    # Materials
    #FluidBiomedical::write::WriteMaterialsFile True
    #write::SetConfigurationAttribute main_launch_file [ConvectionDiffusion::write::GetAttribute main_launch_file]
}


proc ::FluidBiomedical::write::GetModelPartName { } {
    return [Fluid::write::getFluidModelPartFilename]
}

proc ::FluidBiomedical::write::GetAttribute {att} {
    return [Fluid::write::GetAttribute $att]
}

proc ::FluidBiomedical::write::GetAttributes {} {
    return [Fluid::write::GetAttributes]
}

proc ::FluidBiomedical::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::FluidBiomedical::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}
