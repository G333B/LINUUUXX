#!/bin/bash

source ./config.sh


echo "****** Ouverture de l'environnement *******"

#desactivation des acl 
sudo chattr -a "$PASSWORD_FILE"
sudo chattr -i "$PASSWORD_FILE"
sudo chattr -a "$ENV_FILE"


#Verification du fichier
if [ ! -f "$PASSWORD_FILE" ]; then
    echo ">> Le fichier de mot de passe n'existe pas $PASSWORD_FILE."
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo ">> Le fichier d'environnement n'existe pas $ENV_FILE."
    exit 1
fi


#verfi montage
if mountpoint -q "$MOUNT_POINT"; then
    echo ">> Point de montage '$MOUNT_POINT' déjà monté. Démontage..."
    sudo umount "$MOUNT_POINT" || { echo ">> Échec du démontage de '$MOUNT_POINT'. Environnement peut être occupé."; exit 1; }
fi


# si le périphérique LUKS est déjà ouvert, on le ferme
if [ -b "/dev/mapper/$MAPPER_NAME" ]; then
    echo ">> Périphérique LUKS '$MAPPER_NAME' déjà ouvert. Fermeture..."
    sudo cryptsetup close "$MAPPER_NAME" || { echo ">> Échec de fermeture de '$MAPPER_NAME'. Environnement peut être en cours d'utilisation."; exit 1; }
fi

#point de montage
sudo cryptsetup open "$ENV_FILE" "$MAPPER_NAME" --key-file "$PASSWORD_FILE"
sudo mkdir -p "$MOUNT_POINT"
sudo mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo "Échec de l'ouverture du fichier d'environnement"
    exit 1
fi
echo ">> L'environnement est monté sur $MOUNT_POINT."

#installation deboostrap en stable pour chroot
if [ -f "$MOUNT_POINT/bin/bash" ]; then
    echo ">> Le système de fichiers monté contient /bin/bash."
else
    echo ">> installation deboostrap en cours..."
    sudo debootstrap stable "$MOUNT_POINT" http://deb.debian.org/debian/
    echo ">> deboostrap terminé."
    exit 1
fi

# Enter chroot
echo ">> Entrée dans l'environnement chroot..."
sudo chroot "$MOUNT_POINT" /bin/bash

# Vérification du contenu avant chroot
if [ ! -f "$MOUNT_POINT/bin/bash" ]; then
    echo "Erreur : Le système de fichiers monté ne contient pas /bin/bash."
    sudo umount "$MOUNT_POINT"
    sudo cryptsetup close "$MAPPER_NAME"
    exit 1
fi

