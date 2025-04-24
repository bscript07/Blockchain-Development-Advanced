// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error InvalidAmount();
error InsufficientValue();
error BuyPeriodEnded();
error InvalidProof();
error InvalidIndex();
error AlreadyClaimed();
error InvalidSignature();
error InvalidRelayer();

contract AIAgentShare is ERC20, Ownable, EIP712, ERC20Permit {
    uint256 public constant MIN_AMOUNT_MINUS_ONE = 99 * 10 ** 18;
    uint256 public constant MAX_AMOUNT_PLUS_ONE = 50001 * 10 ** 18;
    uint256 public constant TOTAL_PARTICIPANTS = 260;
    uint256 public constant BITS_PER_UINT = 256; // 256 bits
    uint256 public constant RELAYER_FEE = 5 * 10 ** 18;
    bytes32 public constant STRUCT_TYPE_HASH = keccak256("BuyApproval(uint256 amount, int256 deadline)");

    uint256 public immutable BUY_PERIOD_ENDS = block.timestamp + 10 days; // 10 days buying period
    bytes32 public immutable root;

    address public relayer;

    uint256 public shareHoldersPool = 5_000_000 * 10 ** 18; // 5 million tokens for share holders
    uint256 public price = 0.1 ether; // 0.1 ether price per 1 token

    /**
     *
     * @dev Bitmap storage for tracking claimed whitelist spots
     * We need to track 260 participants, but a uint256 can olny store 256 bits
     * Therefore, we use an array of 2 uint256s:
     * - claimedBitmap[0] stores bits 0-255 (participants 0-255)
     * - claimedBitmap[1] stores bits 0-3 (participants 255-259)
     * Each bit represents whether a participant has claimed their whitelist spot:
     * - 0 = not claimed
     * - 1 = claimed
     *
     * Bit positions in claimedBitmap[1]: 00000000000
     * - bit 0: participant 256
     * - bit 1: participant 257
     * - bit 2: participant 258
     * - bit 3: participant 259
     *
     * Visual representation of the bitmap:
     * - claimedBitmap[0]: [bit255 ... bit5 bit4 bit3 bit2 bit1 bit0] // participants 0-255
     * - claimedBitmap[1]: [bit255 ... bit3 bit2 bit1 bit0] // participants 256-259
     */
    uint256[2] private claimedBitmap;

    constructor(bytes32 _root, address _relayer)
        ERC20("AIAgentShare", "AIS")
        Ownable(msg.sender)
        ERC20Permit("AIAgentShare")
    {
        _mint(msg.sender, 5_000_000 * 10 ** 18); // 5 million tokens for contract owner
        root = _root;
        relayer = _relayer;
    }

    function setRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
    }

    function buy(uint256 amount, uint256 index, bytes32[] memory proof) external payable {
        require(msg.value == (amount * price) / 10 ** 18, InsufficientValue());

        _buy(msg.sender, amount, amount, index, proof);
    }

    function buyWithSignature(
        address buyer,
        uint256 amount,
        uint256 index,
        uint256 deadline,
        bytes32[] memory proof,
        bytes memory signature
    ) external payable {
        require(msg.sender == relayer, InvalidRelayer());
        require(isValidSignature(buyer, amount, deadline, signature), InvalidSignature());

        _mint(msg.sender, RELAYER_FEE);
        _buy(buyer, amount, amount - RELAYER_FEE, index, proof);
    }

    function _buy(address buyer, uint256 amount, uint256 amountToMint, uint256 index, bytes32[] memory proof) private {
        require(amount > MIN_AMOUNT_MINUS_ONE && amount < MAX_AMOUNT_PLUS_ONE, InvalidAmount());
        require(block.timestamp < BUY_PERIOD_ENDS, BuyPeriodEnded());
        require(isValidProof(index, msg.sender, proof), InvalidProof());
        require(!isClaimed(index), AlreadyClaimed());

        _setClaimed(index);
        shareHoldersPool -= amount;

        _mint(buyer, amountToMint);
    }

    function claimLeftShares() external onlyOwner {
        _mint(msg.sender, shareHoldersPool);
    }

    function isValidSignature(address buyer, uint256 amount, uint256 deadline, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(STRUCT_TYPE_HASH, amount, deadline)));

        return ECDSA.recover(hash, signature) == buyer;
    }

    function isValidProof(uint256 index, address buyer, bytes32[] memory proof) public view returns (bool) {
        // Leaf1 + Leaf2 + Leaf3 ..... 32 bytes + 32 bytes 1 leaf are stored in one slot 32 bytes
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, buyer))));

        return MerkleProof.verify(proof, root, leaf);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        if (index >= TOTAL_PARTICIPANTS) revert InvalidIndex();

        // Calculate which uint256 in the array to use (0 or 1)
        uint256 bitmapIndex = index / BITS_PER_UINT;
        // Calculate which bit within the uint256 to set (0-255) 0000 0000
        uint256 bitIndex = index % BITS_PER_UINT;
        // Create a mask with a 1 at the bit position we want to check
        uint256 mask = 1 << bitIndex;
        // Check if the bit is set by adding the mask
        return (claimedBitmap[bitmapIndex] & mask) != 0;
    }

    function _setClaimed(uint256 index) private {
        if (index >= TOTAL_PARTICIPANTS) revert InvalidIndex();

        // Calculate which uint256 in the array to use (0 or 1)
        uint256 bitmapIndex = index / BITS_PER_UINT;
        // Calculate which bit within the uint256 to set (0-255) 0000 0000
        uint256 bitIndex = index % BITS_PER_UINT;
        // Create a mask with a 1 at the bit position we want to check
        uint256 mask = 1 << bitIndex;
        // Set the bit by ORing with the mask
        claimedBitmap[bitmapIndex] = claimedBitmap[bitmapIndex] | mask;
    }
}

// 000000000000000000 & 10 = 000000000000000000
// 000000000000000010 & 10 = 000000000000000010
// 000000000000001010 & 10000 = == 0

// 000000000000000000 | 10 = 000000000000000010     ===> 0 or 1 change the value in left slot
