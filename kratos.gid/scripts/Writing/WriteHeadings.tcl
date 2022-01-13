
proc write::writeModelPartData { } {
    # Write the model part data
    set s [mdpaIndent]
    WriteString "${s}Begin ModelPartData"
    WriteString "${s}//  VARIABLE_NAME value"
    WriteString "${s}End ModelPartData"
    WriteString ""
}

proc write::writeTables { } {
    # Write the model part data
    set s [mdpaIndent]
    WriteString "${s}Begin Table"
    WriteString "${s}Table content"
    WriteString "${s}End Table"
    WriteString ""
}
