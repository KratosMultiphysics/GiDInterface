namespace eval Chimera::xml {
    # Namespace variables declaration
    variable dir
}

proc Chimera::xml::Init { } {
    # Namespace variables inicialization
    Model::InitVariables dir $Chimera::dir

    spdAux::processIncludes
}

proc Chimera::xml::getUniqueName {name} {
    return [Fluid::xml::getUniqueName $name]
}

proc Chimera::xml::CustomTree { args } {
    spdAux::processIncludes
    Fluid::xml::CustomTree {*}$args
    
    set root [customlib::GetBaseRoot]
    # Change the app name
    [$root selectNodes "container\[@n = 'Fluid'\]"] setAttribute pn "Chimera"
}
proc Chimera::xml::UpdateParts {domNode args} {
    Fluid::xml::UpdateParts $domNode {*}$args
}

Chimera::xml::Init
