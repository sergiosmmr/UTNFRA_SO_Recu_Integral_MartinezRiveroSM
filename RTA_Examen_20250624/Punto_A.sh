#!/bin/bash

# Variables de discos
DISCO_SDC=$(sudo fdisk -l | grep "/dev/sdc" | awk '{print $2}' | awk -F':' '{print $1}')
DISCO_SDD=$(sudo fdisk -l | grep "/dev/sdd" | awk '{print $2}' | awk -F':' '{print $1}')
DISCO_SDE=$(sudo fdisk -l | grep "/dev/sde" | awk '{print $2}' | awk -F':' '{print $1}')

echo "[+] Paso 1: Crear primera partición en $DISCO_SDE (sin tipo)"
sudo fdisk $DISCO_SDE << EOF
n
p
1

+512M
w
EOF

sleep 2

echo "[+] Paso 2: Cambiar tipo de partición a '82' (Swap)"
sudo fdisk $DISCO_SDE << EOF
t
82
w
EOF

sleep 2

echo "[+] Resultado de partición:"
sudo fdisk -l $DISCO_SDE | grep "^/dev/sde"

echo "[+] Reparticionando $DISCO_SDC con 2 particiones tipo LVM"
sudo fdisk $DISCO_SDC << EOF
n
p
1

+2G
t
8e

n
p
2


t
2
8e

w
EOF

echo "[+] Reparticionando $DISCO_SDD con 1 partición tipo LVM"
sudo fdisk $DISCO_SDD << EOF
n
p
1


t
8e
w
EOF

echo "[+] Resultado de particiones en $DISCO_SDD"
sudo fdisk -l $DISCO_SDD | grep "^/dev/sdd"
echo "[+] Resultado de particiones en $DISCO_SDC"
sudo fdisk -l $DISCO_SDC | grep "^/dev/sdc"


echo "[+] Verificando existencia de particiones requeridas..."
for part in /dev/sdc1 /dev/sdc2 /dev/sdd1 /dev/sde1; do
  if [ -b "$part" ]; then
    echo "✔ Existe: $part"
  else
    echo "❌ FALTA: $part - Abortando script."
    exit 1
  fi
done

echo "[+] Crear volúmenes físicos (PV)"
sudo pvcreate -y /dev/sdc1 /dev/sdc2 /dev/sdd1

echo "[+] Crear grupos de volúmenes (VG)"
sudo vgcreate -y vg_datos /dev/sdc2 /dev/sdd1
sudo vgcreate -y vg_temp /dev/sdc1

echo "[+] Crear volúmenes lógicos (LV)"
sudo lvcreate -L 10M -y vg_datos -n lv_docker
sudo lvextend -L +700M -y /dev/mapper/vg_datos-lv_docker
sudo lvcreate -L 1.2G -y vg_datos -n lv_multimedia
sudo lvcreate -L 1.9G -y vg_temp -n lv_swap

echo "[+] Formatear volúmenes lógicos si no están formateados"

if ! sudo blkid /dev/mapper/vg_datos-lv_docker > /dev/null; then
  sudo mkfs.ext4 -F /dev/mapper/vg_datos-lv_docker
else
  echo "✔ /dev/mapper/vg_datos-lv_docker ya tiene sistema de archivos"
fi

if ! sudo blkid /dev/mapper/vg_datos-lv_multimedia > /dev/null; then
  sudo mkfs.ext4 -F /dev/mapper/vg_datos-lv_multimedia
else
  echo "✔ /dev/mapper/vg_datos-lv_multimedia ya tiene sistema de archivos"
fi

# Swap LVM
sudo mkswap -f /dev/mapper/vg_temp-lv_swap

# Swap tradicional
sudo mkswap -f /dev/sde1

echo "[+] Crear puntos de montaje"
sudo mkdir -p /var/lib/docker
sudo mkdir -p /Multimedia

echo "[+] Montar volúmenes"
sudo mount /dev/mapper/vg_datos-lv_docker /var/lib/docker
sudo mount /dev/mapper/vg_datos-lv_multimedia /Multimedia
sudo swapon /dev/mapper/vg_temp-lv_swap
sudo swapon /dev/sde1

echo "[+] Configurar /etc/fstab para montajes permanentes"
echo '/dev/mapper/vg_datos-lv_docker /var/lib/docker ext4 defaults 0 2' | sudo tee -a /etc/fstab
echo '/dev/mapper/vg_datos-lv_multimedia /Multimedia ext4 defaults 0 2' | sudo tee -a /etc/fstab
echo '/dev/mapper/vg_temp-lv_swap none swap sw 0 0' | sudo tee -a /etc/fstab
echo '/dev/sde1 none swap sw 0 0' | sudo tee -a /etc/fstab

echo "[✔] Punto A completado correctamente"

