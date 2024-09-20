// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NFTMarket is Ownable {

    uint256 private _nextTokenId;
    
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(uint256 indexed tokenId, address seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address seller, address buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId, address seller);

    constructor() ERC721("MJToken", "MJT") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function mint(address to, string memory imgUri) external onlyOwner {
        uint256 tokenId = _nextTokenId;
        _safeMint(to, tokenId);
        
        string memory tokenURI = generateTokenURI(tokenId, imgUri);
        _setTokenURI(tokenId, tokenURI);

        _nextTokenId++;
    }

    function generateTokenURI(uint256 tokenId, string memory imgUri) internal pure returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "MJToken #', toString(tokenId), '",',
            '"description": "Micjohn NFT On Chain",',
            '"image": "', imgUri, '"',
            '}'
        );
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(dataURI)
        ));
    }

    function listNFT(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");
        
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isActive: true
        });
        
        emit NFTListed(tokenId, msg.sender, price);
    }

    function cancelListing(uint256 tokenId) external {
        require(listings[tokenId].seller == msg.sender, "Not the seller");
        require(listings[tokenId].isActive, "Listing not active");
        
        delete listings[tokenId];
        
        emit ListingCancelled(tokenId, msg.sender);
    }

    function buyNFT(uint256 tokenId) external payable {
        Listing memory listing = listings[tokenId];
        require(listing.isActive, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");
        
        address seller = listing.seller;
        uint256 price = listing.price;
        
        delete listings[tokenId];
        
        _transfer(seller, msg.sender, tokenId);
        payable(seller).transfer(price);
        
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        
        emit NFTSold(tokenId, seller, msg.sender, price);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    function getOwner() public view returns (address) {
        return owner();
    }
}