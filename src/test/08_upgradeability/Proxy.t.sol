// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {Proxy, DelegateCallFailed} from "@/08_upgradeability/DelegateCall.sol";
import {Implementation} from "@/08_upgradeability/DelegateCall.sol";

contract ProxyTest is Test {
    Proxy proxy;
    Implementation implementation;

    address public user = address(0xabcd);

    function setUp() public {
        proxy = new Proxy();
        implementation = new Implementation();
    }

    function testDelegateCallWorks() public {
        // Set amount for test == 0.3 ether
        uint256 amountToSend = 0.3 ether;

        // Give 1 ether to user
        vm.deal(user, 1 ether);

        // Set my user for the next call
        vm.prank(user);
        proxy.setVars{value: amountToSend}(address(implementation), 1234);

        // Check if is true
        assertEq(proxy.num(), 1234);
        assertEq(proxy.sender(), user);
        assertEq(proxy.value(), amountToSend);
    }

    function testDelegateCallNotWorks() public {
        // Proxy contract address
        address proxyAddress = address(proxy);

        // Icorrect function delegate call
        bytes memory badCall = abi.encodeWithSignature("missingSetVars(uint256)", 1);

        // Throw an error if delegate call failed
        vm.expectRevert(DelegateCallFailed.selector);

        // Call from proxy address
        (bool ok,) = proxyAddress.call{value: 0}(badCall);
        ok;
    }
}
