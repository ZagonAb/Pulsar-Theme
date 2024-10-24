#!/bin/bash
# Guardar como "round-png-corners.sh"

# Variable para contar archivos procesados
processed=0
total_files=0

# Función para limpieza al salir
cleanup() {
    echo -e "\n\nInterrumpido por el usuario."
    echo "Archivos procesados: $processed de $total_files"
    echo "Proceso cancelado."
    exit 1
}

# Registrar la función cleanup para la señal SIGINT (Ctrl+C)
trap cleanup SIGINT

# Verificar si hay archivos PNG en el directorio
if ! ls *.png >/dev/null 2>&1; then
    echo "No se encontraron archivos PNG en el directorio actual"
    exit 1
fi

# Preguntar por el radio de redondeo
while true; do
    echo -n "Ingrese el porcentaje de redondeo para las esquinas (1-100): "
    read radius
    if [[ "$radius" =~ ^[0-9]+$ ]] && [ "$radius" -ge 1 ] && [ "$radius" -le 100 ]; then
        break
    else
        echo "Por favor, ingrese un número válido entre 1 y 100"
    fi
done

echo -e "\nUsando un radio de redondeo del $radius%"

# Contar total de archivos a procesar
total_files=$(ls -1 *.png | wc -l)
echo "Total de archivos a procesar: $total_files"

# Crear directorio para las imágenes procesadas si no existe
mkdir -p rounded_images

# Función para procesar una imagen
process_image() {
    local input="$1"
    local output="rounded_images/$1"

    echo -n "Procesando ($((processed + 1))/$total_files): $input... "
    convert "$input" \
        -alpha set \
        \( +clone -alpha extract \
        -draw "fill black polygon 0,0 0,$radius $radius,0 fill white circle $radius,$radius $radius,0" \
        \( +clone -flip \) -compose Multiply -composite \
        \( +clone -flop \) -compose Multiply -composite \) \
        -alpha off -compose CopyOpacity -composite \
        -background none \
        "$output" && echo "✓" || echo "❌"

    ((processed++))
}

# Procesar todas las imágenes PNG
for img in *.png; do
    process_image "$img"
done

echo -e "\n¡Proceso completado!"
echo "Total de imágenes procesadas: $processed"
echo "Radio de redondeo utilizado: $radius%"
echo "Las imágenes procesadas se encuentran en el directorio 'rounded_images/'"
