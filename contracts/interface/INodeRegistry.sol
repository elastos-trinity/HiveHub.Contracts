// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "../token/ERC721/IERC721.sol";

interface INodeRegistry is IERC721 {
    struct Node {
        uint256 tokenId;
        string tokenURI;
        string nodeEntry;
        address receiptAddr;
        address ownerAddr;
    }
    function mint(uint256 tokenId, string memory tokenURI, string memory nodeEntry, address quoteToken, uint256 mintFee) external payable;
    function mint(uint256 tokenId, string memory tokenURI, string memory nodeEntry, address receiptAddr, address quoteToken, uint256 mintFee) external payable;
    function burn(uint256 tokenId) external;
    function updateNode(uint256 tokenId, string memory tokenURI, address receiptAddr) external;
    function revealNode() external;
    function isRevealed() external view returns (uint256);
    function nodeInfo(uint256 tokenId) external view returns (Node memory);
    function nodeCount() external view returns (uint256);
    function nodeByIndex(uint256 index) external view returns (Node memory);
    function nodeIds() external view returns (bytes32[] memory);
    function ownedNodeCount(address ownerAddr) external view returns (uint256);
    function ownedNodeByIndex(address ownerAddr, uint256 index) external view returns (Node memory);
    function ownedNodeIds(address ownerAddr) external view returns (bytes32[] memory);
    function isValidNodeId(uint256 tokenId) external view returns (bool);
    function setPlatformAddr(address platformAddr) external;
    function platformAddress() external view returns (address);
    event RegisteredFees(uint256 tokenId, address platformAddr, address quoteToken, uint256 registerFee);
    event NodeRegistered(uint256 tokenId, string tokenURI, string nodeEntry, address receiptAddr, address ownerAddr);
    event NodeUnregistered(uint256 tokenId);
    event NodeUpdated(uint256 tokenId, string newNodeURI);
    event NodeRevealed(uint256 state);
    event PlatformFeeChanged(address platformAddress);
}
