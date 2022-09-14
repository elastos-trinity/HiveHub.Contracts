// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "../common/Agentable.sol";
import "../common/ReentrancyGuardUpgradeable.sol";
import "../common/EnumerableSet.sol";
import "../token/ERC20/IERC20.sol";
import "../token/ERC721/ERC721.sol";

contract NodeRegistry is Agentable, ReentrancyGuardUpgradeable, ERC721 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice RegisterFee is chareged on registeration.
     * @param tokenId Node unique Id.
     * @param platformAddr Platform address to receive register fees.
     * @param quoteToken ERC20 token address or native token (ELA) with 0x0
     * @param registerFee Register fee.
     */
    event RegisteredFees(
        uint256 tokenId,
        address platformAddr,
        address quoteToken,
        uint256 registerFee
    );

    /**
     * @notice A new node is registered.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node  entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     * @param ownerAddr ESC address to make register transaction.
     * @param agentAddr ESC address of agent, if none it can be 0.
     */
    event NodeRegistered(
        uint256 tokenId,
        string tokenURI,
        string nodeEntry,
        address receiptAddr,
        address ownerAddr,
        address agentAddr
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
     * @param tokenId Revealed node Id.
     */
    event NodeRevealed(uint256 tokenId);

    /**
     * @dev MUST emit when platform fee config is updated.
     * The `platformAddress` argument MUST be the address of the platform.
     */
    event PlatformFeeChanged(
        address platformAddress
    );

    /**
     * @dev MUST emit when a new agent is added.
     * The `account` argument MUST be the updated account.
     */
    event AgentAdded(
        address account
    );

    /**
     * @dev MUST emit when a new agent is removed.
     * The `account` argument MUST be the updated account.
     */
    event AgentRemoved(
        address account
    );

    struct Node {
        uint256 tokenId;
        string tokenURI;
        string nodeEntry;
        address receiptAddr;
        address ownerAddr;
        address agentAddr;
        bool isRevealed;
    }

    string private constant _name = "Hive Node Token Collection";
    string private constant _symbol = "HNTC";
    address private _platformAddr;
    mapping(uint256 => Node) private _allTokens;
    EnumerableSet.UintSet private _tokens;
    mapping(address => EnumerableSet.UintSet) private _agentTokens;
    // EnumerableSet.AddressSet private _agents;
    address[] private _agents;
    mapping(address => uint256) private agentToIndex; // agent => index of _agents

    /**
     * @notice Initialize a node registry contract with platform address info.
     * @param platformAddress_ platform address.
     */
    function initialize(address platformAddress_) external initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        require(
            _setPlatformAddr(platformAddress_),
            "NodeRegistry: initialize platform address failed"
        );
    }

    /**
     * @notice Register a new node by personal wallet.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param quoteToken address of quote token.
     * @param mintFee amount of ERC20 token.
     */
     function mint(
        uint256 tokenId,   //nodeId
        string memory tokenURI,  //nodeURI
        string memory nodeEntry,
        address quoteToken,
        uint256 mintFee
    ) external payable nonReentrant {
        _mintByWallet(tokenId, tokenURI, nodeEntry, msg.sender, quoteToken, mintFee);
    }

    /**
     * @notice Register a new node by personal wallet.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     * @param quoteToken address of quote token.
     * @param mintFee amount of ERC20 token.
     */
    function mint(
        uint256 tokenId,   //nodeId
        string memory tokenURI,  //nodeURI
        string memory nodeEntry,
        address receiptAddr,
        address quoteToken,
        uint256 mintFee
    ) external payable nonReentrant {
        _mintByWallet(tokenId, tokenURI, nodeEntry, receiptAddr, quoteToken, mintFee);
    }

    /**
     * @notice Register a new node by agent.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     * @param ownerAddr ESC address to make register transaction.
     */
    function mint(
        uint256 tokenId,   //nodeId
        string memory tokenURI,  //nodeURI
        string memory nodeEntry,
        address receiptAddr,
        address ownerAddr
    ) external onlyAgentOrOwner nonReentrant {
        require(
            receiptAddr != address(0),
            "NodeRegistry: invalid receipt address"
        );
        require(
            ownerAddr != address(0),
            "NodeRegistry: invalid node owner address"
        );

        _mintNewnode(tokenId, tokenURI, nodeEntry, receiptAddr, ownerAddr, msg.sender);
    }

    /**
     * @notice Register a new node by personal wallet.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     * @param quoteToken address of quote token.
     * @param mintFee amount of ERC20 token.
     */
    function _mintByWallet(
        uint256 tokenId,
        string memory tokenURI,
        string memory nodeEntry,
        address receiptAddr,
        address quoteToken,
        uint256 mintFee
    ) internal virtual {
        require(
            receiptAddr != address(0),
            "NodeRegistry: invalid receipt address"
        );

        uint256 registerFee = quoteToken == address(0) ? msg.value : mintFee;
        if (quoteToken == address(0)) {
            if (registerFee > 0) {
                bool success;
                (success, ) = payable(_platformAddr).call{value: registerFee}("");
                require(success, "NodeRegistry: register fee transfer failed");
            }
        } else {
            require( msg.value == 0,
                "NodeRegistry: Do not pay ETH when register with ERC20 token"
            );
            if (registerFee > 0) {
                require(
                    IERC20(quoteToken).allowance(msg.sender, address(this)) >= registerFee,
                    "NodeRegistry: Not enough quote token approved for the register"
                );

                uint256 beforeBalance = IERC20(quoteToken).balanceOf(address(msg.sender));
                require(
                    IERC20(quoteToken).transferFrom(msg.sender, _platformAddr, registerFee),
                    "NodeRegistry: register fee transfer failed"
                );
                require(
                    beforeBalance.sub(IERC20(quoteToken).balanceOf(address(msg.sender))) == registerFee,
                    "NodeRegistry: Non-standard ERC20 token not supported"
                );
            }
        }

        emit RegisteredFees(
                tokenId,
                _platformAddr,
                quoteToken,
                registerFee
            );
        _mintNewnode(tokenId, tokenURI, nodeEntry, receiptAddr, msg.sender, address(0));
    }

    /**
     * @notice Register a new node.
     * @param tokenId Node unique Id.
     * @param tokenURI Node uri.
     * @param nodeEntry Node entry.
     * @param receiptAddr ESC address to receive tipping or other payments.
     * @param ownerAddr ESC address to make register transaction.
     * @param agentAddr address of agent, if none it can be 0.
     */
    function _mintNewnode(
        uint256 tokenId,
        string memory tokenURI,
        string memory nodeEntry,
        address receiptAddr,
        address ownerAddr,
        address agentAddr
    ) internal virtual {
        _mint(ownerAddr, tokenId);
        _setTokenURI(tokenId, tokenURI);

        Node memory newNode;
        newNode.tokenId = tokenId;
        newNode.tokenURI = tokenURI;
        newNode.nodeEntry = nodeEntry;
        newNode.receiptAddr = receiptAddr;
        newNode.ownerAddr = ownerAddr;
        newNode.agentAddr = agentAddr;
        newNode.isRevealed = false;

        _allTokens[tokenId] = newNode;
        // registered nodes
        _tokens.add(tokenId);
        // registered nodes by registerants.
        if (agentAddr != address(0)) {
            _agentTokens[agentAddr].add(tokenId);
        }

        emit NodeRegistered(tokenId, tokenURI, nodeEntry, receiptAddr, ownerAddr, agentAddr);
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
     * @notice Unregister a node by agent.
     * @param tokenId Node Id to be removed.
     * @param ownerAddr address of node owner.
     */
    function burn(
        uint256 tokenId,
        address ownerAddr
    ) external onlyAgentOrOwner nonReentrant {
        require(
            _exists(tokenId),
            "NodeRegistry: invalid nodeId"
        );
        require(
            ownerOf(tokenId) == ownerAddr,
            "NodeRegistry: invalid node owner address"
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
        // agent nodes
        address agentAddr = _allTokens[tokenId].agentAddr;
        if (agentAddr != address(0)) {
            _agentTokens[agentAddr].remove(tokenId);
        }
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
    function updatenode(
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
     * @notice Update node by agent.
     * @param tokenId Node Id to be updated.
     * @param tokenURI Updated node uri.
     * @param receiptAddr Updated ESC address to receive tipping.
     * @param ownerAddr Address of node owner.
     */
    function updateNode(
        uint256 tokenId,
        string memory tokenURI,
        address receiptAddr,
        address ownerAddr
    ) external onlyAgentOrOwner nonReentrant {
        require(
            _exists(tokenId),
            "NodeRegistry: invalid nodeId"
        );
        require(
            ownerOf(tokenId) == ownerAddr,
            "NodeRegistry: invalid node owner address"
        );

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
     * @param tokenId node Id.
     */
    function revealNode(uint256 tokenId) external nonReentrant onlyOwner {
        require(_exists(tokenId), "NodeRegistry: invalid nodeId");
        _allTokens[tokenId].isRevealed = true;
        emit NodeRevealed(tokenId);
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
            require(_allTokens[tokenId].isRevealed == true, "NodeRegistry: node is not revealed");
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
     * @notice Get count of nodes registered by given agent.
     * @param agentAddr ESC address of agent.
     * @return The count of nodes.
     */
    function agentNodeCount(
        address agentAddr
    ) public view returns (uint256) {
        return _agentTokens[agentAddr].length();
    }

    /**
     * @notice Get count of nodes by agent address
     * @param agentAddr ESC address of agent.
     * @param index Index of node.
     * @return Node info.
     */
    function agentNodeByIndex(
        address agentAddr,
        uint256 index
    ) external view returns (Node memory) {
        uint256 tokenId = _agentTokens[agentAddr].at(index);
        return _allTokens[tokenId];
    }

    /**
     * @notice Get list of nodes by agent address
     * @param agentAddr ESC address of agent.
     * @return The list of node Ids.
     */
    function agentNodeIds(
        address agentAddr
    ) external view returns (bytes32[] memory) {
        return _agentTokens[agentAddr].get();
    }

    /**
     * @notice Set agent role.
     */
    function _setAgent(address _addr, bool _state) internal virtual override {
        super._setAgent(_addr, _state);
        if (_state) {
            // _agents.add(_addr);
            agentToIndex[_addr] = _agents.length;
            _agents.push(_addr);
            emit AgentAdded(_addr);
        }
        else {
            // _agents.remove(_addr);
            _agents[agentToIndex[_addr]] = _agents[_agents.length - 1];
            agentToIndex[_agents[_agents.length - 1]] = agentToIndex[_addr];
            _agents.pop();
            emit AgentRemoved(_addr);
        }
    }

    /**
     * @notice Get count of agents.
     * @return count the count of agent addresses.
     */
    function agentCount() external view returns (uint256) {
        return _agents.length;
    }

    /**
     * @notice Get list of agents.
     * @return agents the list of agent addresses.
     */
    function agents() external view returns (address[] memory) {
        return _agents;
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
     * @param platformAddr address of platform
     */
    function setPlatformAddr(
        address platformAddr
    ) external onlyOwner {
        require(
            _setPlatformAddr(platformAddr), 
            "NodeRegistry: set platform address failed"
        );
    }

    /**
     * @dev Set platform address config.
     * @param platformAddr address of platform
     * @return success success or failed
     */
    function _setPlatformAddr(address platformAddr) internal returns (bool) {
        require(
            platformAddr != address(0),
            "NodeRegistry: invalid platform address"
        );
        _platformAddr = platformAddr;
        emit PlatformFeeChanged(platformAddr);
        return true;
    }

    /**
     * @dev Get platform address config
     * @return platformAddress address of platform
     */
    function platformAddress() external view returns (address) {
        return _platformAddr;
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
