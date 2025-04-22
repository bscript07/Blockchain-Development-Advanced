// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import {ERC2612} from "@/05_signatures/AdvancedERC20.sol";
// import {ExceedsInitialSupply,
// ExceedsMaxSupply,
// InvalidSignature,
// AuthorizationAlreadyUsed,
// AuthorizationNotValid,
// AuthorizationExpired
// } from "@/05_signatures/AdvancedERC20.sol";

// contract ERC2612Test is Test {
//     // Declare ERC2612 contract
//     ERC2612 public erc2612;
//     // Set owner private key
//     uint256 ownerPrivateKey = 0x123;
//     // Set owner with private key
//     address public owner = vm.addr(ownerPrivateKey);
//     address public user1;
//     address public user2;

//     // Declare initial supply 10 millions tokens
//     uint256 initialSupply = 10_000_000 * 10 ** 18;

//     function setUp() public {
//         user1 = makeAddr("user1");
//         user2 = makeAddr("user2");

//         // Set owner for the next function call
//         vm.prank(owner);

//         // Add new ERC2612 instance
//         erc2612 = new ERC2612(initialSupply);

//         // Owner transfer 1000 tokens to user1
//         vm.prank(owner);
//         erc2612.transfer(user1, 1000 * 10 ** 18);
//     }

//     function testMetadata() public view {
//         assertEq(erc2612.name(), "ERC20 Token");
//         assertEq(erc2612.symbol(), "ERCT");
//         assertEq(erc2612.decimals(), 18);
//     }

//     // function testConstructorRevert() public {
//     //     uint256 tooMuch = erc2612.MAX_SUPPLY() + 1;
//     //     vm.expectRevert(ERC2612.ExceedsInitialSupply.selector);
//     //     new ERC2612(tooMuch);
//     // }

//     function testBurn() public {
//         uint256 burnAmount = 500 * 10 ** 18;

//         vm.prank(owner);
//         uint256 before = erc2612.balanceOf(owner);

//         vm.prank(owner);
//         erc2612.burn(burnAmount);

//         uint256 balanceAfter = erc2612.balanceOf(owner);
//         assertEq(balanceAfter, before - burnAmount);
//     }

//     // TODO
//     // function testTransfer() public {
//     //   uint256 amount = 100 * 1e18;

//     //   vm.prank(owner);
//     //   erc2612.mint(owner, amount);

//     //   uint256 senderBalanceBefore = erc2612.balanceOf(owner);
//     //   uint256 recipientBalanceBefore = erc2612.balanceOf(user1);

//     //   vm.prank(owner);
//     //   bool success = erc2612.transfer(user1, amount);

//     //   uint256 senderBalanceAfter = erc2612.balanceOf(owner);
//     //   uint256 recipientBalanceAfter = erc2612.balanceOf(user1);

//     //   assertTrue(success, "Transfer should return true");
//     //   assertEq(senderBalanceAfter, senderBalanceBefore - amount, "Sender balance should decrease");
//     //   assertEq(recipientBalanceAfter, recipientBalanceBefore + amount, "Recipient balance should increase");
//     // }

//     function testApprove() public {
//         vm.prank(owner);
//         erc2612.approve(user1, 1000 * 10 ** 18);
//         assertEq(erc2612.allowance(owner, user1), 1000 * 10 ** 18);
//     }

//     function testTransferFrom() public {
//         vm.prank(owner);
//         erc2612.approve(user1, 1000 * 10 ** 18);

//         vm.prank(user1);
//         erc2612.transferFrom(owner, user2, 1000 * 10 ** 18);
//         assertEq(erc2612.balanceOf(user2), 1000 * 10 ** 18);
//     }

// //     function testPermitValidSignature() public {
// //     uint256 value = 1000 * 1e18;
// //     uint256 deadline = block.timestamp + 1 hours;
// //     uint256 nonce = erc2612.nonces(owner);

// //     bytes32 digest = erc2612.getPermitTypedDataHash(owner, user1, value, nonce, deadline);
// //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

// //     vm.prank(user1);
// //     erc2612.permit(owner, user1, value, deadline, v, r, s);

// //     assertEq(erc2612.allowance(owner, user1), value);
// // }

