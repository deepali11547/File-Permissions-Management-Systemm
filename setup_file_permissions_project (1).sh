#!/bin/bash

PROJECT_DIR="$HOME/FilePermissionsProject"

mkdir -p "$PROJECT_DIR/sample_files"
mkdir -p "$PROJECT_DIR/permission_backups"
cd "$PROJECT_DIR" || exit 1

pwd

touch permission_activity.log

touch sample_files/test.txt

touch sample_files/notice.txt

echo "This is a sample file for the File Permissions Management System." > sample_files/test.txt

echo "BCA Linux Lab Notice" > sample_files/notice.txt

cat > file_permissions_management.sh <<'EOF2'
#!/bin/bash

PROJECT_DIR="$HOME/FilePermissionsProject"
BACKUP_DIR="$PROJECT_DIR/permission_backups"
LOG_FILE="$PROJECT_DIR/permission_activity.log"

cd "$PROJECT_DIR" || exit 1

log_activity() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

pause_screen() {
    echo
    read -r -p "Press Enter to continue..." answer
}

get_existing_path() {
    read -r -p "Enter file or directory path: " selected_path
    if [[ ! -e "$selected_path" ]]; then
        echo "Path does not exist."
        return 1
    fi
    return 0
}

view_permissions() {
    echo "VIEW PERMISSIONS"
    if get_existing_path; then
        ls -ld "$selected_path"
        log_activity "Viewed permissions of $selected_path"
    fi
}

change_numeric_permissions() {
    echo "CHANGE PERMISSIONS USING NUMBERS"
    if ! get_existing_path; then return; fi
    read -r -p "Enter permission value, for example 755 or 644: " mode
    if chmod "$mode" "$selected_path"; then
        echo "Permissions changed successfully."
        ls -ld "$selected_path"
        log_activity "Changed numeric permissions of $selected_path to $mode"
    else
        echo "Permission change failed."
    fi
}

symbolic_permissions() {
    echo "CHANGE PERMISSIONS USING SYMBOLS"
    if ! get_existing_path; then return; fi
    read -r -p "Enter symbolic permission, for example u+r or g-w: " mode
    if chmod "$mode" "$selected_path"; then
        echo "Permissions changed successfully."
        ls -ld "$selected_path"
        log_activity "Applied symbolic permission $mode to $selected_path"
    else
        echo "Permission change failed."
    fi
}

add_permissions() {
    echo "ADD PERMISSIONS"
    if ! get_existing_path; then return; fi
    read -r -p "Who? Enter u, g, o or a: " who
    read -r -p "Which permissions? Enter r, w, x or a combination: " permissions
    case "$who" in
        u|g|o|a) ;;
        *) echo "Enter u, g, o or a."; return ;;
    esac
    case "$permissions" in
        *[!rwx]*|'') echo "Enter r, w, x or a combination."; return ;;
    esac
    if chmod "$who+$permissions" "$selected_path"; then
        echo "Permissions added successfully."
        ls -ld "$selected_path"
        log_activity "Added $permissions for $who on $selected_path"
    else
        echo "Could not add permissions."
    fi
}

remove_permissions() {
    echo "REMOVE PERMISSIONS"
    if ! get_existing_path; then return; fi
    read -r -p "Who? Enter u, g, o or a: " who
    read -r -p "Which permissions? Enter r, w, x or a combination: " permissions
    case "$who" in
        u|g|o|a) ;;
        *) echo "Enter u, g, o or a."; return ;;
    esac
    case "$permissions" in
        *[!rwx]*|'') echo "Enter r, w, x or a combination."; return ;;
    esac
    if chmod "$who-$permissions" "$selected_path"; then
        echo "Permissions removed successfully."
        ls -ld "$selected_path"
        log_activity "Removed $permissions for $who from $selected_path"
    else
        echo "Could not remove permissions."
    fi
}

check_file_access() {
    echo "CHECK FILE ACCESS"
    if ! get_existing_path; then return; fi
    if [[ -r "$selected_path" ]]; then echo "Read access: YES"; else echo "Read access: NO"; fi
    if [[ -w "$selected_path" ]]; then echo "Write access: YES"; else echo "Write access: NO"; fi
    if [[ -x "$selected_path" ]]; then echo "Execute/search access: YES"; else echo "Execute/search access: NO"; fi
    log_activity "Checked access for $selected_path"
}

owner_group_details() {
    echo "OWNER AND GROUP DETAILS"
    if ! get_existing_path; then return; fi
    ls -ld "$selected_path"
    echo "1. Change owner"
    echo "2. Change group"
    echo "3. Check a user's ID and groups"
    echo "4. Return"
    read -r -p "Enter choice: " subchoice
    case "$subchoice" in
        1)
            read -r -p "Enter new owner username: " new_owner
            if chown "$new_owner" "$selected_path"; then
                echo "Owner changed successfully."
                ls -ld "$selected_path"
                log_activity "Changed owner of $selected_path to $new_owner"
            else
                echo "Could not change owner. You may need administrator permission."
            fi
            ;;
        2)
            read -r -p "Enter new group name: " new_group
            if chgrp "$new_group" "$selected_path"; then
                echo "Group changed successfully."
                ls -ld "$selected_path"
                log_activity "Changed group of $selected_path to $new_group"
            else
                echo "Could not change group. You may need administrator permission."
            fi
            ;;
        3)
            read -r -p "Enter username: " user_name
            id "$user_name"
            groups "$user_name"
            log_activity "Viewed ID and groups for $user_name"
            ;;
        4) ;;
        *) echo "Invalid choice." ;;
    esac
}

