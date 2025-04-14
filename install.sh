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
    target="$1"

    mrep_base="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"

    # Se o alvo for um arquivo dentro da MReplays
    if [[ "$target" == "$mrep_base/"* && -f "$target" ]]; then
        file_mtime=$(/system/bin/stat -c '%y' "$target")
        mtime_date=${file_mtime%.*}
        fake_nanos=$(shuf -i 100000000-999999999 -n 1)

        echo "Access: ${mtime_date}.${fake_nanos}"
        echo "Modify: ${mtime_date}.${fake_nanos}"
        echo "Change: ${mtime_date}.${fake_nanos}"
        return 0
    fi

    # Se for a pasta MReplays (sem barra ou com barra)
    if [[ "$target" == "$mrep_base" || "$target" == "$mrep_base/" ]]; then
        latest_file=$(ls -t "$mrep_base"/*.bin 2>/dev/null | head -n 1)
        if [ -n "$latest_file" ]; then
            file_mtime=$(/system/bin/stat -c '%y' "$latest_file")
            mtime_date=${file_mtime%.*}
            fake_nanos=$(shuf -i 100000000-999999999 -n 1)

            # Gera hora aleatória entre 00 e 23
            random_hour=$(shuf -i 0-23 -n 1)

            # Soma 1 dia e aplica hora aleatória
            access_date=$(date -d "$mtime_date +1 day" +"%Y-%m-%d")
            access_date="$access_date $(printf "%02d" $random_hour):$(date -d "$mtime_date" +"%M:%S")"

            echo "Access: ${access_date}.${fake_nanos}"
            echo "Modify: ${mtime_date}.${fake_nanos}"
            echo "Change: ${mtime_date}.${fake_nanos}"
            return 0
        fi
    fi

    # Chamada para o stat normal se não bater com nada acima
    /system/bin/stat "$@"
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
