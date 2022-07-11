// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IPermissionOracle
/// @author Aragon Association - 2021
/// @notice This interface can be implemented to support more customary permissions depending on on- or off-chain state, e.g., by querying token ownershop or a secondary oracle, respectively.
interface IPermissionOracle {
    /// @notice This method is used to check if a call is permitted.
    /// @param _where The address of the target contract.
    /// @param _who The address (EOA or contract) for which the permission are checked.
    /// @param _permissionID The permission identifier.
    /// @param _data Optional data passed to the `PermissionOracle` implementation.
    /// @return allowed Returns true if the call is permitted.
    function checkPermissions(
        address _where,
        address _who,
        bytes32 _permissionID,
        bytes calldata _data
    ) external returns (bool allowed);
}