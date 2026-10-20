#!/usr/bin/env bash
# Script para iniciar el emulador Android y correr spotMarket
cd "$(dirname "$0")"
export PATH="/home/hipolito/Documentos/Aplicaciones/flutter/bin:$PATH"

echo "=========================================="
echo "📱 Iniciando emulador Android (AndroidESpero)..."
echo "=========================================="

flutter emulators --launch AndroidESpero
echo "Esperando a que el emulador esté listo..."
sleep 5

flutter run

