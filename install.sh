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
    target="${1%/}"  # Remove barra final se existir
    
    # Caminho exato da pasta MReplays
    MREPLAYS_PATH="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
    
    # 1. Se for a pasta MReplays (caminho exato)
    if [[ "$target" == "$MREPLAYS_PATH" ]]; then
        # Encontra o arquivo mais recente na pasta
        latest_file=$(ls -t "$MREPLAYS_PATH" | head -n 1)
        
        if [[ -n "$latest_file" ]]; then
            # Pega o mtime do arquivo mais recente
            file_mtime=$(/system/bin/stat -c '%y' "$MREPLAYS_PATH/$latest_file")
            modify_time="${file_mtime%.*}.738291465 +0000"
        else
            modify_time="2023-10-15 14:22:00.738291465 +0000"
        fi
        
        echo "  File: '$target'"
        echo "  Size: $(/system/bin/stat -c '%s' "$target")    Blocks: $(/system/bin/stat -c '%b' "$target")"
        echo "Access: 2025-04-04 18:33:00.456156912 +0000"  # Fixo
        echo "Modify: $modify_time"  # Igual ao arquivo mais recente
        echo "Change: $modify_time"  # Igual ao arquivo mais recente
        return 0
    fi
    
    # 2. Se for arquivo DENTRO de MReplays
    if [[ "$target" == "$MREPLAYS_PATH"/* ]]; then
        # Pega os timestamps REAIS do arquivo
        real_mtime=$(/system/bin/stat -c '%y' "$target")
        real_atime=$(/system/bin/stat -c '%x' "$target")
        real_ctime=$(/system/bin/stat -c '%z' "$target")
        
        echo "  File: '$target'"
        echo "  Size: $(/system/bin/stat -c '%s' "$target")    Blocks: $(/system/bin/stat -c '%b' "$target")"
        echo "Access: ${real_mtime%.*}.123456789 +0000"
        echo "Modify: ${real_mtime%.*}.123456789 +0000"
        echo "Change: ${real_mtime%.*}.123456789 +0000"
        return 0
    fi
    
    # 3. Para qualquer outro arquivo/pasta, mostra stat normal
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
