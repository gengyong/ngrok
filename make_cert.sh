
if [ -d "./keys" ]; then
    echo "certificates exists, quit."
    exit
fi

if [ -z "$1" ]; then
    echo "usage: $0 [domain]"
    exit
fi

NGROK_DOMAIN=$1

echo "make certificate for $NGROK_DOMAIN ..."

mkdir -p keys/$NGROK_DOMAIN
cd keys/$NGROK_DOMAIN
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -out rootCA.pem \
    -days 5000 \
    -subj "/CN=$NGROK_DOMAIN" 
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
    -subj "/CN=$NGROK_DOMAIN"
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt \
    -days 5000 \
    -extfile <(printf "subjectAltName=DNS:$NGROK_DOMAIN")

cp -f rootCA.pem ../../assets/client/tls/ngrokroot.crt
cp -f server.crt ../../assets/server/tls/snakeoil.crt
cp -f server.key ../../assets/server/tls/snakeoil.key
cd -