#!/bin/bash

# Limpiar cualquier construcción anterior
echo "Limpiando construcciones anteriores..."
rm -rf ./build/*
mkdir -p ./build

# Copiar archivos necesarios
echo "Copiando archivos necesarios..."
cp -r ./aeonix/* ./build/

# Crear la imagen ISO
echo "Creando la imagen ISO..."
mkisofs -o aeonix.iso -J -R ./build/

# Crear la imagen ROM (ajustar según sea necesario)
echo "Creando la imagen ROM..."
dd if=/dev/zero of=aeonix.rom bs=1M count=10

echo "Construcción completada. Las imágenes se encuentran en el directorio actual."
