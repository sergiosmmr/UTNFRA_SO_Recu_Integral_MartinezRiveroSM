#!/bin/bash

# 1. Crear archivo Lista_URL.txt
echo "[+] Creando archivo Lista_URL.txt con URLs de prueba"
mkdir -p ~/TP_2_SO/202408/bash_script
cat <<EOF > ~/TP_2_SO/202408/bash_script/Lista_URL.txt
https://www.google.com
https://httpstat.us/404
https://httpstat.us/503
EOF

# 2. Crear estructura de carpetas
echo "[+] Creando estructura de /tmp/head-check/"
sudo mkdir -p /tmp/head-check/{ok,Error/cliente,Error/servidor}

# 3. Crear script /usr/local/bin/martinez_check_URL.sh
echo "[+] Generando script martinez_check_URL.sh en /usr/local/bin/"
sudo tee /usr/local/bin/martinez_check_URL.sh > /dev/null << 'EOF'
#!/bin/bash

ARCHIVO_URL="$1"
RUTA_BASE="/tmp/head-check"
LOG_GENERAL="/var/log/status_URL.log"

while read -r URL; do
  TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
  STATUS_CODE=$(curl -LI -o /dev/null -w '%{http_code}' -s "$URL")
  DOMINIO=$(echo "$URL" | awk -F/ '{print $3}')
  URL_LOG_FORMAT=$(echo "$URL" | awk -F// '{print $2}')
  LINEA="$TIMESTAMP - Code:$STATUS_CODE - URL:$URL_LOG_FORMAT"

  echo "$LINEA" | sudo tee -a "$LOG_GENERAL" > /dev/null

  # Clasificación por código
  if (( STATUS_CODE == 200 )); then
    CARPETA="$RUTA_BASE/ok"
  elif (( STATUS_CODE >= 400 && STATUS_CODE < 500 )); then
    CARPETA="$RUTA_BASE/Error/cliente"
  elif (( STATUS_CODE >= 500 && STATUS_CODE < 600 )); then
    CARPETA="$RUTA_BASE/Error/servidor"
  fi

  echo "$LINEA" | sudo tee -a "$CARPETA/$DOMINIO.log" > /dev/null
done < "$ARCHIVO_URL"
EOF

# 4. Dar permisos de ejecución al script creado
echo "[+] Dando permisos de ejecución a martinez_check_URL.sh"
sudo chmod +x /usr/local/bin/martinez_check_URL.sh

# 5. Ejecutar el script pasándole el archivo como argumento
ARCHIVO_ABSOLUTO=~/TP_2_SO/202408/bash_script/Lista_URL.txt
echo "[+] Ejecutando verificación de URLs"
sudo /usr/local/bin/martinez_check_URL.sh "$ARCHIVO_ABSOLUTO"

echo "[✔] Punto B finalizado"

