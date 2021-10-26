#!/bin/bash

set -x

GDM_FILE="/usr/share/gdm/defaults.conf"
CUSTOM_GDM_FILE="/etc/gdm/custom.conf"
LXDM_FILE="/etc/lxdm/lxdm.conf"
LIGHTDM_FILE="/etc/lightdm/lightdm.conf"
SDDM_FILE="/etc/sddm.conf"

LIVE_USER_GROUPS="audio bumblebee cdrom cdrw clamav console games \
kvm lp lpadmin messagebus plugdev polkituser portage pulse pulse-access pulse-rt \
scanner usb users uucp vboxguest vboxusers video wheel"
LIVE_USER=mocaccino
LIVE_PERSISTENT_HOME_LABEL="live:/home"

setup_autologin() {
    # GDM - GNOME
    if [ -f "${GDM_FILE}" ]; then
        sed -i "s/^AutomaticLoginEnable=.*/AutomaticLoginEnable=true/" ${GDM_FILE}
        sed -i "s/^AutomaticLogin=.*/AutomaticLogin=${LIVE_USER}/" ${GDM_FILE}

        sed -i "s/^TimedLoginEnable=.*/TimedLoginEnable=true/" ${GDM_FILE}
        sed -i "s/^TimedLogin=.*/TimedLogin=${LIVE_USER}/" ${GDM_FILE}
        sed -i "s/^TimedLoginDelay=.*/TimedLoginDelay=0/" ${GDM_FILE}

        # It seems that restart of the getty@tty1.service (inside setup_vt_autologin)
        # block gdm bootstrap
        sed -i "s/^Conflicts=getty@t.*//g" ${GDM_FILE}

    elif [ -f "${CUSTOM_GDM_FILE}" ]; then
        # FIXME: if this is called multiple times, it generates duplicated entries
        sed -i "s:\[daemon\]:\[daemon\]\nAutomaticLoginEnable=true\nAutomaticLogin=${LIVE_USER}\nTimedLoginEnable=true\nTimedLogin=${LIVE_USER}\nTimedLoginDelay=0:" \
            "${CUSTOM_GDM_FILE}"
        # change other entries there
        sed -i "s/^TimedLogin=.*/TimedLogin=${LIVE_USER}/" "${CUSTOM_GDM_FILE}"
        sed -i "s/^AutomaticLogin=.*/AutomaticLogin=${LIVE_USER}/" "${CUSTOM_GDM_FILE}"
        sed -i "s/^Conflicts=getty@t.*//g" /lib/systemd/system/gdm.service
    fi

    # LXDM
    if [ -f "$LXDM_FILE" ]; then
        sed -i "s/autologin=.*/autologin=${LIVE_USER}/" $LXDM_FILE
        sed -i "/^#.*autologin=/ s/^#//" $LXDM_FILE
    fi

    # SDDM
    if [ -f "$SDDM_FILE" ]; then
        sed -i "s/^User=.*/User=${LIVE_USER}/" $SDDM_FILE
        sed -i "s/^Session=.*/Session=default/" $SDDM_FILE

        # This fix shutdown issue with sddm
        #	systemctl stop getty@tty1
    fi

    # LightDM
    if [ -f "$LIGHTDM_FILE" ]; then
        sed -i "s/autologin-user=.*/autologin-user=${LIVE_USER}/" $LIGHTDM_FILE
        sed -i "/^#.*autologin-user=/ s/^#//" $LIGHTDM_FILE
    fi

    fixup_gnome_autologin_session
}

disable_autologin() {
    # GDM - GNOME
    if [ -f "${GDM_FILE}" ]; then
        sed -i "/^AutomaticLoginEnable=.*/d" ${CUSTOM_GDM_FILE}
        sed -i "/^AutomaticLogin=.*/d" ${CUSTOM_GDM_FILE}
        sed -i "/^TimedLoginEnable=.*/d" ${CUSTOM_GDM_FILE}
        sed -i "/^TimedLogin=.*/d" ${CUSTOM_GDM_FILE}
        sed -i "/^TimedLoginDelay=.*/d" ${CUSTOM_GDM_FILE}
        sed -i "s/^AutomaticLoginEnable=.*/AutomaticLoginEnable=false/" ${GDM_FILE}
    fi

    # LXDM
    if [ -f "$LXDM_FILE" ]; then
        sed -i "s/^autologin=.*/autologin=/" $LXDM_FILE
    fi

    # LightDM
    if [ -f "$LIGHTDM_FILE" ]; then
        sed -i "s/^autologin-user=.*/#autologin-user=/" $LIGHTDM_FILE
    fi

    # SDDM
    if [ -f "$SDDM_FILE" ]; then
        sed -i "s/Relogin=.*/Relogin=false/" $SDDM_FILE
        sed -i "s/^Session=.*/Session=/" $SDDM_FILE
        sed -i "s/^User=.*/User=/" $SDDM_FILE
    fi
}

