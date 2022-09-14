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
        address agentAddr;
    }

    // agent management
    function isAgent(address _addr) external view returns (bool);
    function addAgent(address agent) external;
    function removeAgent(address agent) external;
    function renounceAgentship() external;
    function agentCount() external view returns (uint256);
    function agents() external view returns (address[] memory);

    function mint(uint256 tokenId, string memory tokenURI, string memory nodeEntry, address quoteToken, uint256 mintFee) external payable;
    function mint(uint256 tokenId, string memory tokenURI, string memory nodeEntry, address receiptAddr, address quoteToken, uint256 mintFee) external payable;
    function mint(uint256 tokenId, string memory tokenURI, string memory nodeEntry, address receiptAddr, address ownerAddr) external;
    function burn(uint256 tokenId) external;
    function burn(uint256 tokenId, address ownerAddr) external;

    function updateNode(uint256 tokenId, string memory tokenURI, address receiptAddr) external;
    function updateNode(uint256 tokenId, string memory tokenURI, address receiptAddr, address ownerAddr) external;

    function nodeInfo(uint256 tokenId) external view returns (Node memory);
    function nodeCount() external view returns (uint256);
    function nodeByIndex(uint256 index) external view returns (Node memory);
    function nodeIds() external view returns (bytes32[] memory);
    function ownedNodeCount(address ownerAddr) external view returns (uint256);
    function ownedNodeByIndex(address ownerAddr, uint256 index) external view returns (Node memory);
    function ownedNodeIds(address ownerAddr) external view returns (bytes32[] memory);
    function agentNodeCount(address agentAddr) external view returns (uint256);
    function agentNodeByIndex(address agentAddr, uint256 index) external view returns (Node memory);
    function agentNodeIds(address agentAddr) external view returns (bytes32[] memory);

    function isValidNodeId(uint256 tokenId) external view returns (bool);

    function setPlatformAddr(address platformAddr) external;
    function platformAddress() external view returns (address);

    event RegisteredFees(uint256 tokenId, address platformAddr, address quoteToken, uint256 registerFee);
    event NodeRegistered(uint256 tokenId, string tokenURI, string nodeEntry, address receiptAddr, address ownerAddr, address agentAddr);
    event NodeUnregistered(uint256 tokenId);
    event NodeUpdated(uint256 tokenId, string newNodeURI);
    event PlatformFeeChanged(address platformAddress);
    event AgentAdded(address account);
    event AgentRemoved(address account);
}
