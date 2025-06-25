git clone https://github.com/kelseyhightower/consul-on-kubernetes.git


cd consul-on-kubernetes

#为了实现Consul成员间的TLS通信，需要生成证书和私钥：
cfssl gencert -initca ca/ca-csr.json | cfssljson -bare ca


#创建Consul的TLS证书和私钥：
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca/ca-config.json \
  -profile=default \
  ca/consul-csr.json | cfssljson -bare consul


#Consul成员之间的Gossip通信通过共享加密密钥加密。执行以下命令来生成并存储一个加密密钥：
export GOSSIP_ENCRYPTION_KEY=$(openssl rand -base64 16)



#Consul集群会结合CLI参数、TLS证书和配置文件进行设置。将Gossip加密密钥和TLS证书存入Secret中：
kubectl create secret generic consul \
  --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}" \
  --from-file=ca.pem \
  --from-file=consul.pem \
  --from-file=consul-key.pem  -n consul


#将Consul服务器配置文件保存到ConfigMap：

kubectl create configmap consul --from-file=configs/server.json -n consul


#创建一个头less服务，使每个Consul成员在集群内部可访问：

kubectl create -f services/consul.yaml  -n consul


#创建Consul服务账户

kubectl apply -f serviceaccounts/consul.yaml -n consul

kubectl apply -f clusterroles/consul.yaml  -n consul


#使用StatefulSet部署一个三节点的Consul集群：

kubectl create -f statefulsets/consul.yaml -n consul


