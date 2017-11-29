#/bin/bash
set -e

PLAYGROUNDHOSTNAME=${1:-demo.youbpm.com}

curl -fsSL get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.15.0/docker-compose-$(uname -s)-$(uname -m)"
sudo chmod +x /usr/local/bin/docker-compose
wget https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh
bash goinstall.sh --64

GOPATH=$HOME/go
GOROOT=$HOME/.go
PATH=$PATH:$GOROOT/bin
export GOPATH
export PATH
export GOROOT

mkdir -p $HOME/go/src/github.com/play-with-docker 
cd $HOME/go/src/github.com/play-with-docker
git clone https://github.com/play-with-docker/play-with-docker.git
cd play-with-docker
go get -u github.com/golang/dep/cmd/dep
dep ensure
sudo docker swarm init 
sudo modprobe xt_ipvs
sudo docker pull  franela/dind:hybrid
mv docker-compose.yml 1.yml;envsubst < "1.yml" > "docker-compose.yml";rm 1.yml
sed -i  's/- .\/haproxy/- \/home\/ubuntu\/go\/src\/github.com\/play-with-docker\/play-with-docker\/haproxy/g' docker-compose.yml
sed -i "s/\/pwd\/sessions -name l2/\/pwd\/sessions -name l2 -playground-domain $PLAYGROUNDHOSTNAME/g" docker-compose.yml
#change in haproxy.conf localhost to real path
sed -i "s/localhost/$PLAYGROUNDHOSTNAME/g" haproxy/haproxy.cfg
#change in docker-compose.yml ./haproxy to full path and demo.youbpm to something smart
sudo docker system prune -f
sudo docker-compose up
