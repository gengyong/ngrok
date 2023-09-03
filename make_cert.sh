
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
    -subj "/CN=$NGROK_DOMAIN" \
    -days 5000
openssl genrsa -out device.key 2048
openssl req -new -key device.key -out device.csr \
    -subj "/CN=$NGROK_DOMAIN" \
    -addext "subjectAltName = DNS:$NGROK_DOMAIN"
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt \
    -days 5000

cp -f rootCA.pem ../../assets/client/tls/ngrokroot.crt
cp -f device.crt ../../assets/server/tls/snakeoil.crt
cp -f device.key ../../assets/server/tls/snakeoil.key
cd -