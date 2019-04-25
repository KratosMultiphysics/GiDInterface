namespace eval Stent::xml {
     variable dir
}

proc Stent::xml::Init { } {
    variable dir
    Model::InitVariables dir $Stent::dir
    
    # Import our elements
    Model::ForgetElements
    Model::getElements Elements.xml

    spdAux::processIncludes
}

proc Stent::xml::getUniqueName {name} {
    return ST$name
}


proc Stent::xml::CustomTree { args } {
    spdAux::processIncludes
    Structural::xml::CustomTree {*}$args
}


proc Structural::xml::ProcCheckGeometryStructural {domNode args} {
    set ret "line"
    return $ret
}

Stent::xml::Init
