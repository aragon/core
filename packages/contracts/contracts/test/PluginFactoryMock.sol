// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "../plugin/PluginFactoryBase.sol";
import "./MajorityVotingMock.sol";
import "../utils/Proxy.sol";

contract PluginFactoryMock is PluginFactoryBase {
    event NewPluginDeployed(address dao, bytes params);

    constructor() {
        basePluginAddress = address(new MajorityVotingMock());
    }

    function deploy(address _dao, bytes calldata _params)
        public
        override
        returns (address plugin, BulkPermissionsLib.Item[] memory permissions)
    {
        plugin = basePluginAddress;

        emit NewPluginDeployed(_dao, _params);
    }
}
