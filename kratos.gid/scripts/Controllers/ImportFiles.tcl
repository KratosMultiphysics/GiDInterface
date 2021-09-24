
# Handle file input
proc ::spdAux::LaunchFileWindow { } {
    # if {[GiD_Info Project Modelname] eq "UNNAMED"} {
    #     MessageBoxOk [_ "Model error"] [_ "Save your model first"] error
    #     return
    # }
    set FileSelector::callback_after_new_file "::spdAux::SaveModelFile"
    set FileSelector::callback_view_file "::spdAux::ViewFile"
    set FileSelector::callback_delete_file "::spdAux::DeleteFile"
    FileSelector::InitFileHandler
}

proc ::spdAux::ViewFile {file_id} {
    exec {*}[auto_execok start] "" [file join [GidUtils::GetDirectoryModel] $file_id]
}

proc ::spdAux::LoadModelFiles { {root "" }} {
    if {$root eq ""} {
        set root [customlib::GetBaseRoot]
        customlib::UpdateDocument
    }
    set files [$root getElementsByTagName "file"]
    if {[llength $files] > 0} {
        Kratos::LoadImportFiles
        foreach elem $files {
            FileSelector::AddFile [$elem @n]
        }
    }
}

proc ::spdAux::SaveModelFile { fileid } {
    customlib::UpdateDocument
    FileSelector::AddFile $fileid
    gid_groups_conds::addF {container[@n='files']} file [list n ${fileid}]
    customlib::UpdateDocument
    FileSelector::CopyFilesIntoModel [GidUtils::GetDirectoryModel]
}

proc ::spdAux::ProcGetFilesValues { domNode } {
    customlib::UpdateDocument
    spdAux::LoadModelFiles
    lappend listilla "- No file - (add files using File handler toolbar)"
    lappend listilla {*}[FileSelector::GetAllFiles]
    if {[get_domnode_attribute $domNode v] ni $listilla} {$domNode setAttribute v [lindex $listilla 0]}
    return [join $listilla ","]
}

proc ::spdAux::DeleteFile { fileid } {
    customlib::UpdateDocument

    set used_nodes [[customlib::GetBaseRoot] selectNodes "//value\[@type = 'file' and @v = '$fileid'\]"]
    foreach used_node $used_nodes {
        W "Warning: Deleted file $fileid was used in [[$used_node parent] @pn] > [$used_node @pn]"
    }

    set file_node [[customlib::GetBaseRoot] selectNodes "//file\[@n = '$fileid'\]"]
    if {$file_node ne ""} {$file_node delete}
    RequestRefresh
}

proc spdAux::UpdateFileField { fileid domNode} {
    if {$fileid ne ""} {
        $domNode setAttribute v $fileid
        spdAux::SaveModelFile $fileid
        RequestRefresh 
    }
}
