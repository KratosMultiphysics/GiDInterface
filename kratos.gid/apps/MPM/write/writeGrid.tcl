proc MPM::write::WriteGridMDPA { } {
    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates
    set list_of_groups [concat [MPM::write::GetPartsGroups grid] [MPM::write::GetConditionsGroups] [MPM::write::GetNodalConditionsGroups]]
    write::writeNodalCoordinatesOnGroups $list_of_groups

    # Grid element connectivities
    writeGridConnectivities

    # Write conditions
    writeConditions

    # Write Submodelparts
    writeSubmodelparts grid
}