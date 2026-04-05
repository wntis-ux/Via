#!/bin/bash

# Colors
R='\033[0;31m' G='\033[0;32m' B='\033[0;34m'
C='\033[0;36m' Y='\033[1;33m' W='\033[1;37m' N='\033[0m'

menu() {
    clear
    echo -e "${B}==============================${N}"
    echo -e "${W}      SSH Account Manager     ${N}"
    echo -e "${B}==============================${N}"
    echo -e "${Y}NGINX : [$(systemctl is-active nginx | tr a-z A-Z)]  SSHD : [$(systemctl is-active sshd | tr a-z A-Z)]${N}"
    echo -e "${B}==============================${N}"
    echo -e "${G}[01]${N} • Create SSH Account"
    echo -e "${G}[02]${N} • Delete SSH Account"
    echo -e "${G}[03]${N} • List All Accounts"
    echo -e "${G}[04]${N} • Online Users"
    echo -e "${G}[05]${N} • Renew Account"
    echo -e "${G}[06]${N} • Change Password"
    echo -e "${G}[07]${N} • Server Info"
    echo -e "${R}[00]${N} • Exit"
    echo -e "${B}==============================${N}"
    read -p "Choose: " c </dev/tty
    case $c in
        1) create_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) online_users ;;
        5) renew_user ;;
        6) change_pass ;;
        7) server_info ;;
        0) exit 0 ;;
        *) menu ;;
    esac
}

create_user() {
    clear
    echo -e "${C}=== Create SSH Account ===${N}"
    read -p "Username: " user </dev/tty
    read -p "Password: " pass </dev/tty
    read -p "Days: " days </dev/tty
    exp=$(date -d "+${days} days" +"%Y-%m-%d")
    useradd -e $exp -s /bin/false -M $user 2>/dev/null
    echo "$user:$pass" | chpasswd
    ip=$(curl -s ifconfig.me)
    port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    [ -z "$port" ] && port=22
    echo -e "${B}==============================${N}"
    echo -e "${G} Account Created Successfully ${N}"
    echo -e "${B}==============================${N}"
    echo -e "${W} Host    :${N} ${G}$ip${N}"
    echo -e "${W} Port    :${N} ${G}$port${N}"
    echo -e "${W} User    :${N} ${G}$user${N}"
    echo -e "${W} Pass    :${N} ${G}$pass${N}"
    echo -e "${W} Expires :${N} ${G}$exp${N}"
    echo -e "${B}==============================${N}"
    read -p "Press Enter to go back..." </dev/tty
    menu
}

delete_user() {
    clear
    echo -e "${R}=== Delete SSH Account ===${N}"
    list_users_simple
    read -p "Username to delete: " user </dev/tty
    userdel -f $user 2>/dev/null
    echo -e "${R}✔ Account deleted: $user${N}"
    read -p "Press Enter to go back..." </dev/tty
    menu
}

list_users_simple() {
    echo -e "${Y}Username\t\tExpiry Date${N}"
    echo "--------------------------------"
    while IFS=: read -r u _ _ _ _ _ shell; do
        if [[ "$shell" == "/bin/false" ]]; then
            exp=$(chage -l $u 2>/dev/null | grep "Account expires" | cut -d: -f2)
            echo -e "${W}$u${N}\t\t${G}$exp${N}"
        fi
    done < /etc/passwd
}

list_users() {
    clear
    echo -e "${C}=== All SSH Accounts ===${N}"
    list_users_simple
    read -p "Press Enter to go back..." </dev/tty
    menu
}

online_users() {
    clear
    echo -e "${C}=== Online Users ===${N}"
    echo -e "${Y}Username\t\tIP${N}"
    echo "--------------------------------"
    who | awk '{print $1"\t\t"$5}' | tr -d '()'
    echo ""
    echo -e "${G}Total online: $(who | wc -l)${N}"
    read -p "Press Enter to go back..." </dev/tty
    menu
}

renew_user() {
    clear
    echo -e "${C}=== Renew Account ===${N}"
    list_users_simple
    read -p "Username: " user </dev/tty
    read -p "Add days: " days </dev/tty
    exp=$(date -d "+${days} days" +"%Y-%m-%d")
    chage -E $exp $user
    echo -e "${G}✔ Account $user renewed until: $exp${N}"
    read -p "Press Enter to go back..." </dev/tty
    menu
}

change_pass() {
    clear
    echo -e "${C}=== Change Password ===${N}"
    list_users_simple
    read -p "Username: " user </dev/tty
    read -p "New Password: " pass </dev/tty
    echo "$user:$pass" | chpasswd
    echo -e "${G}✔ Password changed for: $user${N}"
    read -p "Press Enter to go back..." </dev/tty
    menu
}

server_info() {
    clear
    echo -e "${C}=== Server Info ===${N}"
    ip=$(curl -s ifconfig.me)
    port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    [ -z "$port" ] && port=22
    os=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    uptime=$(uptime -p)
    echo -e "${W} IP       :${N} ${G}$ip${N}"
    echo -e "${W} SSH Port :${N} ${G}$port${N}"
    echo -e "${W} OS       :${N} ${G}$os${N}"
    echo -e "${W} Uptime   :${N} ${G}$uptime${N}"
    echo -e "${W} Users    :${N} ${G}$(who | wc -l) online${N}"
    echo -e "${B}==============================${N}"
    read -p "Press Enter to go back..." </dev/tty
    menu
}

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${R}Error: Run as root -> sudo bash script.sh${N}"
    exit 1
fi

menu
