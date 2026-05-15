#!/bin/bash

# --- Configuration ---
home_catalog="$HOME"

# Asking user for the number of files to process to keep the menu readable
read -p "How many files would like to display? " head_number

# --- Functions ---

# Scans the home directory for the largest files and prepares data for the menu
show_menu() {
    # find: search for files up to 3 levels deep
    # printf: get file size in bytes and full path
    # sort -rn: sort numerically by bytes in reverse (largest first)
    mapfile -t data < <(find "$home_catalog" -maxdepth 3 -type f -printf "%s %p\n" 2>/dev/null | sort -rn | head -n $head_number) 
    if [ ${#data[@]} -eq 0 ]; then
        echo "No files to display."
        exit 0
    fi

    paths=()
    names=()

    # Processing raw data into human-readable format
    for line in "${data[@]}"; do
            size_bytes=$(echo "$line" | cut -d' ' -f1)
            full_path=$(echo "$line" | cut -d' ' -f2-)

            # numfmt: converts bytes to KiB, MiB, GiB for better UX
            size_readable=$(numfmt --to=iec --suffix=B "$size_bytes")

            paths+=("$full_path")
            names+=("$(basename "$full_path") [$size_readable]")
    done
    }

# Handles the interactive selection and file deletion
selection_mode() {
    PS3="Select file number to delete or option number for informations and exit: "
    options=("${names[@]}" "INFORMATIONS" "EXIT")

    # Using the 'select' built-in for a simple, numeric menu
    select choice in "${options[@]}"; do
        case "$choice" in
            "EXIT") exit 0 ;;
            "INFORMATIONS")
                echo "Informations about the files: "
                ls -lh "${paths[@]}" 2>/dev/null
                ;;
            "") echo "Incorrect number." ;;
            *)
                # Calculate array index from the menu selection
                index=$((REPLY-1))
                p="${paths[$index]}" 

                # Safety prompt to prevent accidental deletion
                echo "Are you sure you want to delete this file: $choice? (y/n)"
                read -r confirmation
                if [[ "$confirmation" == "y" ]]; then
                    rm -f "$p"
                    echo "Removed: $choice"

                    # Refresh the menu after file is gone
                    show_menu
                    options=("${names[@]}" "INFORMATIONS" "EXIT")
                    break
                else
                    echo "Canceled."
                fi
                ;;
        esac
    done
}

# --- Main Execution ---
show_menu
while true; do
    selection_mode
done