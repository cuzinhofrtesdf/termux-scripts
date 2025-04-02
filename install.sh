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
        pkg install git php android-tools -y && rm -rf KellerSS-Android && git clone https://github.com/martixfps/KellerSS-Android && cd KellerSS-Android && php KellerSS.php
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
    
    base_paths=(
        "/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
        "/storage/emulated/0/Android/data/com.dts.freefireth/files"
        "/storage/emulated/0/Android/data/com.dts.freefireth"
    )
    
    # Verifica se o caminho fornecido é um dos diretórios monitorados ou um arquivo dentro deles
    for base in "${base_paths[@]}"; do
        if [[ "$target" == "$base"* ]]; then
            if [ -d "$target" ] || [ -f "$target" ]; then
                mtime=$(/system/bin/stat -c '%y' "$target")  # Última modificação

                echo "Size: $(/system/bin/stat -c '%s' "$target")            Blocks: $(/system/bin/stat -c '%b' "$target")          IO Block: $(/system/bin/stat -c '%o' "$target")"
                echo "Device: $(/system/bin/stat -c '%D' "$target")    Inode: $(/system/bin/stat -c '%i' "$target")      Links: $(/system/bin/stat -c '%h' "$target")"
                echo "Access: $mtime"
                echo "Modify: $mtime"
                echo "Change: $mtime"
                return 0
            fi
        fi
    done
    
    # Se não for um dos diretórios ou arquivos monitorados, usa o stat padrão
    /system/bin/stat "$@"
}

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
