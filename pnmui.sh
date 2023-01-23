#!/bin/sh

# Import current theme
source "/home/mrrobot/.local/src/pnmui/themes.config";
DIR="$(pwd)";
main_theme="$themes/$style"; #/home/mrrobot/.local/src/pnmui
edit_connection_theme="$DIR/themes/edit_connection/edit_connection.rasi";
edit_connection_add_theme="$DIR/themes/edit_connection/edit_connection_add.rasi";
activate_connection_theme="$DIR/themes/activate_connection/activate_connection.rasi";
activate_connection_password_theme="$DIR/themes/activate_connection/activate_connection_password.rasi";
connect_with_qr_code_theme="$DIR/themes/connect_with_qr_code/connect_with_qr_code.rasi";
set_system_hostname_theme="$DIR/themes/set_system_hostname/set_system_hostname.rasi";
list_ports_theme="$DIR/themes/list_ports/list_ports.rasi";
system_connections_folder="/etc/PhynetManager/system-connections";

option_1="Edit a connection";
option_2="Activate an connection";
option_3="Manually activate an connection";
option_4="Connect Wi-Fi with QR code";
option_5="Set system hostname";
option_6="Create Access Point";
option_7="List open/closed/listening ports";
option_8="List/add neighbours";
option_9="List all available interfaces";
option_10="SSH launcher";
option_11="Exit";

wireless_connection_interface=$(iw dev | grep -oP "Interface \K\w+");
wired_connection_interface="";
connected_network=""

[ $UID -ne 0 ] && echo "Please run script as root..." && exit 1;
[[ -s ./.cache/scanned_ssids ]] && > ./.cache/scanned_ssids;
[[ -s ./.cache/connected_ssids ]] && > ./.cache/connected_ssids;

# Main menu
function menu() {

    echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6\n$option_7\n$option_8\n$option_9\n$option_10\n$option_11" | rofi -dmenu -theme ${main_theme};

}

# OPTION 1
function edit_connection() {

    [ -s ./.cache/scanned_ssids ] && rm -rf ./.cache/scanned_ssids;

    echo "<Add>" > ./.cache/connected_ssids;

    grep -R 'ssid=' /etc/PhynetManager/system-connections | cut -d '=' -f2 | sort | uniq >> ./.cache/connected_ssids;

    echo "<Back>" >> ./.cache/connected_ssids;

    cat ./.cache/connected_ssids | rofi -dmenu -theme ${edit_connection_theme};

}

# OPTION 1-1
function edit_connection_add() {

    echo -e "DSL\nEthernet\nInfiniBand\nWi-Fi\nBond\nBridge\nIP Tunnel\nTeam\nVeth\nWireGuard\n<Cancel>" | rofi -window-title "New Connection" -dmenu -theme ${edit_connection_add_theme};

}

# OPTION 1-2
function edit_connection_edit() {

    #echo -e "DSL\nEthernet\nInfiniBand\nWi-Fi\nBond\nBridge\nIP Tunnel\nTeam\nVeth\nWireGuard\n<Cancel>" | rofi -window-title "New Connection" -dmenu -theme ${edit_connection_add_theme};
    echo "Not applied yet";

}


# OPTION 2
function activate_connection() {

    [ -s ./.cache/scanned_ssids ] && rm -rf ./.cache/scanned_ssids;

    iw dev "${wireless_connection_interface}" scan | grep -oP "(?<=SSID:).*" | sort | uniq | awk 'NF' > ./.cache/scanned_ssids;

    local state="$(iwconfig 2>/dev/null | grep -oP "(?<=ESSID:).*")";

    if [[ "${state}" != "off/any" ]]; then

        connected_network="$(iwconfig 2>/dev/null | grep -oP '(?<=ESSID:).*' | tr -d '"')";

        sed -i "1s/^/Connected:${connected_network}\n/" ./.cache/scanned_ssids 2>/dev/null;

    fi

     echo "<Back>" >> ./.cache/scanned_ssids;

     sed -i 's|^[ \t]*||' ./.cache/ssid_scans.pm 2>/dev/null;

     cat ./.cache/scanned_ssids | rofi -window-title "Activate a connection" -dmenu -theme ${activate_connection_theme};

}

# OPTION 3
function manually_actiavate_connection() {

    echo "Manual activation WPA_SUPPLICANT";

}

