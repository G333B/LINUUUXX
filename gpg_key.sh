#!/bin/bash

source ./config.sh

echo " --------------------------------------"
echo "|                                      |"
echo "|                                      |"
echo "|       CONFIGURATION GPG_KEY          |"         
echo "|                                      |"
echo "|                                      |"
echo "---------------------------------------"
echo

# Fonction pour créer une paire de clés GPG
create_gpg_keys() {
    echo ">> Création d'une paire de clés GPG..."
    gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 2048
Name-Real: $USER_NAME
Name-Email: $USER_EMAIL
Expire-Date: 1y
%no-protection
EOF
    if [ $? -ne 0 ]; then
        echo "Erreur : Échec de la création de la paire de clés GPG."
        exit 1
    fi
    echo ">> Paire de clés GPG créée avec succès."
}

# Fonction pour exporter les clés publiques et privées dans l'environnement sécurisé
export_gpg_keys() {
    echo ">> Exportation des clés GPG dans l'environnement sécurisé..."
    gpg --armor --export "$USER_EMAIL" | sudo tee "$MOUNT_POINT/.public_key.asc" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Erreur : Échec de l'exportation de la clé publique."
        exit 1
    fi
    echo ">> Clé publique exportée vers $MOUNT_POINT/.public_key.asc."

    gpg --armor --export-secret-keys "$USER_EMAIL" | sudo tee "$MOUNT_POINT/.private_key.asc" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Erreur : Échec de l'exportation de la clé privée."
        exit 1
    fi
    echo ">> Clé privée exportée vers $MOUNT_POINT/.private_key.asc."
}

# Fonction pour importer des clés GPG depuis l'environnement sécurisé
import_gpg_keys() {
    echo ">> Importation des clés GPG depuis l'environnement sécurisé..."
    if [ -f "$MOUNT_POINT/.public_key.asc" ] && [ -f "$MOUNT_POINT/.private_key.asc" ]; then
        gpg --import "$MOUNT_POINT/.public_key.asc"
        gpg --import "$MOUNT_POINT/.private_key.asc"
        if [ $? -ne 0 ]; then
            echo "Erreur : Échec de l'importation des clés GPG."
            exit 1
        fi
        echo ">> Clés GPG importées avec succès depuis l'environnement sécurisé."
    else
        echo "Erreur : Les fichiers de clés GPG n'existent pas dans l'environnement sécurisé."
        exit 1
    fi
}

# Menu principal
echo "Que souhaitez-vous faire ?"
echo "1. Créer une paire de clés GPG"
echo "2. Exporter les clés GPG dans l'environnement sécurisé"
echo "3. Importer les clés GPG depuis l'environnement sécurisé"
read -p "Entrez votre choix (1/2/3) : " choice

case $choice in
    1)
        create_gpg_keys
        ;;
    2)
        export_gpg_keys
        ;;
    3)
        import_gpg_keys
        ;;
    *)
        echo "Choix invalide."
        exit 1
        ;;
esac

echo ">> Opération terminée."