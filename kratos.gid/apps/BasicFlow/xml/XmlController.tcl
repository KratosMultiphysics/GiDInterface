namespace eval ::BasicFlow::xml {
    namespace path ::BasicFlow
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
    variable dir
}

proc ::BasicFlow::xml::Init { } {
    # Namespace variables inicialization
    Model::InitVariables dir $::BasicFlow::dir
}

proc ::BasicFlow::xml::getUniqueName {name} {
    return [::BasicFlow::GetAttribute prefix]${name}
}

proc ::BasicFlow::xml::CustomTree { args } {
    set root [customlib::GetBaseRoot]

    
}
