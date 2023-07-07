#!/bin/bash
#!/bin/zsh

clear
search_dir=("$HOME/anaconda3/" "$HOME/miniconda3/" "$HOME/opt/anaconda3/" "$HOME/opt/miniconda3/" "$HOME/anaconda/" "$HOME/miniconda/")
target_folder="hummingbot"

for search_from in "${search_dir[@]}"; do
    if [ -d "$search_from" ]; then
        # echo "$search_from folder found!"
        result=$(find "$search_from" -type d -name "$target_folder" -print -quit)
        if [ -n "$result" ]; then
            echo "Conda environment exist found in $search_from/envs/$target_folder"
            break
        else
            echo "No conda env found, please install anaconda3 or miniconda3"
        fi
    fi
        
done