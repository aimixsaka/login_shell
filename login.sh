#!/bin/sh
# login script for njupt

##
# INFO level message
##
info() {
  echo -e "\n\e[32mINFO: $1\e[0m\n"
}

##
# WARN level message
##
warn() {
  echo -e "\n\e[33mWARN: $1\e[0m\n"
}

##
# ERROR level message
##
error() {
  echo -e "\n\e[31mERROR: $1\e[0m\n"
  exit 1
}

##
# TODO: rebuild with elegent!!!
# preconnect to ISP
##
preconnect() {
    if ! nmcli device wifi connect $ISP; then
      nmcli device wifi rescan
      sleep 2
      nmcli device wifi connect $ISP ||
        error "Cannot connect to $ISP"
    fi
}

##
# Preset some variable after preconnect
##
preset() {
  IP=$(ip --json addr show dev wlp0s20f3 | jq '.[0].addr_info.[0].local' | tr -d \")
  case $ISP in
    "NJUPT-CHINANET")
      info "Detected that you are using 'NJUPT-CHINANET'"
      LOGIN_ID="$USERNAME@njxy"
      ;;
    "NJUPT-CMCC")
      info "Detected that you are using 'NJUPT-CMCC'"
      LOGIN_ID="$USERNAME@cmcc"
      ;;
    "NJUPT")
      info "Detected that you are using 'NJUPT'"
      LOGIN_ID="$USERNAME"
      ;;
    *)
      error "Cannot recognize wifi name!"
  esac
}

usage() {
  echo "Usage: ./login -U \"username\" -P \"password\" -I \"isp\""
  echo "Login to NJUPT internet"
  echo
  echo "  -h, --help             output help message"
  echo "  -I, --isp              which isp to connect(NJUPT,NJUPT-CMCC,NJUPT-CHINANET)"
  echo "  -U, --username         login username, usually your student id"
  echo "  -P, --password         login password"
}

login() {
  curl -k \
    --request GET \
    --connect-timeout 5 \
    "https://10.10.244.11:802/eportal/portal/login?callback=dr1003&login_method=1&user_account=,0,${LOGIN_ID}&user_password=${PASSWORD}&wlan_user_ip=${IP}&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name="

  if curl -s --head --connect-timeout 3 https://www.baidu.com | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    info "Connected"
  else
    error "Connect Failed, is it the fault of magic?"
  fi
}

##
# Start
##
while (( $# )); do
  case "$1" in 
    -h | --help | "") usage; exit 0;  ;;
    -I | --isp)       ISP="$2";       shift 2;;
    -U | --username)  USERNAME="$2";  shift 2;;   
    -P | --password)  PASSWORD="$2";  shift 2;;
    # invalid parms
    *)                echo "Unexpected option: $1"; usage; exit 1;;
  esac
done

if [[ -z "$PASSWORD" ]] || [[ -z "$USERNAME" ]] || [[ -z "$ISP" ]]; then
  error "Missing Params!"
fi

# preconnect
preconnect

# set some info
preset

# try to login
login
