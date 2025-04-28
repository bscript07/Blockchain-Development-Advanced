// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {Shibon} from "@/08_upgradeability/UpgradeableTreasury.sol";
import {TreasuryV1} from "@/08_upgradeability/UpgradeableTreasury.sol";
import {TreasuryV2} from "@/08_upgradeability/UpgradeableTreasury.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract UpgradeableTreasuryTest is Test {
    Shibon public shibon;
    TreasuryV1 public treasuryV1;
    TreasuryV2 public treasuryV2;
    TransparentUpgradeableProxy public proxy;
    ProxyAdmin public proxyAdmin;

    address public user = makeAddr("user");
    address public owner = makeAddr("owner");

    function setUp() public {
        // Set up the token 🪙
        shibon = new Shibon();
        shibon.mint(owner, 1000 * 10 ** 18); // Mint tokens for the owner

        // Deploy ProxyAdmin 🛠️
        proxyAdmin = new ProxyAdmin(owner);

        // Deploy TreasuryV1 💰
        treasuryV1 = new TreasuryV1();
        treasuryV1.initialize(address(shibon));

        // Deploy Proxy for TreasuryV1 🏦
        proxy = new TransparentUpgradeableProxy(
            address(treasuryV1),
            address(proxyAdmin),
            abi.encodeWithSelector(treasuryV1.initialize.selector, address(shibon))
        );

        // Point the proxy to TreasuryV1 📜
        treasuryV1 = TreasuryV1(address(proxy));

        // Set up TreasuryV2 (for future upgrade) 🔄
        treasuryV2 = new TreasuryV2();
    }
}
