#!/bin/bash

hex_fg() { echo -ne "\033[38;2;$1;$2;$3m"; }

NC='\033[0m'
C_PRIME=$(hex_fg 187 134 252)
C_ACCENT=$(hex_fg 3 218 198)
C_WARN=$(hex_fg 255 184 108)
C_DANGER=$(hex_fg 255 85 85)
C_GOSSIP=$(hex_fg 139 233 253)

START_QUIPS=(
    "Initiating neural handshake..." 
    "Cloning target identity..." 
    "Mapping remote file-tree..."
    "Bypassing security protocols..."
    "Injecting build payload..."
    "Scanning for vulnerabilities..."
    "Establishing encrypted tunnel..."
)

END_QUIPS=(
    "The heist was a success." 
    "Loot secured." 
    "Mainframe compromised."
    "Ghosting the server logs..."
    "Neural link severed. Operation complete."
)

JOKES=(
    "Why did the developer go broke? Because he used up all his cache."
    "Hardware: The part of a computer that you can kick."
    "A SQL query walks into a bar, walks up to two tables, and asks, 'Can I join you?'"
    "There are 10 types of people in the world: those who understand binary, and those who don't."
    "Programming is 10% writing code and 90% understanding why it's not working."
    "I'd tell you a joke about UDP, but you might not get it."
    "An optimist says the glass is half full. A pessimist says it's half empty. A programmer says it's twice as large as necessary."
)

