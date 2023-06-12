#!/bin/bash
####################### install aws cli
AccessKey='AKIA4PZTVEZPNB5I42WJ'
SecretKey='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'
sudo apt-get update
sudo apt-get install -y awscli
aws configure set aws_access_key_id "$AccessKey"
aws configure set aws_secret_access_key "$SecretKey"
######################### Parameters

BaseUrl=$(aws cloudformation list-exports --query "Exports[?Name=='magento-alb-ALBEndpoint'].Value" --output text --region eu-central-1)
DBHost=$(aws cloudformation list-exports --query "Exports[?Name=='magento-rds-DBEndpoint'].Value" --output text --region eu-central-1)
DBName=$(aws cloudformation list-exports --query "Exports[?Name=='magento-rds-DBMasterUsername'].Value" --output text --region eu-central-1)
DBPassword=$(aws cloudformation list-exports --query "Exports[?Name=='magento-rds-DBMasterUserPassword'].Value" --output text --region eu-central-1)
AdminUser=$(aws cloudformation list-exports --query "Exports[?Name=='magento-rds-DBMasterUsername'].Value" --output text --region eu-central-1)
AdminPassword=$(aws cloudformation list-exports --query "Exports[?Name=='magento-rds-DBMasterUserPassword'].Value" --output text --region eu-central-1)
EsHost=$(aws cloudformation list-exports --query "Exports[?Name=='magento-es-EsDomainEndpoint'].Value" --output text --region eu-central-1)
EsPort=443
EsUser=$(aws cloudformation list-exports --query "Exports[?Name=='magento-es-EsMasterUsername'].Value" --output text --region eu-central-1)
EsPassword=$(aws cloudformation list-exports --query "Exports[?Name=='magento-es-EsMasterUserPassword'].Value" --output text --region eu-central-1)
RedisServer=$(aws cloudformation list-exports --query "Exports[?Name=='magento-ec-ElastiCachePrimaryEndpoint'].Value" --output text --region eu-central-1)
RedisPort=$(aws cloudformation list-exports --query "Exports[?Name=='magento-ec-ElastiCacheClusterPort'].Value" --output text --region eu-central-1)
#BucketName='webkul-s3extension'
Region='eu-central-1'
PublicKey='49d1c54d206e19340755129627d96bf6'
PrivateKey='db060a47cee75868043aa97359427ccf'

#################### Update and install Apache
sudo apt update
sudo apt install apache2 -y
######################### Check Apache version and enable it
systemctl is-enabled apache2

####################### Install MySQL and configure root user
sudo apt install mysql-server -y
#sudo mysql -e "SELECT user,authentication_string,plugin,host FROM mysql.user;"
#sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '{DBPassword}';"
#sudo mysql -e "SELECT user,authentication_string,plugin,host FROM mysql.user;"

#sudo mysql -u root -p${DBPassword} -e "SELECT user,authentication_string,plugin,host FROM mysql.user;"
#sudo mysql -u root -p${DBPassword} -e "CREATE USER 'magento2'@'localhost' IDENTIFIED BY '{DBPassword}';"
#sudo mysql -u root -p${DBPassword} -e "ALTER USER 'magento2'@'localhost' IDENTIFIED WITH mysql_native_password BY '{DBPassword}';"
#sudo mysql -u root -p${DBPassword} -e "GRANT ALL PRIVILEGES ON *.* TO 'magento2'@'localhost' WITH GRANT OPTION;"
#sudo mysql -u root -p${DBPassword} -e "SELECT user,authentication_string,plugin,host FROM mysql.user;"
#sudo mysql -u magento2 -p${DBPassword} -e "CREATE DATABASE magento2;"
############### configure RDS mysql server
sudo mysql -u ${DBName} -p${DBPassword} --host ${DBHost} -e "CREATE DATABASE magento2;"

################## Update and install PHP 7.4
sudo apt update
sudo apt install php7.4 libapache2-mod-php php-mysql -y
######################## Replace index.html with index.php and vice versa
sudo sed -i 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.cgi index.pl index.html index.xhtml index.htm/g' /etc/apache2/mods-enabled/dir.conf
########################" Install required PHP modules
sudo apt install php7.4-mbstring -y
sudo phpenmod mbstring
sudo a2enmod rewrite
sudo apt install php7.4-bcmath php7.4-intl php7.4-soap php7.4-zip php7.4-gd php7.4-json php7.4-curl php7.4-cli php7.4-xml php7.4-xmlrpc php7.4-gmp php7.4-common -y
sudo systemctl reload apache2
################## Update PHP configuration
sudo sed -i 's/max_execution_time = 30/max_execution_time = 18000/g' /etc/php/7.4/cli/php.ini
sudo sed -i 's/max_input_time = 60/max_input_time = 1800/g' /etc/php/7.4/cli/php.ini
sudo sed -i 's/memory_limit = -1/memory_limit = 2G/g' /etc/php/7.4/cli/php.ini