setup_home_mount() {
    local target_label="${LIVE_PERSISTENT_HOME_LABEL}"
    local device=$(blkid -L "${target_label}")

    # check if there is a device available
    [ -z "${device}" ] && return 0

    mkdir -p /home || return 1
    mount "${device}" /home || return 1
}

setup_live_user() {
    local live_user="${1}"
    local live_uid="${2}"
    if [ -z "${live_user}" ]; then
        live_user="${LIVE_USER}"
    fi
    if [ -n "${live_uid}" ]; then
        live_uid="-u ${live_uid}"
    fi
    id ${live_user} &> /dev/null
    if [ "${?}" != "0" ]; then
        local live_groups=""
        local avail_groups=$(cat /etc/group | cut -d":" -f 1 | xargs echo)
        for a_group in ${avail_groups}; do
            for p_group in ${LIVE_USER_GROUPS}; do
                if [ "${p_group}" = "${a_group}" ]; then
                    if [ -z "${live_groups}" ]; then
                        live_groups="${p_group}"
                    else
                        live_groups="${live_groups},${p_group}"
                    fi
                fi
            done
        done
        # then setup live user, that is missing
        useradd -d "/home/${live_user}" -g root -G ${live_groups} -c "MocaccinoOS" \
            -m -N -p "" -s /bin/bash ${live_uid} "${live_user}"
        # setting sudoers file
        [ -e /etc/sudoers ] && grep -q -F ${live_user} /etc/sudoers || echo "${live_user} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        return 0
    fi
    return 1
}

setup_vt_autologin() {
        cp /lib/systemd/system/getty@.service \
            /etc/systemd/system/autologin@.service
        sed -i "/^ExecStart=/ s:/sbin/agetty:/sbin/agetty --autologin root:g" \
            /lib/systemd/system/getty@.service
        sed -i "/^ExecStart=/ s:-o.*--noclear::g" \
            /lib/systemd/system/getty@.service
        systemctl daemon-reload
        systemctl restart getty@tty1
}

setup_desktop_session() {
    local usr="${1}"
    local sess="${2}"

    local dmrc_file="/home/${usr}/.dmrc"
    local skel_dmrc_file="/etc/skel/.dmrc"

    local dmrc_f_dir=
    for dmrc_f in "${dmrc_file}" "${skel_dmrc_file}"; do
        dmrc_f_dir=$(dirname "${dmrc_f}")
        [ -d "${dmrc_f_dir}" ] || continue

        echo "[Desktop]" > "${dmrc_f}"
        echo "Session=${sess}" >> "${dmrc_f}"
        chown "${usr}" "${dmrc_f}"
    done

    if [ -x "/usr/libexec/gdm-set-default-session" ]; then
        # oh my fucking glorious god, this
        # is AccountsService bullshit
        # cross fingers
        gdm-set-default-session "${sess}"
    fi
    if [ -x "/usr/libexec/gdm-set-session" ]; then
        # GDM 3.6 support
        /usr/libexec/gdm-set-session "${usr}" "${sess}"
    fi

    # LightDM support
    ln -sf "${sess}.desktop" /usr/share/xsessions/default.desktop
}

setup_gui_installer() {
    # Configure Fluxbox
    local flux_dir="/home/${LIVE_USER}/.fluxbox"
    local flux_startup_file="${flux_dir}/startup"
    if [ ! -d "${flux_dir}" ]; then
        mkdir "${flux_dir}" && chown "${LIVE_USER}" "${flux_dir}"
    fi
    sed -i "/installer --fullscreen/ s/^# //" "${flux_startup_file}"

    setup_desktop_session "${LIVE_USER}" "fluxbox"

}

# This function reads /etc/skel/.dmrc and properly
# set the Session= value inside AccountsService.
# Blame the idiots who broke de-facto standards
# and created this fugly thing called AccountsService
fixup_gnome_autologin_session() {
    local cur_session=

    if [ -f "/etc/skel/.dmrc" ]; then
        cur_session=$(cat /etc/skel/.dmrc | grep ^Session | cut -d"=" -f 2)
    fi
    if [ -z "${cur_session}" ]; then
        return 0
    fi

    setup_desktop_session "${LIVE_USER}" "${cur_session}"
}

systemd_running() {
    test -d /run/systemd/system
}

openrc_running() {
    test -e /run/openrc/softlevel
}

