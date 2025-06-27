#!/bin/bash


SERVICE="nginx"
TARGET_DIR="/media/sf_shared/Resources/$SERVICE"

# Crear directorio de destino si no existe
mkdir -p "$TARGET_DIR"

# Obtener todas las versiones disponibles
echo "Obteniendo versiones disponibles para $SERVICE..."
versions=($(apt-cache madison "$SERVICE" | awk '{print $3}' | sort -u))

# Mostrar versiones encontradas
echo "Versiones encontradas:"
for i in "${!versions[@]}"; do
    echo "[$i]. ${versions[$i]}"
done

# Descargar cada versión con sus dependencias
for version in "${versions[@]}"; do
    echo -e "\nDescargando versión $version..."
    
    # Crear subdirectorio para esta versión
    VERSION_DIR="$TARGET_DIR/$version"
    sudo mkdir -p "$VERSION_DIR"
    
    # Descargar el paquete principal y todas sus dependencias
    sudo apt-get download "$SERVICE=$version" && \
    sudo apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "$SERVICE=$version" | grep "^\w" | sort -u) && \
    sudo mv *.deb "$VERSION_DIR/"
    
    if [ $? -eq 0 ]; then
        echo "Versión $version descargada correctamente en $VERSION_DIR"
    else
        echo "Error al descargar la versión $version"
        # Eliminar directorio si la descarga falló
        sudo rmdir "$VERSION_DIR" 2>/dev/null
    fi
done

echo -e "\nProceso completado. Los paquetes se han guardado en $TARGET_DIR"