🛠️ AOSP Pixel Sync Assistant
This script is an interactive terminal dashboard that automates the tedious process of setting up, updating, and initializing Alch3myOS source trees for Google Pixel devices (spanning the Pixel 7 through Pixel 10 generations).

🚀 Key Features
Smart Target Chassis Selector: Automatically maps the correct folder structure, makefile names, and platform families (GS201, ZUMA, ZUMAPRO, LAGUNA) for your specific device.

Adaptive Repo Routing: Dynamically chooses between custom development organizations (Alch3myOS-Devices) and upstream fallbacks (LineageOS), auto-correcting branch names on the fly.

Self-Healing Git Workers: Automatically clears stuck Git index locks, hard-resets changes, cleans untracked files, and smoothly handles branch fallbacks to prevent sync interruptions.

Preemptive SSH Handshake: Verifies your cryptographic access keys against GitHub, GitLab, and Codeberg before wasting time trying to pull down code.

Persistent Custom Vault: Features a built-in wizard to inject, save, and permanently track your own custom third-party repositories.

Automated Lunch Routine: Concludes by automatically sourcing the AOSP build environment (build/envsetup.sh) and running the lunch command for your selected build variant (user, userdebug, eng).

⚙️ How to Set It Up
To deploy this script into your Android building environment, follow these vertical setup steps:

1. Place the Script
Move the sync.sh file directly into your rom working directory (or any subfolder inside it; the script will automatically locate your workspace root).

2. Grant Executive Permissions
Open your terminal, navigate to the folder containing your script, and make it executable:

3. chmod +x sync.sh

4. Ensure SSH Keys Are Configured
Because the script pulls from secure sources using SSH URLs (e.g., git@github.com:...), make sure your SSH private keys are added to your system ssh-agent and registered with your Git accounts

5. ssh-add ~/.ssh/id_

6. Launch the script ./sync.sh

💡 Quick Tips
First Run: Choose option 1 (Start Repo Syncing Process) to select your device and jump straight into building.

Customization: If you have personal device trees or custom kernel tweaks you want pulled every single time, use option 2 (Manually clone git repos) and reply y when it asks to save to the configuration vault.

Starting Fresh: If your device profiles ever feel cluttered or out-of-date, run option 3 (Reset to Default Template) to cleanly restore the script's core ecosystem back to its default state.
