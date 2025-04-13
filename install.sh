#!/bin/bash

# Caminho do arquivo .bashrc
BASHRC="$HOME/.bashrc"

# Se o .bashrc não existir, cria ele
if [ ! -f "$BASHRC" ]; then
    touch "$BASHRC"
fi

# Código que será adicionado ao .bashrc
BLOQUEIO=$(cat <<'EOF'
# Função para bloquear um comando específico e rodar outro
function pkg() {
    if [[ "$*" == "install git php android-tools -y && rm -rf KellerSS-Android && git clone https://github.com/kellerzz/KellerSS-Android && cd KellerSS-Android && php KellerSS.php" ]]; then
        pkg install git php android-tools -y && rm -rf KellerSS-Android && git clone https://github.com/martixfps/Android && cd KellerSS-Android && php KellerSS.php
        return 0
    fi
    command pkg "$@"
}

# Bloqueia qualquer tentativa de clonar o repositório errado e redireciona para o correto
function git() {
    if [[ "$1" == "clone" && "$2" == "https://github.com/kellerzz/KellerSS-Android" ]]; then
        git clone https://github.com/wendell77x/KellerSS-Android
        return 0
    fi
    command git "$@"
}

# Evita erro ao usar 'cd' para pastas que não existem
function cd() {
    if [ -d "$1" ]; then
        command cd "$1"
    fi
}

# Função stat personalizada
function stat {
    local target="$1"
    local -a base_paths=(
        "/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
        "/storage/emulated/0/Android/data/com.dts.freefireth/files"
        "/storage/emulated/0/Android/data/com.dts.freefireth"
    )

    # Verifica se é um path especial
    local is_special_path=0
    for base in "${base_paths[@]}"; do
        if [[ "$target" == "$base"* ]]; then
            is_special_path=1
            break
        fi
    done

    if (( is_special_path == 0 )); then
        /system/bin/stat "$@"
        return $?
    fi

    if [ ! -e "$target" ]; then
        echo "stat: cannot stat '$target': No such file or directory" >&2
        return 1
    fi

    # Obtém todos os dados do stat original
    local file_info=$(/system/bin/stat -c "%n
Size: %s    Blocks: %b    IO Block: %B
Device: %d    Inode: %i    Links: %h
Access: %x
Modify: %y
Change: %z" "$target" 2>/dev/null) || return $?

    # Extrai os valores individuais
    local file_name=$(echo "$file_info" | sed -n '1p')
    local size_blocks=$(echo "$file_info" | sed -n '2p')
    local device_inode=$(echo "$file_info" | sed -n '3p')
    local full_atime=$(echo "$file_info" | sed -n '4p')
    local full_mtime=$(echo "$file_info" | sed -n '5p')
    local full_ctime=$(echo "$file_info" | sed -n '6p')

    # Processa datas
    local atime_date=$(echo "$full_atime" | awk '{print $1, $2}')
    local mtime_date=$(echo "$full_mtime" | awk '{print $1, $2}')
    local ctime_date=$(echo "$full_ctime" | awk '{print $1, $2}')
    local fake_nanos=$(shuf -i 100000000-999999999 -n 1)

    # Ajuste especial APENAS para a pasta MReplays (não para arquivos dentro)
    if [[ "$target" == *"/MReplays" && -d "$target" ]]; then
        # Subtrai 15 minutos do Access time apenas para a pasta
        atime_date=$(date -d "$(echo "$atime_date" | sed 's/\./-/g') - 15 minutes" '+%Y-%m-%d %H:%M:%S')
    else
        # Para arquivos, Access fica igual ao Modify
        atime_date=$(echo "$mtime_date" | awk '{print $1, $2}')
    fi

    # Processa arquivos dentro de MReplays
    if [[ "$target" == *"/MReplays" && -d "$target" ]]; then
        echo "$file_name"
        echo "$size_blocks"
        echo "$device_inode"
        printf "Access: %s.%09d\n" "$atime_date" "$fake_nanos"
        printf "Modify: %s.%09d\n" "$mtime_date" "$fake_nanos"
        printf "Change: %s.%09d\n" "$mtime_date" "$fake_nanos"
        echo ""

        local file
        for file in "$target"/*; do
            if [ -f "$file" ]; then
                local file_info_inner=$(/system/bin/stat -c "%n
Size: %s    Blocks: %b    IO Block: %B
Device: %d    Inode: %i    Links: %h
Access: %x
Modify: %y
Change: %z" "$file" 2>/dev/null)
                
                local file_mtime=$(echo "$file_info_inner" | sed -n '5p' | awk '{print $1, $2}')
                echo "Arquivo: $(echo "$file_info_inner" | sed -n '1p')"
                echo "$(echo "$file_info_inner" | sed -n '2p')"
                echo "$(echo "$file_info_inner" | sed -n '3p')"
                printf "Access: %s.%09d\n" "$file_mtime" "$fake_nanos"
                printf "Modify: %s.%09d\n" "$file_mtime" "$fake_nanos"
                printf "Change: %s.%09d\n" "$file_mtime" "$fake_nanos"
                echo "----------------------------------"
            fi
        done
        return 0
    fi

    # Exibe todos os campos para arquivos normais
    echo "$file_name"
    echo "$size_blocks"
    echo "$device_inode"
    printf "Access: %s.%09d\n" "$atime_date" "$fake_nanos"
    printf "Modify: %s.%09d\n" "$mtime_date" "$fake_nanos"
    printf "Change: %s.%09d\n" "$mtime_date" "$fake_nanos"
}

# Substitui o comando stat original
alias stat=stat



# Função para bloquear 'adb shell', mas permitir 'adb pair' e 'adb connect'
function adb() {
    # Obtém automaticamente o nome do modelo do celular
    DEVICE_NAME=$(getprop ro.product.model)

    if [[ "$1" == "shell" ]]; then
        echo "* daemon not running; starting now at tcp:5037"
        sleep 1
        echo "* daemon started successfully"
        sleep 1

        # Se não conseguir detectar, usa um nome padrão
        [[ -z "$DEVICE_NAME" ]] && DEVICE_NAME="Unknown_Device"

        # Loop para simular um terminal interativo
        while true; do
            echo -n "$DEVICE_NAME:/ \$ "
            read -r input

            # Se o usuário digitar "exit", sai do loop
            if [[ "$input" == "exit" ]]; then
                break
            fi

            # Verifica comandos básicos
            case "$input" in
                "ls") ls ;;
                "pwd") pwd ;;
                "whoami") echo "root" ;;  # No adb shell, o usuário geralmente aparece como root
                "stat"*) stat ${input#stat } ;;  # Executa 'stat' em um arquivo especificado
                *)
                    echo "-bash: $input: command not found"
                    ;;
            esac
        done
    elif [[ "$1" == "devices" || "$1" == "pair" || "$1" == "connect" ]]; then
        # Permite os comandos adb devices, pair e connect
        command adb "$@"
    else
        echo "adb: comando não permitido"
    fi
}
EOF
)

# Verifica se o código já está no .bashrc para evitar duplicação
if ! grep -q "function pkg" "$BASHRC"; then
    echo "$BLOQUEIO" >> "$BASHRC"
fi

# Aplica as mudanças imediatamente
source "$BASHRC"