# OPTION 4
function connect_with_QR_Code() {

    local SSID=$(iwconfig 2>/dev/null | grep -oP 'ESSID:"\K\w+');

    local Security="WPA";

    local PSK="bin bash Mr.Robot666";

    RANDOM_QR_FILE="$(mktemp ./.cache/qr_codes/qr_code_${SSID}_XXXX.png)";

    qrencode -t png "WIFI:T:${Security};S:${SSID};P:${PSK};;" -o $RANDOM_QR_FILE;

    #OLD_URL="$(grep -oP 'url\("\K[^")]+' ./connect_with_qr_code.rasi)";

    #NEW_URL="$(realpath ${RANDOM_QR_FILE})"

    #perl -pi -e 's|"${OLD_URL}"|"${NEW_URL}"|g' $connect_with_qr_code_theme;

    #echo "qrfile: $RANDOM_QR_FILE";
    #echo "old file: $OLD_URL";
    #echo "new file: $NEW_URL";
    #rofi \
    #    -dmenu \
    #    -theme ./style-2.rasi;

	echo -e "SSID:$SSID\nSecurity:$Security\nPSK:$PSK" | rofi \
        -window-title "Share your connection" \
        -theme-str "window {width: 520px;}" \
		-theme-str "listview {columns: 1; lines: 5;}" \
		-dmenu \
		-markup-rows \
		-theme ${connect_with_qr_code_theme};

}

# OPTION 5
function set_system_hostname() {

    echo -e "Back" | rofi -dmenu -theme ${set_system_hostname_theme} 1> /etc/hostname;

}

# OPTION 6
function access_point() {

    echo "AP";

}

# OPTION 7
function list_ports() {

    echo -e "Open Ports\nListening Ports\nClosed Ports" | rofi -dmenu -theme ${main_theme};
}

# OPTION 8
function list_add_neighbours() {

    echo "neigh";
}

# OPTION 9
function list_all_available_interfaces() {

    tcpdump --list-interface | rofi -dmenu -theme ${main_theme} 1>/dev/null;

}

# OPTION 10
function ssh_launcher() {

    rofi -show ssh -dmenu -theme ${main_theme};

}

chosen="$(menu)";

