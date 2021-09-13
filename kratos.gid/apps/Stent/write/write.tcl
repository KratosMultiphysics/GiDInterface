namespace eval ::Stent::write {
    namespace path ::Stent
    Kratos::AddNamespace [namespace current]
 }

proc Stent::write::Init { } { }

# MDPA Blocks
proc Stent::write::writeModelPartEvent { } {Structural::write::writeModelPartEvent}

# Materials
proc Stent::write::WriteMaterialsFile { } {Structural::write::WriteMaterialsFile}

# Custom files
proc Stent::write::writeCustomFilesEvent { } {Structural::write::writeCustomFilesEvent}

# Project parameters
proc Stent::write::writeParametersEvent { } {Structural::write::writeParametersEvent}
