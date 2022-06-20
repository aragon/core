import {expect} from 'chai';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';
import {ethers} from 'hardhat';
import {DAO, ERC165Registry, RepoFactory} from '../../typechain';
import {customError} from '../test-utils/custom-error-helper';

const EVENTS = {
  NewRepo: 'NewRepo',
};

const zeroAddress = ethers.constants.AddressZero;

async function getRepoFactoryEvents(tx: any) {
  const data = await tx.wait();
  const {events} = data;
  const {name, repo} = events.find(
    ({event}: {event: any}) => event === EVENTS.NewRepo
  ).args;

  return {
    name,
    repo,
  };
}

describe('APM: RepoFactory: ', function () {
  let signers: SignerWithAddress[];
  let ownerAddress: string;
  let dao: DAO;
  let repoRegistry: ERC165Registry;
  let repoFactory: RepoFactory;

  before(async () => {
    signers = await ethers.getSigners();
    ownerAddress = await signers[0].getAddress();
  });

  beforeEach(async function () {
    // DAO
    const DAO = await ethers.getContractFactory('DAO');
    dao = await DAO.deploy();
    await dao.initialize('0x00', ownerAddress, ethers.constants.AddressZero);

    // deploy and initialize ERC165Registry
    const ERC165Registry = await ethers.getContractFactory('ERC165Registry');
    repoRegistry = await ERC165Registry.deploy();
    await repoRegistry.initialize(dao.address, '0x73053410'); // '0x73053410' = type(IRepo).interfaceId;

    // deploy RepoFactory
    const RepoFactory = await ethers.getContractFactory('RepoFactory');
    repoFactory = await RepoFactory.deploy(repoRegistry.address);

    // grant REGISTER_ROLE to repoFactory
    dao.grant(
      repoRegistry.address,
      repoFactory.address,
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes('REGISTER_ROLE'))
    );
  });

  it('fail to create new repo with no REGISTER_ROLE', async () => {
    dao.revoke(
      repoRegistry.address,
      repoFactory.address,
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes('REGISTER_ROLE'))
    );

    const repoName = 'my-repo';

    await expect(
      repoFactory.newRepo(repoName, ownerAddress)
    ).to.be.revertedWith(
      customError(
        'ACLAuth',
        repoRegistry.address,
        repoRegistry.address,
        repoFactory.address,
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes('REGISTER_ROLE'))
      )
    );
  });

  it('create new repo', async () => {
    const repoName = 'my-repo';

    let tx = await repoFactory.newRepo(repoName, ownerAddress);

    const {name, repo} = await getRepoFactoryEvents(tx);

    expect(name).to.equal(repoName);
    expect(repo).not.undefined;
  });

  it('fail creating new repo with wrong major version', async () => {
    const repoName = 'my-repo';
    const initialSemanticVersion: [number, number, number] = [0, 0, 0];
    const pluginFactoryAddress = zeroAddress;
    const contentURI = '0x00';

    await expect(
      repoFactory.newRepoWithVersion(
        repoName,
        initialSemanticVersion,
        pluginFactoryAddress,
        contentURI,
        ownerAddress
      )
    ).to.be.revertedWith(customError('InvalidBump'));
  });

  it('create new repo with version', async () => {
    const repoName = 'my-repo';
    const initialSemanticVersion: [number, number, number] = [1, 0, 0];
    const pluginFactoryAddress = zeroAddress;
    const contentURI = '0x00';

    let tx = await repoFactory.newRepoWithVersion(
      repoName,
      initialSemanticVersion,
      pluginFactoryAddress,
      contentURI,
      ownerAddress
    );

    const {name, repo} = await getRepoFactoryEvents(tx);

    expect(name).to.equal(repoName);
    expect(repo).not.undefined;
  });
});
