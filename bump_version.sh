#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new_version>"
    exit 1
fi

new_version="$1"

for yaml_file in  `find -name "main.yml"`; do 

    if [ ! -f "$yaml_file" ]; then
        echo "The file $yaml_file does not exist."
        exit 1
    fi
    
    sed -i "s/\(ROLE_VERSION:\s*\).*/\1'$new_version'/" "$yaml_file"
done

echo "The version of the ansible jobs, have been updated to:  $new_version."

