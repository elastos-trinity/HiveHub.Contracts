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
    function mint(uint256 tokenId, string memory tokenURI, string memory nodeEntry) external payable;
    function mint(uint256 tokenId, string memory tokenURI, string memory nodeEntry, address receiptAddr) external payable;
    function burn(uint256 tokenId) external;
    function updateNode(uint256 tokenId, string memory tokenURI, address receiptAddr) external;
    function reveal() external;
    function isRevealed() external view returns (uint256);
    function nodeInfo(uint256 tokenId) external view returns (Node memory);
    function nodeCount() external view returns (uint256);
    function nodeByIndex(uint256 index) external view returns (Node memory);
    function nodeIds() external view returns (bytes32[] memory);
    function ownedNodeCount(address ownerAddr) external view returns (uint256);
    function ownedNodeByIndex(address ownerAddr, uint256 index) external view returns (Node memory);
    function ownedNodeIds(address ownerAddr) external view returns (bytes32[] memory);
    function isValidNodeId(uint256 tokenId) external view returns (bool);
    function setPlatformFee(address platformAddr, uint256 platformFee) external;
    function getPlatformFee() external view returns (address platformAddress, uint256 platformFee);
    event RegisteredFees(uint256 tokenId, address platformAddr, uint256 registerFee);
    event NodeRegistered(uint256 tokenId, string tokenURI, string nodeEntry, address receiptAddr, address ownerAddr);
    event NodeUnregistered(uint256 tokenId);
    event NodeUpdated(uint256 tokenId, string newNodeURI);
    event NodeRevealed(uint256 state);
    event PlatformFeeChanged(address platformAddress,uint256 platformFee);
}
