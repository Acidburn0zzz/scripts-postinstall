#! /bin/bash

######## Variables ##############
# enforcing/permissive/disabled : Statut de SELinux à activer
selinux=enforcing
# 0/1 : Si on veut activer ssh		
enablessh=1
# Liste de logiciels additionnels à installer	
addsoftwares="nmon htop"
# 0/1 : Si on veut installer les codecs
codecs=1
# 0/1 : Si on veut installer les extensions GNOME dash-to-dock, appindicator et gsconnect
gnomeextensions=1
# 0/1 : Si on veut supprimer gnome-software et packagekit		
removepackagekit=1
# 0/1 : Si on veut supprimer les logiciels annexes de GNOME (Avoir un gnome light)
removeextragnome=1
# 0/1 : Si on veut supprimer les services d'impression et scanner
removecupsscan=1
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
# 0/1 : Si on veut installer VirtualBox		
virtualbox=0
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

######## Script ################

# SELinux
sed -e "s/SELINUX=.*/SELINUX=$selinux/" -i /etc/sysconfig/selinux

# SSH
if [[ "$enablessh" -eq "1" ]]
then
	systemctl enable --now sshd.service
fi

# Optimisations DNF
isfm=$(grep -c fastestmirror /etc/dnf/dnf.conf)
if [[ "$isfm" -eq "0" ]]
then
	echo "fastestmirror=1" >> /etc/dnf/dnf.conf
fi 

# MàJ
dnf -y --nogpgcheck --refresh upgrade

# RPM Fusion
dnf install --nogpgcheck -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
if [[ "$removepackagekit" -ne "1" ]]
then
	dnf install --nogpgcheck -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data
fi

# Outils divers
if [[ -n $addsoftwares ]]
then
	dnf install --nogpgcheck -y $addsoftwares
fi

# Codecs
if [[ "$codecs" -eq "1" ]]
then
	dnf install --nogpgcheck -y gstreamer-ffmpeg gstreamer-plugins-bad gstreamer-plugins-bad-nonfree gstreamer-plugins-ugly gstreamer1-plugins-{base,good,bad-free,good-extras,bad-free-extras} gstreamer1-plugin-mpg123 gstreamer1-libav gstreamer1-plugins-{bad-freeworld,ugly}
fi

# Gnomeextensions
if [[ "$gnomeextensions" -eq "1" ]]
then
	dnf install --nogpgcheck -y gnome-shell-extension-{dash-to-dock,appindicator,gsconnect}
fi

# Packagekit
if [[ "$removepackagekit" -eq "1" ]]
then
	dnf -y autoremove gnome-software PackageKit
fi

# ExtraGNOME
if [[ "$removeextragnome" -eq "1" ]]
then
	dnf -y autoremove baobab cheese epiphany gnome-{calendar,characters,clocks,contacts,dictionary,disk-utility,font-viewer,logs,maps,photos,user-docs,,weather} gucharmap sushi
fi

# Suppression de l'impression et scan
if [[ "$removecupsscan" -eq "1" ]]
then
	dnf -y autoremove cups simple-scan
fi

# Abrtd
if [[ "$removeabrtd" -eq "1" ]]
then
	dnf autoremove -y abrtd*
fi

# Libvirt
if [[ "$removelibvirt" -eq "1" ]]
then
	dnf autoremove -y libvirt*
fi

# Nvidia
if [[ "$nvidiaproprio" -eq "1" ]]
then
	dnf install --nogpgcheck -y xorg-x11-drv-nvidia akmod-nvidia xorg-x11-drv-nvidia-cuda
fi

#Broadcom
if [[ "$broadcomwifi" -eq "1" ]]
then
	dnf install --nogpgcheck -y akmod-wl
fi

#VirtualBox
if [[ "$steam" -eq "1" ]]
then
	dnf install --nogpgcheck -y VirtualBox
	akmods
	systemctl restart systemd-modules-load.service
fi

#Steam
if [[ "$steam" -eq "1" ]]
then
	dnf install --nogpgcheck -y steam
fi

#Vivaldi
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

		gsettings set org.gnome.shell  favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed -e 's/firefox.desktop/vivaldi-stable.desktop/')"
	fi
fi


echo "Préparation terminée, il est recommandé de redémarrer !"
