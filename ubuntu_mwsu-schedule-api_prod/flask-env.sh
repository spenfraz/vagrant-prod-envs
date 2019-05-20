#!/bin/bash

cd /home/vagrant

echo "======= apt-get update ======="
sudo apt-get update >> upstart.log 2>&1

echo "======= install nginx ======="
sudo apt-get -y install nginx >> upstart.log 2>&1

echo "======= check status of nginx service ======="
systemctl status nginx >> upstart.log 2>&1

echo "======= check (ufw) firewall ======"
sudo ufw app list >> upstart.log 2>&1

echo "======= ufw allow Nginx Full ======="
sudo ufw allow 'Nginx Full' >> upstart.log 2>&1

echo "======= enable ufw ======="
echo "y" | sudo ufw enable >> upstart.log 2>&1

echo "======= ufw allow port 22 ======="
sudo ufw allow 22 >> upstart.log 2>&1

echo "======= apt-get update ======="
sudo apt-get update >> upstart.log 2>&1

echo "======= install python3 -pip, -dev, -setuptools & other dev libraries ======="
sudo apt-get -y install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools >> upstart.log 2>&1

echo "======= install python3 virtualenvironment ========"
sudo apt-get -y install python3-venv >> upstart.log 2>&1

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
from routes import app

if __name__ == "__main__":
    app.run()
EOF

echo "======= create mwsu-schedule-api systemd service unit file ======="
cat << EOF | sudo tee /etc/systemd/system/mwsu-schedule-api.service >> upstart.log 2>&1
[Unit]
Description=Gunicorn instance to serve mwsu-schedule-api
After=network.target

[Service]
User=vagrant
Group=www-data
WorkingDirectory=/home/vagrant/mwsu-schedule-api
Environment="PATH=/home/vagrant/mwsu-schedule-api/venv/bin"
ExecStart=/home/vagrant/mwsu-schedule-api/venv/bin/gunicorn --workers 3 --bind unix:mwsu-schedule-api.socket -m 007 wsgi:app

[Install]
WantedBy=multi-user.target
EOF

echo "======= start and enable mwsu-schedule-api.service ======="
sudo systemctl start mwsu-schedule-api >> upstart.log 2>&1
sudo systemctl enable mwsu-schedule-api >> upstart.log 2>&1
sudo systemctl status mwsu-schedule-api >> upstart.log 2>&1

echo "======= create configuration file (Nginx pass web requests to socket) ======="
cat << EOF | sudo tee /etc/nginx/sites-available/mwsu-schedule-api >> upstart.log 2>&1
server {
    listen 80;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/vagrant/mwsu-schedule-api/mwsu-schedule-api.socket;
    }
}
EOF

echo "======= remove /etc/nginx/sites-enabled/default ======="
sudo rm /etc/nginx/sites-enabled/default >> upstart.log 2>&1

echo "======= link configuration file to the sites-enabled directory ======="
sudo ln -s /etc/nginx/sites-available/mwsu-schedule-api /etc/nginx/sites-enabled >> upstart.log 2>&1

echo "======= check nginx config file ======="
sudo nginx -t >> upstart.log 2>&1

echo "======= restart nginx ======="
sudo systemctl restart nginx >> upstart.log 2>&1