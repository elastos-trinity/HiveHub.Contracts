// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "../common/OwnableUpgradeable.sol";
import "../common/ReentrancyGuardUpgradeable.sol";
import "../common/EnumerableSet.sol";
import "../token/ERC20/IERC20.sol";
import "../token/ERC721/ERC721.sol";

contract NodeRegistry is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

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
     * @param receiptAddr ESC address to receive tipping or other payments.
     * @param ownerAddr ESC address to make register transaction.
     */
    event NodeRegistered(
        uint256 tokenId,
        string tokenURI,
        string nodeEntry,
        address receiptAddr,
        address ownerAddr
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
     */
    event NodeUpdated(
        uint256 tokenId,
        string newNodeURI
    );

    /**
     * @notice Node revealed event
     * @param state Revealed state, 1 for true, 0 for false
     */
    event revealed(uint256 state);

    /**
     * @dev MUST emit when platform fee config is updated.
     * The `platformAddress` argument MUST be the address of the platform.
     * The `platformFee` argument MUST be the fee rate of the platform.
     */
    event PlatformFeeChanged(
        address platformAddress,
        uint256 platformFee
    );

    struct Node {
        uint256 tokenId;
        string tokenURI;
        string nodeEntry;
        address receiptAddr;
        address ownerAddr;
    }

    string private constant _name = "Hive Node Token Collection";
    string private constant _symbol = "HNTC";
    uint256 private _isRevealed;
    uint256 private _platformFee;
    address private _platformAddr;
    mapping(uint256 => Node) private _allTokens;
    EnumerableSet.UintSet private _tokens;

    /**
     * @notice Initialize a node registry contract with platform address info.
     * @param platformAddress_ platform address.
     * @param platformFee_ platform fee.
     */
    function initialize(address platformAddress_, uint256 platformFee_) external initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        require(
            _setPlatformAddr(platformAddress_, platformFee_),
            "NodeRegistry: initialize platform fee failed"
        );
    }

    /**
     * @notice Register a new node by personal wallet.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     */
     function mint(
        uint256 tokenId,   // nodeId
        string memory tokenURI,  // nodeURI
        string memory nodeEntry
    ) external payable nonReentrant {
        _mint(tokenId, tokenURI, nodeEntry, msg.sender);
    }

    /**
     * @notice Register a new node by personal wallet.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     */
    function mint(
        uint256 tokenId,   //nodeId
        string memory tokenURI,  //nodeURI
        string memory nodeEntry,
        address receiptAddr
    ) external payable nonReentrant {
        _mint(tokenId, tokenURI, nodeEntry, receiptAddr);
    }

    /**
     * @notice Register a new node by personal wallet.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     */
    function _mint(
        uint256 tokenId,
        string memory tokenURI,
        string memory nodeEntry,
        address receiptAddr
    ) internal virtual {
        require(
            receiptAddr != address(0),
            "NodeRegistry: invalid receipt address"
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
        emit RegisteredFees(tokenId, _platformAddr, msg.value);
        _mintNewNode(tokenId, tokenURI, nodeEntry, receiptAddr, msg.sender);
    }

    /**
     * @notice Register a new node.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     * @param ownerAddr ESC address to make register transaction.
     */
    function _mintNewNode(
        uint256 tokenId,
        string memory tokenURI,
        string memory nodeEntry,
        address receiptAddr,
        address ownerAddr
    ) internal virtual {
        _mint(ownerAddr, tokenId);
        _setTokenURI(tokenId, tokenURI);

        Node memory newNode;
        newNode.tokenId = tokenId;
        newNode.tokenURI = tokenURI;
        newNode.nodeEntry = nodeEntry;
        newNode.receiptAddr = receiptAddr;
        newNode.ownerAddr = ownerAddr;

        _allTokens[tokenId] = newNode;
        _tokens.add(tokenId);

        emit NodeRegistered(tokenId, tokenURI, nodeEntry, receiptAddr, ownerAddr);
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

        _burn(tokenId);
    }

    /**
     * @notice Unregister a node.
     * @param tokenId Node Id to be removed.
     */
    function _burn(
        uint256 tokenId
    ) internal virtual override {
        super._burn(tokenId);
        // registered nodes
        _tokens.remove(tokenId);
        // Clear _allTokens
        if (_allTokens[tokenId].tokenId != 0) {
            delete _allTokens[tokenId];
        }

        emit NodeUnregistered(tokenId);
    }

    /**
     * @notice Update node by personal wallet.
     * @param tokenId Node Id to be updated.
     * @param tokenURI Updated node uri.
     * @param receiptAddr updated ESC address to receive tipping.
     */
    function updateNode(
        uint256 tokenId,
        string memory tokenURI,
        address receiptAddr
    ) external nonReentrant {
        require(
            _exists(tokenId),
            "NodeRegistry: invalid nodeId"
        );
        require(
            ownerOf(tokenId) == msg.sender,
            "NodeRegistry: caller is not node owner"
        );
        // receipt Addr can be 0x0, which means no changes.
        _updateNode(tokenId, tokenURI, receiptAddr);
    }

    /**
     * @notice Update node info.
     * @param tokenId Node Id to be updated.
     * @param tokenURI Node uri.
     * @param receiptAddr ESC address to receive tipping.
     */
    function _updateNode(
        uint256 tokenId,
        string memory tokenURI,
        address receiptAddr
    ) internal {
        Node memory updatedNode = _allTokens[tokenId];
        updatedNode.tokenId = tokenId;
        updatedNode.tokenURI = tokenURI;
        if (receiptAddr != address(0))
            updatedNode.receiptAddr = receiptAddr;
        _allTokens[tokenId] = updatedNode;

        emit NodeUpdated(tokenId, tokenURI);
    }

    /**
     * @notice Reveal node
     */
    function reveal() external nonReentrant onlyOwner {
        require(_isRevealed == 0, "NodeRegistry: node is already revealed");
        _isRevealed = 1;
        emit revealed(1);
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
     * @notice Override to change ownership of the token
     * @param from Address of sender.
     * @param to Address of receiver.
     * @param tokenId node Id.
     */
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        _allTokens[tokenId].ownerAddr = to;
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
