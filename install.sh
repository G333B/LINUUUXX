source ./config.sh


echo " --------------------------------------"
echo "|                                      |"
echo "|                                      |"
echo "|           INSTALLATION ENV           |"         
echo "|                                      |"
echo "|                                      |"
echo "---------------------------------------"
echo

#Parametre de la taille fichier
read -p ">> Taille du fichier ? (default : $DEFAULT_SIZE) " taille
    if [ -z "$taille" ]; then
        taille=$DEFAULT_SIZE
    fi

#creation ddossiers fichiers
mkdir -p "$(dirname "$ENV_FILE")"
mkdir -p "$(dirname "$PASSWORD_FILE")"


#mdp
read -p ">> Password ? (**Stock in $PASSWORD_FILE **) : " password
echo
if [ -z "$password" ]; then
    echo ">> Veuillez entrer un mot de passe."
    exit 1
fi
echo "$password" > $PASSWORD_FILE

if [ -f "$PASSWORD_FILE" ]; then
    sudo chmod 4400 "$PASSWORD_FILE"
else
    echo "Erreur : Le fichier $PASSWORD_FILE n'existe pas."
    exit 1
fi




#input taille
tailleMO=$(numfmt --from=iec "$taille")
if [ -z "$tailleMO" ] || [ "$tailleMO" -lt 1048576 ]; then
    echo "Erreur : La taille doit être supérieure à 1 Mo."
    exit 1
fi
tailleMO=$(($tailleMO / 1048576))

#acl pour fichier environnement
sudo chattr -a "$ENV_FILE"

#creation du fichier
dd if=/dev/zero of="$ENV_FILE" bs=1M count="$tailleMO" status=progress
if [ $? -ne 0 ]; then
    echo "Échec de la création du fichier"
    sudo rm -f "$PASSWORD_FILE"
    exit 1
fi


#chiffrement 
echo ">> Chiffrement du fichier..."
sudo cryptsetup luksFormat "$ENV_FILE" --key-file "$PASSWORD_FILE"
if [ $? -ne 0 ]; then
    echo "Échec du chiffrement du fichier"
    sudo rm -f "$PASSWORD_FILE"
    exit 1
fi

#formatage du fichier en ext4
echo ">> Formatage du fichier en ext4..."
sudo cryptsetup open "$ENV_FILE" "$MAPPER_NAME" --key-file "$PASSWORD_FILE"
sudo mkfs.ext4 -F "/dev/mapper/$MAPPER_NAME"
if [ $? -ne 0 ]; then
    echo "Échec du formatage du fichier"
    sudo cryptsetup close "$MAPPER_NAME"
    sudo rm -f "$PASSWORD_FILE"
    sudo rm -f "$ENV_FILE"
    exit 1
fi

#protection fichier acl
sudo chattr +a "$ENV_FILE"
sudo chattr +a "$PASSWORD_FILE"

echo ">> Fichier créé et formaté avec succès."
