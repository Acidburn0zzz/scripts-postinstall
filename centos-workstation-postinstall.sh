#! /bin/bash

######## Variables ##############
# enforcing/permissive/disabled : Statut de SELinux à activer
selinux=enforcing
# 0/1 : Ajouter cockpit
cockpit=0
# 0/1 : Activer les Flatpak
addflatpak=1
# 0/1 : Désactiver le parefeu firewalld
disablefirewalld=0
# Liste de logiciels additionnels à installer	
addsoftwares="nmon htop vim"
# 0/1 : Si on veut installer les codecs
codecs=1
# 0/1 : Si on veut installer les extensions GNOME dash-to-dock, appindicator
gnomeextensions=1
# 0/1 : Si on veut supprimer les logiciels annexes de GNOME (Avoir un gnome light)
removeextragnome=1
# 0/1 : Si on veut supprimer les services d'impression et scanner
removecupsscan=0
# 0/1 : Si on veut supprimer abrtd
removeabrtd=1
# 0/1 : Si on veut supprimer libvirt installé par défaut
removelibvirt=1
# 0/1 : Si on veut installer NVidia Proprio (Optimus supporté)
# /!\ SecureBoot doit être désactivé pour cette option
nvidiaproprio=0
# 0/1 : Si on veut installer les pilotes Wi-Fi Broadcom
# /!\ SecureBoot doit être désactivé
broadcomwifi=0
# 0/1 : Si on veut installer Steam
steam=0
# 0/1 : Si on veut remplacer Firefox par Vivaldi
vivaldi=1
######## FIN Variables ##########


######## Check root #############
if [[ $EUID -ne 0 ]]
then
	sudo chmod +x $(dirname $0)/$0
	sudo $(dirname $0)/$0
	exit;
fi

######## Vérifs auto ###########
isvbox=$(LANG=C hostnamectl | grep -i virtualization | grep -c oracle)
centos=$(rpm -E %centos)
######## Script ################

# SELinux
sed -e "s/SELINUX=.*/SELINUX=$selinux/" -i /etc/sysconfig/selinux

# Optimisations DNF
if [[ "$centos" -eq "8" ]]
then
	isfm=$(grep -c fastestmirror /etc/dnf/dnf.conf)
	if [[ "$isfm" -eq "0" ]]
	then
		echo "fastestmirror=1" >> /etc/dnf/dnf.conf
	fi 
fi


# MàJ
if [[ "$centos" -eq "8" ]]
then
	dnf -y --nogpgcheck --refresh upgrade
fi

# Dépôts
if [[ "$centos" -eq "8" ]]
then
	dnf config-manager --set-enabled extras
	dnf config-manager --set-enabled PowerTools
	dnf install -y --nogpgcheck epel-release
	dnf install -y --nogpgcheck https://www.elrepo.org/elrepo-release-8.0-2.el8.elrepo.noarch.rpm
	dnf install -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
	dnf install -y --nogpgcheck https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
	dnf -y --nogpgcheck --refresh upgrade
fi

#Flatpak
if [[ "$centos" -eq "8" ]]
then
	if [[ "$addflatpak" -eq "1" ]]
	then
		dnf install --nogpgcheck -y flatpak
		flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	fi
fi


# Outils divers
if [[ "$centos" -eq "8" ]]
then
	if [[ -n $addsoftwares ]]
	then
		dnf install --nogpgcheck -y $addsoftwares
	fi
fi

# Cockpit
if [[ "$centos" -eq "8" ]]
then
	if [[ "$cockpit" -eq "1" ]]
	then
		dnf install --nogpgcheck -y cockpit
		dnf install --nogpgcheck -y cockpit-networkmanager cockpit-selinux cockpit-dashboard cockpit-system cockpit-storaged
		systemctl enable cockpit.socket
		systemctl start cockpit.socket
		firewall-cmd --add-service=cockpit --permanent
		firewall-cmd --reload
	fi
fi


# Désactiver firewalld
if [[ "$centos" -eq "8" ]]
then
	if [[ "$disablefirewalld" -eq "1" ]]
	then
		systemctl stop firewalld
		systemctl disable wirewalld
	fi
