#!/bin/bash
# encrypt_login_for_maxl.sh
# Created by:  luciano.ventura@gmail.com 2013-04-18


# return codes
readonly SUCCESS=0
readonly FAILURE=1


# define startmaxl.sh path
readonly start_maxl=essmsh


user_name="" 
user_pass=""
public_key=""
private_key=""
encrypted_user_name=""
encrypted_user_pass=""


back_title="Encrypt login for MaxL"


#
###############################################################################
#
show_msg_ok(){
    msg=" Encrypted user name is: $encrypted_user_name \n"
    msg=$msg"Encrypted password  is: $encrypted_user_pass \n"
    msg=$msg"Private key         is: $private_key \n"
     
    whiptail                        \
    --backtitle "$back_title"       \
    --fb                            \
    --msgbox "$msg" 0 0
}
#
###############################################################################
#
show_msg_empty(){
    empty_input=$1
     
    whiptail                        \
    --backtitle "$back_title"       \
    --fb                            \
    --msgbox "Input $1 can not be empty" 0 0
}
#
###############################################################################
#
show_msg_exit(){
    whiptail                      \
    --backtitle "$back_title"     \
    --fb                          \
    --msgbox "Finishing..." 0 0
}
#
###############################################################################
#
get_user_name(){
    # get essbase login
    user_name=$(
        whiptail                                 \
        --backtitle  "$back_title"               \
        --fb                                     \
        --inputbox "Input user name" 10 30       \
        3>&1 1>&2 2>&3
        )
     
    ret_code=$?
    if ! [ $ret_code = $SUCCESS ]; then
        show_msg_exit
         
        exit $FAILURE
    fi
     
    if [ -z "$user_name" ]; then
        show_msg_empty "user name"
         
        get_user_name
    fi
}
#
###############################################################################
#
get_user_pass(){
    # get essbase password
    user_pass=$(
        whiptail                                 \
        --backtitle  "$back_title"               \
        --fb                                     \
        --passwordbox "Input password" 10 30     \
        3>&1 1>&2 2>&3
        )
     
    ret_code=$?
    if ! [ $ret_code = $SUCCESS ]; then
        show_msg_exit
         
        exit $FAILURE
    fi
     
    if [ -z "$user_pass" ]; then
        show_msg_empty "password"
         
        get_user_pass
    fi
}
#
###############################################################################
#
generate_keys(){
    # generate public and private keys file, clean and delete after use
     
    tempfile=$(mktemp)
     
    $start_maxl -gk > tempfile
     public_key=$(head -n 7 tempfile | tail -n 1 | awk '{print $5}')
    private_key=$(head -n 8 tempfile | tail -n 1 | awk '{print $5}')
    shred -u $tempfile
}
#
###############################################################################
#
encrypt_login(){
    # create temp file and unset unencrypted password variable
     
    echo login $user_name $user_pass " ;" > temp.msh
    unset user_pass
     
    # encrypt login and password, clean and delete temp file
    $start_maxl -E temp.msh $public_key > /dev/null
    shred -u temp.msh
     
    # get encrypted login and password from temp.mshs, clean and delete
    encrypted_user_name=$(head -n 1 temp.mshs | awk '{print $3}')
    encrypted_user_pass=$(head -n 1 temp.mshs | awk '{ sub(";", ""); print $5}')
    shred -u temp.mshs
}
#
###############################################################################
#

# MAIN
get_user_name

get_user_pass

generate_keys

encrypt_login

show_msg_ok

show_msg_exit

exit $SUCCESS