list_files() {
    echo "LIST FILES"
    read -r -p "Enter directory path, or press Enter for the project folder: " directory
    directory="${directory:-.}"
    if [[ -d "$directory" ]]; then
        ls -la "$directory"
        log_activity "Listed files in $directory"
    else
        echo "Directory does not exist."
    fi
}

search_files() {
    echo "SEARCH FILE NAMES"
    read -r -p "Enter directory path, or press Enter for the project folder: " directory
    directory="${directory:-.}"
    if [[ ! -d "$directory" ]]; then
        echo "Directory does not exist."
        return
    fi
    read -r -p "Enter part of the file name to search for: " search_text
    if [[ -z "$search_text" ]]; then
        echo "Enter a search word."
        return
    fi
    ls -1 "$directory" | grep -i "$search_text"
    log_activity "Searched file names in $directory for $search_text"
}

backup_permissions() {
    echo "BACKUP FILE AND PERMISSIONS"
    if ! get_existing_path; then return; fi
    if [[ ! -f "$selected_path" ]]; then
        echo "Choose a file for this backup option."
        return
    fi
    read -r -p "Enter a backup file name, for example test_backup.txt: " backup_name
    if [[ -z "$backup_name" ]]; then
        echo "Backup name cannot be empty."
        return
    fi
    if cp -p "$selected_path" "$BACKUP_DIR/$backup_name"; then
        echo "Backup created in $BACKUP_DIR/$backup_name"
        echo "The copy keeps the file's permission mode where permitted by the system."
        log_activity "Backed up $selected_path as $backup_name"
    else
        echo "Backup failed."
    fi
}

restore_permissions() {
    echo "RESTORE FILE AND PERMISSIONS"
    ls -l "$BACKUP_DIR"
    read -r -p "Enter the backup file name: " backup_name
    if [[ ! -f "$BACKUP_DIR/$backup_name" ]]; then
        echo "Backup file does not exist."
        return
    fi
    read -r -p "Enter the destination file path: " destination
    if [[ -z "$destination" ]]; then
        echo "Destination cannot be empty."
        return
    fi
    if cp -p "$BACKUP_DIR/$backup_name" "$destination"; then
        echo "File restored. The copy keeps the saved permission mode where permitted by the system."
        ls -l "$destination"
        log_activity "Restored $backup_name to $destination"
    else
        echo "Restore failed."
    fi
}

acl_management() {
    echo "ACL PERMISSION MANAGEMENT"
    if ! get_existing_path; then return; fi
    echo "1. View ACL"
    echo "2. Give a user ACL permission"
    echo "3. Remove a user's ACL permission"
    echo "4. Remove all ACL entries"
    read -r -p "Enter choice: " acl_choice
    case "$acl_choice" in
        1)
            getfacl "$selected_path"
            log_activity "Viewed ACL of $selected_path"
            ;;
        2)
            read -r -p "Enter username: " acl_user
            read -r -p "Enter permission, for example r or rw: " acl_permissions
            setfacl -m "u:$acl_user:$acl_permissions" "$selected_path"
            getfacl "$selected_path"
            log_activity "Added ACL for $acl_user on $selected_path"
            ;;
        3)
            read -r -p "Enter username: " acl_user
            setfacl -x "u:$acl_user" "$selected_path"
            getfacl "$selected_path"
            log_activity "Removed ACL for $acl_user from $selected_path"
            ;;
        4)
            setfacl -b "$selected_path"
            getfacl "$selected_path"
            log_activity "Removed all ACL entries from $selected_path"
            ;;
        *) echo "Invalid choice." ;;
    esac
}

show_activity_log() {
    echo "ACTIVITY LOG"
    cat "$LOG_FILE"
}

while true
do
    echo
    echo "=============================================="
    echo "     FILE PERMISSIONS MANAGEMENT SYSTEM"
    echo "=============================================="
    echo "1. View Permissions"
    echo "2. Change Permissions Using Numbers"
    echo "3. Change Permissions Using Symbols"
    echo "4. Add Permissions"
    echo "5. Remove Permissions"
    echo "6. Check File Access"
    echo "7. View or Change Owner and Group"
    echo "8. List Files"
    echo "9. Search File Names"
    echo "10. Backup File and Permissions"
    echo "11. Restore File and Permissions"
    echo "12. ACL Permission Management"
    echo "13. View Activity Log"
    echo "14. Exit"
    echo "=============================================="
    read -r -p "Enter your choice (1-14): " choice
    case "$choice" in
        1) view_permissions; pause_screen ;;
        2) change_numeric_permissions; pause_screen ;;
        3) symbolic_permissions; pause_screen ;;
        4) add_permissions; pause_screen ;;
        5) remove_permissions; pause_screen ;;
        6) check_file_access; pause_screen ;;
        7) owner_group_details; pause_screen ;;
        8) list_files; pause_screen ;;
        9) search_files; pause_screen ;;
        10) backup_permissions; pause_screen ;;
        11) restore_permissions; pause_screen ;;
        12) acl_management; pause_screen ;;
        13) show_activity_log; pause_screen ;;
        14)
            log_activity "Program closed"
            echo "Thank you for using the File Permissions Management System."
            exit 0
            ;;
        *)
            echo "Invalid choice. Enter a number from 1 to 14."
            pause_screen
            ;;
    esac
done
EOF2

chmod +x file_permissions_management.sh

touch permission_activity.log

echo "Project files created in:"
pwd
ls -l
ls -l sample_files

./file_permissions_management.sh
