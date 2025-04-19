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
# Função stat personalizada
function stat {
    input="$1"

    # Normaliza caminho: remove barra final, converte /sdcard pra /storage/emulated/0
    target="${input%/}"
    if [[ "$target" == /sdcard/* ]]; then
        target="/storage/emulated/0${target#/sdcard}"
    fi

    # Caminhos base que queremos monitorar
    base_mreplays="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
    base_paths=(
        "$base_mreplays"
        "/storage/emulated/0/Android/data/com.dts.freefireth/files"
        "/storage/emulated/0/Android/data/com.dts.freefireth"
    )

    for base in "${base_paths[@]}"; do
        if [[ "$target" == "$base"* ]]; then
            if [ -e "$target" ]; then
                # Pega datas reais
                full_atime=$(/system/bin/stat -c '%x' "$target")
                full_mtime=$(/system/bin/stat -c '%y' "$target")
                full_ctime=$(/system/bin/stat -c '%z' "$target")

                atime_date=${full_atime%.*}
                mtime_date=${full_mtime%.*}
                ctime_date=${full_ctime%.*}

                # Pasta MReplays (exata)
                if [[ "$target" == "$base_mreplays" ]]; then
                    fake_atime="2025-04-04 18:33:00.456156912"
                    fake_nanos=$(shuf -i 100000000-999999999 -n 1)

                    echo "Size: $(/system/bin/stat -c '%s' "$target")    Blocks: $(/system/bin/stat -c '%b' "$target")    IO Block: $(/system/bin/stat -c '%o' "$target")"
                    echo "Device: $(/system/bin/stat -c '%D' "$target")    Inode: $(/system/bin/stat -c '%i' "$target")    Links: $(/system/bin/stat -c '%h' "$target")"
                    echo "Access: $fake_atime"
                    echo "Modify: ${mtime_date}.${fake_nanos}"
                    echo "Change: ${mtime_date}.${fake_nanos}"
                    return 0
                fi

                # Qualquer coisa DENTRO da pasta MReplays (arquivos ou subpastas)
                if [[ "$target" == "$base_mreplays/"* ]]; then
                    fake_nanos=$(shuf -i 100000000-999999999 -n 1)
                    echo "Size: $(/system/bin/stat -c '%s' "$target")    Blocks: $(/system/bin/stat -c '%b' "$target")    IO Block: $(/system/bin/stat -c '%o' "$target")"
                    echo "Device: $(/system/bin/stat -c '%D' "$target")    Inode: $(/system/bin/stat -c '%i' "$target")    Links: $(/system/bin/stat -c '%h' "$target")"
                    echo "Access: ${mtime_date}.${fake_nanos}"
                    echo "Modify: ${mtime_date}.${fake_nanos}"
                    echo "Change: ${mtime_date}.${fake_nanos}"
                    return 0
                fi

                # Outros diretórios base, exibe real
                echo "Access: $full_atime"
                echo "Modify: $full_mtime"
                echo "Change: $full_ctime"
                return 0
            fi
        fi
    done

    # Fora dos paths definidos, stat normal
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