############### Install elasticsearch
#sudo apt install curl -y
#sudo curl -sSfL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --no-default-keyring --keyring=gnupg-ring:/etc/apt/trusted.gpg.d/magento.gpg --import
#sudo sh -c 'echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list'
#sudo chmod 666 /etc/apt/trusted.gpg.d/magento.gpg
#sudo apt update
#sudo apt install elasticsearch
#sudo systemctl daemon-reload
#sudo systemctl enable elasticsearch.service
#sudo systemctl start elasticsearch.service
#sudo sed -i 's/#node.name/node.name/g' /etc/elasticsearch/elasticsearch.yml
#sudo sed -i 's/#cluster.name/cluster.name/g' /etc/elasticsearch/elasticsearch.yml
#sudo sed -i 's/#network.host: 192.168.0.1/network.host: 127.0.0.1/g' /etc/elasticsearch/elasticsearch.yml
#sudo sed -i 's/#http.port: 9200/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml
#sudo systemctl daemon-reload
#sudo systemctl restart elasticsearch.service
#curl -X GET 'http://localhost:9200'

################### install composer
cd /var/www/html/
sudo wget https://getcomposer.org/installer -O composer-setup.php
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
composer

################# Install Magento
sudo chown -R  ubuntu:ubuntu /var/www/html/
sudo -u ubuntu composer --no-interaction config --global http-basic.repo.magento.com "$PublicKey" "$PrivateKey"
sudo -u ubuntu composer create-project --no-install --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.3 magento2
cd magento2
sudo -u ubuntu composer config --global allow-plugins true
sudo -u ubuntu composer install

#################### Set directory permissions
cd /var/www/html/magento2
sudo find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
sudo find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
sudo chown -R ubuntu:www-data .
sudo chmod u+x bin/magento

################# configure magento
sudo php bin/magento setup:install --base-url=http://${BaseUrl} --db-host=${DBHost} --db-name=${DBName} --db-user=${DBName} --db-password=${DBPassword} --admin-firstname=Admin --admin-lastname=Admin --admin-email=admin@admin.com --admin-user=admin --admin-password=${DBPassword} --language=en_US --currency=USD --timezone=America/Chicago --backend-frontname=admin --search-engine=elasticsearch7 --elasticsearch-host=https://${EsHost} --elasticsearch-port=${EsPort} --elasticsearch-enable-auth=1 --elasticsearch-username=${EsUser} --elasticsearch-password=${EsPassword}


################# configure Apache
cat <<EOF | sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/magento2/pub

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory "/var/www/html">
        AllowOverride all
    </Directory>
</VirtualHost>
EOF
sudo systemctl restart apache2
sudo chmod -R 777 var pub/static generated generated/
sudo php bin/magento module:disable Magento_TwoFactorAuth

#sudo php bin/magento cache:flush
#sudo php bin/magento cache:clean

echo "***************Magento 2 setup completed.***********"

############### Install Redis
sudo apt-get install redis -y
sudo bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=${RedisServer} --page-cache-redis-port=${RedisPort} --page-cache-redis-db=1

sudo bin/magento setup:config:set --session-save=redis --session-save-redis-host=${RedisServer} --session-save-redis-port=${RedisPort} --session-save-redis-log-level=4 --session-save-redis-db=2

sudo bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=${RedisServer} --cache-backend-redis-port=${RedisPort} --cache-backend-redis-db=0

sudo php bin/magento cache:flush
sudo php bin/magento cache:clean
sudo php bin/magento setup:upgrade
sudo php bin/magento setup:di:compile

sudo php bin/magento cache:flush
sudo php bin/magento cache:clean
sudo php bin/magento indexer:reindex

echo "***************Redis setup completed.***********"

############ install s3 module
#cd
#sudo wget https://github.com/wiembk/s3-extention/archive/master.zip
#unzip master.zip
#sudo cp s3-extention-main/app /var/www/html/magento2
#cd /var/www/html/magento2
#sudo composer require aws/aws-sdk-php
#sudo php bin/magento setup:upgrade
#sudo php bin/magento setup:di:compile
#sudo php bin/magento cache:flush
#sudo php bin/magento cache:clean

echo "*************** S3 setup completed.***********"
