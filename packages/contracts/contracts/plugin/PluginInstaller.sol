import "./PluginFactoryBase.sol";
import "./IPluginRepo.sol";
import "../core/component/Component.sol";

import "../core/IDAO.sol";

contract GnosisMultiSig {}

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
    /// @inheritdoc PluginFactoryBase
    function deploy(address _dao, bytes memory _params)
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
    ) internal returns (address plugin, BulkPermissionsLib.Item[] storage permissions) {
        // Deploy contracts
        ExamplePlugin examplePlugin = new ExamplePlugin();
        examplePlugin.initialize(IDAO(_dao), _gnosisMultiSig);
        plugin = address(examplePlugin);

        // Prepare permissions
        permissions.push(
            BulkPermissionsLib.Item({
                operation: BulkPermissionsLib.Operation.Grant,
                where: _dao,
                who: plugin,
                permissionID: ExamplePlugin(plugin).X_PERMISSION_ID()
            })
        );
        permissions.push(
            BulkPermissionsLib.Item({
                operation: BulkPermissionsLib.Operation.Grant,
                where: plugin,
                who: _gnosisMultiSig,
                permissionID: ExamplePlugin(plugin).Y_PERMISSION_ID()
            })
        );
    }

    function _deployProcess1(address _dao)
        internal
        returns (address plugin, BulkPermissionsLib.Item[] memory permissions)
    {
        // alternative deployment process
    }
}

contract PluginInstaller {
    function installPlugin(
        address _dao,
        PluginFactoryBase _factory,
        bytes memory params
    ) external returns (address plugin) {
        (plugin, ) = _factory.deploy(_dao, params);
    }

    /* function uninstallPlugin(address _dao,  PluginFactory _factory)
        external
        returns (address[] memory relatedContracts)
    {
        // TODO assert that the Plugin is installed on the DAO
    } */
}

contract PluginSequenceInstaller {
    address internal pluginInstaller;

    constructor(address _pluginInstaller) {
        pluginInstaller = _pluginInstaller;
    }

    struct PluginInstallInfo {
        bytes params;
    }

    function installSequence(
        IDAO _dao,
        PluginFactoryBase[] calldata _plugins,
        bytes[] memory params
    ) external {
        bytes memory output;

        for (uint256 i = 0; i < _plugins.length; i++) {
            // map output to input
            address plugin = abi.decode(output, (address)); // this is to be replaced by a more complicated mapping

            IDAO.Action memory action = IDAO.Action({
                to: pluginInstaller,
                value: 0,
                data: abi.encodeWithSelector(PluginInstaller.installPlugin.selector, _dao, plugin)
            });

            (bool success, bytes memory response) = action.to.call{value: action.value}(
                action.data
            );

            output = response;

            if (!success) revert IDAO.ActionFailed();
        }
    }

    function uninstallSequence(IDAO _dao, Component[] calldata _plugins) external {}
}
