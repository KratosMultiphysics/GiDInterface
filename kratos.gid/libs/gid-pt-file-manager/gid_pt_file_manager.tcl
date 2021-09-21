package provide gid_pt_file_manager 1.0

# Usage:
    # set FileSelector::callback_after_new_file "PFEM::xml::SaveModelFile"
    # set FileSelector::callback_view_file "PFEM::xml::ViewFile"
    # set FileSelector::callback_delete_file "PFEM::xml::DeleteFile"
    # FileSelector::InitFileHandler

namespace eval ::FileSelector {


    variable selected_file
    variable save_to_model
    variable w
    variable w_list
    variable files_to_model
    variable files_list
    
    variable callback_after_new_file
    variable callback_view_file
    variable callback_delete_file
}

proc ::FileSelector::Start {} {
    variable selected_file
    set selected_file ""
        
    variable w
    set w .gid.fileSelector
    variable w_list
    set w_list .gid.fileList
    
    variable files_to_model
    set files_to_model [list ]
    
    variable files_list
    set files_list [list ]
}
FileSelector::Start

# PUBLIC FUNCTIONS
proc ::FileSelector::InitFileHandler {  } {
    
    variable w_list
    catch {destroy $w_list}
    toplevel $w_list
    wm title $w_list "File handler"
    wm minsize $w_list 400 200
    wm resizable $w_list 0 0
    
    ttk::frame $w_list.frame#2 -style groove.TFrame -borderwidth 3
    ttk::frame $w_list.frame#6 -style BottomFrame.TFrame        
    ttk::frame $w_list.frame#1 -borderwidth 2 -style groove.TFrame
    label $w_list.label#1 -text [_ "File name"]
    listbox $w_list.listbox#1 \
        -height 8 \
        -width 40 \
        -xscrollcommand "$w_list.scrollbar#1 set" \
        -yscrollcommand "$w_list.scrollbar#2 set" -selectmode single
    
    ttk::scrollbar $w_list.scrollbar#2 -command [list $w_list.listbox#1 yview] -orient vertical
    ttk::scrollbar $w_list.scrollbar#1 -command [list $w_list.listbox#1 xview] -orient horizontal
    
    menu $w_list.runprocmenu
    bind $w_list.listbox#1 <1> "focus $w_list.listbox#1"
    if { [esMac] } {
        bind $w_list.listbox#1 <$::gid_central_button> "event generate $w_list.listbox#1 <1> -rootx %X -rooty %Y ; ShowRunprocMenu $w_list %X %Y"
    } else {
        bind $w_list.listbox#1 <$::gid_right_button> "event generate $w_list.listbox#1 <1> -rootx %X -rooty %Y ; ShowRunprocMenu $w_list %X %Y"
    }
    
    ttk::button $w_list.button#1 -text [_ "View file"] -command [list FileSelector::ViewFile] -style BottomFrame.TButton                  
    ttk::button $w_list.button#2 -text [_ "Delete file"] -command [list FileSelector::DeleteFile] -style BottomFrame.TButton                    
    
    ttk::button $w_list.button#4 -text [_ "Add file"] -command [list FileSelector::InitWindow] -style BottomFrame.TButton           
    
    focus $w_list.button#4
    ttk::button $w_list.button#5 -text [_ "Close"] -command [list destroy $w_list] -style BottomFrame.TButton
    
    # Geometry management
    grid $w_list.frame#2 -in $w_list.frame#1        -row 4 -column 1  -sticky nw -padx 1 -pady 1
    grid $w_list.frame#6 -in $w_list        -row 3 -column 1 -sticky ew
    grid anchor $w_list.frame#6 center
    grid $w_list.frame#1 -in $w_list        -row 1 -column 1  -sticky nesw -columnspan 2  -padx 3 -pady 3
    grid $w_list.label#1 -in $w_list.frame#1 -row 1 -column 1 -sticky w -pady 3 -padx 3
    grid $w_list.listbox#1 -in $w_list.frame#1        -row 2 -column 1  -sticky nesw
    grid $w_list.scrollbar#2 -in $w_list.frame#1        -row 2 -column 2 -sticky ns
    grid $w_list.scrollbar#1 -in $w_list.frame#1        -row 3 -column 1 -sticky ew
    grid $w_list.button#4 -in $w_list.frame#2        -row 1 -column 1 -sticky w -padx 3
    grid $w_list.button#1 -in $w_list.frame#2        -row 1 -column 2 -sticky w -padx 3
    grid $w_list.button#2 -in $w_list.frame#2        -row 1 -column 3 -sticky w -padx 3
    
    grid $w_list.button#5  -in $w_list.frame#6 -padx 3 -pady 3
    
    grid columnconfigure $w_list.frame#2 "1 2" -weight 1
    
    grid rowconfigure $w_list 1 -weight 1
    grid columnconfigure $w_list 1 -weight 1
    
    grid rowconfigure $w_list.frame#1 2 -weight 1
    grid columnconfigure $w_list.frame#1 1 -weight 1
    
    FileSelector::FillFileList
}

# what can be: current or window
proc ::FileSelector::DeleteFile { } {
    variable w_list
    variable files_list
    
    set wbase $w_list
    set w $w_list.listbox#1
    if { [$w size] == 1 } { $w sel set 0}
    set sel [$w curselection]
    if {$sel eq ""} {return ""}
    set fil [$w get $sel]
    set idx [lsearch $files_list $fil]
    set files_list [lreplace $files_list $idx $idx]
    FileSelector::FillFileList
    
    variable callback_delete_file
    $callback_delete_file $fil
}

