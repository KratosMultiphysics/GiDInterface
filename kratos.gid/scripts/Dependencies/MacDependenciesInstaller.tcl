##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################
namespace eval ::Kratos::Dependencies::Mac {
    # Variable declaration

    variable curr_win
    variable brew_path
    variable python_path
    variable llvm_path
}

proc ::Kratos::Dependencies::Mac::Init { } {
    #W "Carga los pasos"
    variable curr_win
    set curr_win ""
    variable brew_path
    set brew_path "/usr/local/bin/brew"
    variable python_path
    set python_path "/usr/local/bin/python@3.9"
    variable llvm_path
    set llvm_path "/usr/local/bin/llvm"
}


proc ::Kratos::Dependencies::Mac::StartWizard { } {
    variable kratos_private

    Kratos::LoadWizardFiles
    
    smart_wizard::Init
    smart_wizard::SetWizardNamespace "::Kratos::Dependencies::Mac"
    smart_wizard::SetWizardWindowName ".gid.dependenciesinstaller"
    smart_wizard::SetWizardImageDirectory [file join $::Kratos::kratos_private(Path) images]
    smart_wizard::LoadWizardDoc [file join $::Kratos::kratos_private(Path) scripts Dependencies MacDependenciesInstaller.wiz]
    smart_wizard::ImportWizardData

    smart_wizard::CreateWindow

}

# Brew
    proc ::Kratos::Dependencies::Mac::Brew { win } {
        variable curr_win
        set curr_win $win
        variable brew_path

        if {[file exists $brew_path]} {
            smart_wizard::SetProperty Brew status,value "Status: Installed!"
        }
        smart_wizard::AutoStep $curr_win Brew
        # smart_wizard::SetWindowSize 350 350
    }

    proc ::Kratos::Dependencies::Mac::VisitBrew {} {
        VisitWeb "https://brew.sh/"
    }

    proc ::Kratos::Dependencies::Mac::InstallBrew {} {
        variable curr_win
        variable brew_path
        if {![file exists $brew_path]} {
            smart_wizard::SetProperty Brew status,value "Check the Terminal!"
            exec [file join $::Kratos::kratos_private(Path) scripts Dependencies macos_brew.sh]
        }
        ::Kratos::Dependencies::Mac::CheckBrewMsg
        smart_wizard::AutoStep $curr_win Brew
    }
    proc ::Kratos::Dependencies::Mac::CheckBrewMsg { } {
        variable curr_win
        variable brew_path
        if {![file exists $brew_path]} {
            after 5000 {::Kratos::Dependencies::Mac::CheckBrewMsg}
        } else {
            smart_wizard::SetProperty Brew status,value "Status: Installed!"
            smart_wizard::AutoStep $curr_win Brew
        }
    }

# Python
    proc ::Kratos::Dependencies::Mac::Python { win } {
        variable curr_win
        set curr_win $win
        variable python_path

        if {[file exists $python_path]} {
            smart_wizard::SetProperty Python status,value "Status: Installed!"
        }
        smart_wizard::AutoStep $curr_win Python
    }

    proc ::Kratos::Dependencies::Mac::VisitPython { } {
        VisitWeb "https://formulae.brew.sh/formula/python@3.9"
    }

    proc ::Kratos::Dependencies::Mac::InstallPython { } {
        variable curr_win
        variable python_path
        if {![file exists $python_path]} {
            smart_wizard::SetProperty Python status,value "Check the Terminal!"
            exec [file join $::Kratos::kratos_private(Path) scripts Dependencies macos_python.sh]
        }
        ::Kratos::Dependencies::Mac::CheckPythonMsg
        smart_wizard::AutoStep $curr_win Python
    }
    proc ::Kratos::Dependencies::Mac::CheckPythonMsg { } {
        variable curr_win
        variable python_path
        if {![file exists $python_path]} {
            after 5000 {::Kratos::Dependencies::Mac::CheckPythonMsg}
        } else {
            smart_wizard::SetProperty Python status,value "Status: Installed!"
            smart_wizard::AutoStep $curr_win Python
        }
    }
    
# llvm
    proc ::Kratos::Dependencies::Mac::Llvm { win } {
        variable curr_win
        set curr_win $win
        variable llvm_path

        if {[file exists $llvm_path]} {
            smart_wizard::SetProperty Llvm status,value "Status: Installed!"
        }
        smart_wizard::AutoStep $curr_win Llvm
    }

    proc ::Kratos::Dependencies::Mac::VisitLlvm { } {
        VisitWeb "https://formulae.brew.sh/formula/llvm"
    }

    proc ::Kratos::Dependencies::Mac::InstallLlvm { } {
        variable curr_win
        variable llvm_path
        if {![file exists $llvm_path]} {
            smart_wizard::SetProperty Llvm status,value "Check the Terminal!"
            exec [file join $::Kratos::kratos_private(Path) scripts Dependencies macos_llvm.sh]
        }
        ::Kratos::Dependencies::Mac::CheckLlvmMsg
        smart_wizard::AutoStep $curr_win Llvm
    }
    proc ::Kratos::Dependencies::Mac::CheckLlvmMsg { } {
        variable curr_win
        variable llvm_path
        if {![file exists $llvm_path]} {
            after 5000 {::Kratos::Dependencies::Mac::CheckLlvmMsg}
        } else {
            smart_wizard::SetProperty Llvm status,value "Status: Installed!"
            smart_wizard::AutoStep $curr_win Llvm
        }
    }
    