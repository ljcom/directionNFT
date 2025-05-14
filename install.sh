npm install

npx hardhat node
npx hardhat run scripts/deploy.js --network localhost
npx hardhat run scripts/compile.js --network localhost
npx hardhat run scripts/upgrade.js --network localhost
