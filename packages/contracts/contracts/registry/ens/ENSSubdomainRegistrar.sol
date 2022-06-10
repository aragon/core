// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "../../core/component/Component.sol";

/// @title A registrar for ENS subdomains
/// @author Aragon Association - 2022
/// @notice This contract registers ENS subdomains under a parent domain specified in the installation process.
///         This contract must either be domain node owner or be an approved operator of the node owner.
///         During the subdomain registration, the same resolver as specified in the parent domain is used.
contract ENSSubdomainRegistrar is Component {
    bytes4 internal constant REGISTRY_INTERFACE_ID = this.registerSubnode.selector;
    bytes32 public constant REGISTER_ENS_SUBDOMAIN_ROLE = keccak256("REGISTER_ENS_SUBDOMAIN_ROLE");

    ENS private ens;
    bytes32 public node;

    /// @notice Thrown if the registrar is not authorized and is neither the domain node owner
    ///         nor an approved operator of the domain node owner
    error RegistrarUnauthorized(address nodeOwner, address here);

    /// @notice Initializes the component
    /// @param _managingDao The interface of the DAO managing the components permissions
    /// @param _ens The interface of the ENS registry to be used
    /// @param _node The ENS parent domain node under which the subdomains are to be registered
    function initialize(
        IDAO _managingDao,
        ENS _ens,
        bytes32 _node
    ) external initializer {
        address nodeOwner = _ens.owner(_node);

        // This contract must either be the domain node owner or be an approved operator of the node owner
        if (nodeOwner != address(this) && !_ens.isApprovedForAll(nodeOwner, address(this)))
            revert RegistrarUnauthorized({nodeOwner: nodeOwner, here: address(this)});

        _registerStandard(REGISTRY_INTERFACE_ID);

        __Component_init(_managingDao);

        ens = _ens;
        node = _node;
    }

    /// @notice Registers a new subdomain and gives ownership to the specified address
    /// @param _label The labelhash of the subdomain name
    /// @param _owner The address of the new subdomain owner
    function registerSubnode(bytes32 _label, address _owner)
        external
        auth(REGISTER_ENS_SUBDOMAIN_ROLE)
    {
        ens.setSubnodeRecord(node, _label, _owner, ens.resolver(node), 0);
    }
}
