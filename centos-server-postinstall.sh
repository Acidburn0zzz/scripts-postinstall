#! /bin/bash

######## Variables ##############
# enforcing/permissive/disabled : Statut de SELinux à activer
selinux=enforcing
# 0/1 : Ajouter cockpit
cockpit=1
# 0/1 : Désactiver le parefeu firewalld
disablefirewalld=0
# Liste de logiciels additionnels à installer	
addsoftwares="nmon htop vim screen"
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
	dnf -y --nogpgcheck --refresh upgrade
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


echo "Préparation terminée, il est recommandé de redémarrer !"
