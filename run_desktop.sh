#!/usr/bin/env bash
# Script para ejecutar spotMarket en Linux Desktop
cd "$(dirname "$0")"
export PATH="/home/hipolito/Documentos/Aplicaciones/flutter/bin:$PATH"
export DISPLAY="${DISPLAY:-:0}"

echo "=========================================="
echo "🚀 Iniciando spotMarket en Linux Desktop..."
echo "=========================================="

flutter run -d linux

