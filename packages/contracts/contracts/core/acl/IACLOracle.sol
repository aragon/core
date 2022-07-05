// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title The IACLOracle to have dynamic permissions
/// @author Aragon Association - 2021
/// @notice This contract used to have dynamic permissions as for example that only users with a token X can do Y.
interface IACLOracle {
    // @dev This method is used to check if a callee has the permissions for.
    // @param _where The address of the contract
    // @param _who The address of a EOA or contract to give the permissions
    // @param _permissionID The permission identifier
    // @param _data The optional data passed to the ACLOracle registered.
    // @return bool
    function checkPermissions(
        address _where,
        address _who,
        bytes32 _permissionID,
        bytes calldata _data
    ) external returns (bool allowed);
}