RAND_START=${START_QUIPS[$RANDOM % ${#START_QUIPS[@]}]}
RAND_END=${END_QUIPS[$RANDOM % ${#END_QUIPS[@]}]}
RAND_JOKE=${JOKES[$RANDOM % ${#JOKES[@]}]}

check_auth() {
    ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -T "git@$1" &>/dev/null
    local status=$?
    [[ $status -eq 0 || $status -eq 1 ]] && return 0 || return 1
}

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
CURRENT_DIR="$(dirname "$SCRIPT_PATH")"
TEMP_TOP="$CURRENT_DIR"

while [[ "$TEMP_TOP" != / && ! -d "$TEMP_TOP/.repo" ]]; do 
    TEMP_TOP="$(dirname "$TEMP_TOP")"
done

[ -d "$TEMP_TOP/.repo" ] && TOP="$TEMP_TOP" || { echo -e "${C_DANGER} [!] NO REPO ROOT FOUND${NC}"; exit 1; }

VAULT_FILE="$TOP/.custom_repos"
[ ! -f "$VAULT_FILE" ] && touch "$VAULT_FILE"

DEVICE_DB="$TOP/.device_manifest"

if [ ! -f "$DEVICE_DB" ] || [ ! -s "$DEVICE_DB" ]; then
    cat << 'EOF' > "$DEVICE_DB"
Pixel 7 (Panther)|panther|panther|GS201|git@github.com:Alch3myOS-Devices/device_google_pantah-kernels.git|pantah-kernels|16
Pixel 7 Pro (Cheetah)|cheetah|cheetah|GS201|git@github.com:Alch3myOS-Devices/device_google_pantah-kernels.git|pantah-kernels|16
Pixel 7a (Lynx)|lynx|lynx|GS201|git@github.com:Alch3myOS-Devices/device_google_lynx-kernels.git|lynx-kernels|16
Pixel 8 (Shiba)|shiba|shiba|ZUMA|git@github.com:Alch3myOS-Devices/device_google_shusky-kernels.git|shusky-kernels|16
Pixel 8 Pro (Husky)|husky|husky|ZUMA|git@github.com:Alch3myOS-Devices/device_google_shusky-kernels.git|shusky-kernels|16
Pixel 8a (Akita)|akita|akita|ZUMA|git@github.com:Alch3myOS-Devices/device_google_akita-kernels.git|akita-kernels|16
Pixel 9 (Tokay)|tokay|tokay|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_caimito-kernels.git|caimito-kernels|16-qpr2
Pixel 9 Pro (Caiman)|caiman|caiman|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_caimito-kernels.git|caimito-kernels|16-qpr2
Pixel 9 Pro XL (Komodo)|komodo|komodo|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_caimito-kernels.git|caimito-kernels|16-qpr2
Pixel 9a (Tegu)|tegu|tegu|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_tegu-kernels.git|tegu-kernels|16-qpr2
Pixel 10 (Frankel)|frankel|frankel|LAGUNA|git@github.com:Alch3myOS-Devices/device_google_muzel-kernels.git|muzel-kernels|16
Pixel 10 Pro (Blazer)|blazer|blazer|LAGUNA|git@github.com:Alch3myOS-Devices/device_google_muzel-kernels.git|muzel-kernels|16
Pixel 10 Pro XL (Mustard)|mustard|mustard|LAGUNA|git@github.com:Alch3myOS-Devices/device_google_muzel-kernels.git|muzel-kernels|16
EOF
fi

sync_worker() {
    local URL=$1; local DIR_REL=$2; local BRANCH=$3
    local DIR="$TOP/$DIR_REL"
    
    if [[ "$DIR_REL" == *"google-modules" || "$DIR_REL" == *"devices" || "$DIR_REL" == *"prebuilts_gki" ]]; then
        if [[ "$URL" == *"gs-6.6"* ]]; then
            DIR="$TOP/kernel/google/gs-6.6/private/$(basename "$DIR_REL")"
            DIR_REL="kernel/google/gs-6.6/private/$(basename "$DIR_REL")"
        else
            DIR="$TOP/kernel/google/gs-6.1/private/$(basename "$DIR_REL")"
            DIR_REL="kernel/google/gs-6.1/private/$(basename "$DIR_REL")"
        fi
    fi

    local ACTUAL_BRANCH="$BRANCH"

    [[ "$URL" == *"LineageOS"* ]] && ACTUAL_BRANCH="lineage-23.2"
    [[ "$URL" == *"TheMuppets"* ]] && ACTUAL_BRANCH="lineage-23.2"
    
    local REMOTE_NAME="origin"
    [[ "$URL" == *"Pyrtle93"* ]] && REMOTE_NAME="origin1"

    if [ ! -d "$DIR/.git" ]; then
        rm -rf "$DIR"
        mkdir -p "$(dirname "$DIR")"
        if git clone --single-branch -b "$ACTUAL_BRANCH" "$URL" "$DIR" --quiet &>/dev/null; then
             echo -e "   ${C_ACCENT}>> [NEW]${NC} $DIR_REL ($ACTUAL_BRANCH)"
        else
             if git clone --single-branch "$URL" "$DIR" --quiet &>/dev/null; then
                 local FALLBACK_BR=$(cd "$DIR" && git rev-parse --abbrev-ref HEAD)
                 echo -e "   ${C_WARN}>> [FALLBACK NEW]${NC} $DIR_REL ($FALLBACK_BR)${NC}"
             else
                 echo -e "   ${C_DANGER}>> [CLONE FAIL]${NC} $DIR_REL${NC}"
             fi
        fi
    else
        (
            cd "$DIR" || exit
            [ -f ".git/index.lock" ] && rm -f ".git/index.lock"
            [ -f ".git/refs/heads/$ACTUAL_BRANCH.lock" ] && rm -f ".git/refs/heads/$ACTUAL_BRANCH.lock"
            
            git reset --hard HEAD --quiet &>/dev/null
            git clean -fdX --quiet &>/dev/null
            
            if ! git remote | grep -q "^${REMOTE_NAME}$"; then
                REMOTE_NAME=$(git remote | head -n 1)
                [ -z "$REMOTE_NAME" ] && REMOTE_NAME="origin"
            fi

            local CURRENT_URL=$(git remote get-url "$REMOTE_NAME" 2>/dev/null)
            if [[ "$CURRENT_URL" != "$URL" ]]; then
                git remote set-url "$REMOTE_NAME" "$URL" &>/dev/null 
                if [ $? -ne 0 ]; then
                    git remote add "$REMOTE_NAME" "$URL" &>/dev/null
                fi
            fi
            
            if git fetch "$REMOTE_NAME" "$ACTUAL_BRANCH" --quiet &>/dev/null; then
                git checkout -B "$ACTUAL_BRANCH" --quiet &>/dev/null
                git reset --hard FETCH_HEAD --quiet
                echo -e "   ${C_ACCENT}>> [OK]${NC} $DIR_REL"
            else
                local DEFAULT_BR=$(git remote show "$REMOTE_NAME" 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)
                if [[ -n "$DEFAULT_BR" ]] && git fetch "$REMOTE_NAME" "$DEFAULT_BR" --quiet &>/dev/null; then
                    git checkout -B "$DEFAULT_BR" --quiet &>/dev/null
                    git reset --hard FETCH_HEAD --quiet
                    echo -e "   ${C_WARN}>> [RESOLVED UPSTREAM]${NC} $DIR_REL ($DEFAULT_BR)${NC}"
                else
                    echo -e "   ${C_DANGER}>> [FIX FAIL]${NC} $DIR_REL${NC}"
                fi
            fi
        )
    fi
}

clear
echo -e "${C_ACCENT}     _     _       ____ _   _ _____ __  __ __   __${NC}"
echo -e "${C_PRIME}    / \   | |     / ___| | | |___ /|  \/  |\ \ / /${NC}"
echo -e "${C_GOSSIP}   / _ \  | |    | |   | |_| | |_ \| |\/| | \ V / TS${NC}"
echo -e "${C_ACCENT}  / ___ \ | |___ | |___|  _  |___) | |  | |  | |  ${NC}"
echo -e "${C_PRIME} /_/   \_\|_____| \____|_| |_|____/|_|  |_|  |_|  ${NC}"
echo -e ""

global_options=(
    "Start Repo Syncing Process"
    "Manually clone git repos"
    "Reset to Default Template"
    "Abort"
)

while true; do
    OLD_COLUMNS=$COLUMNS
    COLUMNS=1
    
    select opt in "${global_options[@]}"; do
        COLUMNS=$OLD_COLUMNS
        case "$opt" in
            "Start Repo Syncing Process")
                break 2
                ;;
            "Manually clone git repos")
                while true; do
                    echo -e "\n${C_PRIME}=== REPOSITORY CLONE HINT ===${NC}"
                    echo -e "${C_GOSSIP}Use this to pull any standalone custom repo directly into your environment.${NC}"
                    echo -e "${C_GOSSIP}Type 'b' or 'back' at any prompt to cancel.${NC}\n"

                    echo -e "${C_ACCENT}Hint: The full Git address (e.g., git@github.com:username/repo.git)${NC}"
                    echo -ne "${C_WARN}URL: ${NC}"; read -r live_url
                    [[ "$live_url" == "b" || "$live_url" == "back" ]] && break
                    
                    echo -e "\n${C_ACCENT}Hint: Location inside staging folder (e.g., vendor/extra/tools)${NC}"
                    echo -ne "${C_WARN}Path: ${NC}"; read -r live_path
                    [[ "$live_path" == "b" || "$live_path" == "back" ]] && break
                    
                    echo -e "\n${C_ACCENT}Hint: Target branch name (e.g., 16 or 16-qpr2)${NC}"
                    echo -ne "${C_WARN}Branch: ${NC}"; read -r live_branch
                    [[ "$live_branch" == "b" || "$live_branch" == "back" ]] && break

                    if [[ -n "$live_url" && -n "$live_path" && -n "$live_branch" ]]; then
                        TARGET_DIR="$TOP/$live_path"
                        rm -rf "$TARGET_DIR"
                        mkdir -p "$(dirname "$TARGET_DIR")"
                        if git clone --single-branch -b "$live_branch" "$live_url" "$TARGET_DIR"; then
                            echo -e "${C_ACCENT}[+] Success at $live_path.${NC}"
                            echo -e "${C_ACCENT}Hint: Saving adds this permanently so it runs every time you sync.${NC}"
                            echo -ne "${C_WARN}Save to configuration vault? (y/N): ${NC}"
                            read -r save_track
                            [[ "$save_track" =~ ^[Yy]$ ]] && echo "$live_url|$live_path|$live_branch" >> "$VAULT_FILE"
                        else
                            echo -e "${C_DANGER}[!] Clone failed.${NC}"
                        fi
                    fi
                    break
                done
                break
                ;;
            "Reset to Default Template")
                echo -e "\n${C_PRIME}=== MANIFEST RESET HINT ===${NC}"
                echo -e "${C_WARN}This will clean out custom entries and force reload all Pixel 7 through 10 profiles.${NC}"
                echo -ne "${C_WARN}Are you sure? (y/n): ${NC}"
                read -r reset_confirm
                if [[ "$reset_confirm" =~ ^[Yy]$ ]]; then
                    > "$VAULT_FILE"
                    rm -f "$DEVICE_DB"
                    echo -e "${C_PRIME}Resetting to default template (v3.7)...${NC}"
                    echo -e "${C_ACCENT}[!] Done. Please re-run the script to view the updated device profiles!${NC}"
                else
                    echo -e "${C_WARN}Reset cancelled.${NC}"
                fi
                break
                ;;
            "Abort")
                exit 1
                ;;
        esac
    done
done

[ -f "$CURRENT_DIR/.build_session" ] && source "$CURRENT_DIR/.build_session"

USE_FAST_TRACK=false

if [ -n "$last_custom_name" ]; then
    clear
    echo -e "${C_PRIME}=== SESSION MEMORY ENGAGED ===${NC}"
    echo -e " ${C_ACCENT}[>>>] Found previous session target:${NC} ${C_WARN}$last_custom_name${NC}\n"
    echo -ne "${C_GOSSIP}Fast-track straight to this target chassis configuration? (Y/n): ${NC}"
    read -r quick_resp
    if [[ "$quick_resp" =~ ^[Yy]$ || -z "$quick_resp" ]]; then
        target_blueprint=$(grep "^$last_custom_name" "$DEVICE_DB")
        if [ -n "$target_blueprint" ]; then
            IFS="|" read -r D_DISPLAY D_FOLDER D_MAKEFILE FAMILY K_URL K_NAME K_BRANCH <<< "$target_blueprint"
            USE_FAST_TRACK=true
        else
            echo -e "${C_WARN}[!] Cached profile no longer exists in database layout. Falling back to menu...${NC}"
            sleep 1.5
        fi
    fi
fi

if [ "$USE_FAST_TRACK" = false ]; then
    while true; do
        clear
        echo -e "${C_PRIME}=== SELECT TARGET CHASSIS ===${NC}"
        echo -e "${C_GOSSIP}Hint: Choose your specific target platform. If your device list is missing profiles,${NC}"
        echo -e "${C_GOSSIP}exit out, run option 3 (Reset to Default Template), and re-launch the script.${NC}\n"

        device_names=()
        device_lines=()

        while IFS= read -r line || [[ -n "$line" ]]; do
            clean_check=$(echo "$line" | sed 's/[[:space:]]//g' | tr -d '\302\240')
            [[ -z "$clean_check" || "$line" =~ ^# ]] && continue
            
            device_lines+=("$line")
            IFS="|" read -r d_display d_fold d_make d_fam d_kurl d_kname d_kbranch <<< "$line"
            device_names+=("$d_display")
        done < "$DEVICE_DB"

        device_names+=("Add New Device Profile")
        device_names+=("Delete Device Profile")
        device_names+=("Back to Main Menu")
        device_names+=("Abort")

        OLD_COLUMNS=$COLUMNS
        COLUMNS=1

        select d_opt in "${device_names[@]}"; do
            COLUMNS=$OLD_COLUMNS
            if [[ "$d_opt" == "Abort" ]]; then
                exit 1
            elif [[ "$d_opt" == "Back to Main Menu" ]]; then
                exec "$SCRIPT_PATH"
            elif [[ "$d_opt" == "Delete Device Profile" ]]; then
                while true; do
                    clear
                    echo -e "${C_PRIME}=== DELETE DEVICE PROFILE ===${NC}"
                    echo -e "${C_WARN}Select a target profile to permanently remove from your database layout.${NC}\n"
                    
                    del_names=()
                    del_lines=()
                    while IFS= read -r d_line || [[ -n "$d_line" ]]; do
                        clean_del_check=$(echo "$d_line" | sed 's/[[:space:]]//g' | tr -d '\302\240')
                        [[ -z "$clean_del_check" || "$d_line" =~ ^# ]] && continue
                        
                        del_lines+=("$d_line")
                        IFS="|" read -r d_disp _ <<< "$d_line"
                        del_names+=("$d_disp")
                    done < "$DEVICE_DB"
                    
                    if [ ${#del_names[@]} -eq 0 ]; then
                        echo -e "${C_WARN}[!] No valid profiles found in the registry file to clear.${NC}"
                        sleep 2
                        break
                    fi
                    
                    del_names+=("Cancel / Abort Deletion")
                    
                    OLD_COLUMNS=$COLUMNS
                    COLUMNS=1
                    select del_opt in "${del_names[@]}"; do
                        COLUMNS=$OLD_COLUMNS
                        if [[ "$del_opt" == "Cancel / Abort Deletion" || -z "$del_opt" ]]; then
                            break 2
                        else
                            del_idx=$((REPLY-1))
                            target_del_line="${del_lines[$del_idx]}"
                            IFS="|" read -r target_disp_name _ <<< "$target_del_line"
                            
                            [ -z "$target_disp_name" ] && target_disp_name="[Blank/Corrupt Line Entry]"

                            echo -e "\n${C_DANGER}[!] WARNING: This will permanently remove $target_disp_name${NC}"
                            echo -ne "${C_WARN}Are you absolutely sure? (y/N): ${NC}"
                            read -r del_confirm
                            if [[ "$del_confirm" =~ ^[Yy]$ ]]; then
                                escaped_line=$(printf '%s\n' "$target_del_line" | sed 's/[^^$*.[\]{}()?\!|+=,-]/\\&/g')
                                sed -i "/^$escaped_line$/d" "$DEVICE_DB"
                                
                                sed -i '/^[[:space:]]*$/d' "$DEVICE_DB"
                                sed -i '/^\xCA\xA0/d' "$DEVICE_DB" 2>/dev/null || true
                                
                                echo -e "${C_ACCENT}[+] Profile removed successfully.${NC}"
                                sleep 1.5
                            else
                                echo -e "${C_WARN}[*] Deletion canceled.${NC}"
                                sleep 1
                            fi
                            break 2
                        fi
                    done
                done
                break
            elif [[ "$d_opt" == "Add New Device Profile" ]]; then
                while true; do
                    clear
                    echo -e "${C_PRIME}=== SELECT REPOSITORIES BLUEPRINT ===${NC}"
                    echo -e "${C_GOSSIP}Choose a device from the catalog to inject its full structure layout variables.${NC}"
                    echo -e "${C_GOSSIP}Type the option number or 'b' / 'back' to abort setup.${NC}\n"

                    blueprint_catalog=(
                        "Pixel 7 (Panther)|panther|panther|GS201|git@github.com:Alch3myOS-Devices/device_google_pantah-kernels.git|pantah-kernels|16"
                        "Pixel 7 Pro (Cheetah)|cheetah|cheetah|GS201|git@github.com:Alch3myOS-Devices/device_google_pantah-kernels.git|pantah-kernels|16"
                        "Pixel 7a (Lynx)|lynx|lynx|GS201|git@github.com:Alch3myOS-Devices/device_google_lynx-kernels.git|lynx-kernels|16"
                        "Pixel 8 (Shiba)|shiba|shiba|ZUMA|git@github.com:Alch3myOS-Devices/device_google_shusky-kernels.git|shusky-kernels|16"
                        "Pixel 8 Pro (Husky)|husky|husky|ZUMA|git@github.com:Alch3myOS-Devices/device_google_shusky-kernels.git|shusky-kernels|16"
                        "Pixel 8a (Akita)|akita|akita|ZUMA|git@github.com:Alch3myOS-Devices/device_google_akita-kernels.git|akita-kernels|16"
                        "Pixel 9 (Tokay)|tokay|tokay|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_caimito-kernels.git|caimito-kernels|16-qpr2"
                        "Pixel 9 Pro (Caiman)|caiman|caiman|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_caimito-kernels.git|caimito-kernels|16-qpr2"
                        "Pixel 9 Pro XL (Komodo)|komodo|komodo|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_caimito-kernels.git|caimito-kernels|16-qpr2"
                        "Pixel 9a (Tegu)|tegu|tegu|ZUMAPRO|git@codeberg.org:Pyrtle93/device_google_tegu-kernels.git|tegu-kernels|16-qpr2"
                        "Pixel 10 (Frankel)|frankel|frankel|LAGUNA|git@github.com:Alch3myOS-Devices/device_google_muzel-kernels.git|muzel-kernels|16"
                        "Pixel 10 Pro (Blazer)|blazer|blazer|LAGUNA|git@github.com:Alch3myOS-Devices/device_google_muzel-kernels.git|muzel-kernels|16"
                        "Pixel 10 Pro XL (Mustard)|mustard|mustard|LAGUNA|git@github.com:Alch3myOS-Devices/device_google_muzel-kernels.git|muzel-kernels|16"
                        "Fully Manual Construction Walkthrough"
                    )

                    blueprint_names=()
                    for bp in "${blueprint_catalog[@]}"; do
                        IFS="|" read -r bp_display _ <<< "$bp"
                        blueprint_names+=("$bp_display")
                    done

                    OLD_COLUMNS=$COLUMNS
                    COLUMNS=1
                    
                    select bp_opt in "${blueprint_names[@]}"; do
                        COLUMNS=$OLD_COLUMNS
                        
                        if [[ -z "$bp_opt" || "$REPLY" == "b" || "$REPLY" == "back" ]]; then
                            echo -e "${C_WARN}[*] Wizard aborted. Returning to main chassis stack...${NC}"
                            sleep 1.5
                            break 2
                        fi

                        if [[ "$bp_opt" == "Fully Manual Construction Walkthrough" ]]; then
                            echo -e "\n${C_PRIME}=== ADD DEVICE CONFIG WALKTHROUGH ===${NC}"
                            echo -ne "${C_WARN}Name: ${NC}"; read -r new_display
                            echo -ne "${C_WARN}Folder: ${NC}"; read -r new_folder
                            echo -ne "${C_WARN}Makefile Name: ${NC}"; read -r new_makefile
                            echo -ne "${C_WARN}Platform Family: ${NC}"; read -r new_family
                            echo -ne "${C_WARN}Kernel Git URL: ${NC}"; read -r new_kurl
                            echo -ne "${C_WARN}Kernel Destination Folder Name: ${NC}"; read -r new_kname
                            echo -ne "${C_WARN}Kernel Branch: ${NC}"; read -r new_kbranch
                            
                            new_display=$(echo "$new_display" | xargs)
                            new_folder=$(echo "$new_folder" | xargs)
                            new_makefile=$(echo "$new_makefile" | xargs)
                            new_family=$(echo "$new_family" | xargs)
                            new_kurl=$(echo "$new_kurl" | xargs)
                            new_kname=$(echo "$new_kname" | xargs)
                            new_kbranch=$(echo "$new_kbranch" | xargs)

                            if [[ -n "$new_display" && -n "$new_folder" && -n "$new_makefile" && -n "$new_family" && -n "$new_kurl" && -n "$new_kname" && -n "$new_kbranch" ]]; then
                                echo "$new_display|$new_folder|$new_makefile|$new_family|$new_kurl|$new_kname|$new_kbranch" >> "$DEVICE_DB"
                                echo "last_custom_name=\"$new_display\"" > "$CURRENT_DIR/.build_session"
                                echo -e "${C_ACCENT}[+] Profile created successfully.${NC}"
                                sleep 1.5
                            else
                                echo -e "${C_DANGER}[!] ERROR: Fields cannot be left blank. Aborting creation.${NC}"
                                sleep 3
                            fi
                            break 2
                        else
                            bp_idx=$((REPLY-1))
                            target_bp_line="${blueprint_catalog[$bp_idx]}"
                            IFS="|" read -r new_display new_folder new_makefile new_family new_kurl new_kname new_kbranch <<< "$target_bp_line"
                            
                            if [[ -n "$new_display" && -n "$new_folder" ]]; then
                                echo "$new_display|$new_folder|$new_makefile|$new_family|$new_kurl|$new_kname|$new_kbranch" >> "$DEVICE_DB"
                                echo "last_custom_name=\"$new_display\"" > "$CURRENT_DIR/.build_session"
                                echo -e "${C_ACCENT}[+] Dynamic catalog injected for $new_display.${NC}"
                                sleep 1.5
                            else
                                echo -e "${C_DANGER}[!] ERROR: Internal parse error. Registry write guarded.${NC}"
                                sleep 3
                            fi
                            break 2
                        fi
                    done
                done
                break 
            elif [ -n "$d_opt" ]; then
                idx=$((REPLY-1))
                target_blueprint="${device_lines[$idx]}"
                IFS="|" read -r D_DISPLAY D_FOLDER D_MAKEFILE FAMILY K_URL K_NAME K_BRANCH <<< "$target_blueprint"
                echo "last_custom_name=\"$D_DISPLAY\"" > "$CURRENT_DIR/.build_session"
                break 2 
            fi
        done
    done
fi

B_MAIN="16"
B_LOS="lineage-23.2"

REPOS=(
    "git@github.com:Alch3myOS-Devices/device_google_gs-common.git|device/google/gs-common|$B_MAIN" 
    "git@github.com:LineageOS/android_kernel_google_gs-6.1_manifest.git|kernel/google/gs-6.1/manifest|$B_LOS" 
    "git@github.com:LineageOS/android_kernel_google_gs-6.1_google-modules.git|kernel/google/gs-6.1/google-modules|$B_LOS" 
    "git@github.com:LineageOS/android_kernel_google_gs-6.1_devices.git|kernel/google/gs-6.1/devices|$B_LOS" 
    "git@gitlab.com:Libra420T/vendor_google_camera.git|vendor/google/camera|$B_MAIN" 
    "git@github.com:Alch3myOS/vendor_google_faceunlock.git|vendor/google/faceunlock|$B_MAIN" 
)

echo -e "${C_GOSSIP} [*] Resolving source tree for ${D_FOLDER}...${NC}"

git ls-remote --exit-code "git@github.com:Alch3myOS-Devices/device_google_${D_FOLDER}.git" refs/heads/$B_MAIN &>/dev/null
if [ $? -eq 0 ]; then
    echo -e "  ${C_ACCENT}>> Source resolved to Alch3myOS-Devices ($B_MAIN)${NC}"
    REPOS+=("git@github.com:Alch3myOS-Devices/device_google_${D_FOLDER}.git|device/google/${D_FOLDER}|$B_MAIN")
else
    echo -e "  ${C_WARN}>> Source not in custom org. Pulling from LineageOS ($B_LOS)${NC}"
    REPOS+=("git@github.com:LineageOS/android_device_google_${D_FOLDER}.git|device/google/${D_FOLDER}|$B_LOS")
fi

# Injects the precise tracked repository path, folder layout, and branch mapping completely dynamically
REPOS+=("${K_URL}|device/google/${K_NAME}|${K_BRANCH}")
REPOS+=("git@github.com:TheMuppets/proprietary_vendor_google_${D_MAKEFILE}.git|vendor/google/${D_MAKEFILE}|$B_LOS")

if [[ "$FAMILY" == "LAGUNA" ]]; then
    REPOS+=("git@github.com:Alch3myOS-Devices/device_google_laguna.git|device/google/laguna|$B_MAIN")
    REPOS+=("git@github.com:LineageOS/android_kernel_google_gs-6.6_devices.git|kernel/google/gs-6.6/devices|$B_LOS")
    REPOS+=("git@github.com:LineageOS/android_kernel_google_gs-6.6_manifest.git|kernel/google/gs-6.6/manifest|$B_LOS")
    REPOS+=("git@github.com:LineageOS/android_kernel_google_gs-6.6_prebuilts_gki.git|kernel/google/gs-6.6/prebuilts_gki|$B_LOS")
    REPOS+=("git@github.com:LineageOS/android_kernel_google_gs-6.6_google-modules.git|kernel/google/gs-6.6/google-modules|$B_LOS")
fi

if [[ "$FAMILY" == "ZUMAPRO" ]]; then
    REPOS+=("git@github.com:Alch3myOS-Devices/device_google_zumapro.git|device/google/zumapro|$B_MAIN")
fi

if [[ "$FAMILY" == "ZUMA" ]]; then
    REPOS+=("git@github.com:Alch3myOS-Devices/device_google_zuma.git|device/google/zuma|$B_MAIN")
fi

if [[ "$FAMILY" == "GS201" ]]; then
    REPOS+=("git@github.com:Alch3myOS-Devices/device_google_gs201.git|device/google/gs201|$B_MAIN")
fi

if [ -s "$VAULT_FILE" ]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && REPOS+=("$line")
    done < "$VAULT_FILE"
fi

clear
echo -e "${C_GOSSIP}TARGET LOCKED:${NC} ${D_DISPLAY}"

echo -e "\n${C_GOSSIP} [+] Checking secure connections...${NC}"
for host in "github.com" "gitlab.com" "codeberg.org"; do
    if check_auth "$host"; then 
        echo -e "  ${C_ACCENT}>> [AUTH OK]${NC} $host"
    else 
        echo -e "  ${C_DANGER}>> [AUTH FAIL]${NC} $host"
        echo -ne "${C_PRIME}Proceed anyway? (y/N): ${NC}"
        read -r auth_resp
        [[ ! "$auth_resp" =~ ^([yY])$ ]] && exit 1
    fi
done

echo -e "\n${C_PRIME} >>> $RAND_START${NC}\n"

for entry in "${REPOS[@]}"; do 
    IFS="|" read -r URL REL BRANCH <<< "$entry"
    sync_worker "$URL" "$REL" "$BRANCH"
done

echo -e "\n${C_GOSSIP} [SCAN] Performing Deep Intelligence Sweep...${NC}"
for entry in "${REPOS[@]}"; do
    IFS="|" read -r URL REL BRANCH <<< "$entry"
    if [[ "$REL" == *"google-modules" || "$REL" == *"devices" || "$REL" == *"prebuilts_gki" ]]; then
        if [[ "$URL" == *"gs-6.6"* ]]; then
            TARGET_MATCH="kernel/google/gs-6.6/private/$(basename "$REL")"
        else
            TARGET_MATCH="kernel/google/gs-6.1/private/$(basename "$REL")"
        fi
    else
        TARGET_MATCH="$REL"
    fi
    
    if [ -d "$TOP/$TARGET_MATCH" ]; then
        echo -e "  ${C_ACCENT}[ VERIFIED ]${NC} $TARGET_MATCH"
    fi
done

echo -e "\n${C_PRIME}  \"$RAND_JOKE\"${NC}"

echo -e "\n${C_ACCENT}Hint: Initializing will configure paths and prepare the final AOSP lunch build setup.${NC}"
echo -ne "${C_GOSSIP} >> Initialize Environment & Lunch? (y/N): ${NC}"
read -r response

if [[ "$response" =~ ^([yY])$ ]]; then
    echo -e "\n${C_PRIME} Select Build Variant:${NC}"
    echo -e "${C_GOSSIP}Hint: userdebug is typical for testing, eng opens full root access paths.${NC}"
    variant_opts=("user" "userdebug" "eng")
    
    OLD_COLUMNS=$COLUMNS
    COLUMNS=1

    select v_opt in "${variant_opts[@]}"; do 
        COLUMNS=$OLD_COLUMNS
        case $v_opt in 
            "user"|"userdebug"|"eng") 
                VARIANT=$v_opt
                break 
                ;; 
        esac
    done
    
    cd "$TOP"
    . build/envsetup.sh
    lunch "lineage_${D_MAKEFILE}-bp4a-${VARIANT}"
    
    echo -e "\n${C_PRIME} >>> $RAND_END${NC}"
    echo -e ""
    
    /bin/bash 
fi
