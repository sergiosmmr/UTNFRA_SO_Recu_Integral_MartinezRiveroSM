#!/bin/bash

# 1. Crear estructura de carpetas
echo "[+] Creando carpeta ~/TP_2_SO/202408/docker/"
mkdir -p ~/TP_2_SO/202408/docker/
cd ~/TP_2_SO/202408/docker/

# 2. Crear Dockerfile
echo "[+] Creando Dockerfile"
cat <<EOF > Dockerfile
FROM nginx:alpine
COPY web /usr/share/nginx/html
EOF

# 3. Crear carpeta web/ y archivo index.html con datos personalizados
echo "[+] Creando carpeta web/ con index.html"
mkdir -p web

CPU_INFO=$(grep "model name" /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs)

cat <<EOF > web/index.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Sistemas Operativos - UTNFRA</title>
</head>
<body>
  <h1>Recuperatorio 2do Parcial</h1>
  <h2>Detalles del Alumno</h2>
  <ul>
    <li>Nombre: Sergio Martinez</li>
    <li>División: 318</li>
    <li>CPU: $CPU_INFO</li>
  </ul>
</body>
</html>
EOF

# 4. Crear archivo web/file/info.txt con modelo y frecuencia de CPU
echo "[+] Creando archivo info.txt con modelo y frecuencia de CPU"
mkdir -p web/file
CPU_FREQ=$(lscpu | grep "CPU MHz" | awk -F: '{print $2}' | xargs)

cat <<EOF > web/file/info.txt
Modelo CPU: $CPU_INFO
Frecuencia: $CPU_FREQ MHz
EOF

# 5. Crear archivo docker-compose.yml
echo "[+] Creando docker-compose.yml"
cat <<EOF > docker-compose.yml
services:
  web:
    image: sergiomax/web3_ri2024-martinez
    ports:
      - "8081:80"
    volumes:
      - ./web/file:/usr/share/nginx/html/file
EOF

# 6. Instrucciones manuales finales
echo ""
echo "[✔] Preparación completa del entorno Docker."
echo ""
echo "  Para continuar, parate en la carpeta:"
echo "   cd ~/TP_2_SO/202408/docker/"
echo ""
echo "  Luego ejecutá manualmente estos comandos:"
echo "   docker build -t sergiomax/web3_ri2024-martinez ."
echo "   docker login   # (si no estás logueado aún)"
echo "   docker push sergiomax/web3_ri2024-martinez"
echo "   docker compose up -d"
echo ""

