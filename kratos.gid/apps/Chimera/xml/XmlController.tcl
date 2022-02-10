namespace eval Chimera::xml {
    namespace path ::Chimera
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
    variable dir
}

proc Chimera::xml::Init { } {
    # Namespace variables inicialization
    Model::InitVariables dir $Chimera::dir

    Model::getConditions Conditions.xml
    Model::getElements Elements.xml
    spdAux::processIncludes
}

proc Chimera::xml::getUniqueName {name} {
    return [Fluid::xml::getUniqueName $name]
}

proc Chimera::xml::CustomTree { args } {
    spdAux::processIncludes
    Fluid::xml::CustomTree {*}$args

    # Protection of submodelparts
    [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute FLBC]/condition\[@n = 'ChimeraInternalBoundary2D'\]"] setAttribute print_smp 0
    [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute FLBC]/condition\[@n = 'ChimeraInternalBoundary3D'\]"] setAttribute print_smp 0

    # Change the app name
    [[customlib::GetBaseRoot] selectNodes "container\[@n = 'Fluid'\]"] setAttribute pn "Chimera"

    # Add ChimeraParts.spd
    set xpath "container\[@n = 'Fluid'\]/condition\[@n='ChimeraParts'\]"
    if {[[customlib::GetBaseRoot] selectNodes $xpath] eq ""} {
        set chimera_parts [gid_groups_conds::addF "container\[@n = 'Fluid'\]" include [list n ChimeraParts active 1 path {apps/Chimera/xml/ChimeraParts.spd}]]

        customlib::UpdateDocument
        set parts [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute FLParts]]
        set new [$chimera_parts cloneNode]
        set parent [[$parts nextSibling] parent]
        $chimera_parts delete
        $parent insertBefore $new [$parts nextSibling]
    }

    customlib::ProcessIncludes $::Kratos::kratos_private(Path)
    spdAux::parseRoutes
}

proc Chimera::xml::UpdateParts {domNode args} {
    Fluid::xml::UpdateParts $domNode {*}$args
}
