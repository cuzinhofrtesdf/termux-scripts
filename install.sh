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

    local fake_nanos=$(shuf -i 100000000-999999999 -n 1)
    local access_date mtime_date change_date

    if [[ "$target" == *"/MReplays"* && -d "$target" ]]; then
        local latest_epoch=0
        local file latest_datetime

        for file in "$target"/*; do
            if [[ -f "$file" && "$file" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2})-([0-9]{2})-([0-9]{2}) ]]; then
                local dt="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}:${BASH_REMATCH[3]}:${BASH_REMATCH[4]}"
                local epoch=$(date -d "$dt" +%s 2>/dev/null)
                if (( epoch > latest_epoch )); then
                    latest_epoch=$epoch
                    latest_datetime="$dt"
                fi
            fi
        done

        if [[ -z "$latest_datetime" ]]; then
            latest_datetime=$(date '+%Y-%m-%d %H:%M:%S')
        fi

        mtime_date="$latest_datetime"
        change_date="$latest_datetime"
        access_date=$(date -d "$latest_datetime - 5 minutes" '+%Y-%m-%d %H:%M:%S')

        for file in "$target"/*; do
            if [ -f "$file" ]; then
                echo "  File: $file"
                echo "  Size: $(stat -c %s "$file")        Blocks: 8          IO Block: 4096   regular file"
                echo "Device: 00h/00d    Inode: 22334455   Links: 1"
                printf "Access: %s.%09d\n" "$mtime_date" "$fake_nanos"
                printf "Modify: %s.%09d\n" "$mtime_date" "$fake_nanos"
                printf "Change: %s.%09d\n" "$mtime_date" "$fake_nanos"
                echo "----------------------------------"
            fi
        done

        echo "  File: $target"
        echo "  Size: $(du -sb "$target" | cut -f1)        Blocks: 8          IO Block: 4096   directory"
        echo "Device: 00h/00d    Inode: 12345678   Links: 2"
        printf "Access: %s.%09d\n" "$access_date" "$fake_nanos"
        printf "Modify: %s.%09d\n" "$mtime_date" "$fake_nanos"
        printf "Change: %s.%09d\n" "$mtime_date" "$fake_nanos"
        return 0
    fi

    # Fallback pra qualquer outro arquivo fora do MReplays
    local full_atime full_mtime full_ctime
    full_atime=$(/system/bin/stat -c '%x' "$target") || return $?
    full_mtime=$(/system/bin/stat -c '%y' "$target") || return $?
    full_ctime=$(/system/bin/stat -c '%z' "$target") || return $?

    local short_atime="${full_atime%.*}"
    local short_mtime="${full_mtime%.*}"
    local short_ctime="${full_ctime%.*}"

    echo "  File: $target"
    echo "  Size: $(stat -c %s "$target")        Blocks: 1          IO Block: 4096   $(stat -c %F "$target")"
    echo "Device: 00h/00d    Inode: 99887766   Links: 1"
    printf "Access: %s.%09d\n" "$short_atime" "$fake_nanos"
    printf "Modify: %s.%09d\n" "$short_mtime" "$fake_nanos"
    printf "Change: %s.%09d\n" "$short_ctime" "$fake_nanos"
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
