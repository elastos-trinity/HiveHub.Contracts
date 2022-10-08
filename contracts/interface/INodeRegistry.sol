// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "../token/ERC721/IERC721.sol";

interface INodeRegistryDataAndEvents {
    /**
     * @notice Hive Node Info
     * @param tokenId The nodeId starts from 1
     * @param tokenURI The node uri
     * @param nodeEntry The node entry
     */
    struct Node {
        uint256 tokenId;
        string tokenURI;
        string nodeEntry;
    }

    /**
     * @notice RegisterFee is chareged on registeration.
     * @param tokenId Node unique Id.
     * @param platformAddr Platform address to receive register fees.
     * @param registerFee Register fee.
     */
    event RegisteredFees(
        uint256 tokenId,
        address platformAddr,
        uint256 registerFee
    );

    /**
     * @notice A new node is registered.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node  entry.
     */
    event NodeRegistered(
        uint256 tokenId,
        string tokenURI,
        string nodeEntry
    );

    /**
     * @notice Node unregistered event
     * @param tokenId Unregistered node Id
     */
    event NodeUnregistered(
        uint256 tokenId
    );

    /**
     * @notice Node updated event
     * @param tokenId Updated node Id.
     * @param newNodeURI Updated node uri.
     * @param newNodeEntry Updated node entry.
     */
    event NodeUpdated(
        uint256 tokenId,
        string newNodeURI,
        string newNodeEntry
    );

    /**
     * @notice Node revealed event
     * @param state Revealed state, 1 for true, 0 for false
     */
    event Revealed(uint256 state);

    /**
     * @dev MUST emit when platform fee config is updated.
     * The `platformAddress` argument MUST be the address of the platform.
     * The `platformFee` argument MUST be the fee rate of the platform.
     */
    event PlatformFeeChanged(
        address platformAddress,
        uint256 platformFee
    );
}

interface INodeRegistry is IERC721, INodeRegistryDataAndEvents {
    function pause() external;
    function unpause() external;
    function mint(string memory tokenURI, string memory nodeEntry) external payable;
    function burn(uint256 tokenId) external;
    function updateNode(uint256 tokenId, string memory tokenURI, string memory nodeEntry) external;
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
    function getLastTokenId() external view returns (uint256);
    function getTokenId(string memory nodeEntry) external view returns (uint256);
    function setPlatformFee(address platformAddr, uint256 platformFee) external;
    function getPlatformFee() external view returns (address platformAddress, uint256 platformFee);
}
