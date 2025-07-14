#!/bin/bash

source ./config.sh

echo "****** Gestion des configurations SSH ******"



sudo chattr -a "$PASSWORD_FILE"
sudo chattr -i "$PASSWORD_FILE"
sudo chattr -a "$ENV_FILE"
sudo chattr -a "$MOUNT_POINT"


# créer un fichier de configuration SSH template
create_ssh_template() {
    echo ">> Création du fichier de configuration SSH template..."
    sudo mkdir -p "$COFFRE_DIR"
    cat <<EOF | sudo tee "$COFFRE_DIR/ssh_config_template" > /dev/null
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    LogLevel QUIET
EOF
    echo ">> Fichier de configuration SSH template créé : $COFFRE_DIR/ssh_config_template"

    sudo chmod 600 "$COFFRE_DIR/ssh_config_template"
    sudo chmod 700 "$COFFRE_DIR"
    echo ">> Permissions ajoutées"
}

# préconfigurer un fichier d'alias
create_alias() {
    echo ">> Préconfiguration du fichier d'alias..."
    echo "alias evsh='ssh -F $COFFRE_DIR/ssh_config_template'" | sudo tee "$COFFRE_DIR/alias_coffre" > /dev/null
    ln -sf "$ALIAS_FILE" "$HOME/.bash_aliases"
    echo ">> Alias ajouté : evsh='ssh -F $COFFRE_DIR/ssh_config_template'"
     echo ">> Lien symbolique créé : ~/.bash_aliases -> $ALIAS_FILE"
}

# importer des configurations et des clés SSH
import_ssh_config() {
    echo ">> Importation des configurations SSH existantes..."
    if [ -f "$HOME/.ssh/config" ]; then
        echo ">> Fichier de configuration trouvé : $HOME/.ssh/config"
        echo "Liste des hôtes disponibles :"
        grep -E "^Host " "$HOME/.ssh/config" | awk '{print $2}'
        read -p "Entrez le nom de l'hôte à importer : " host

        # Extraction des lignes de configuration pour l'hôte sélectionné
        awk "/^Host $host/,/^Host /" "$HOME/.ssh/config" | sed '$d' > "$COFFRE_DIR/$host_config"
        echo ">> Configuration importée pour l'hôte $host : $COFFRE_DIR/$host_config"

        #IdentityFile
        sed -i "s|IdentityFile .*|IdentityFile $COFFRE_DIR/$host_key|" "$COFFRE_DIR/$host_config"
        echo ">> Ligne IdentityFile modifiée pour pointer vers le coffre."

        # Copie des clés SSH 
        cp "$HOME/.ssh/$host_key" "$COFFRE_DIR/$host_key"
        cp "$HOME/.ssh/$host_key.pub" "$COFFRE_DIR/$host_key.pub"
        echo ">> Paires de clés SSH copiées dans le coffre."
    else
        echo "Erreur : Aucun fichier de configuration SSH trouvé."
        exit 1
    fi
}



# Menu principal
echo "----------------------------------------"
echo "|                                      |"
echo "|                                      |"
echo "|    Gestion des configurations SSH    |"         
echo "|                                      |"
echo "|                                      |"
echo "----------------------------------------"
echo 
echo "1. Créer un fichier de configuration SSH template"
echo "2. Préconfigurer un fichier d'alias"
echo "3. Importer des configurations et clés SSH existantes"
read -p "choix (1/2/3) : " choice

case $choice in
    1)
        create_ssh_template
        ;;
    2)
        create_alias
        ;;
    3)
        import_ssh_config
        ;;
    *)
        echo "Choix invalide."
        exit 1
        ;;
esac

echo ">> Opération terminée."