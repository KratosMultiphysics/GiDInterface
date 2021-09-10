namespace eval ::Stent::xml {
    namespace path ::Stent
}

proc Stent::xml::Init { } {
    Model::InitVariables dir $::Stent::dir
    
    # Import our elements
    Model::ForgetElements
    Model::getElements Elements.xml

    spdAux::processIncludes
}

proc Stent::xml::getUniqueName {name} {
    return [::Stent::GetAttribute prefix]$name
}


proc Stent::xml::CustomTree { args } {
    spdAux::processIncludes
    Structural::xml::CustomTree {*}$args
}

proc Structural::xml::ProcCheckGeometryStructural {domNode args} {
    set ret "line"
    return $ret
}

proc Stent::xml::UpdateParts {domNode args} {
    Structural::xml::UpdateParts $domNode {*}$args
}

