#!/bin/sh
# login script for njupt

##
# INFO level message
##
info() {
  echo -e "\e[32mINFO: $1\e[0m"
}

##
# WARN level message
##
warn() {
  echo -e "\e[33mWARN: $1\e[0m"
}

##
# ERROR level message
##
error() {
  echo -e "\e[31mERROR: $1\e[0m"
  exit 1
}

##
# TODO: rebuild with elegent!!!
# preconnect to ISP
##
preconnect() {
  nmcli device wifi rescan
  sleep 2
  EXIST=`nmcli device wifi list | grep $ISP`
  if [ -z "$EXIST" ]; then
    warn "Can not find $ISP, will retry in 2 seconds"
    sleep 2
    # UGLY!
    EXIST=`nmcli device wifi list | grep $ISP`
    if [ -z "$EXIST" ]; then
      error "Not exist: $ISP"
    fi
  else
    # no need for error handling
    nmcli device wifi connect $ISP > /dev/null
    info "Preconnected Successfully"
  fi
}

##
# Preset some variable after preconnect
##
preset() {
  # magic variable(
  WLANACIP="10.255.252.150"
  WLANACNAME="XL-BRAS-SR8806-X"
  
  # get pc ip
  IP=$(ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1)
  
  # Deprecated(use command parm instead)
  # get operator connected
  #isp=$(nmcli -t -f ACTIVE,SSID dev wifi | grep yes | cut -d: -f2)
  
  case $ISP in
    "NJUPT-CHINANET")
      info "Detected that you are using 'NJUPT-CHINANET'"
      LOGIN_ID="%2C0%2C${USERNAME}%40njxy"
      ;;
    "NJUPT-CMCC")
      info "Detected that you are using 'NJUPT-CMCC'"
      LOGIN_ID="%2C0%2C${USERNAME}%40cmcc"
      ;;
    "NJUPT")
      info "Detected that you are using 'NJUPT'"
      LOGIN_ID="%2C0%2C${USERNAME}"
      ;;
    *)
      error "Cannot recognize wifi name!"
  esac
}

usage() {
  echo "Usage: ./login -U \"username\" -P \"password\" -I \"isp\""
  echo "Login to NJUPT internet"
  echo
  echo "  -I        which isp to connect(NJUPT,NJUPT-CMCC,NJUPT-CHINANET)"
  echo "  -U        login username, usually your student id"
  echo "  -P        login password"
}

login() {
  curl "http://10.10.244.11:801/eportal/?c=ACSetting&a=Login&protocol=http:&hostname=10.10.244.11&iTermType=1&wlanuserip=${IP}&wlanacip=${WLANACIP}&wlanacname=${WLANACNAME}&mac=00-00-00-00-00-00&ip=${IP}&enAdvert=0&queryACIP=0&loginMethod=1" \
    --data "DDDDD=${LOGIN_ID}&upass=${PASSWORD}&R1=0&R2=0&R3=0&R6=0&para=00&0MKKey=123456&buttonClicked=&redirect_url=&err_flag=&username=&password=&user=&cmd=&Login=&v6ip="

  if curl -s --head --connect-timeout 3 https://www.baidu.com | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    info "Connected"
  else
    error "Connect Failed! Check your username or password"
  fi
}

##
# Start
##
# precheck

while [ "$#" -ne "0" ]
do
  case "$1" in 
    -h | --help | "") usage; exit 0;  ;;
    -I | --isp)       ISP="$2";       shift 2;;
    -U | --username)  USERNAME="$2";  shift 2;;   
    -P | --password)  PASSWORD="$2";  shift 2;;
    # invalid parms
    *)                echo "Unexpected option: $1"; usage; exit 1;;
  esac
done

if [ -z "$PASSWORD" ] || [ -z "$USERNAME" ] || [ -z "$ISP" ]; then
  error "Missing Params!"
fi

# precheck if already connected
curl -s --head --connect-timeout 3 https://www.baidu.com | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
SUCCESS="$?"
CURRENT_ISP=`nmcli -t -f ACTIVE,SSID dev wifi | grep yes | cut -d: -f2`
if [ "$SUCCESS" -eq "0" ] && [ $ISP = $CURRENT_ISP ]; then
  warn "You have already connected to internet"
  exit 0
fi

# preconnect
preconnect

# set some info
preset

# try to login
login
