#!/bin/bash

cd /home/vagrant

echo "======= yum update ======="
sudo yum -y update >> upstart.log 2>&1

echo "======= install git, yum-utils, gcc ======="
sudo yum -y install git yum-utils gcc >> upstart.log 2>&1

echo "======= groupinstall development ======="
sudo yum -y groupinstall development >> upstart.log 2>&1

# Inline with Upstream Stable
# https://ius.io/
# "IUS is a community project that provides RPM packages for newer 
# versions of select software for Enterprise Linux distributions."
echo "======= install IUS ======="
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm >> upstart.log 2>&1

echo "======= install python36u, -pip and -devel ======="
sudo yum -y install python36u python36u-pip python36u-devel >> upstart.log 2>&1

echo "======= install nginx, ufw ======="
sudo yum -y install nginx ufw >> upstart.log 2>&1

echo "======= check status of nginx service ======="
systemctl status nginx >> upstart.log 2>&1

echo "======= yum update ======="
sudo yum -y update >> upstart.log 2>&1

echo "======= clone mwsu-schedule-api project ======="
git clone https://github.com/spenfraz/mwsu-schedule-api.git >> upstart.log 2>&1

echo "======= cd into project directory ======="
cd mwsu-schedule-api/ >> upstart.log 2>&1

#  replace app.run(debug=True) with app.run(host='0.0.0.0' in routes.py
sed -i "s/    app.run(debug=True)/    app.run(host=\'0.0.0.0\')/g" routes.py >> upstart.log 2>&1

echo "======= create python3.6 virtual environment ======="
python3.6 -m venv venv >> upstart.log 2>&1

echo "======= activate virtual environment ======="
source venv/bin/activate >> upstart.log 2>&1

echo "======= install from requirements.txt ======="
pip install -r requirements.txt >> upstart.log 2>&1

echo "======= install gunicorn ======="
pip install gunicorn >> upstart.log 2>&1

echo "======= create wsgi.py (WSGI entry point) ======="
cat > wsgi.py << EOF | >> upstart.log 2>&1
from routes import app as application

if __name__ == "__main__":
    application.run()
EOF

echo "======= create mwsu-schedule-api systemd service unit file ======="
cat << EOF | sudo tee /etc/systemd/system/mwsu-schedule-api.service >> upstart.log 2>&1
[Unit]
Description=Gunicorn instance to serve mwsu-schedule-api
After=network.target

[Service]
User=vagrant
Group=nginx
WorkingDirectory=/home/vagrant/mwsu-schedule-api
Environment="PATH=/home/vagrant/mwsu-schedule-api/venv/bin"
ExecStart=/home/vagrant/mwsu-schedule-api/venv/bin/gunicorn --workers 3 --bind unix:mwsu-schedule-api.socket -m 007 wsgi

[Install]
WantedBy=multi-user.target
EOF

echo "======= start and enable mwsu-schedule-api.service ======="
sudo systemctl start mwsu-schedule-api >> upstart.log 2>&1
sudo systemctl enable mwsu-schedule-api >> upstart.log 2>&1
sudo systemctl status mwsu-schedule-api >> upstart.log 2>&1

echo "======= remove all "default_server" from /etc/nginx/nginx.conf ======="
sudo sed -i -e 's/default_server//g' /etc/nginx/nginx.conf

echo "======= create config heredoc /etc/nginx/nginx.conf ======="
cat > /tmp/nginx.conf.edit << EOF
    include /etc/nginx/conf.d/*.conf;

    server {
        listen 80 default_server;
        server_name $(curl icanhazip.com >> upstart.log 2>&1):80 default_server;

        location / {
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_pass http://unix:/home/vagrant/mwsu-schedule-api/mwsu-schedule-api.socket;
        }
    }
EOF

# Replace "include /etc/nginx/conf.d/*.conf" with contents of /tmp/nginx.conf.edit ======="
sudo sed -i "/include \/etc\/nginx\/conf\.d\/\*\.conf;/ {
    r /tmp/nginx.conf.edit
    d
    }" /etc/nginx/nginx.conf

echo "======= remove /tmp/nginx.conf.edit ======="
rm /tmp/nginx.conf.edit

echo "======= add nginx user to vagrant group ======="
sudo usermod -a -G vagrant nginx

echo "======= give vagrant execute permissions on home ======="
chmod 710 /home/vagrant

echo "======= make SELinux happy ======="
sudo yum -y install policycoreutils-python >> upstart.log 2>&1
sudo semanage permissive -a httpd_t >> upstart.log 2>&1

echo "======= check nginx config file ======="
sudo nginx -t >> upstart.log 2>&1

echo "======= start and enable nginx ======="
sudo systemctl start nginx >> upstart.log 2>&1
sudo systemctl enable nginx >> upstart.log 2>&1
