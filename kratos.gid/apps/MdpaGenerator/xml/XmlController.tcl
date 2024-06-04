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

proc ::MdpaGenerator::xml::GetListOfSubModelParts { } {
    set list_of_submodelparts [write::getPartsGroupsId node]

    return $list_of_submodelparts
}

proc ::MdpaGenerator::xml::GetCurrentWriteMode { } {
    return [write::getValue SMP_write_mode]
}