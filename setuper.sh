#!/bin/bash

# Текстовая запись для баннера

banner_text1="\e[31m╔═╗╔═╗╔╦╗╦ ╦╔═╗╔═╗╦═╗\e[0m"
banner_text2="\e[31m╚═╗║╣  ║ ║ ║╠═╝║╣ ╠╦╝\e[0m"
banner_text3="\e[31m╚═╝╚═╝ ╩ ╚═╝╩  ╚═╝╩╚═\e[0m"

# Коды цветов
RD="\e[31mRD\e[0m"
GR="\e[32mGR\e[0m"
RST="\e[0m"

# Настройка SSH
#
setup_ssh(){
    echo "По умолчанию SSH работает на порту 22, это не безопасно, рано или поздно его кто-то попробует перебрать."
    read -p "Хотите ли вы его изменить? (1-yes/2-no): " change_port

    if [ "$change_port" = "1" ]; then
        read -p "Введите новый порт для SSH: " new_port

        # Проверяем, занят ли введенный порт
        if sudo netstat -tuln | grep ":$new_port\b" >/dev/null; then
            echo "Ошибка: Порт $new_port уже занят. Пожалуйста, попробуйте другой порт."
            return
        else
            # Внесение изменений в файл конфигурации SSH
            sudo sed -i "s/Port 22/Port $new_port/" /etc/ssh/sshd_config
            echo "Порт SSH успешно изменен на $new_port."
            sudo systemctl start sshd
            sudo systemctl enable sshd
            sudo ufw allow OpenSSH
            sudo ufw allow $new_port/tcp
            sudo ufw enable
            sudo ufw status
        fi
    else
        echo "Окей, пропустим эту настройку"
    fi
}

install_lamp(){
    sudo apt update
    sudo apt -y install tasksel
    sudo tasksel install lamp-server
    sudo systemctl status apache2
    sudo systemctl status mysql
    
}



install_python() {
    echo "Установка пакета Python (python3, pip3, flask)..."
    # Установка Python 3
    sudo apt update
    sudo apt install -y python3
    echo -e "Установка python3 - [\e[32mОК\e[0m]"
    sudo apt install -y python3-pip
    echo -e "Установка pip3 - [\e[32mОК\e[0m]"
    # Установка Flask через pip3
    sudo pip3 install Flask
    # Вывод уведомления о завершении установки пакета Python
    echo -e "Установка Flask - [\e[32mОК\e[0m]"
}

