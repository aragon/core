import "./PluginFactoryBase.sol";
import "./IPluginRepo.sol";
import "../core/permission/IPermissionOracle.sol";
import "../core/component/Component.sol";

import "../core/IDAO.sol";

// external contract
contract GnosisMultiSig {

}

contract Helper {}

contract ExamplePlugin is Component {
    address internal gnosisMultiSig;

    bytes32 public constant X_PERMISSION_ID = keccak256("X_PERMISSION");
    bytes32 public constant Y_PERMISSION_ID = keccak256("Y_PERMISSION");

    /// @param _gnosisMultiSig An example of an external contract.
    function initialize(IDAO _dao, address _gnosisMultiSig) external {
        __Component_init(_dao);
        gnosisMultiSig = _gnosisMultiSig;
    }
}

contract ExamplePluginFactory is PluginFactoryBase {
    mapping(address => bytes32) public placeholderToName;

    /// @inheritdoc PluginFactoryBase
    function deploy(address _dao, bytes calldata _params)
        public
        override
        returns (address plugin, BulkPermissionsLib.Item[] memory permissions)
    {
        // decode params
        (uint256 processId, address gnosisMultiSig, uint256 configValue) = abi.decode(
            _params,
            (uint256, address, uint256)
        );

        if (processId == 0) {
            return _deployProcess0(_dao, gnosisMultiSig, configValue);
        } else if (processId == 1) {
            return _deployProcess1(_dao);
        } else {
            revert ProcessIdUnknown();
        }
    }

    function _deployProcess0(
        address _dao,
        address _gnosisMultiSig,
        uint256 _configValue
    ) internal returns (address plugin, BulkPermissionsLib.Item[] memory permissions) {
        // Deploy contracts
        ExamplePlugin examplePlugin = new ExamplePlugin();

        examplePlugin.initialize(IDAO(_dao), _gnosisMultiSig);
        plugin = address(examplePlugin);

        // Prepare permissions
        permissions = new BulkPermissionsLib.Item[](2);

        permissions[0] = BulkPermissionsLib.Item({
            operation: BulkPermissionsLib.Operation.Grant,
            where: _dao,
            who: plugin,
            permissionID: ExamplePlugin(plugin).X_PERMISSION_ID()
        });
        permissions[1] = BulkPermissionsLib.Item({
            operation: BulkPermissionsLib.Operation.Grant,
            where: plugin,
            who: _gnosisMultiSig,
            permissionID: ExamplePlugin(plugin).Y_PERMISSION_ID()
        });
    }

    function _deployProcess1(address _dao)
        internal
        returns (address plugin, BulkPermissionsLib.Item[] memory permissions)
    {
        // Alternative installation
    }
}

contract PluginInstaller {
    function installPlugin(
        address _dao,
        PluginFactoryBase _factory,
        bytes memory params
    ) external returns (address plugin) {
        BulkPermissionsLib.Item[] memory permissions;

        (plugin, permissions) = _factory.deploy(_dao, params);

        PermissionManager(_dao).bulk(permissions);
    }

    /* function uninstallPlugin(address _dao,  PluginFactory _factory)
        external
        returns (address[] memory relatedContracts)
    {
        // TODO assert that the Plugin is installed on the DAO
    } */
}

contract PluginSequenceInstaller {
    uint256 nonce;
    address internal pluginInstaller;

    constructor(address _pluginInstaller) {
        pluginInstaller = _pluginInstaller;
    }

    struct DependentPlugin {
        PluginFactoryBase pluginFactory;
        uint8 dependeeIndex;
        uint8 whereToReplace;
        bytes params;
    }

    function installSequence(
        IDAO _dao,
        PluginFactoryBase[] calldata _plugins,
        DependentPlugin[] calldata depPlugins
    ) external {
        IDAO.Action[] memory actions = new IDAO.Action[](1);

        address[] memory deployedPlugins = new address[](_plugins.length);

        bytes memory output;

        for (uint256 i = 0; i < _plugins.length; i++) {
            // Map output to input
            deployedPlugins[i] = abi.decode(output, (address));

            // Instruction to the input field that we want to replace

            bytes paramsModified = depPlugins.params;
            paramsModified = actions[0] = IDAO.Action({
                to: pluginInstaller,
                value: 0,
                data: abi.encodeWithSelector(
                    PluginInstaller.installPlugin.selector,
                    _dao,
                    staticParams[i],
                    deployedPlugins[depPlugins[i].dependeeIndex]
                )
            });

            output = IDAO(_dao).execute(nonce, actions)[0];

            nonce++;
        }
    }

    function uninstallSequence(IDAO _dao, Component[] calldata _plugins) external {}
}
