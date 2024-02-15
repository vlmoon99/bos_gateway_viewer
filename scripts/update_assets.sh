cd .. &&
cd assets/ &&
rm -r bos-gateway-core &&
git clone https://github.com/vlmoon99/bos-gateway-core.git &&
cd bos-gateway-core/ &&
npm install && 
npm run build-prod
