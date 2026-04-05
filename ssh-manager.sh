#!/bin/bash

# Colors
R='\033[0;31m' G='\033[0;32m' B='\033[0;34m'
C='\033[0;36m' Y='\033[1;33m' W='\033[1;37m' N='\033[0m'

menu() {
    clear
    echo -e "${B}==============================${N}"
    echo -e "${W}     SSH Account Manager      ${N}"
    echo -e "${B}==============================${N}"
    echo -e "${G}[01]${N} • إنشاء حساب SSH جديد"
    echo -e "${G}[02]${N} • حذف حساب SSH"
    echo -e "${G}[03]${N} • عرض جميع الحسابات"
    echo -e "${G}[04]${N} • عرض الحسابات المتصلة"
    echo -e "${G}[05]${N} • تجديد تاريخ انتهاء حساب"
    echo -e "${R}[00]${N} • خروج"
    echo -e "${B}==============================${N}"
    read -p "اختر: " c </dev/tty
    case $c in
        1) create_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) online_users ;;
        5) renew_user ;;
        0) exit 0 ;;
        *) menu ;;
    esac
}

create_user() {
    clear
    echo -e "${C}=== إنشاء حساب جديد ===${N}"
    read -p "اسم المستخدم: " user </dev/tty
    read -p "كلمة المرور: " pass </dev/tty
    read -p "عدد الأيام: " days </dev/tty
    exp=$(date -d "+${days} days" +"%Y-%m-%d")
    useradd -e $exp -s /bin/false -M $user
    echo "$user:$pass" | chpasswd
    echo -e "${G}✔ تم إنشاء الحساب: $user | تنتهي: $exp${N}"
    read -p "اضغط Enter للرجوع..." </dev/tty
    menu
}

delete_user() {
    clear
    echo -e "${R}=== حذف حساب ===${N}"
    list_users
    read -p "اسم المستخدم للحذف: " user </dev/tty
    userdel -f $user
    echo -e "${R}✔ تم حذف الحساب: $user${N}"
    read -p "اضغط Enter للرجوع..." </dev/tty
    menu
}

list_users() {
    clear
    echo -e "${C}=== قائمة الحسابات ===${N}"
    echo -e "${Y}المستخدم\t\tتاريخ الانتهاء${N}"
    echo "--------------------------------"
    while IFS=: read -r u _ _ _ _ _ shell; do
        if [[ "$shell" == "/bin/false" ]]; then
            exp=$(chage -l $u 2>/dev/null | grep "Account expires" | cut -d: -f2)
            echo -e "${W}$u${N}\t\t${G}$exp${N}"
        fi
    done < /etc/passwd
    read -p "اضغط Enter للرجوع..." </dev/tty
    menu
}

online_users() {
    clear
    echo -e "${C}=== الحسابات المتصلة الآن ===${N}"
    echo -e "${Y}المستخدم\t\tIP${N}"
    echo "--------------------------------"
    who | awk '{print $1"\t\t"$5}' | tr -d '()'
    echo ""
    echo -e "${G}إجمالي المتصلين: $(who | wc -l)${N}"
    read -p "اضغط Enter للرجوع..." </dev/tty
    menu
}

renew_user() {
    clear
    echo -e "${C}=== تجديد حساب ===${N}"
    list_users
    read -p "اسم المستخدم: " user </dev/tty
    read -p "عدد الأيام الإضافية: " days </dev/tty
    exp=$(date -d "+${days} days" +"%Y-%m-%d")
    chage -E $exp $user
    echo -e "${G}✔ تم تجديد $user حتى: $exp${N}"
    read -p "اضغط Enter للرجوع..." </dev/tty
    menu
}

menu
