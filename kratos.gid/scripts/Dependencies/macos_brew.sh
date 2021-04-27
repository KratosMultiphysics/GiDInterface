echo "Installing brew"
which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
    # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > $TMPDIR/kratosbrewinstall.sh
    cmd="\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    osascript -e "tell application \"Terminal\" to do script \"/bin/bash $TMPDIR/kratosbrewinstall.sh \""
else
    osascript -e "tell application \"Terminal\" to do script \"brew update\""
    
fi
