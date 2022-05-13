const fs = require('fs/promises');
const fetch = require('node-fetch');
const path = require('path');
const IPFS = require('ipfs-http-client');
const {ethers} = require('ethers');
const networks = require('../../../../packages/contracts/networks.json');
const Erc20VotingJson = require('../../../../packages/contracts/artifacts/contracts/votings/ERC20/ERC20Voting.sol/ERC20Voting.json');
const WhiteVotingJson = require('../../../../packages/contracts/artifacts/contracts/votings/whitelist/WhitelistVoting.sol/WhitelistVoting.json');
const ERC156Json = require('../../../../packages/contracts/artifacts/contracts/core/erc165/ERC165.sol/ERC165.json');
const dummyDaos = require('../../../../dummy_daos.json');
const gas = require('./estimateGas');
const parseArgs = require('minimist');

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

async function proposal() {
  console.log('\n=== Staring A Proposal on a DAO ===');

  const args = parseArgs(process.argv.slice(2));

  const daoJsonKey = args.daoKey;
  const networkName = args.network;
  const privKey = args.privKey;

  const provider = new ethers.providers.JsonRpcProvider(
    networkName === 'localhost'
      ? 'http://127.0.0.1:8545'
      : networks[networkName].url
  );
  const signer = new ethers.Wallet(privKey, provider);

  const daoAddress = dummyDaos[networkName][daoJsonKey].address;
  const votingAddress = dummyDaos[networkName][daoJsonKey].packages[0];

  console.log('votingAddresses', votingAddress);

  // metadata
  const metaObj = {
    name: 'Dummy Proposal',
    description: 'Dummy withdraw proposal for QA and testing purposes...',
    links: [
      {label: 'link01', url: 'https://link.01'},
      {label: 'link02', url: 'https://link.02'},
    ],
  };
  const client = IPFS.create('https://ipfs.infura.io:5001/api/v0');
  const cid = await client.add(JSON.stringify(metaObj));

  console.log('ipfs cid', cid.path);

  let metadata = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(cid.path));

  // action
  // get one of the deposits
  const dummyDAOFile = await fs.readFile(path.join('./', 'dummy_daos.json'));
  let content = JSON.parse(dummyDAOFile.toString());

  const deposits = content[networkName][daoJsonKey].deposits;

  const deposit = deposits[getRandomInt(deposits.length)];

  // prepare action
  let ABI = [
    'function withdraw(address _token, address _to, uint256 _amount, string _reference)',
  ];
  let iface = new ethers.utils.Interface(ABI);
  let encoded = iface.encodeFunctionData('withdraw', [
    deposit.token,
    signer.address,
    ethers.utils.parseEther(deposit.amount),
    'withdrawing from dao to:' + signer.address,
  ]);

  const actions = [[daoAddress, '0', encoded]];

  let overrides = await gas.setGasOverride(provider);

  // get voting type via interface
  erc165 = new ethers.Contract(votingAddress, ERC156Json.abi, signer);

  const isERC20Voting = await erc165.supportsInterface('0x27a0eec0');

  console.log('isERC20Voting', isERC20Voting);

  // initiate Voting contract
  let VotingContract;
  if (isERC20Voting) {
    VotingContract = new ethers.Contract(
      votingAddress,
      Erc20VotingJson.abi,
      signer
    );
  } else {
    VotingContract = new ethers.Contract(
      votingAddress,
      WhiteVotingJson.abi,
      signer
    );
  }

  let proposalTx = await VotingContract.newVote(
    metadata,
    actions,
    0,
    0,
    true,
    2,
    overrides
  ); // vote Yea and execute

  await proposalTx.wait();

  const resultObj = {
    proposalTx: proposalTx.hash,
    metadata: metaObj,
    dao: daoAddress,
  };

  console.log('writing results:', resultObj, 'to file.', '\n');

  // edit or add property
  if (!content[networkName][daoJsonKey].proposal) {
    content[networkName][daoJsonKey].proposal = {};
  }
  content[networkName][daoJsonKey].proposal = resultObj;
  //write file
  await fs.writeFile(
    path.join('./', 'dummy_daos.json'),
    JSON.stringify(content, null, 2)
  );

  console.log('!Done');
}

proposal()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
