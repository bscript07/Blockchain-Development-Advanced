// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @notice A contract for minting NFTs with random attributes using Chainlink VRF
 * @dev Implements Chainlink VRF for generating random traits for each NFT
 */

error MintFeeNotPaid();
error MintingClosed();
error InvalidRequestId();
error TransferFailed();
error TokenDoesNotExists();

struct Attributes {
    string species;
    string color;
    string eyeShape;
    uint8 flightSpeed;
    uint8 fireResistance;
}

struct MintRequest {
    address minter;
    bool fulfilled;
}

contract RandomNFT is ERC721URIStorage, VRFConsumerBaseV2Plus {
    using Strings for uint256;

    // NFT Variables
    uint256 private _nextTokenId;
    mapping(uint256 => Attributes) public tokenAttributes;
    bool public mintingOpen;
    uint256 private immutable i_mintFee;
    uint256 private immutable i_maxSupply;

    // Chainlink VRF Variables
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    address private immutable i_vrfCoordinatorV2;

    // Request tracking
    mapping(uint256 => MintRequest) private s_mintRequests; // requestId -> MintRequest

    // Predefined traits store in array of strings
    string[] private speciesOptions;
    string[] private colorOptions;
    string[] private eyeShapeOptions;

    // Events
    event NFTRequested(uint256 indexed requestId, address requester);
    event NFTMinted(uint256 indexed tokenId, address owner, Attributes attributes);

    constructor(
        uint256 mintFee,
        uint256 maxSupply,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) 
        ERC721("Cyberpunk", "CPNK")
        VRFConsumerBaseV2Plus(vrfCoordinatorV2)
    {
        i_mintFee = mintFee;
        i_maxSupply = maxSupply;
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_vrfCoordinatorV2 = vrfCoordinatorV2;
        mintingOpen = true;

        // Initialize characteristic options
        speciesOptions = ["Dragon", "Phoenix", "Unicorn", "Griffin", "Serpent"];
        colorOptions = ["Red", "Blue", "Gold", "Silver", "Emerald", "Purple", "Black", "White"];
        eyeShapeOptions = ["Almond", "Round", "Upturned", "Downturned"];
    }

    /**
     * @notice Requests to mint a new NFT with random attributes
     * @dev Calls Chainlink VRF to get random values for attributes
     */
    function requestMint() external payable returns (uint256) {
        if (!mintingOpen) revert MintingClosed();
        if (msg.value < i_mintFee) revert MintFeeNotPaid();
        if (_nextTokenId >= i_maxSupply) revert MintingClosed();

        // Request random number from Chainlink VRF
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_gasLane,
            subId: i_subscriptionId,
            requestConfirmations: 3, // Standard confirmations
            callbackGasLimit: i_callbackGasLimit,
            numWords: 1, // We only need one random number (can derive multiple values from it)
            extraArgs: "" // No extra args needed
        });
        
        uint256 requestId = IVRFCoordinatorV2Plus(i_vrfCoordinatorV2).requestRandomWords(req);
        
        // Store the mint request
        s_mintRequests[requestId] = MintRequest({
            minter: msg.sender,
            fulfilled: false
        });
        
        emit NFTRequested(requestId, msg.sender);
        
        return requestId;
    }

    /**
     * @notice Callback function used by VRF Coordinator to return random number
     * @param _requestId - id of the request
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 _requestId, 
        uint256[] calldata randomWords
    ) internal override {
        // Validate request
        MintRequest storage mintRequest = s_mintRequests[_requestId];
        if (mintRequest.minter == address(0)) revert InvalidRequestId();
        if (mintRequest.fulfilled) revert InvalidRequestId();
        
        // Mark as fulfilled
        mintRequest.fulfilled = true;
        
        // Generate random attributes from the provided randomness
        uint256 randomValue = randomWords[0];
        Attributes memory newAttributes = generateAttributes(randomValue);
        
        // Mint the NFT
        uint256 tokenId = _nextTokenId++;
        _safeMint(mintRequest.minter, tokenId);
        
        // Store the attributes
        tokenAttributes[tokenId] = newAttributes;
        
        // Set token URI with on-chain metadata
        string memory tokenURI = generateTokenURI(tokenId, newAttributes);
        _setTokenURI(tokenId, tokenURI);
        
        emit NFTMinted(tokenId, mintRequest.minter, newAttributes);
    }

    /**
     * @notice Generates random attributes based on the provided random value
     * @param randomValue - random number from VRF
     * @return Attributes - struct containing the generated attributes
     */
    function generateAttributes(uint256 randomValue) private view returns (Attributes memory) {
        uint256 speciesRand = uint256(keccak256(abi.encode(randomValue, 1))) % speciesOptions.length;
        uint256 colorRand = uint256(keccak256(abi.encode(randomValue, 2))) % colorOptions.length;
        uint256 eyeRand = uint256(keccak256(abi.encode(randomValue, 5))) % eyeShapeOptions.length;
        
        // Generate flight speed (1-100)
        uint8 flightSpeed = uint8(1 + (uint256(keccak256(abi.encode(randomValue, 3))) % 100));
        
        // Generate fire resistance (1-100)
        uint8 fireResistance = uint8(1 + (uint256(keccak256(abi.encode(randomValue, 4))) % 100));
        
        return Attributes({
            species: speciesOptions[speciesRand],
            color: colorOptions[colorRand],
            eyeShape: eyeShapeOptions[eyeRand],
            flightSpeed: flightSpeed,
            fireResistance: fireResistance
        });
    }

    /**
     * @notice Generates on-chain metadata for the token as a base64 encoded JSON
     * @param tokenId - ID of the token
     * @param attributes - attributes of the token
     * @return string - base64 encoded JSON metadata
     */
    function generateTokenURI(uint256 tokenId, Attributes memory attributes) private pure returns (string memory) {
           string memory name = string.concat("Cyberpunk #", tokenId.toString());
           string memory description = "A randomly generated cyberpunk hero with unique attributes and svg image";

           string memory attributesJson = string.concat(
                '[{"trait_type": "Species", "value": "', attributes.species, '"}, ',
                '{"trait_type": "Color", "value": "', attributes.color, '"}, ',
                '{"trait_type": "Eye Shape", "value": "', attributes.eyeShape, '"}, ',
                '{"trait_type": "Flight Speed", "value": ', uint256(attributes.flightSpeed).toString(), '}, ',
                '{"trait_type": "Fire Resistance", "value": ', uint256(attributes.fireResistance).toString(), '}]'
    );

           string memory json = string.concat(
                '{"name": "', name, '", ',
                '"description": "', description, '", ',
                '"attributes": ', attributesJson, ', ',
                '"image": "data:image/svg+xml;base64,', generateSVGImage(attributes), '"}'
    );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
}


    /**
     * @notice Generates a simple SVG image based on the NFT attributes
     * @param attributes - attributes of the token
     * @return string - base64 encoded SVG image
     */
    function generateSVGImage(Attributes memory attributes) private pure returns (string memory) {
        // Create a simple colored circle with the creature's species inside
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">',
                '<rect width="100%" height="100%" fill="black" />',
                '<circle cx="150" cy="150" r="120" fill="', toLowercase(attributes.color), '" />',
                '<text x="150" y="150" font-size="24" text-anchor="middle" dominant-baseline="middle" fill="white">',
                attributes.species,
                '</text>',
                '<text x="150" y="180" font-size="16" text-anchor="middle" dominant-baseline="middle" fill="white">',
                'Flight: ', uint256(attributes.flightSpeed).toString(), ' | Fire: ', uint256(attributes.fireResistance).toString(),
                '</text>',
                '</svg>'
            )
        );
        
        return Base64.encode(bytes(svg));
    }


    /**
     * @notice Converts a string to lowercase (simple implementation for color names)
     * @param str - input string
     * @return result - lowercase string
     */
    function toLowercase(string memory str) private pure returns (string memory) {
        // Simple conversion for our specific color names
        // In a full implementation, you'd want a complete lowercase conversion function
        if (compareStrings(str, "Red")) return "red";
        if (compareStrings(str, "Blue")) return "blue";
        if (compareStrings(str, "Gold")) return "gold";
        if (compareStrings(str, "Silver")) return "silver";
        if (compareStrings(str, "Emerald")) return "emerald";
        if (compareStrings(str, "Purple")) return "purple";
        if (compareStrings(str, "Black")) return "black";
        if (compareStrings(str, "White")) return "white";
        return str;
    }

    /**
     * @notice Compares two strings for equality
     * @param a - first string
     * @param b - second string
     * @return bool - true if strings are equal
     */
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
     * @notice Get attributes of a specific token
     * @param tokenId - ID of the token
     * @return Attributes - struct containing the token's attributes
     */
    function getTokenAttributes(uint256 tokenId) external view returns (Attributes memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExists();
        return tokenAttributes[tokenId];
    }

    /**
     * @notice Check if a token exists
     * @param tokenId - ID of the token
     * @return bool - true if token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @notice Toggle minting status (open/closed)
     * @dev Only owner can call this function
     */
    function toggleMinting() external onlyOwner {
        mintingOpen = !mintingOpen;
    }

    /**
     * @notice Withdraw contract balance to owner
     * @dev Only owner can call this function
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @notice Get current mint fee
     * @return uint256 - current mint fee
     */
    function getMintFee() external view returns (uint256) {
        return i_mintFee;
    }

    /**
     * @notice Get max supply of NFTs
     * @return uint256 - max supply
     */
    function getMaxSupply() external view returns (uint256) {
        return i_maxSupply;
    }

    /**
     * @notice Get next token ID
     * @return uint256 - next token ID
     */
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }
}