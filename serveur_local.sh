#!/bin/bash

# Verification des commandes utiles
command_utils()
{
	# Apache 
	if ! command -v apache2 &>/dev/null
	then
		echo "The apache2 command is not found"
		echo "Installing..."
		apt install apache2 -y
	fi

	# dpkg
	if ! command -v dpkg-dev &>/dev/null
	then 
		echo "The dpkg command is not found"
		echo "Installing..."
		apt install dpkg-dev -y
	fi
}

# Configuration de apache2
configuration()
{
	command_utils

	# Desactiver la configuration du site par défaut
	cd /etc/apache2/sites-available
	a2dissite 000-default.conf
	systemctl reload apache2

	# Création du repertoire stockant les paquets
	rep="/var/www/paquet"	
	if [ ! -d $rep ]
	then 
		mkdir -p "$rep"
	fi

	# Créer un fichier de configuration site
	file="/etc/apache2/sites-available/deb_paquet.conf"
	if [ ! -f "$file" ]
	then 
		touch $file

		echo -e "<VirtualHost *:80>\n" >> $file 
		echo -e "\tServerName www.localserver.com\n" >> $file
		echo -e "\tServerAdmin webmaster@localhost\n" >> $file
		echo -e "\tDocumentRoot /var/www/paquet\n" >> $file
		echo -e "</VirtualHost>\n" >> $file
	fi 

	# Activer le site 
	a2ensite deb_paquet.conf
	systemctl reload apache2

	# Copier les archives dans le dossier rep
	cp /var/cache/apt/archives/*.deb $rep
	
	# Créer l'index
	cd /var/www/paquet
	dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
}	

configuration
