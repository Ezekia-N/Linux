#!/bin/bash

# Verification des arguments 
if [ $# -ne 1 ]
then
	echo "Usage : $0 <IP serveur local>"
	exit 1
fi

# Configuration
chemin="/etc/apt/sources.list"

if [ -z $(grep -q $1 $chemin) ]
then
	echo "deb [trusted=yes] http://$1 ./" >> $chemin
fi
apt update # Mettre à jour le contenu de sources.list