fi

# Codecs
if [[ "$centos" -eq "8" ]]
then
	if [[ "$codecs" -eq "1" ]]
	then
		dnf install --nogpgcheck -y gstreamer-ffmpeg gstreamer-plugins-bad gstreamer-plugins-bad-nonfree gstreamer-plugins-ugly gstreamer1-plugins-{base,good,bad-free,good-extras,bad-free-extras} gstreamer1-plugin-mpg123 gstreamer1-libav gstreamer1-plugins-{bad-freeworld,ugly}
	fi
fi

# Gnomeextensions
if [[ "$centos" -eq "8" ]]
then
	if [[ "$gnomeextensions" -eq "1" ]]
	then
		dnf install --nogpgcheck -y gnome-shell-extension-{dash-to-dock,appindicator}
	fi
fi

# Packagekit
if [[ "$centos" -eq "8" ]]
then
	if [[ "$removepackagekit" -eq "1" ]]
	then
		dnf -y autoremove gnome-software PackageKit
	fi
fi

# ExtraGNOME
if [[ "$centos" -eq "8" ]]
then
	if [[ "$removeextragnome" -eq "1" ]]
	then
		dnf -y autoremove baobab cheese epiphany gnome-{calendar,characters,clocks,contacts,dictionary,disk-utility,font-viewer,logs,maps,photos,user-docs,,weather} gucharmap sushi
	fi
fi

# Suppression de l'impression et scan
if [[ "$centos" -eq "8" ]]
then
	if [[ "$removecupsscan" -eq "1" ]]
	then
		dnf -y autoremove cups simple-scan
	fi
fi

# Abrtd
if [[ "$centos" -eq "8" ]]
then
	if [[ "$removeabrtd" -eq "1" ]]
	then
		dnf autoremove -y abrtd*
	fi
fi

# Libvirt
if [[ "$centos" -eq "8" ]]
then
	if [[ "$removelibvirt" -eq "1" ]]
	then
		dnf autoremove -y libvirt*
	fi
fi

# Nvidia
if [[ "$centos" -eq "8" ]]
then
	if [[ "$nvidiaproprio" -eq "1" ]]
	then
		dnf install --nogpgcheck -y xorg-x11-drv-nvidia akmod-nvidia xorg-x11-drv-nvidia-cuda
	fi
fi

# Broadcom 
if [[ "$centos" -eq "8" ]]
then
	if [[ "$broadcomwifi" -eq "1" ]]
	then
		dnf install --nogpgcheck -y akmod-wl
	fi
fi

#Steam
if [[ "$centos" -eq "8" ]]
then
	if [[ "$steam" -eq "1" ]]
	then
		dnf install --nogpgcheck -y steam
	fi
fi

#Vivaldi
if [[ "$centos" -eq "8" ]]
then
	if [[ "$vivaldi" -eq "1" ]]
	then
		if [ -d "/etc/yum.repos.d" ]
		then
		
			echo "[vivaldi]" > /etc/yum.repos.d/vivaldi.repo
			echo "name=vivaldi" >> /etc/yum.repos.d/vivaldi.repo
			echo "baseurl=http://repo.vivaldi.com/archive/rpm/x86_64" >> /etc/yum.repos.d/vivaldi.repo
			echo "enabled=1" >> /etc/yum.repos.d/vivaldi.repo
			echo "gpgcheck=1" >> /etc/yum.repos.d/vivaldi.repo
			echo "gpgkey=http://repo.vivaldi.com/archive/linux_signing_key.pub" >> /etc/yum.repos.d/vivaldi.repo
		
	
			dnf install --nogpgcheck -y vivaldi-stable
			/opt/vivaldi/update-ffmpeg
			/opt/vivaldi/update-widevine
			dnf autoremove -y firefox
	
			#TODO awk -F: '$3 >= 1000 AND $3 <= 2000 {print $1}' /etc/passwd
			gsettings set org.gnome.shell  favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed -e 's/firefox.desktop/vivaldi-stable.desktop/')"
		fi
	fi
fi

echo "Préparation terminée, il est recommandé de redémarrer !"
