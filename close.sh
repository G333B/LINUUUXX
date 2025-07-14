#!/bin/bash

source ./config.sh

echo "****** Fermeture de l'environnement *******"

# Vérification si le point de montage est actif
if mountpoint -q "$MOUNT_POINT"; then
    echo ">> Démontage du point de montage $MOUNT_POINT..."
    sudo umount "$MOUNT_POINT"
    if [ $? -ne 0 ]; then
        echo "Erreur : Échec du démontage du point de montage $MOUNT_POINT."
        exit 1
    fi
else
    echo ">> Le point de montage $MOUNT_POINT n'est pas monté."
fi

# Vérification si le mapper cryptographique est actif
if sudo cryptsetup status "$MAPPER_NAME" | grep -q "active"; then
    echo ">> Fermeture du mapper cryptographique $MAPPER_NAME..."
    sudo cryptsetup close "$MAPPER_NAME"
    if [ $? -ne 0 ]; then
        echo "Erreur : Échec de la fermeture du mapper cryptographique $MAPPER_NAME."
        exit 1
    fi
else
    echo ">> Le mapper cryptographique $MAPPER_NAME n'est pas actif."
fi

# Suppression du répertoire de montage
if [ -d "$MOUNT_POINT" ]; then
    echo ">> Suppression du répertoire de montage $MOUNT_POINT..."
    sudo rmdir "$MOUNT_POINT" 2>/dev/null
fi

echo ">> Environnement fermé avec succès."