setup_default_xsession() {
  local sess="${1}"
  echo "[Desktop]" > /etc/skel/.dmrc
  echo "Session=${sess}" >> /etc/skel/.dmrc
  rm -vf /usr/share/xsessions/default.desktop || true
  ln -sf "${sess}.desktop" /usr/share/xsessions/default.desktop
}


setup_openrc_network() {
  # Setup network
  cd /etc/init.d
  ln -s netif.tmpl net.eth0
  rc-update add net.eth0 default
  echo template=dhcpcd > /etc/conf.d/net.eth0
  re-update add "net.eth0"

}

setup_xorg_server() {
  mkdir -p /etc/X11/ || true

  setup_all_fonts

  glib_update_schemas

  gtk_update_icons

  mime_update_db

  return 0
}


prepare() {

  EROOT=""

  source /usr/share/mocaccino-funtoo/triggers/triggers-loader

  # Create /etc/shadow,/etc/group,/etc/gshadow,/etc/passwd files
  rm /etc/shadow || true
  touch /etc/shadow
  rm /etc/group || true
  touch /etc/group
  rm /etc/gshadow || true
  touch /etc/gshadow
  rm /etc/passwd || true
  touch /etc/passwd

  touch /etc/fstab
  # Trying to fix /dev/ptmx group issue
  #echo "devpts /dev/pts devpts gid=5,mode=620 0 0" >> /etc/fstab

  echo "Europe/Rome" > /etc/timezone

  # Create root and mocaccino user
  entities merge -s /var/lib/mocaccino/entities -a

  echo "Creating /etc/inittab..."
  cp /var/lib/mocaccino/inittab /etc/inittab -v

  # Create all others entities
  main_layer="funtoo-base"
  entities merge -s /usr/share/mocaccino/layers/${main_layer}/entities/ \
    -s /usr/share/mocaccino/layers/funtoo-boot/entities/ -a

  entities merge -s /var/lib/mocaccino/entities-mocaccino-groups -a

  echo "mocaccino-funtoo" > /etc/hostname
  sed -i -e 's|^hostname=.*|hostname="mocaccino-funtoo"|' /etc/conf.d/hostname

  openrc_init_runlevels

  mkdir /var/tmp || true

  # Temporary stuff

  # TODO: probably could be set on finalizer.
  polkit_setup

  dbus_gen_machineid

#    systemctl --no-reload disable ldconfig.service 2> /dev/null
#    systemctl stop ldconfig.service 2> /dev/null
    ENABLED_SERVICES=(
      "avahi-daemon"
      "local"
      "bluetooth"
      # Temporay enable logger always. On ISO probably we can to maintain
      # this off.
      "metalog"
      "NetworkManager"
      "xdm"

#      "cups"
#        "cups-browsed"
    )
    for srv in "${ENABLED_SERVICES[@]}"; do
        rc-update add "${srv}" default
    done

    echo "
127.0.0.1   mocaccino-funtoo localhost
::1         mocaccino-funtoo localhost
"   > /etc/hosts

    # Temporary. Maybe it's better set UTC here.
    echo "Europe/Rome" > /etc/localtime


    ENABLED_BOOT_SERVICES=(
      "dbus"
      "binfmt"
      "elogind"
      "hostname"
      #"modules"
      "opentmpfiles-setup"
      "procfs"
      "root"
      "swap"
      "urandom"
    )

    for srv in "${ENABLED_BOOT_SERVICES[@]}"; do
        rc-update add "${srv}" boot
    done

    ENABLED_SYSINIT_SERVICES=(
      "udev-postmount"
      "udev-trigger"
      "udev-settle"
      "cgroups"
      "devfs"
      "dmesg"
      "sysfs"
    )
    for srv in "${ENABLED_SYSINIT_SERVICES[@]}"; do
        rc-update add "${srv}" sysinit
    done

    setup_xorg_server

    eselect opengl set xorg-x11 --use-old

    if [ -f "/usr/share/xsessions/gnome.desktop" ]; then
        setup_default_xsession "gnome"
#        systemctl enable "gdm"
    fi

    locale-gen

    # Temporary fix for gnome
    if [ -e /etc/motd ] ; then
      cp /etc/motd /etc/issue
      rm /etc/motd
    fi

    # Temporary fix until entities will handle this
    mkdir -p /home/mocaccino
    chown mocaccino:users -R /home/mocaccino

    #sed -i -e 's|INACTIVE_TIMEOUT.*|INACTIVE_TIMEOUT=60|g' /etc/conf.d/NetworkManager

    echo "mocaccino ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/99-mocaccino

    ldconfig
}
