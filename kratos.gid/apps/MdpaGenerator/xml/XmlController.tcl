namespace eval ::MdpaGenerator::xml {
    namespace path ::MdpaGenerator
    Kratos::AddNamespace [namespace current]
    
    # Namespace variables declaration
    variable dir
}

proc ::MdpaGenerator::xml::Init { } {
    # Namespace variables inicialization
    variable dir
    Model::InitVariables dir $::MdpaGenerator::dir
    
}