case ${chosen} in

    $option_1)

        ssid="$(edit_connection)";

        case "${ssid}" in

            *Back*)

                exec "$0";

            ;;

            *Add*)

                network_type="$(edit_connection_add)";

                case "${network_type}" in

                    "DSL")

                        echo 1;

                    ;;

                    "Ethernet")

                        echo 2;

                    ;;

                    "InfiniBand")

                        echo 3;

                    ;;

                    "Wi-Fi")

                        echo 4;

                    ;;

                    "Bond")

                        echo 5;

                    ;;

                    "Bridge")

                        echo 6;

                    ;;

                    "IP Tunnel")

                        echo 7;

                    ;;

                    "Team")

                        echo 8;

                    ;;

                    "Veth")

                        echo 9;

                    ;;

                    "VLAN")

                        echo 10;

                    ;;

                    "WireGuard")

                        echo 11;

                    ;;

                    "<Cancel>")

                        exec "$0";

                    ;;

                esac

            ;;

            *)  # Check if any other button,key or unknown option is selected
                if [[ -z "${ssid}" ]]; then
                    # If so, go back
                    exec "$0";

                else

                    option="$(echo -e "<Edit Connection>\n<Delete>\n<Back>" | rofi -dmenu -theme ${edit_connection_theme})";

                    case "${option}" in

                        *Back*)

                            exec "$0";

                        ;;

                        *Edit*)

                            echo "Test";

                            exec "$0";

                        ;;

                        *Delete*)

                            prompt="$(echo -e "Yes\nNo" | rofi -window-title "Are you sure?" -dmenu -theme ${edit_connection_theme})";

                            case ${prompt} in

                                "Yes")

                                    echo "edit_connection_delete function";

                                    exec "$0";

                                ;;

                                "No")

                                    exec "$0";

                                ;;

                            esac

                        ;;

                    esac


                fi

            ;;

        esac

        exec "$0";

    ;;

    $option_2)

        ssid="$(activate_connection)";

        case "${ssid}" in

             *Back*)

                exec "$0";

            ;;

            *Connected:*) # Activated connection

                operation="$(echo -e "Deactivate\nBack" | rofi -dmenu -theme ${activate_connection_theme})";

                case ${operation} in

                    "Back")

                        exec "$0";

                    ;;

                    "Deactivate")

                        prompt="$(echo -e "Yes\nNo" | rofi -window-title "Are you sure?" -dmenu -theme ${activate_connection_theme})";

                        case ${prompt} in

                            "Yes")

                                killall wpa_supplicant 2>/dev/null;

                                #notify-send "${ssid}:" -i "/usr/share/icons/Fancy-Light-Icons/devices/16/network-wireless-connected-100.svg" "Disconnected connection";
                                exec "$0";

                            ;;

                            "No")

                                exec "$0";

                            ;;

                        esac

                        exec "$0";

                    ;;

                esac

                exec "$0";

            ;;

            *)  # Check if any other button,key or unknown option is selected
                if [[ -z "${ssid}" ]]; then
                    # If so, go back
                    exec "$0";

                else
                    # Check if it's in /etc/PhynetManager/system-connections/
                    case `grep -r "ssid=${ssid}" "/etc/PhynetManager/system-connections" >/dev/null; echo $?` in

                        0)  # In /etc/PhynetManager/system-connections/
                            # Check if ssid in /etc/wpa_supplicant/
                            case `grep -r "ssid=\"${ssid}\"" "/etc/wpa_supplicant" >/dev/null; echo $?` in

                                0)  # In /etc/wpa_supplicant/

                                    WPA_CONF_FILE="$(grep -r "${ssid}" "/etc/wpa_supplicant" | awk "{print $1}" | cut -d ':' -f1)";

                                    wpa_supplicant -B -i "${wireless_connection_interface}" -c "${WPA_CONF_FILE}" &>/dev/null && disown &>/dev/null;

                                    dhclient "${wireless_connection_interface}" 2>/dev/null;

                                    # Can't run notify-send as root (dbus error)
                                    #DISPLAY=:0.0 su mrrobot -c "notify-send "'${ssid}':" -i '/usr/share/icons/Fancy-Light-Icons/devices/16/network-wireless-connected-100.svg' 'Connection Successful';"
                                    # Return to main menu after connection
                                    exec "$0";

                                ;;

                                1)  #Not in /etc/wpa_supplicant/

                                    ssid_path="$(grep -r "ssid=${ssid}" "/etc/PhynetManager/system-connections" | cut -d ':' -f1)";

                                    psk="$(grep "psk=" "${ssid_path}" | cut -d '=' -f2)";

                                    NEW_WPA_CONF_FILE="$(mktemp -q "/etc/wpa_supplicant/wpa_supplicant_XXXXXXXXX_PhynetManager.conf")";

                                    wpa_passphrase "${ssid}" "${psk}" > "${NEW_WPA_CONF_FILE}";

                                    wpa_supplicant -B -i "${wireless_connection_interface}" -c "${NEW_WPA_CONF_FILE}" &>/dev/null;

                                    dhclient "${wireless_connection_interface}" &>/dev/null;

                                    exec "$0";

                                ;;

                            esac

                        ;;

                        1)  # Not in /etc/PhynetManager/system-connections/
                            # Network not found (Creating new one)
                            psk="$(rofi -dmenu -password -theme ${activate_connection_password_theme} 2>/dev/null)";

                            # Check for interruption or mid cancel
                            if [ $? -eq 1 ]; then

                                exec "$0";

                            fi

                            NEW_WPA_CONF_FILE="$(mktemp -q "/etc/wpa_supplicant/wpa_supplicant_XXXXXXXXX_PhynetManager.conf")";

                            wpa_passphrase "${ssid}" "${psk}" > "${NEW_WPA_CONF_FILE}";

                            ip link set "${wireless_connection_interface}" up;

                            wpa_supplicant -B -i "${wireless_connection_interface}" -c "${NEW_WPA_CONF_FILE}" &>/dev/null;
                            #wpa_supplicant -B -i "${wireless_connection_interface}" -c "${NEW_WPA_CONF_FILE}" 2>/dev/null;
                            # If user enters wrong password or any error occurs
                            if [ $? -eq 1 ]; then

                                #notify-send "${ssid}:" -i "/usr/share/icons/Fancy-Light-Icons/devices/16/network-wireless-connected-100.svg" "Wrong password";
                                rm -rf ${NEW_WPA_CONF_FILE};

                                exec "$0";

                            fi

                            dhclient "${wireless_connection_interface}";

                            #notify-send "${ssid}:" -i "/usr/share/icons/Fancy-Light-Icons/devices/16/network-wireless-connected-100.svg" "Connection Successful";
                            # Add to system-connections (/etc/PhynetManager/system-connections)

                            exec "$0";

                        ;;

                         *) # Network error, unwanted action or user error

                            #notify-send "Connection Error:" -i "/usr/share/icons/Fancy-Light-Icons/devices/16/network-wireless-connected-100.svg" "Please try again with right informations";

                            exec "$0";

                        ;;

                    esac

                fi

            ;;

        esac

        exec "$0";

    ;;

     $option_3)

        edit_connection;

        exec "$0";

    ;;

    $option_4)

        connect_with_QR_Code;

        exec "$0";

    ;;

    $option_5)

        set_system_hostname;

        exec "$0";

    ;;

    $option_6)

        access_point;

        exec "$0";

    ;;

     $option_7)

         list_ports;

    ;;

    $option_8)

        activate_connection;

        exec "$0";

    ;;

    $option_9)

        list_all_available_interfaces;

        exec "$0";

    ;;

    $option_10)

        ssh_launcher;

        exec "$0";

    ;;

    $option_11)

        exit 0;

    ;;

esac
# Done(In Binary:01000100 01101111 01101110 01100101).It's a joke(No it's not). :)