#!/bin/bash
clear
# banner
echo
echo
echo "===============  PULL REQUEST DOWNLOADER version 0.01 ==============="
echo
echo
echo "ℹ️  Press [ENTER] for default values"
echo
echo

# prompt if which repository? hummingbot by default
read -p "Enter repository to clone (default: https://github.com/hummingbot/hummingbot) >> " github_repo

# prompt which branch should be use? development if from hummingbot by default 
read -p "Enter branch name to checkout(default: hummingbot/development) >> " github_branch

# prompt folder name to save pull request 
read -p "Enter folder name >> " github_folder


# input validation
if [$github_repo == ""]
then 
    github_repo="https://github.com/hummingbot/hummingbot"
fi

if [$github_branch == ""]
then
    github_branch="development"
fi

look_for_dir (){
    # this function look for directory first and creates the folder if available
    if [[ $github_folder == "" ]]
    then 
        x=0 ; folder_exist=false
        while [ $folder_exist == false ]
            do 
                github_folder="folder_$x"
                if [ -d "$PWD/$github_folder" ]
                then 
                    x=$((x + 1)) # increments the default folder
                else
                    folder_exist=true
                fi
        done 
    fi
}; look_for_dir

look_for_conda (){
    # this function look for Anaconda or Minconda dir
    if [ -d "$HOME/miniconda3" ]
    then
        source $HOME/miniconda3/etc/profile.d/conda.sh
    elif [ -d "$HOME/anaconda3" ]
    then 
        source $HOME/anaconda3/etc/profile.d/conda.sh
    else
        echo "No python distributior available (Anaconda3 or Miniconda3)"
    fi
}

echo 
echo "Repository: $github_repo"
echo "Checkout branch: $github_branch"
echo "Directory: $PWD/$github_folder"
read -p "Proceed? (default: yes) >> " github_next
echo

if [[ $github_next == "Yes" ]] || [[ $github_next == "y" ]] || [[ $github_next == "Y" ]] || [[ $github_next == "yes" ]] || [[ $github_next == "" ]]
then 
    # mkdir $PWD/$github_folder # create directory
    # echo -ne '##### (33%)\r'
    # sleep 1
    # echo -ne '############# (66%)\r'
    # sleep 1
    # echo -ne '####################### \r'
    # echo -ne 'Folder succesfully created (100%)'
    # echo
    # echo
    git clone -b $github_branch $github_repo $github_folder # cloning, checkou and folder creation
    cd $github_folder
    ./clean && ./install
    look_for_conda && conda activate hummingbot # && ./compile
    git log | head -5
    echo
    $SHELL
else
    echo
    echo "Exiting setup since invalid answer! try again later"
    echo 
    exit 
fi


