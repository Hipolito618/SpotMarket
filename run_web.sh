#!/usr/bin/env bash
# Script para ejecutar spotMarket en navegador Web local (Firefox)
cd "$(dirname "$0")"
export PATH="/home/hipolito/Documentos/Aplicaciones/flutter/bin:$PATH"

echo "=========================================="
echo "🌐 Iniciando spotMarket en la Web (Firefox)..."
echo "=========================================="

# Servir la versión web compilada en el puerto 8080
python3 -m http.server 8080 --directory build/web &
SERVER_PID=$!

echo "Servidor web activo en http://localhost:8080"
sleep 1

# Abrir en Firefox si está instalado
if command -v firefox >/dev/null 2>&1; then
    firefox http://localhost:8080 >/dev/null 2>&1 &
fi

echo "Presiona Ctrl+C para detener el servidor web."
wait $SERVER_PID

