# Changing the APT sources.list to kambing.ui.ac.id
sudo cp '/vagrant/sources.list' '/etc/apt/sources.list'

# Updating the repo with the new sources
sudo apt-get update -y

sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'

wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

sudo apt-get update -y
sudo apt-get install apt-transport-https -y
sudo apt-get update -y
sudo apt-get install dotnet-sdk-2.2 -y


wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

sudo apt-get update -y
sudo apt-get install apt-transport-https -y
sudo apt-get update -y
sudo apt-get install aspnetcore-runtime-2.2 -y

curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install nodejs -y

mkdir /home/vagrant/projects
cd /home/vagrant/projects
git clone https://github.com/adisazhar123/dotnet-core-reactredux-blog.git
cd /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa

dotnet restore /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa
npm install /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/ClientApp

sudo rm -r /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/wwwroot/Storage
sudo ln -s /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/Storage /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/wwwroot
dotnet publish --configuration Release
mkdir /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/bin/Release/netcoreapp2.2/publish/Storage
mkdir /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/bin/Release/netcoreapp2.2/publish/Storage/Uploads
sudo chown www-data:www-data -R /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/bin/Release/netcoreapp2.2/publish/Storage/Uploads

sudo mkdir /var/www/AdisBlog
sudo ln -s /home/vagrant/projects/dotnet-core-reactredux-blog/src/App/Spa/bin/Release/netcoreapp2.2/publish /var/www/AdisBlog

sudo cp /vagrant/adisblog /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/adisblog /etc/nginx/sites-enabled
sudo rm /etc/nginx/sites-enabled/default

sudo cp /vagrant/kestrel-adisblog.service /etc/systemd/system
sudo systemctl enable kestrel-adisblog.service
sudo systemctl start kestrel-adisblog.service
