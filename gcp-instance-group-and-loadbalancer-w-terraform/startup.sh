#!/bin/bash
apt update -y
apt-get update -y
apt-get install nfs-common -y
apt install unzip -y
apt install apache2 \
    ghostscript \
    libapache2-mod-php \
    mysql-server \
    php \
    php-bcmath \
    php-curl \
    php-imagick \
    php-intl \
    php-json \
    php-mbstring \
    php-mysql \
    php-xml \
    php-zip -y

mkdir -p /srv/www/wordpress/wp-content
chown -R www-data: /srv/*
sudo mount ${FLSTIP}:/${FLSTNAME} /srv/www/wordpress/wp-content
echo -e "${FLSTIP}:/${FLSTNAME} /srv/www/wordpress/wp-content nfs defaults,_netdev 0 0" >> /etc/fstab
sudo chmod go+rw /srv/www/wordpress/wp-content
#curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www
cd /home/thedoctor
wget https://github.com/mehmetafsar510/aws_devops/raw/master/teamwork-agendas/dms.zip
unzip dms.zip
mysql -h "${MYDBURI}" -u ${DBUSER} -p${DBPASSWORD} ${DBNAME} < datamigration.sql
cd /home/thedoctor/html
cp * -R /srv/www/wordpress/
chown -R www-data: /srv/*
sudo chmod go+rw /srv/www/wordpress/wp-content

cat << EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF
a2ensite wordpress
a2enmod rewrite
a2dissite 000-default
service apache2 reload
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/database_name_here/${DBNAME}/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/username_here/${DBUSER}/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/password_here/${DBPASSWORD}/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/localhost/${MYDBURI}/' /srv/www/wordpress/wp-config.php
sudo service apache2 restart

cat >> /home/thedoctor/update_wp_ip.sh<< 'EOF'
#!/bin/bash
source <(php -r 'require("/srv/www/wordpress/wp-config.php"); echo("DB_NAME=".DB_NAME."; DB_USER=".DB_USER."; DB_PASSWORD=".DB_PASSWORD."; DB_HOST=".DB_HOST); ')
SQL_COMMAND="mysql -u $DB_USER -h $DB_HOST -p$DB_PASSWORD $DB_NAME -e"
OLD_URL=$(mysql -u $DB_NAME -h $DB_HOST -p$DB_PASSWORD $DB_NAME -e 'select option_value from wp_options where option_id = 1;' | grep http)
ALBDNSNAME=${ALBDNSNAME}
                 
$SQL_COMMAND "UPDATE wp_options SET option_value = replace(option_value, '$OLD_URL', 'https://$ALBDNSNAME') WHERE option_name = 'home' OR option_name = 'siteurl';"
$SQL_COMMAND "UPDATE wp_posts SET guid = replace(guid, '$OLD_URL','https://$ALBDNSNAME');"
$SQL_COMMAND "UPDATE wp_posts SET post_content = replace(post_content, '$OLD_URL', 'https://$ALBDNSNAME');"
$SQL_COMMAND "UPDATE wp_postmeta SET meta_value = replace(meta_value,'$OLD_URL','https://$ALBDNSNAME');"
EOF

chmod 755 /home/thedoctor/update_wp_ip.sh
/home/thedoctor/update_wp_ip.sh