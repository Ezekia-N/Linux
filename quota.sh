#!/bin/bash

# Variable
HOME_DIR="/home"
DATA="/data"
FSTAB="/etc/fstab"
USERS=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)

# Verification commande
command_verification()
{
	# Verification de la commande quota
	if ! command -v quota &>/dev/null
	then
		echo "The quota command is not found"
		echo "Installing..."
		apt install quota -y
	fi
	
	# Verification de la commande mail
	if ! command -v mail &>/dev/null
	then 
		echo "The mail command is not found"
		echo "Installing..."
		apt install mailutils -y
	fi
}

# Quota sur la partition /data
data_quota()
{
	# Ajouter l'option usrquota et grpquota sur la partition /data
	if [ -z "$(sed -n "/\/data.*defaults,usrquota,grpquota/Ip" $FSTAB)" ]
	then 
		sed -i '/\/data/s/defaults/defaults,usrquota,grpquota/' $FSTAB
	fi
	
	systemctl daemon-reload
	mount -o remount $DATA # Remonter la partition
	command_verification # Verification des commandes utilisé par le programme
	quotacheck -cum $DATA && quotacheck -cgm $DATA # Créer les fichiers de quotas
	quotaon $DATA # Activer les quotas 

	# Editer les quotas de la partition /data
	for i in $USERS
	do
		setquota -u $i 500000 700000 1000 1000 $DATA           
	done

	# Envoyer un mail aux utilisateurs qui dépassent le quota dans la partition /data
	USER="$(repquota $DATA | awk -F" " '($3>$4 || $7>$8) { print $1 }')"
	for i in $USER
	do
		echo "Vous avez dépassé le quota" | mail -s "Quota dépassé" $i
		echo "L'utilisateur $i a dépassé le quota" | mail -s "Quota dépassé" root >/dev/null
	done
}

# Quota sur la partition /home
home_quota()
{
	# Ajouter l'option usrquota sur partition /home
	if [ -z "$(sed -n "/\/home.*defaults,usrquota/Ip" $FSTAB)" ]
	then 
		sed -i '/\/home/s/defaults/defaults,usrquota/' $FSTAB
	fi
	systemctl daemon-reload
	mount -o remount $HOME # Remonter la partition /hom
	command_verication # Verification de la commande quota
	quotacheck -cum $HOME # Créer le fichier du quota

	quotaon $HOME # Activer le quota

	# Editer les quotas de la partition /home
	for i in $USERS
	do
		setquota -u $i 500000 700000 0 0 $HOME          
	done	

	# Envoyer un mail aux utilisateurs qui dépassent le quota dans la partition /home
	USER="$(repquota $HOME | awk -F" " '$3 > $4 { print $1 }')"
	for i in $USER
	do
		echo "Vous avez dépassé le quota" | mail -s "Quota dépassé" $i
		echo "L'utilisateur $i a dépassé le quota" | mail -s "Quota dépassé" root
	done
}

ajouter_cron()
{
	chemin="/home/$USER/quota.sh"
	semaine="0 6 * * 1 /bin/bash $chemin" 

	if crontab -l 2>/dev/null | grep -Fq "$chemin"; then
		echo "Cron est déja installé"
	else
		echo "$semaine" | crontab -
	fi
}

# Verification de la partition /home
if [ "$(grep -c $HOME_DIR $FSTAB)" -eq 0 ]
then
	echo "$HOME_DIR partition is not found in fstab"
else
	home_quota
fi

# Verification de la partition /data
if [ "$(grep -c $DATA $FSTAB)" -eq 0 ]
then
	echo "$DATA partition is not found in fstab"
else
	data_quota
fi

ajouter_cron