proc ::FileSelector::ViewFile { } {
    variable w_list
    
    set wbase $w_list
    set w $w_list.listbox#1
    if { [$w size] == 1 } { $w sel set 0}
    set sel [$w curselection]
    if {$sel eq ""} {return ""}
    set fil [$w get $sel]

    variable callback_view_file
    $callback_view_file $fil
}

proc ::FileSelector::FillFileList { } {
    variable w_list
    variable files_list
    if { [GidUtils::AreWindowsDisabled] } {
        return
    }  
    if { ![winfo exists $w_list] } { 
        return 
    }
    
    $w_list.listbox#1 delete 0 end
    foreach name $files_list {
        $w_list.listbox#1 insert end $name
    }
}

proc ::FileSelector::InitWindow {} {
    set ::FileSelector::selected_file ""
    set ::FileSelector::save_to_model 0
    FileSelector::_OpenFileSelector
}

proc ::FileSelector::FinishWindow {result} {
    variable result_proc_name
    variable result_proc_args
    
    if {$result} {
        variable save_to_model
        variable selected_file
        variable files_list
        
        if {$save_to_model} {
            set selected_file [::FileSelector::_ProcessFile $selected_file]
        }
        variable callback_after_new_file
        if {$callback_after_new_file ne ""} {$callback_after_new_file $selected_file}
    } 
    catch {variable w; destroy $w}
    
    variable w_list
    
    if { ![winfo exists $w_list] } { 
        return 
    }
    FileSelector::FillFileList
    
    focus $w_list.button#4
    
}

proc ::FileSelector::CopyFilesIntoModel { dir } {
    variable files_to_model
    # variable files_list
    foreach f $files_to_model {
        # set files_list [lsearch -all -inline -not -exact $files_list $f]
        file copy -force $f $dir
        #lappend files_list [file join $dir $f]
    }
    set files_to_model [list ]
}

proc ::FileSelector::GetAllFiles { } {
    variable files_list
    return $files_list
}
proc ::FileSelector::AddFile { fileid } {
    variable files_list
    
    if {$fileid ne "" && $fileid ni $files_list} {
        lappend files_list $fileid
    }
}

proc ::FileSelector::ClearFileList { } {
    variable files_list
    set files_list [list ]
}

# PRIVATE FUNCTIONS
proc ::FileSelector::_ProcessFile {mfile} {
    variable files_to_model
    lappend files_to_model $mfile
    set selected_file [file join . [file tail $mfile] ]
    return $selected_file
}

proc ::FileSelector::_OpenFileSelector { } {
    variable w
    ::InitWindow $w [_ "Select a file"] PreFileSelectorWindowGeom FileSelector
    if { ![winfo exists $w] } return ;# windows disabled || usemorewindows == 0
    
    # Top frame
    set fr1 [ttk::frame $w.fr1 -borderwidth 10]
    
    # Label
    set lab1 [ttk::label $fr1.lab1 -text {Filename: } -justify left -anchor w ]
    grid $lab1 -row 0 -column 0 -sticky ew 
    
    # Entry
    grid [ttk::entry $fr1.ent1 -width 40 -textvariable ::FileSelector::selected_file]  -column 1 -row 0 -sticky we; # -state readonly
    
    # Button browse
    grid [ttk::button $fr1.browse -text "Browse" -command "set ::FileSelector::selected_file \[tk_getOpenFile\]" ]  -column 2 -row 0 -sticky we
    
    # Checkbutton
    set ::FileSelector::save_to_model 1
    grid [ttk::label $fr1.check -text "File will be copied into your model folder" ] -column 0 -row 1 -columnspan 3 -sticky we
    #grid [ttk::checkbutton $fr1.check -text "Save file into model?" -variable ::FileSelector::save_to_model] -column 0 -row 1 -columnspan 3 -sticky we
    
    grid $fr1 -column 0 -row 0 -sticky nw
    
    ttk::frame $w.but -style BottomFrame.TFrame   
    ttk::button $w.but.accept -text [_ "Apply"] -command "[list FileSelector::FinishWindow 1 ]"  -underline 0 -style BottomFrame.TButton   
    ttk::button $w.but.close -text [_ "Close"] -command "[list FileSelector::FinishWindow 0 ]" -underline 0 -style BottomFrame.TButton   
    
    
    grid columnconfigure $w.fr1 1 -weight 1
    
    grid $w.but.accept -row 1 -column 1 -padx 5 -pady 6
    grid $w.but.close -row 1 -column 3 -padx 5 -pady 6
    grid $w.but -row 4 -column 0  -sticky ews -columnspan 7
    if { $::tcl_version >= 8.5 } { grid anchor $w.but center }
    
    grid $w.but -row 3 -sticky ews -columnspan 7
    
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 3 -weight 1
    #
    ## Resize behavior management
    #wm minsize $w 180 200
    
    focus $w.but.accept
    bind $w <Alt-c> "$w.but.close invoke"
    bind $w <Escape> "$w.but.close invoke"
}
set FileSelector::callback_after_new_file ""
set FileSelector::callback_view_file ""
set FileSelector::callback_delete_file ""