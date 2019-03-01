namespace eval Stent::xml {
     variable dir
}

proc Stent::xml::Init { } {
    variable dir
    Model::InitVariables dir $Stent::dir
    spdAux::processIncludes
}

proc Stent::xml::getUniqueName {name} {
    return ST$name
}


proc Stent::xml::CustomTree { args } {
    spdAux::processIncludes
    Structural::xml::CustomTree {*}$args
}

Stent::xml::Init
