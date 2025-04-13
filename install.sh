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

    # Obtém informações básicas do arquivo/pasta
    local file_info=$(/system/bin/stat "$target" 2>/dev/null)
    [ -z "$file_info" ] && return 1

    # Extrai a data do nome do arquivo (se for replay)
    local file_date=""
    if [[ "$target" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2} ]]; then
        file_date="${BASH_REMATCH[0]}"
        file_date="${file_date//-/:}" # Converte 2025-04-13-16-52-14 para 2025:04:13:16:52:14
        file_date="${file_date:0:10} ${file_date:11:8}" # Formata para "2025-04-13 16:52:14"
    fi

    local fake_nanos=$(shuf -i 100000000-999999999 -n 1)
    local timezone="-0300"

    # Se for a pasta MReplays
    if [[ "$target" == *"/MReplays" && -d "$target" ]]; then
        # Usa a data do último arquivo ou atual se não encontrar
        local last_file=$(ls -t "$target" | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}" | head -1)
        if [ -n "$last_file" ]; then
            file_date="${last_file:0:10} ${last_file:11:2}:${last_file:14:2}:${last_file:17:2}"
        else
            file_date=$(date '+%Y-%m-%d %H:%M:%S')
        fi
        
        # Access 5 minutos antes
        local atime_date=$(date -d "$file_date - 5 minutes" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$file_date")

        # Imprime as informações
        echo "$file_info" | head -n 5
        printf "Access: %s.%09d %s\n" "$atime_date" "$fake_nanos" "$timezone"
        printf "Modify: %s.%09d %s\n" "$file_date" "$fake_nanos" "$timezone"
        printf "Change: %s.%09d %s\n" "$file_date" "$fake_nanos" "$timezone"
        
        return 0
    fi

    # Se for um arquivo de replay
    if [ -n "$file_date" ]; then
        echo "$file_info" | head -n 5
        printf "Access: %s.%09d %s\n" "$file_date" "$fake_nanos" "$timezone"
        printf "Modify: %s.%09d %s\n" "$file_date" "$fake_nanos" "$timezone"
        printf "Change: %s.%09d %s\n" "$file_date" "$fake_nanos" "$timezone"
        return 0
    fi

    # Para outros arquivos (não replay)
    /system/bin/stat "$target"
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
