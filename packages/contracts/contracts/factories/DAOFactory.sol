/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./../votings/whitelist/WhitelistVoting.sol";
import "./../votings/ERC20/ERC20Voting.sol";
import "./../tokens/GovernanceERC20.sol";
import "./../tokens/GovernanceWrappedERC20.sol";
import "./../registry/Registry.sol";
import "./../core/DAO.sol";
import "../utils/Proxy.sol";
import "../tokens/MerkleMinter.sol";
import "./TokenFactory.sol";

/// @title DAOFactory to create a DAO
/// @author Giorgi Lagidze & Samuel Furter - Aragon Association - 2022
/// @notice This contract is used to create a DAO.
contract DAOFactory {
    using Address for address;
    using Clones for address;

    error MintArrayLengthMismatch(uint256 receiversArrayLength, uint256 amountsArrayLength);

    address public erc20VotingBase;
    address public whitelistVotingBase;
    address public daoBase;

    Registry public registry;
    TokenFactory public tokenFactory;

    struct DAOConfig {
        string name;
        bytes metadata;
    }

    event DAOCreated(string name, address indexed token, address indexed voting);

    // @dev Stores the registry and token factory address and creates the base contracts required for the factory
    // @param _registry The DAO registry to register the DAO with his name
    // @param _tokenFactory The Token Factory to register tokens
    constructor(Registry _registry, TokenFactory _tokenFactory) {
        registry = _registry;
        tokenFactory = _tokenFactory;

        setupBases();
    }

    function newERC20VotingDAO(
        DAOConfig calldata _daoConfig,
        uint256[3] calldata _votingSettings,
        TokenFactory.TokenConfig calldata _tokenConfig,
        TokenFactory.MintConfig calldata _mintConfig,
        address _gsnForwarder
    ) external returns (
        DAO dao,
        ERC20Voting voting,
        ERC20VotesUpgradeable token,
        MerkleMinter minter
    ) {
        if(_mintConfig.receivers.length != _mintConfig.amounts.length)
            revert MintArrayLengthMismatch({
                receiversArrayLength: _mintConfig.receivers.length,
                amountsArrayLength: _mintConfig.amounts.length
            });

        dao = createDAO(_daoConfig, _gsnForwarder);

        // Create token and merkle minter
        dao.grant(address(dao), address(tokenFactory), dao.ROOT_ROLE());
        (token, minter) = tokenFactory.newToken(dao, _tokenConfig, _mintConfig);
        dao.revoke(address(dao), address(tokenFactory), dao.ROOT_ROLE());

        // register dao with its name and token to the registry
        // TODO: shall we add minter as well ?
        registry.register(_daoConfig.name, dao, msg.sender, address(token));

        voting = createERC20Voting(dao, token, _votingSettings);

        setDAOPermissions(dao, address(voting));

        emit DAOCreated(_daoConfig.name, address(token), address(voting));
    }

    function newWhitelistVotingDAO(
        DAOConfig calldata _daoConfig,
        uint256[3] calldata _votingSettings,
        address[] calldata _whitelistVoters,
        address _gsnForwarder
    ) external returns (DAO dao, WhitelistVoting voting) {
        dao = createDAO(_daoConfig, _gsnForwarder);

        // register dao with its name and token to the registry
        registry.register(_daoConfig.name, dao, msg.sender, address(0));

        voting = createWhitelistVoting(dao, _whitelistVoters, _votingSettings);

        setDAOPermissions(dao, address(voting));

        emit DAOCreated(_daoConfig.name, address(0), address(voting));
    }

    function createDAO(DAOConfig calldata _daoConfig, address _gsnForwarder) internal returns (DAO dao) {
        // create dao
        dao = DAO(createProxy(daoBase, bytes("")));
        // initialize dao with the ROOT_ROLE as DAOFactory
        dao.initialize(_daoConfig.metadata, address(this), _gsnForwarder);
    }

    function setDAOPermissions(DAO dao, address voting) internal {
        // set roles on the dao itself.
        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](7);

        // Grant DAO all the permissions required
        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, dao.DAO_CONFIG_ROLE(), address(dao));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, dao.WITHDRAW_ROLE(), address(dao));
        items[2] = ACLData.BulkItem(ACLData.BulkOp.Grant, dao.UPGRADE_ROLE(), address(dao));
        items[3] = ACLData.BulkItem(ACLData.BulkOp.Grant, dao.ROOT_ROLE(), address(dao));
        items[4] = ACLData.BulkItem(ACLData.BulkOp.Grant, dao.SET_SIGNATURE_VALIDATOR_ROLE(), address(dao));
        items[5] = ACLData.BulkItem(ACLData.BulkOp.Grant, dao.EXEC_ROLE(), voting);

        // Revoke permissions from factory
        items[6] = ACLData.BulkItem(ACLData.BulkOp.Revoke, dao.ROOT_ROLE(), address(this));

        dao.bulk(address(dao), items);
    }

    /// @dev internal helper method to create ERC20Voting
    function createERC20Voting(
        DAO _dao, 
        ERC20VotesUpgradeable _token, 
        uint256[3] calldata _votingSettings
    ) internal returns (ERC20Voting erc20Voting) {
        erc20Voting = ERC20Voting(
            createProxy(
                erc20VotingBase,
                abi.encodeWithSelector(
                    ERC20Voting.initialize.selector,
                    _dao,
                    address(0),
                    _votingSettings[0],
                    _votingSettings[1],
                    _votingSettings[2],
                    _token
                )
            )
        );

         // Grant dao the necessary permissions for ERC20Voting
        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](2);
        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.UPGRADE_ROLE(), address(_dao));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.MODIFY_VOTE_CONFIG(), address(_dao));

        _dao.bulk(address(erc20Voting), items);
    }

    /// @dev internal helper method to create Whitelist Voting
    function createWhitelistVoting(
        DAO _dao, 
        address[] calldata _whitelistVoters, 
        uint256[3] calldata _votingSettings
    ) internal returns (WhitelistVoting whitelistVoting) {
        whitelistVoting = WhitelistVoting(
            createProxy(
                whitelistVotingBase,
                abi.encodeWithSelector(
                    WhitelistVoting.initialize.selector,
                    _dao,
                    address(0),
                    _votingSettings[0],
                    _votingSettings[1],
                    _votingSettings[2],
                     _whitelistVoters
                )
            )
        );

        // Grant dao the necessary permissions for WhitelistVoting
        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](3);
        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, whitelistVoting.MODIFY_WHITELIST(), address(_dao));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, whitelistVoting.MODIFY_CONFIG(), address(_dao));
        items[2] = ACLData.BulkItem(ACLData.BulkOp.Grant, whitelistVoting.UPGRADE_ROLE(), address(_dao));

        _dao.bulk(address(whitelistVoting), items);
    }

    // @dev Internal helper method to set up the required base contracts on DAOFactory deployment.
    function setupBases() private {
        erc20VotingBase = address(new ERC20Voting());
        whitelistVotingBase = address(new WhitelistVoting());
        daoBase = address(new DAO());
    }
}
