#!/bin/bash

###############################################################################
#
# configure-kiosk.sh
#
# Author: dgrubb
# Date 05/26/2017
#
# Configures a fresh installation of Xubuntu to convert it into a kiosk which
# only runs a web application within Google Chrome. A user is created, named
# kiosk, whose account can only be accessed by automatically launching an X
# session (password is disabled). That X session doesn't include any desktop
# environment but instead runs Google Chrome in fullscreen kiosk mode.
#
# Usage: Launch as root (or with root permissions):
#   $ sudo ./configure-kiosk.sh
#
#   Tested on:
#
#       Xubuntu 17.04
#
# Other Ubuntu relatives will probably work fine, but I've only tested it on
# the above list.
#
###############################################################################

launch_dir=`pwd`
readonly START_TIME=`date +%Y-%m-%dT%H:%M:%S`
readonly LOG_DIR="logs"
readonly LOG_FILE="build_$START_TIME.log"
readonly LOG_OUT="$launch_dir/$LOG_DIR/$LOG_FILE"
readonly WEB_APP_URL="http://localhost"

readonly KIOSK_DESKTOP_RC="\
[Desktop]\n\
Session=kiosk\n"

readonly KIOSK_AUTOLOGIN="\
[Seat:*]\n\
allow-guest=false\n\
greeter-hide-users=true\n\
autologin-guest=false\n\
autologin-user=kiosk\n\
autologin-user-timeout=0\n"

readonly KIOSK_DEFAULT_SESSION="\
[Seat:*]\n\
user-session=kiosk\n"

readonly KIOSK_XSESSION="\
[Desktop Entry]\n\
Type=Application\n\
Encoding=UTF-8\n\
Name=Kiosk\n\
Comment=Start a Chrome-based Kiosk session\n\
Exec=/bin/bash /home/kiosk/start-chrome.sh\n\
Icon=google=chrome"

readonly START_CHROME="\
#!/bin/bash\n\n\
X_RES=\`xrandr | grep \"*\" | awk -Fx '{ print \$1 }' | sed 's/[^0-9]*//g'\`\n\
Y_RES=\`xrandr | grep \"*\" | awk -Fx '{ print \$2 }' | awk '{ print \$1 }'\`\n\n\
/usr/bin/google-chrome --kiosk --start-fullscreen --window-position=0,0 \
--window-size=\$X_RES,\$Y_RES --no-first-run --incognito --no-default-browser-check \
--disable-translate $WEB_APP_URL\n"

###############################################################################

# Configuration steps
do_install_chrome=y
do_create_kiosk_user=y
do_create_kiosk_xsession=y
do_enable_kiosk_autologin=y
do_write_chrome_startup=y

###############################################################################

msg() {
    echo "[$(date +%Y-%m-%dT%H:%M:%S%z)]: $@" >&2
}

###############################################################################

create_kiosk_user() {
    msg "Creating kiosk group and user"
    getent group kiosk || (
        groupadd kiosk
        useradd kiosk -s /bin/bash -m -g kiosk -p '*'
        passwd -d kiosk # Delete kiosk's password
        # Lock kiosk's account so that kiosk can't login using SSH or by
        # switching tty. However, lightdm can still start a session with this
        # user
        passwd -l kiosk
    )
}

###############################################################################

create_kiosk_xsession() {
    msg "Creating Kiosk Xsession"
    echo -e $KIOSK_XSESSION > /usr/share/xsessions/kiosk.desktop
}

###############################################################################

install_chrome() {
    msg "Installing Chrome browser"
    grep chrome /etc/apt/sources.list.d/google-chrome.list >&/dev/null || (
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
        echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
        apt-get update
        apt-get install -y --no-install-recommends google-chrome-stable
    )
}

###############################################################################

enable_kiosk_autologin() {
    msg "Enabling Kiosk autologin"
    echo -e $KIOSK_AUTOLOGIN > /etc/lightdm/lightdm.conf
    echo -e $KIOSK_DEFAULT_SESSION > /etc/lightdm/lightdm.conf.d/99-kiosk.conf
}

###############################################################################

write_chrome_startup() {
    msg "Writing script which starts Chrome with dynamic window size"
    echo -e $START_CHROME > /home/kiosk/start-chrome.sh
    chown kiosk:kiosk /home/kiosk/start-chrome.sh
    chmod +x /home/kiosk/start-chrome.sh
}

###############################################################################
# Start execution
###############################################################################

# Provide an opportunity to stop installation
msg "Configure Kiosk"
read -p "Press ENTER to continue (c to cancel) ..." entry
if [ ! -z $entry ]; then
    if [ $entry = "c" ]; then
        msg "Install cancelled"
        exit 0
    fi
fi

if [ $do_install_chrome = "y" ]; then
    install_chrome
fi

if [ $do_create_kiosk_user = "y" ]; then
    create_kiosk_user
fi

if [ $do_create_kiosk_xsession = "y" ]; then
    create_kiosk_xsession
fi

if [ $do_enable_kiosk_autologin = "y" ]; then
    enable_kiosk_autologin
fi

if [ $do_write_chrome_startup = "y" ]; then
    write_chrome_startup
fi

msg "Installation complete, please reboot with: $ sudo reboot"

exit 0

###############################################################################
# End execution
###############################################################################

