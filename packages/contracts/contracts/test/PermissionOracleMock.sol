// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../core/permission/IPermissionOracle.sol";

contract PermissionOracleMock is IPermissionOracle {
    bool internal _checkPermissionsResult = true;

    function checkPermissions(
        address, /* _where */
        address, /* _who */
        bytes32, /* _permissionID */
        bytes memory /* _data */
    ) external view returns (bool) {
        return _checkPermissionsResult;
    }

    function setWillPerform(bool _result) external {
        _checkPermissionsResult = _result;
    }
}