//     function testTransferWithAuthorization() public {
//         uint256 value = 1000 * 10 ** 18;
//         uint256 validAfter = block.timestamp;
//         uint256 validBefore = block.timestamp + 1 hours;
//         bytes32 nonce = keccak256("nonce_1");

//         bytes32 digest = erc2612.getAuthorizationTypedDataHash(owner, user1, value, validAfter, validBefore, nonce);
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

//         vm.prank(user1);
//         erc2612.transferWithAuthorization(owner, user1, value, validAfter, validBefore, nonce, v, r, s);

//         assertEq(erc2612.balanceOf(user1), 1000 * 1e18 + value);
//         assertTrue(erc2612.authorizationUsed(nonce));
//     }

//     // TODO
//     // function testAuthorizationExpired() public {
//     //     uint256 value = 1000 * 10 ** 18;
//     //     uint256 validAfter = block.timestamp + 2 hours;
//     //     uint256 validBefore = block.timestamp - 1 hours;
//     //     bytes32 nonce = keccak256("nonce_expired");

//     //     vm.prank(owner);
//     //     erc2612.mint(owner, value);

//     //     bytes32 digest = erc2612.getAuthorizationTypedDataHash(owner, user1, value, validAfter, validBefore, nonce);
//     //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

//     //     vm.prank(user1);
//     //     vm.expectRevert(ERC2612.AuthorizationExpired.selector);
//     //     erc2612.transferWithAuthorization(owner, user1, value, validAfter, validBefore, nonce, v, r, s);
//     // }

//     function testAuthorizationNotValidYet() public {
//         uint256 value = 1000 * 10 ** 18;
//         uint256 validAfter = block.timestamp + 1 hours;
//         uint256 validBefore = block.timestamp + 2 hours;
//         bytes32 nonce = keccak256("nonce_future");

//         bytes32 digest = erc2612.getAuthorizationTypedDataHash(owner, user1, value, validAfter, validBefore, nonce);
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

//         vm.prank(user1);
//         vm.expectRevert(ERC2612.AuthorizationNotValid.selector);
//         erc2612.transferWithAuthorization(owner, user1, value, validAfter, validBefore, nonce, v, r, s);
//     }

//     function testInvalidSignature() public {
//         uint256 value = 1000 * 10 ** 18;
//         uint256 validAfter = block.timestamp;
//         uint256 validBefore = block.timestamp + 1 hours;
//         bytes32 nonce = keccak256("nonce_invalid");

//         bytes32 digest = erc2612.getAuthorizationTypedDataHash(owner, user1, value, validAfter, validBefore, nonce);
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
//         v = v == 27 ? 28 : 27; // Invalid v

//         vm.prank(user1);
//         vm.expectRevert(ERC2612.InvalidSignature.selector);
//         erc2612.transferWithAuthorization(owner, user1, value, validAfter, validBefore, nonce, v, r, s);
//     }

//     function testAuthorizationAlreadyUsed() public {
//         uint256 value = 1000 * 10 ** 18;
//         uint256 validAfter = block.timestamp;
//         uint256 validBefore = block.timestamp + 1 hours;
//         bytes32 nonce = keccak256("nonce_used");

//         bytes32 digest = erc2612.getAuthorizationTypedDataHash(owner, user1, value, validAfter, validBefore, nonce);
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

//         vm.prank(user1);
//         erc2612.transferWithAuthorization(owner, user1, value, validAfter, validBefore, nonce, v, r, s);

//         vm.prank(user1);
//         vm.expectRevert(ERC2612.AuthorizationAlreadyUsed.selector);
//         erc2612.transferWithAuthorization(owner, user1, value, validAfter, validBefore, nonce, v, r, s);
//     }

//     // 🔁 EIP-712 Digest Generator for transferWithAuthorization
//     function getAuthorizationDigest(
//         address from,
//         address to,
//         uint256 value,
//         uint256 validAfter,
//         uint256 validBefore,
//         bytes32 nonce
//     ) internal view returns (bytes32) {
//         return erc2612.getAuthorizationTypedDataHash(
//           from,
//           to,
//           value,
//           validAfter,
//           validBefore,
//           nonce
//     );
//     }
// }
