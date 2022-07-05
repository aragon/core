// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../core/component/Component.sol";

/// @notice A test component that manages permission to internal objects by associating their IDs with specific DAOs. Only the DAO for which the object was created has the permission to perform ID-gated actions on them.
/// @dev This is realized by asking an `IPermissionOracle` that must be authorized in the DAO's ACL.
contract TestSharedComponent is Component {
    bytes32 public constant ID_GATED_ACTION_PERMISSION_ID =
        keccak256("ID_GATED_ACTION_PERMISSION_ID");

    mapping(uint256 => IDAO) public ownedIds;

    uint256 internal _counter;

    error ObjectIdNotAssigned(uint256 _id);

    modifier sharedAuth(uint256 _id, bytes32 _permissionID) {
        if (address(ownedIds[_id]) == address(0)) {
            revert ObjectIdNotAssigned(_id);
        }

        if (!ownedIds[_id].hasPermission(address(this), _msgSender(), _permissionID, _msgData())) {
            revert PermissionLib.PermissionUnauthorized({
                here: address(this),
                where: address(this),
                who: _msgSender(),
                permissionID: _permissionID
            });
        }

        _;
    }

    function initialize(IDAO _dao) external initializer {
        __Component_init(_dao);
    }

    /// @notice Creates a new object with an ID being associated with a specific DAO
    /// @param _dao The DAO that manages permissions for the object
    /// @return id The ID that is associated with the object and the DAO
    function createNewObject(IDAO _dao) external returns (uint256 id) {
        id = _counter;
        ownedIds[id] = _dao;
        _counter++;
    }

    /// @notice Executes something if the `id` parameter is authorized by the DAO associated through `ownedIds`.
    ///         This is done by asking an `IPermissionOracle` that must be authorized in the DAO's ACL via `grantWithOracle` and the `ID_GATED_ACTION_PERMISSION_ID`.
    /// @param _id The ID that is associated with a specific DAO
    function idGatedAction(uint256 _id) external sharedAuth(_id, ID_GATED_ACTION_PERMISSION_ID) {
        // do something
    }
}

/// @notice The oracle associated with `TestSharedComponent`
contract TestIdGatingOracle is IPermissionOracle {
    uint256 public allowedId;

    constructor(uint256 _id) {
        allowedId = _id;
    }

    /// @notice Checks the calldata and expects the `id` to be the first argument of type `uint256`

    function checkPermissions(
        address _where,
        address _who,
        bytes32 _permissionID,
        bytes calldata _data
    ) external view returns (bool) {
        (_where, _who, _permissionID);

        // Security issue? Can the method be wrapped?

        // Skip the signature (the first 4 bytes) and decode the first parameter as a `uint256`
        uint256 id = abi.decode(_data[4:], (uint256));

        // let perform if the id match
        return id == allowedId;
    }
}
