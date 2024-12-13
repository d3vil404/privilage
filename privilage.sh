#!/bin/bash

# Rishi's Privilege Escalation Scanner
# Owned and Developed by Rishi

# Output file for results
RESULTS_FILE="/tmp/priv_esc_results.txt"
> "$RESULTS_FILE"

# Colored output
function print_info() {
    echo -e "\033[1;33m[+] $1\033[0m"
}

function print_suggestion() {
    echo -e "\033[1;32m[!] $1\033[0m"
}

function print_error() {
    echo -e "\033[1;31m[-] $1\033[0m"
}

# Banner
print_info "*********************************************"
print_info "        Rishi's Privilege Escalation Tool"
print_info "          Owned and Developed by Rishi"
print_info "*********************************************"
print_info "Starting enumeration...\n"

# Function to suggest exploits
function suggest_exploit() {
    binary=$1
    base_binary=$(basename "$binary")
    gtfo_output=$(curl -s "https://gtfobins.github.io/gtfobins/$base_binary/" | grep -oP '(sudo .*|.*\<cp\>.*)')

    if [[ -n "$gtfo_output" ]]; then
        echo -e "\033[1;36mPossible exploit for $binary\033[0m"
        echo -e "\033[1;36m$gtfo_output\033[0m"
        echo -e "Possible exploit for $binary" >> "$RESULTS_FILE"
        echo "$gtfo_output" >> "$RESULTS_FILE"
    fi
}

# 1. Check for sudo privileges
print_info "Checking for sudo privileges..."
sudo -l 2>/dev/null | grep -q "(ALL)" && echo "Sudo Privileges: sudo -l indicates potential escalation." >> "$RESULTS_FILE"

# 2. Search for writable files owned by root
print_info "Searching for writable files owned by root..."
writable_files=$(find / -writable -type f -user root 2>/dev/null)
if [[ -n "$writable_files" ]]; then
    echo "Writable Files Owned by Root: Review the following files for potential privilege escalation." >> "$RESULTS_FILE"
    echo "$writable_files" >> "$RESULTS_FILE"
fi

# 3. Check for SUID binaries
print_info "Searching for SUID binaries..."
suid_binaries=$(find / -perm -4000 -type f 2>/dev/null)
if [[ -n "$suid_binaries" ]]; then
    echo "SUID Binaries: The following binaries may be exploitable." >> "$RESULTS_FILE"
    echo "$suid_binaries" >> "$RESULTS_FILE"
    while read -r binary; do
        suggest_exploit "$binary"
    done <<< "$suid_binaries"
fi

# 4. Check for cron jobs
print_info "Checking for cron jobs..."
cron_jobs=$(cat /etc/crontab 2>/dev/null; ls -la /etc/cron* 2>/dev/null)
if [[ -n "$cron_jobs" ]]; then
    echo "Cron Jobs: Review these jobs for potential escalation." >> "$RESULTS_FILE"
    echo "$cron_jobs" >> "$RESULTS_FILE"
fi

# 5. Kernel exploit check
print_info "Checking kernel version for exploits..."
kernel_version=$(uname -r)
kernel_exploits=$(curl -s "https://www.exploit-db.com" | grep -i "$kernel_version")
if [[ -n "$kernel_exploits" ]]; then
    echo "Kernel Exploits: Potential kernel exploits for version $kernel_version." >> "$RESULTS_FILE"
    echo "$kernel_exploits" >> "$RESULTS_FILE"
fi

# Summary and suggestions
print_info "\nEnumeration complete. Results saved to $RESULTS_FILE.\n"

# Analyze results and summarize possible privilege escalation paths
possible_methods=()

if sudo -l 2>/dev/null | grep -q "(ALL)"; then
    possible_methods+=("Sudo Privileges")
fi

if [[ -n "$suid_binaries" ]]; then
    possible_methods+=("SUID Binaries")
fi

if [[ -n "$writable_files" ]]; then
    possible_methods+=("Writable Files Owned by Root")
fi

if [[ -n "$cron_jobs" ]]; then
    possible_methods+=("Cron Jobs")
fi

if [[ -n "$kernel_exploits" ]]; then
    possible_methods+=("Kernel Exploits")
fi

if [[ ${#possible_methods[@]} -gt 0 ]]; then
    print_suggestion "Potential privilege escalation paths found:"
    for method in "${possible_methods[@]}"; do
        print_info "- $method"
    done
else
    print_error "No direct privilege escalation paths found. Review the enumeration results manually."
fi

# Display possible exploits in terminal
if [[ -s "$RESULTS_FILE" ]]; then
    print_suggestion "\nPossible Exploits Identified During Scan:"
    cat "$RESULTS_FILE"
fi

print_info "\nReview the detailed results in $RESULTS_FILE for more information."
