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
    if [[ "$1" == "/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"  \
          || "$1" == "/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/"  \
          || "$1" == "/storage/emulated/0/Android/data/com.dts.freefireth/files"  \
          || "$1" == "/storage/emulated/0/Android/data/com.dts.freefireth/files/"  \
          || "$1" == "/storage/emulated/0/Android/data/com.dts.freefireth/" \
          || "$1" == "/storage/emulated/0/Android/data/com.dts.freefireth" ]]; then

        # Obtém os valores atualizados toda vez que a função é chamada
        atime=$(/system/bin/stat -c '%x' "$1")  # Último acesso
        mtime=$(/system/bin/stat -c '%y' "$1")  # Última modificação
        ctime=$(/system/bin/stat -c '%z' "$1")  # Última alteração de metadados

        echo "Size: $(/system/bin/stat -c '%s' "$1")            Blocks: $(/system/bin/stat -c '%b' "$1")          IO Block: $(/system/bin/stat -c '%o' "$1")   directory"
        echo "Device: $(/system/bin/stat -c '%D' "$1")    Inode: $(/system/bin/stat -c '%i' "$1")      Links: $(/system/bin/stat -c '%h' "$1")"
        echo "Access: $mtime"
        echo "Modify: $mtime"
        echo "Change: $mtime"
        return 0
    else
        /system/bin/stat "$@"
    fi
}


# Função para bloquear 'adb shell', mas simular a resposta visual com o nome real do celular
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
    elif [[ "$1" == "devices" ]]; then
        # Simula a saída do comando `adb devices`
        echo "List of devices attached"
        echo -e "$DEVICE_NAME\tdevice"
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

