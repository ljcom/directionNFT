npm install

npx hardhat node

npx hardhat clean
npx hardhat compile

npx hardhat run scripts/deploy.js --network localhost

npm uninstall chai
npm install --save-dev chai@4.3.7



npx hardhat run scripts/compile.js --network localhost
npx hardhat run scripts/upgrade.js --network localhost

# MockIDRT
npx hardhat run scripts/deployMockIDRT.js --network localhost

#test
npx hardhat test
npx hardhat test test/fullFlow.test.js