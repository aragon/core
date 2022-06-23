import chai, {expect} from 'chai';
import {ethers} from 'hardhat';
import chaiUtils from '../../test-utils';
import {customError} from '../../test-utils/custom-error-helper';

chai.use(chaiUtils);

import {DAO, InterfaceBasedRegistryMock} from '../../../typechain';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

const EVENTS = {
  Registered: 'Registered',
};

describe('InterfaceBasedRegistry', function () {
  let signers: SignerWithAddress[];
  let interfaceBasedRegistryMock: InterfaceBasedRegistryMock;
  let dao: DAO;
  let ownerAddress: string;

  before(async () => {
    signers = await ethers.getSigners();
    ownerAddress = await signers[0].getAddress();

    // DAO
    const DAO = await ethers.getContractFactory('DAO');
    dao = await DAO.deploy();
    await dao.initialize('0x00', ownerAddress, ethers.constants.AddressZero);
  });

  beforeEach(async () => {
    const InterfaceBasedRegistryMock = await ethers.getContractFactory(
      'InterfaceBasedRegistryMock'
    );
    interfaceBasedRegistryMock = await InterfaceBasedRegistryMock.deploy();

    await interfaceBasedRegistryMock.initialize(dao.address);

    // grant REGISTER_ROLE to registrer
    dao.grant(
      interfaceBasedRegistryMock.address,
      ownerAddress,
      ethers.utils.id('REGISTER_ROLE')
    );
  });

  describe('Register', async () => {
    it('fail if registrant address is not a contract', async function () {
      const randomAddress = await signers[8].getAddress();

      await expect(
        interfaceBasedRegistryMock.register(randomAddress)
      ).to.be.revertedWith(
        customError('ContractAddressInvalid', randomAddress)
      );
    });

    it('fail to register if interfaceId is not supported', async () => {
      const AdaptiveERC165 = await ethers.getContractFactory('AdaptiveERC165');
      let adaptiveERC165 = await AdaptiveERC165.deploy();

      await expect(
        interfaceBasedRegistryMock.register(adaptiveERC165.address)
      ).to.be.revertedWith('ContractInterfaceInvalid');
    });

    it('fail register if REGISTER_ROLE is not granted', async () => {
      dao.revoke(
        interfaceBasedRegistryMock.address,
        ownerAddress,
        ethers.utils.id('REGISTER_ROLE')
      );

      await expect(
        interfaceBasedRegistryMock.register(dao.address)
      ).to.be.revertedWith(
        customError(
          'ACLAuth',
          interfaceBasedRegistryMock.address,
          interfaceBasedRegistryMock.address,
          ownerAddress,
          ethers.utils.id('REGISTER_ROLE')
        )
      );
    });

    it('register known interface', async () => {
      // check if address is not already registered
      expect(await interfaceBasedRegistryMock.entries(dao.address)).to.equal(
        false
      );

      await expect(await interfaceBasedRegistryMock.register(dao.address))
        .to.emit(interfaceBasedRegistryMock, EVENTS.Registered)
        .withArgs(dao.address);

      expect(await interfaceBasedRegistryMock.entries(dao.address)).to.equal(
        true
      );
    });
  });
});