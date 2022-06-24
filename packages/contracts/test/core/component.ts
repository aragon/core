import {expect} from 'chai';
import {ethers} from 'hardhat';
import {ERRORS} from '../test-utils/custom-error-helper';

import {ComponentMock, DAOMock} from '../../typechain';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

describe('Component', function () {
  let signers: SignerWithAddress[];
  let componentMock: ComponentMock;
  let daoMock: DAOMock;
  let ownerAddress: string;

  before(async () => {
    signers = await ethers.getSigners();
    ownerAddress = await signers[0].getAddress();

    const DAOMock = await ethers.getContractFactory('DAOMock');
    daoMock = await DAOMock.deploy(ownerAddress);
  });

  beforeEach(async () => {
    const ComponentMock = await ethers.getContractFactory('ComponentMock');
    componentMock = await ComponentMock.deploy();

    await componentMock.initialize(daoMock.address);
  });

  describe('Initialization', async () => {
    it('reverts if trying to re-initialize', async () => {
      await expect(
        componentMock.initialize(daoMock.address)
      ).to.be.revertedWith(ERRORS.ALREADY_INITIALIZED);
    });
  });

  describe('Context: ', async () => {
    it('returns the right message sender', async () => {
      expect(await componentMock.msgSender()).to.be.equal(ownerAddress);
    });
  });
});
