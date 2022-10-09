// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPausable.sol";

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

interface INodeRegistry is IERC721, IPausable, INodeRegistryDataAndEvents {
    /**
     * @notice Register a new node by personal wallet.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     */
    function mint(string memory tokenURI, string memory nodeEntry) external payable;

    /**
     * @notice Unregister a node by personal wallet.
     * @param tokenId Node Id to be removed.
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Update node by personal wallet.
     * @param tokenId Node Id to be updated.
     * @param tokenURI Updated node uri.
     * @param nodeEntry Updated node entry.
     */
    function updateNode(uint256 tokenId, string memory tokenURI, string memory nodeEntry) external;

    /**
     * @notice Reveal node
     */
    function reveal() external;

    /**
     * @notice Get revealed state
     * @return Revealed state
     */
    function isRevealed() external view returns (uint256);

    /**
     * @notice Get node by nodeId
     * @param tokenId Node Id.
     * @return Node information.
     */
    function nodeInfo(uint256 tokenId) external view returns (Node memory);

    /**
     * @notice Get count of existing nodes.
     * @return count existing node count.
     */
    function nodeCount() external view returns (uint256);

    /**
     * @notice Get node by nodeId
     * @param index Index of node.
     * @return Node information.
     */
    function nodeByIndex(uint256 index) external view returns (Node memory);

    /**
     * @notice Get list of existing nodes.
     * @return The list of existing node ids
     */
    function nodeIds() external view returns (bytes32[] memory);

    /**
     * @notice Get count of nodes by owner address
     * @param ownerAddr ESC address of owner.
     * @return Node count.
     */
    function ownedNodeCount(address ownerAddr) external view returns (uint256);

    /**
     * @notice Get count of nodes by owner address
     * @param ownerAddr ESC address of owner.
     * @param index Index of node.
     * @return Node info.
     */
    function ownedNodeByIndex(address ownerAddr, uint256 index) external view returns (Node memory);

    /**
     * @notice Get list of nodes by owner address
     * @param ownerAddr ESC address of owner.
     * @return nodeIds list of node Ids.
     */
    function ownedNodeIds(address ownerAddr) external view returns (bytes32[] memory);

    /**
     * @notice Check validity of given nodeId.
     * @param tokenId Node Id to check.
     * @return The validity of nodeId
     */
    function isValidNodeId(uint256 tokenId) external view returns (bool);

    /**
     * @notice Get last tokenId.
     * @return The last nodeId
     */
    function getLastTokenId() external view returns (uint256);

    /**
     * @notice Get node Id from node uri and node entry.
     * @param nodeEntry Node Entry.
     * @return The node Id
     */
    function getTokenId(string memory nodeEntry) external view returns (uint256);

    /**
     * @dev Set platform fee config.
     * @param platformAddr Address of platform
     * @param platformFee Platform Fee
     */
    function setPlatformFee(address platformAddr, uint256 platformFee) external;

    /**
     * @dev Get platform address config
     * @return platformAddress address of platform
     * @return platformFee platform fee
     */
    function getPlatformFee() external view returns (address platformAddress, uint256 platformFee);
}
