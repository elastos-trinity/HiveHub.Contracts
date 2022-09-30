// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;


import "../interface/INodeRegistry.sol";
import "../common/EnumerableSet.sol";
import "../common/PausableUpgradeable.sol";
import "../common/OwnableUpgradeable.sol";
import "../common/ReentrancyGuardUpgradeable.sol";
import "../token/ERC20/IERC20.sol";
import "../token/ERC721/ERC721.sol";

contract NodeRegistry is INodeRegistryDataAndEvents, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721, PausableUpgradeable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    string private constant _name = "Hive Node Token Collection";
    string private constant _symbol = "HNTC";
    uint256 private _lastTokenId;
    uint256 private _isRevealed;
    uint256 private _platformFee;
    address private _platformAddr;
    mapping(uint256 => Node) private _allTokens;
    EnumerableSet.UintSet private _tokens;
    mapping(string => mapping(string => uint256)) private _nodeToTokenId;

    /**
     * @notice Initialize a node registry contract with platform address info.
     * @param platformAddress_ platform address.
     * @param platformFee_ platform fee.
     */
    function initialize(address platformAddress_, uint256 platformFee_) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC721_init(_name, _symbol);
        require(
            _setPlatformAddr(platformAddress_, platformFee_),
            "NodeRegistry: initialize platform fee failed"
        );
    }

    /**
     * @notice Pause the vesting release.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the vesting release.
     */
    function unpause() external onlyOwner {
        require(_platformAddr != address(0), "NodeRegistry: Contract is not initialized");
        _unpause();
    }

    /**
     * @notice Register a new node by personal wallet.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     */
    function mint(
        string memory tokenURI,
        string memory nodeEntry
    ) external payable nonReentrant whenNotPaused {
        require(
            _nodeToTokenId[tokenURI][nodeEntry] == 0,
            "NodeRegistry: duplicated node"
        );
        require(
            msg.value == _platformFee,
            "NodeRegistry: incorrect register fee"
        );
        if (msg.value > 0) {
            bool success;
            (success, ) = payable(_platformAddr).call{value: msg.value}("");
            require(success, "NodeRegistry: register fee transfer failed");
        }
        uint256 tokenId = _lastTokenId.add(1);
        emit RegisteredFees(tokenId, _platformAddr, msg.value);
        
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        Node memory newNode;
        newNode.tokenId = tokenId;
        newNode.tokenURI = tokenURI;
        newNode.nodeEntry = nodeEntry;

        _allTokens[tokenId] = newNode;
        _tokens.add(tokenId);
        _lastTokenId = tokenId;
        _nodeToTokenId[tokenURI][nodeEntry] = tokenId;

        emit NodeRegistered(tokenId, tokenURI, nodeEntry);
    }

    /**
     * @notice Unregister a node by personal wallet.
     * @param tokenId Node Id to be removed.
     */
    function burn(
        uint256 tokenId
    ) external nonReentrant {
        require(
            _exists(tokenId),
            "NodeRegistry: invalid nodeId"
        );
        require(
            ownerOf(tokenId) == msg.sender || msg.sender == owner(),
            "NodeRegistry: caller is not node owner or contract owner"
        );
        super._burn(tokenId);
        
        Node memory nodeToBurn = _allTokens[tokenId];
        _tokens.remove(tokenId);
        _nodeToTokenId[nodeToBurn.tokenURI][nodeToBurn.nodeEntry] = 0;
        delete _allTokens[tokenId];

        emit NodeUnregistered(tokenId);
    }

    /**
     * @notice Update node by personal wallet.
     * @param tokenId Node Id to be updated.
     * @param tokenURI Updated node uri.
     * @param nodeEntry Updated node entry.
     */
    function updateNode(
        uint256 tokenId,
        string memory tokenURI,
        string memory nodeEntry
    ) external nonReentrant {
        require(
            _exists(tokenId),
            "NodeRegistry: invalid nodeId"
        );
        require(
            ownerOf(tokenId) == msg.sender,
            "NodeRegistry: caller is not node owner"
        );
        require(
            _nodeToTokenId[tokenURI][nodeEntry] == 0,
            "NodeRegistry: duplicated node"
        );
        Node memory updatedNode = _allTokens[tokenId];
        _nodeToTokenId[updatedNode.tokenURI][updatedNode.nodeEntry] = 0;

        updatedNode.tokenURI = tokenURI;
        updatedNode.nodeEntry = nodeEntry;

        _allTokens[tokenId] = updatedNode;
        _nodeToTokenId[tokenURI][nodeEntry] = tokenId;

        emit NodeUpdated(tokenId, tokenURI, nodeEntry);
    }

    /**
     * @notice Reveal node
     */
    function reveal() external nonReentrant onlyOwner {
        require(_isRevealed == 0, "NodeRegistry: node is already revealed");
        _isRevealed = 1;
        emit Revealed(1);
    }

    /**
     * @notice Get revealed state
     * @return Revealed state
     */
    function isRevealed() external view returns (uint256) {
        return _isRevealed;
    }

    /**
     * @notice Override to check if the node is revealed or not before transfer
     * @param from Address of sender.
     * @param to Address of receiver.
     * @param tokenId node Id.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0) && to != address(0))
            require(_isRevealed == 1, "NodeRegistry: node is not revealed");
    }

    /**
     * @notice Get node by nodeId
     * @param tokenId Node Id.
     * @return Node information.
     */
    function nodeInfo(
        uint256 tokenId
    ) external view returns (Node memory) {
        return _allTokens[tokenId];
    }

    /**
     * @notice Get count of existing nodes.
     * @return count existing node count.
     */
    function nodeCount() public view returns (uint256) {
        return _tokens.length();
    }

    /**
     * @notice Get node by nodeId
     * @param index Index of node.
     * @return Node information.
     */
    function nodeByIndex(
        uint256 index
    ) external view returns (Node memory) {
        uint256 tokenId = _tokens.at(index);
        return _allTokens[tokenId];
    }

    /**
     * @notice Get list of existing nodes.
     * @return The list of existing node ids
     */
    function nodeIds() external view returns (bytes32[] memory) {
        return _tokens.get();
    }

    /**
     * @notice Get count of nodes by owner address
     * @param ownerAddr ESC address of owner.
     * @return Node count.
     */
    function ownedNodeCount(
        address ownerAddr
    ) public view returns (uint256) {
        return balanceOf(ownerAddr);
    }

    /**
     * @notice Get count of nodes by owner address
     * @param ownerAddr ESC address of owner.
     * @param index Index of node.
     * @return Node info.
     */
    function ownedNodeByIndex(
        address ownerAddr,
        uint256 index
    ) external view returns (Node memory) {
        uint256 tokenId = tokenOfOwnerByIndex(ownerAddr, index);
        return _allTokens[tokenId];
    }

    /**
     * @notice Get list of nodes by owner address
     * @param ownerAddr ESC address of owner.
     * @return nodeIds list of node Ids.
     */
    function ownedNodeIds(
        address ownerAddr
    ) external view returns (bytes32[] memory) {
        return holderTokens(ownerAddr);
    }

    /**
     * @notice Check validity of given nodeId.
     * @param tokenId Node Id to check.
     * @return The validity of nodeId
     */
    function isValidNodeId(
        uint256 tokenId
    ) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Get last tokenId.
     * @return The last nodeId
     */
    function getLastTokenId() external view returns (uint256) {
        return _lastTokenId;
    }

    /**
     * @notice Get node Id from node uri and node entry.
     * @param tokenURI Node URI.
     * @param nodeEntry Node Entry.
     * @return The node Id
     */
    function getTokenId(
        string memory tokenURI, string memory nodeEntry
    ) external view returns (uint256) {
        return _nodeToTokenId[tokenURI][nodeEntry];
    }

    /**
     * @dev Set platform fee config.
     * @param platformAddr Address of platform
     * @param platformFee Platform Fee
     */
    function setPlatformFee(
        address platformAddr,
        uint256 platformFee
    ) external onlyOwner {
        require(
            _setPlatformAddr(platformAddr, platformFee),
            "NodeRegistry: set platform fee failed"
        );
    }

    /**
     * @dev Set platform address config.
     * @param platformAddr Address of platform
     * @param platformFee Platform Fee
     * @return success success or failed
     */
    function _setPlatformAddr(address platformAddr, uint256 platformFee) internal returns (bool) {
        require(
            platformAddr != address(0),
            "NodeRegistry: invalid platform address"
        );
        _platformAddr = platformAddr;
        _platformFee = platformFee;
        emit PlatformFeeChanged(platformAddr, platformFee);
        return true;
    }

    /**
     * @dev Get platform address config
     * @return platformAddress address of platform
     * @return platformFee platform fee
     */
    function getPlatformFee() external view returns (address platformAddress, uint256 platformFee) {
        platformAddress = _platformAddr;
        platformFee = _platformFee;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
