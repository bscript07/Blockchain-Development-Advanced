// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Marketplace {
    address owner;
    address token;
    uint256 tokenId;
    uint256 price;

    function listForSale(address _token, uint256 _tokenId, uint256 _price) external {
        // add checks
        owner = msg.sender;
        token = _token;
        tokenId = _tokenId;
        price = _price;

        ERC721(token).transferFrom(msg.sender, address(this), tokenId);
    }

    function buyListedItem() external {
        ERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);

        // -------------Royalty-------------//
        uint256 endPrice = price;
        if (ERC721(token).supportsInterface(type(IERC2981).interfaceId)) {
            (address receiver, uint256 amount) = IERC2981(token).royaltyInfo(tokenId, price);
            (bool resRoyalties,) = payable(receiver).call{value: amount}("");
            if (resRoyalties) {
                endPrice -= amount;
            }

            // handle proper
        }

        (bool res,) = payable(owner).call{value: endPrice}("");
        require(res, "No success");
    }
}
