// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {TreasureManager} from "../src/TreasureManager.sol";
import {EmptyContract} from "../test/EmptyContract.sol";

contract TreasureManagerScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        EmptyContract emptyContract = new EmptyContract();
        TransparentUpgradeableProxy proxyTreasureManager =
            new TransparentUpgradeableProxy(address(emptyContract), deployerAddress, "");

        TreasureManager treasureManager = TreasureManager(payable(address(proxyTreasureManager)));
        TreasureManager treasureManagerImplementation = new TreasureManager();
        ProxyAdmin treasureManagerProxyAdmin = ProxyAdmin(_getProxyAdminAddress(address(proxyTreasureManager)));

        treasureManagerProxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(treasureManager)),
            address(treasureManagerImplementation),
            abi.encodeWithSelector(
                TreasureManager.initialize.selector,
                deployerAddress,
                deployerAddress,
                deployerAddress
            )
        );

        console.log("treasureManager=", address(treasureManager));
        console.log("treasureManagerProxyAdmin=", address(treasureManagerProxyAdmin));

        vm.stopBroadcast();
    }

    function _getProxyAdminAddress(address proxy) internal view returns (address) {
        bytes32 adminSlotValue = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        return address(uint160(uint256(adminSlotValue)));
    }
}