# Функция для установки Docker и Docker Compose
install_docker() {
    echo "Установка Docker и Docker Compose..."
    # Установка Docker и Docker Compose
    sudo apt update
    sudo apt install curl software-properties-common ca-certificates apt-transport-https -y
    echo -e "Установка Curl - [\e[32mОК\e[0m]"
    wget -O- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
    echo -e "Импортирование GPG-ключ - [\e[32mОК\e[0m]"
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable"| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo -e "Добавление репозиторя docker - [\e[32mОК\e[0m]"
    sudo apt update
    echo -e "\e[32mПроверка репозитория...\e[0m"
    apt-cache policy docker-ce
    sudo apt install docker-ce -y
    sudo systemctl status docker
    echo -e "Установка docker-ce - [\e[32mОК\e[0m]"
    sudo apt-get install git
    sudo git --version
    echo -e "Установка git - [\e[32mОК\e[0m]"
    sudo git clone https://github.com/docker/compose.git
    echo -e "Установка docker compose - [\e[32mОК\e[0m]"
    echo -e "\e[32mУстановка Docker и Docker compose завершена\e[0m"
}

# Функция для установки и настройки NGINX
install_nginx() {
    echo "Установка и настройка NGINX..."
    # Установка NGINX
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl enable nginx
    # Проверка статуса NGINX
    sudo service nginx status
    if sudo service nginx status | grep -q "active (running)"; then
    echo -e "Установка Nginx - [$RST$GR-OK-$GR$RST]"
    else
        echo -e "Установка Nginx - [$RST$RD-WRONG-$RD$RST]"
    fi
    sudo systemctl is-enabled nginx
    # Установка UFW
    

    # Запись информации в файл nginx.ini
    sudo tee /etc/ufw/applications.d/nginx.ini > /dev/null <<EOF
[Nginx HTTP]
title=Web Server
description=Enable NGINX HTTP traffic
ports=80/tcp

[Nginx HTTPS]
title=Web Server (HTTPS)
description=Enable NGINX HTTPS traffic
ports=443/tcp

[Nginx Full]
title=Web Server (HTTP,HTTPS)
description=Enable NGINX HTTP and HTTPS traffic
ports=80,443/tcp
EOF
    # Проверка списка доступных приложений
    sudo ufw app list
    # Проверка наличия веб-сервера в списке приложений UFW
    if sudo ufw app list | grep -q 'Web Server'; then
        echo -e "Установка приложения для NGINX в UFW - [\e[32mOK\e[0m]"
    else
        echo -e "Ошибка установки приложения для NGINX в UFW"
        #exit 1
    fi
    # Активация портов через UFW
    sudo ufw enable
    sudo ufw allow 'Nginx Full'
    sudo ufw allow 'OpenSSH'
    sudo ufw status
    # Проверка активации портов
    if sudo ufw status | grep -q '80' && sudo ufw status | grep -q '443'; then
        echo -e "Активация портов - [\e[32mOK\e[0m]"
    else
        echo -e "Ошибка активации портов"
        #exit 1
    fi
     # Создание папки для сайта
    read -p "Введите название вашего домена (без http/https/www): " site_name
    sudo mkdir -p /var/www/$site_name/html

    # Добавление индексного файла
    sudo tee /var/www/$site_name/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <title>$site_name</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>$site_name 👍🏽</h1>
</body>
</html>
EOF

    # Создание конфигурационного файла сайта
    sudo tee /etc/nginx/sites-available/$site_name.conf > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $site_name.site www.$site_name.site;
    root /var/www/$site_name/html;
    index index.html;
}
EOF

    # Создание символической ссылки на конфигурационный файл сайта
    sudo ln -s /etc/nginx/sites-available/$site_name.conf /etc/nginx/sites-enabled/

    # Проверка конфигурации NGINX
    if sudo nginx -t | grep -q "successful"; then
        echo -e "Установка $site_name - [\e[32mOK\e[0m]"
    else
        echo -e "Установка $site_name - [\e[31mNO\e[0m]"
        exit 1
    fi   
}

# Функция для установки сертификата SSL (Let's Encrypt)
install_ssl() {
    echo "Установка сертификата SSL (Let's Encrypt)..."
    echo "Список существующих виртуальных хостов:"
    if [ ! "$(ls -A /etc/nginx/sites-enabled)" ]; then
        echo "Ошибка: Нет существующих виртуальных хостов. Установите виртуальные хосты перед установкой сертификата SSL."
        exit 1
    else
        ls -la /etc/nginx/sites-enabled
    fi
    # Запрос названия виртуального хоста
    read -p "Введите название виртуального хоста из списка для установки SSL: " virtual_host
    # Проверка существования файла конфигурации виртуального хоста
    while true; do
        if [ ! -f "/etc/nginx/sites-enabled/$virtual_host" ]; then
            read -p "Ошибка: Виртуальный хост '$virtual_host' не существует. Введите название существующего виртуального хоста из списка для установки SSL (или 'E' для выхода): " virtual_host
            if [ "$virtual_host" = "E" ]; then
                echo "Прерывание..."
                exit 1
            fi
        else
            break
        fi
    done
    # Получение сертификата Let's Encrypt
    sudo certbot certonly --nginx -d $virtual_host -d www.$virtual_host
    # Проверка успешности установки сертификата
    if [ $? -eq 0 ]; then
        echo -e "Установка сертификата SSL - [\e[32mOK\e[0m]"
    else
        echo -e "Установка сертификата SSL - [\e[31mNO\e[0m]"
        exit 1
    fi

    # Создание конфигурационного файла для SSL
    sudo tee /etc/nginx/conf.d/${virtual_host}-ssl.conf > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name $virtual_host www.$virtual_host;
    access_log /var/log/nginx/${virtual_host}-ssl.access.log main;
    root /var/www/$virtual_host/public_html/;
    index index.html index.htm;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/$virtual_host/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$virtual_host/privkey.pem;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

    # Перезапуск NGINX для применения изменений
    sudo systemctl restart nginx

}

#!/bin/bash

# Проверка установки Flask
check_flask() {
    if python3 -c "import flask" >/dev/null 2>&1; then
        echo "$RST$GR-Flask установлен.-$GR$RST"
    else
        echo "\e[31mRD\e[0m-Flask не установлен.-\e[31mRD\e[0m"
    fi
}

# Проверка установки Python и pip
check_python_pip() {
    if command -v python3 >/dev/null 2>&1 && command -v pip3 >/dev/null 2>&1; then
        echo "Python и pip установлены."
    else
        echo "Python и/или pip не установлены."
    fi
}

# Проверка установки Nginx
check_nginx() {
    if command -v nginx >/dev/null 2>&1; then
        echo "Nginx установлен."
    else
        echo "Nginx не установлен."
    fi
}

# Проверка установки PHP
check_php() {
    if command -v php >/dev/null 2>&1; then
        echo "PHP установлен."
    else
        echo "PHP не установлен."
    fi
}

# Проверка установки MariaDB
check_mariadb() {
    if command -v mysql >/dev/null 2>&1; then
        echo "MariaDB установлен."
    else
        echo "MariaDB не установлен."
    fi
}

# Проверка установки PostgreSQL
check_postgresql() {
    if command -v psql >/dev/null 2>&1; then
        echo "PostgreSQL установлен."
    else
        echo "PostgreSQL не установлен."
    fi
}


basic_setup(){
    sudo apt update -y
    sudo apt upgradable 
    sudo apt install ntp
    sudo systemctl enable ntp
}

welcome_input() {
    echo "====================="
    echo -e "$banner_text1"
    echo -e "$banner_text2"
    echo -e "$banner_text3"
    echo "========МЕНЮ========="
    echo -e "                    "
    echo "1. Мастер настройки сервера"
    echo "2. Установка nextcloud"
    echo "3. Подключение домена"
    echo "4. Установка SSL сертификата Let's Encrypt"
    echo "5. Развернуть сервис (установка с github)" 
    echo -e "                    "
    echo "Выйти из скрипта - Ctrl + C" 
    echo -e "                    "
    read -p "Выберите что нужно сделать -> : " virtual_host
}


# Основная функция для выбора действия
main() {
    welcome_input
    basic_setup
    check_flask 
    check_python_pip
    check_nginx
    check_php
    check_mariadb
    check_postgresql
}

# Вызов основной функции
main
