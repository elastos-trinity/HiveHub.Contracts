const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { parseEther } = require("ethers/lib/utils");
const { ethers, upgrades } = require("hardhat");

describe("NodeRegistry Contract", function () {
    let NodeRegistry, nodeRegistry, TESTERC20, testERC20, MockNR, mockNR;
    let owner, addr1, addr2, addrs, platform;
    let receipt1, receipt2, receipt3, receipt4, receipt5;

    before(async function () {
        NodeRegistry = await ethers.getContractFactory("NodeRegistry");
        TESTERC20 = await ethers.getContractFactory("TestERC20");
        MockNR = await ethers.getContractFactory("MockNR");
    });

    beforeEach(async function () {
        [owner, addr1, addr2, platform, receipt1, receipt2, receipt3, receipt4, receipt5, ...addrs] = await ethers.getSigners();
        // deploy test erc20 token
        testERC20 = await TESTERC20.deploy();
        await testERC20.deployed();
        // deploy proxy contract
        nodeRegistry = await upgrades.deployProxy(NodeRegistry, [platform.address]);
        await nodeRegistry.deployed();
    });

    describe("Deployments", function () {
        it("Should be able to register / unregister / update nodes by personal wallet", async function () {
            const registerFee = parseEther('1');
            const node1 = { owner: addr1.address, nodeId: BigNumber.from("1"), nodeUri: "first node uri", nodeEntry: "first node entry", receipt: receipt1.address, quoteToken: ethers.constants.AddressZero, value: registerFee, price: registerFee, fee: registerFee, updatedNodeUri: "updated first node uri", updatedReceipt: receipt1.address }; // Native token (value != 0) - 6 args
            const node2 = { owner: addr2.address, nodeId: BigNumber.from("2"), nodeUri: "second node uri", nodeEntry: "second node entry", receipt: addr2.address, quoteToken: ethers.constants.AddressZero, value: 0, price: registerFee, fee: registerFee, updatedNodeUri: "updated second node uri", updatedReceipt: receipt1.address }; // Native token (value == 0) - 5 args
            const node3 = { owner: owner.address, nodeId: BigNumber.from("3"), nodeUri: "third node uri", nodeEntry: "third node entry", receipt: receipt3.address, quoteToken: testERC20.address, value: registerFee, price: 0, fee: registerFee, updatedNodeUri: "updated third node uri", updatedReceipt: receipt4.address }; // ERC20 token (price == 0) - 6 args
            const node4 = { owner: addr1.address, nodeId: BigNumber.from("4"), nodeUri: "fourth node uri", nodeEntry: "fourth node entry", receipt: addr1.address, quoteToken: testERC20.address, value: 0, price: 0, fee: 0, updatedNodeUri: "updated fourth node uri", updatedReceipt: receipt2.address }; // ERC20 token (value, price == 0 : no fee) - 5 args
            const node5 = { owner: owner.address, nodeId: BigNumber.from("5"), nodeUri: "fifth node uri", nodeEntry: "fifth node entry", receipt: receipt5.address, quoteToken: ethers.constants.AddressZero, value: 0, price: 0, fee: 0, updatedNodeUri: node1.nodeUri, updatedReceipt: ethers.constants.AddressZero }; // Native token (value, price == 0 : no fee) - 6 args
            const node6 = { owner: addr1.address, nodeId: BigNumber.from("6"), nodeUri: "sixth node uri", nodeEntry: "sixth node entry", receipt: receipt1.address, quoteToken: ethers.constants.AddressZero, value: registerFee, price: 0, fee: registerFee, updatedNodeUri: "updated sixth node uri", updatedReceipt: ethers.constants.AddressZero };
            const node7 = { owner: addr2.address, nodeId: BigNumber.from("7"), nodeUri: "seventh node uri", nodeEntry: "seventh node entry", receipt: receipt1.address, quoteToken: ethers.constants.AddressZero, value: 0, price: registerFee, fee: 0, updatedNodeUri: "updated seventh node uri", updatedReceipt: receipt3.address };

            let preBalanceAddr1, preBalanceContract, preBalancePlat, preBalanceOwner;
            let nodes, node_1, node_2, node_3, node_4, node_5, node_6, node_7, ownernodes, addr1nodes, addr2nodes;

            // ********************************************************  Register  ******************************************************** //
            // check input value for register
            await expect(nodeRegistry.connect(addr1)['mint(uint256,string,string,address,address,uint256)'](node1.nodeId, node1.nodeUri, node1.nodeEntry, ethers.constants.AddressZero, node1.quoteToken, node1.value, { value: node1.price })).to.be.revertedWith("NodeRegistry: invalid receipt address");

            // check platform fee config
            const platformAddr = await nodeRegistry.platformAddress();
            expect(platformAddr).to.be.equal(platform.address);

            // register with native token (value != 0)
            // check balance
            const provider = ethers.provider;
            preBalanceAddr1 = await provider.getBalance(addr1.address);
            preBalanceContract = await provider.getBalance(nodeRegistry.address);
            preBalancePlat = await provider.getBalance(platform.address);
            // register
            await expect(nodeRegistry.connect(addr1)['mint(uint256,string,string,address,address,uint256)'](node1.nodeId, node1.nodeUri, node1.nodeEntry, node1.receipt, node1.quoteToken, node1.value, { value: node1.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node1.nodeId, platform.address, node1.quoteToken, node1.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node1.nodeId, node1.nodeUri, node1.nodeEntry, node1.receipt, node1.owner);
            // check balance
            expect(await provider.getBalance(nodeRegistry.address)).to.be.equal(preBalanceContract);
            expect((await provider.getBalance(platform.address)).sub(preBalancePlat)).to.be.equal(node1.fee);

            // register with same nodeId will be reverted
            await expect(nodeRegistry.connect(addr2)['mint(uint256,string,string,address,address,uint256)'](node1.nodeId, node2.nodeUri, node2.nodeEntry, node2.receipt, node2.quoteToken, node2.value, { value: node2.price })).to.be.revertedWith("ERC721: token already minted");


            // register with native token (value == 0)
            await expect(nodeRegistry.connect(addr2)['mint(uint256,string,string,address,uint256)'](node2.nodeId, node2.nodeUri, node2.nodeEntry, node2.quoteToken, node2.value, { value: node2.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node2.nodeId, platform.address, node2.quoteToken, node2.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node2.nodeId, node2.nodeUri, node2.nodeEntry, node2.receipt, node2.owner);

            // register with ERC20 token (value != 0)
            await expect(nodeRegistry.connect(owner)['mint(uint256,string,string,address,address,uint256)'](node3.nodeId, node3.nodeUri, node3.nodeEntry, node3.receipt, node3.quoteToken, node3.value, { value: registerFee })).to.be.revertedWith("Do not pay ETH when register with ERC20 token");
            await expect(nodeRegistry.connect(owner)['mint(uint256,string,string,address,address,uint256)'](node3.nodeId, node3.nodeUri, node3.nodeEntry, node3.receipt, node3.quoteToken, node3.value, { value: node3.price })).to.be.revertedWith("NodeRegistry: Not enough quote token approved for the register");
            // approve certain amount of testERC20 to contract
            await testERC20.connect(owner).approve(nodeRegistry.address, node3.value);
            // check testERC20 balance
            preBalanceOwner = await testERC20.balanceOf(owner.address);
            preBalancePlat = await testERC20.balanceOf(platform.address);
            // register
            await expect(nodeRegistry.connect(owner)['mint(uint256,string,string,address,address,uint256)'](node3.nodeId, node3.nodeUri, node3.nodeEntry, node3.receipt, node3.quoteToken, node3.value, { value: node3.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node3.nodeId, platform.address, node3.quoteToken, node3.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node3.nodeId, node3.nodeUri, node3.nodeEntry, node3.receipt, node3.owner);
            // check testERC20 balance
            expect(preBalanceOwner.sub(await testERC20.balanceOf(owner.address))).to.be.equal(node3.fee);
            expect((await testERC20.balanceOf(platform.address)).sub(preBalancePlat)).to.be.equal(node3.fee);

            // register with ERC20 token (value != 0: no fee)
            await expect(nodeRegistry.connect(addr1)['mint(uint256,string,string,address,address,uint256)'](node4.nodeId, node4.nodeUri, node3.nodeEntry, node4.receipt, node4.quoteToken, node4.value, { value: registerFee })).to.be.revertedWith("Do not pay ETH when register with ERC20 token");
            // check testERC20 balance
            preBalanceAddr1 = await testERC20.balanceOf(addr1.address);
            preBalancePlat = await testERC20.balanceOf(platform.address);
            // register
            await expect(nodeRegistry.connect(addr1)['mint(uint256,string,string,address,uint256)'](node4.nodeId, node4.nodeUri, node4.nodeEntry, node4.quoteToken, node4.value, { value: node4.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node4.nodeId, platform.address, node4.quoteToken, node4.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node4.nodeId, node4.nodeUri, node4.nodeEntry, node4.receipt, node4.owner);
            // check testERC20 balance
            expect(preBalanceAddr1.sub(await testERC20.balanceOf(addr1.address))).to.be.equal(node4.fee);
            expect((await testERC20.balanceOf(platform.address)).sub(preBalancePlat)).to.be.equal(node4.fee);

            // register with native token (value == 0, fee = 0)
            await expect(nodeRegistry.connect(owner)['mint(uint256,string,string,address,address,uint256)'](node5.nodeId, node5.nodeUri, node5.nodeEntry, node5.receipt, node5.quoteToken, node5.value, { value: node5.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node5.nodeId, platform.address, node5.quoteToken, node5.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node5.nodeId, node5.nodeUri, node5.nodeEntry, node5.receipt, node5.owner);

            // ********************************************************  Check state  ******************************************************** //
            // get node by id (nodeInfo)
            node_1 = await nodeRegistry.nodeInfo(node1.nodeId);
            expect(node_1.tokenId).to.be.equal(node1.nodeId);
            expect(node_1.tokenURI).to.be.equal(node1.nodeUri);
            expect(node_1.nodeEntry).to.be.equal(node1.nodeEntry);
            expect(node_1.receiptAddr).to.be.equal(node1.receipt);
            expect(node_1.ownerAddr).to.be.equal(node1.owner);

            node_2 = await nodeRegistry.nodeInfo(node2.nodeId);
            expect(node_2.tokenId).to.be.equal(node2.nodeId);
            expect(node_2.tokenURI).to.be.equal(node2.nodeUri);
            expect(node_2.nodeEntry).to.be.equal(node2.nodeEntry);
            expect(node_2.receiptAddr).to.be.equal(node2.receipt);
            expect(node_2.ownerAddr).to.be.equal(node2.owner);

            node_3 = await nodeRegistry.nodeInfo(node3.nodeId);
            expect(node_3.tokenId).to.be.equal(node3.nodeId);
            expect(node_3.tokenURI).to.be.equal(node3.nodeUri);
            expect(node_3.nodeEntry).to.be.equal(node3.nodeEntry);
            expect(node_3.receiptAddr).to.be.equal(node3.receipt);
            expect(node_3.ownerAddr).to.be.equal(node3.owner);

            node_4 = await nodeRegistry.nodeInfo(node4.nodeId);
            expect(node_4.tokenId).to.be.equal(node4.nodeId);
            expect(node_4.tokenURI).to.be.equal(node4.nodeUri);
            expect(node_4.nodeEntry).to.be.equal(node4.nodeEntry);
            expect(node_4.receiptAddr).to.be.equal(node4.receipt);
            expect(node_4.ownerAddr).to.be.equal(node4.owner);

            node_5 = await nodeRegistry.nodeInfo(node5.nodeId);
            expect(node_5.tokenId).to.be.equal(node5.nodeId);
            expect(node_5.tokenURI).to.be.equal(node5.nodeUri);
            expect(node_5.nodeEntry).to.be.equal(node5.nodeEntry);
            expect(node_5.receiptAddr).to.be.equal(node5.receipt);
            expect(node_5.ownerAddr).to.be.equal(node5.owner);

            // get nodes
            // count
            expect(await nodeRegistry.nodeCount()).to.be.equal(5);
            // nodes by index
            expect((await nodeRegistry.nodeByIndex(0)).tokenId).to.be.equal(node1.nodeId);
            expect((await nodeRegistry.nodeByIndex(1)).tokenId).to.be.equal(node2.nodeId);
            expect((await nodeRegistry.nodeByIndex(2)).tokenId).to.be.equal(node3.nodeId);
            expect((await nodeRegistry.nodeByIndex(3)).tokenId).to.be.equal(node4.nodeId);
            expect((await nodeRegistry.nodeByIndex(4)).tokenId).to.be.equal(node5.nodeId);
            await expect(nodeRegistry.nodeByIndex(5)).to.be.revertedWith("EnumerableSet: index out of bounds");
            // nodeIds
            nodes = await nodeRegistry.nodeIds();
            expect(nodes.length).to.be.equal(5);
            expect(nodes[0]).to.be.equal(node1.nodeId);
            expect(nodes[1]).to.be.equal(node2.nodeId);
            expect(nodes[2]).to.be.equal(node3.nodeId);
            expect(nodes[3]).to.be.equal(node4.nodeId);
            expect(nodes[4]).to.be.equal(node5.nodeId);

            // get owend nodes
            // count
            expect(await nodeRegistry.ownedNodeCount(owner.address)).to.be.equal(2);
            expect(await nodeRegistry.ownedNodeCount(addr1.address)).to.be.equal(2);
            expect(await nodeRegistry.ownedNodeCount(addr2.address)).to.be.equal(1);
            // nodes by index
            expect((await nodeRegistry.ownedNodeByIndex(owner.address, 0)).tokenId).to.be.equal(node3.nodeId);
            expect((await nodeRegistry.ownedNodeByIndex(owner.address, 1)).tokenId).to.be.equal(node5.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(owner.address, 2)).to.be.revertedWith("EnumerableSet: index out of bounds");
            expect((await nodeRegistry.ownedNodeByIndex(addr1.address, 0)).tokenId).to.be.equal(node1.nodeId);
            expect((await nodeRegistry.ownedNodeByIndex(addr1.address, 1)).tokenId).to.be.equal(node4.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(addr1.address, 2)).to.be.revertedWith("EnumerableSet: index out of bounds");
            expect((await nodeRegistry.ownedNodeByIndex(addr2.address, 0)).tokenId).to.be.equal(node2.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(addr2.address, 1)).to.be.revertedWith("EnumerableSet: index out of bounds");
            // nodeIds
            ownernodes = await nodeRegistry.ownedNodeIds(owner.address);
            addr1nodes = await nodeRegistry.ownedNodeIds(addr1.address);
            addr2nodes = await nodeRegistry.ownedNodeIds(addr2.address);

            expect(ownernodes[0]).to.be.equal(node3.nodeId);
            expect(ownernodes[1]).to.be.equal(node5.nodeId);
            expect(addr1nodes[0]).to.be.equal(node1.nodeId);
            expect(addr1nodes[1]).to.be.equal(node4.nodeId);
            expect(addr2nodes[0]).to.be.equal(node2.nodeId);

            // ********************************************************  Unregister  ******************************************************** //
            // check input value for unregister
            await expect(nodeRegistry.connect(addr1)['burn(uint256)'](BigNumber.from(7))).to.be.revertedWith("NodeRegistry: invalid nodeId");
            await expect(nodeRegistry.connect(owner)['burn(uint256)'](BigNumber.from(7))).to.be.revertedWith("NodeRegistry: invalid nodeId");
            await expect(nodeRegistry.connect(addr2)['burn(uint256)'](node1.nodeId)).to.be.revertedWith("NodeRegistry: caller is not node owner or contract owner");
            // unregister with node owner
            await expect(nodeRegistry.connect(addr1)['burn(uint256)'](node1.nodeId)).to.emit(nodeRegistry, "NodeUnregistered").withArgs(node1.nodeId);
            // unregister with owner
            await expect(nodeRegistry.connect(owner)['burn(uint256)'](node2.nodeId)).to.emit(nodeRegistry, "NodeUnregistered").withArgs(node2.nodeId);
            // unregister already unregistered node
            await expect(nodeRegistry.connect(owner)['burn(uint256)'](node1.nodeId)).to.be.revertedWith("NodeRegistry: invalid nodeId");

            // ********************************************************  Check state  ******************************************************** //
            // get node by id (nodeInfo)
            node_1 = await nodeRegistry.nodeInfo(node1.nodeId);
            expect(node_1.tokenId).to.be.equal(0);
            expect(node_1.tokenURI).to.be.equal('');
            expect(node_1.nodeEntry).to.be.equal('');
            expect(node_1.receiptAddr).to.be.equal(ethers.constants.AddressZero);
            expect(node_1.ownerAddr).to.be.equal(ethers.constants.AddressZero);

            node_2 = await nodeRegistry.nodeInfo(node2.nodeId);
            expect(node_2.tokenId).to.be.equal(0);
            expect(node_2.tokenURI).to.be.equal('');
            expect(node_2.nodeEntry).to.be.equal('');
            expect(node_2.receiptAddr).to.be.equal(ethers.constants.AddressZero);
            expect(node_2.ownerAddr).to.be.equal(ethers.constants.AddressZero);

            node_3 = await nodeRegistry.nodeInfo(node3.nodeId);
            expect(node_3.tokenId).to.be.equal(node3.nodeId);
            expect(node_3.tokenURI).to.be.equal(node3.nodeUri);
            expect(node_3.nodeEntry).to.be.equal(node3.nodeEntry);
            expect(node_3.receiptAddr).to.be.equal(node3.receipt);
            expect(node_3.ownerAddr).to.be.equal(node3.owner);

            node_4 = await nodeRegistry.nodeInfo(node4.nodeId);
            expect(node_4.tokenId).to.be.equal(node4.nodeId);
            expect(node_4.tokenURI).to.be.equal(node4.nodeUri);
            expect(node_4.nodeEntry).to.be.equal(node4.nodeEntry);
            expect(node_4.receiptAddr).to.be.equal(node4.receipt);
            expect(node_4.ownerAddr).to.be.equal(node4.owner);

            node_5 = await nodeRegistry.nodeInfo(node5.nodeId);
            expect(node_5.tokenId).to.be.equal(node5.nodeId);
            expect(node_5.tokenURI).to.be.equal(node5.nodeUri);
            expect(node_5.nodeEntry).to.be.equal(node5.nodeEntry);
            expect(node_5.receiptAddr).to.be.equal(node5.receipt);
            expect(node_5.ownerAddr).to.be.equal(node5.owner);

            // get nodes
            // count
            expect(await nodeRegistry.nodeCount()).to.be.equal(3);
            // nodes by index
            expect((await nodeRegistry.nodeByIndex(0)).tokenId).to.be.equal(node5.nodeId);
            expect((await nodeRegistry.nodeByIndex(1)).tokenId).to.be.equal(node4.nodeId);
            expect((await nodeRegistry.nodeByIndex(2)).tokenId).to.be.equal(node3.nodeId);
            await expect(nodeRegistry.nodeByIndex(3)).to.be.revertedWith("EnumerableSet: index out of bounds");
            // nodeIds
            nodes = await nodeRegistry.nodeIds();
            expect(nodes.length).to.be.equal(3);
            expect(nodes[0]).to.be.equal(node5.nodeId);
            expect(nodes[1]).to.be.equal(node4.nodeId);
            expect(nodes[2]).to.be.equal(node3.nodeId);

            // get owend nodes
            // count
            expect(await nodeRegistry.ownedNodeCount(owner.address)).to.be.equal(2);
            expect(await nodeRegistry.ownedNodeCount(addr1.address)).to.be.equal(1);
            expect(await nodeRegistry.ownedNodeCount(addr2.address)).to.be.equal(0);
            // nodes by index
            expect((await nodeRegistry.ownedNodeByIndex(owner.address, 0)).tokenId).to.be.equal(node3.nodeId);
            expect((await nodeRegistry.ownedNodeByIndex(owner.address, 1)).tokenId).to.be.equal(node5.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(owner.address, 2)).to.be.revertedWith("EnumerableSet: index out of bounds");
            expect((await nodeRegistry.ownedNodeByIndex(addr1.address, 0)).tokenId).to.be.equal(node4.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(addr1.address, 1)).to.be.revertedWith("EnumerableSet: index out of bounds");
            await expect(nodeRegistry.ownedNodeByIndex(addr2.address, 0)).to.be.revertedWith("EnumerableSet: index out of bounds");
            // nodeIds
            ownernodes = await nodeRegistry.ownedNodeIds(owner.address);
            addr1nodes = await nodeRegistry.ownedNodeIds(addr1.address);
            addr2nodes = await nodeRegistry.ownedNodeIds(addr2.address);

            expect(ownernodes[0]).to.be.equal(node3.nodeId);
            expect(ownernodes[1]).to.be.equal(node5.nodeId);
            expect(addr1nodes[0]).to.be.equal(node4.nodeId);

            // ********************************************************  Update  ******************************************************** //
            // register 2 more nodes
            await expect(nodeRegistry.connect(addr1)['mint(uint256,string,string,address,address,uint256)'](node6.nodeId, node6.nodeUri, node6.nodeEntry, node6.receipt, node6.quoteToken, node6.value, { value: node6.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node6.nodeId, platform.address, node6.quoteToken, node6.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node6.nodeId, node6.nodeUri, node6.nodeEntry, node6.receipt, node6.owner);
            await expect(nodeRegistry.connect(addr2)['mint(uint256,string,string,address,address,uint256)'](node7.nodeId, node7.nodeUri, node7.nodeEntry, node7.receipt, node7.quoteToken, node7.value, { value: node7.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node7.nodeId, platform.address, node7.quoteToken, node7.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node7.nodeId, node7.nodeUri, node7.nodeEntry, node7.receipt, node7.owner);
            // update node
            // check input value
            await expect(nodeRegistry.connect(addr1)['updateNode(uint256,string,address)'](BigNumber.from(8), node4.updatedNodeUri, node4.updatedReceipt)).to.be.revertedWith("NodeRegistry: invalid nodeId");
            await expect(nodeRegistry.connect(owner)['updateNode(uint256,string,address)'](BigNumber.from(8), node2.updatedNodeUri, node4.updatedReceipt)).to.be.revertedWith("NodeRegistry: invalid nodeId");
            await expect(nodeRegistry.connect(addr2)['updateNode(uint256,string,address)'](BigNumber.from(8), node4.updatedNodeUri, node2.updatedReceipt)).to.be.revertedWith("NodeRegistry: invalid nodeId");
            await expect(nodeRegistry.connect(addr2)['updateNode(uint256,string,address)'](node4.nodeId, node4.updatedNodeUri, node4.updatedReceipt)).to.be.revertedWith("NodeRegistry: caller is not node owner");
            await expect(nodeRegistry.connect(owner)['updateNode(uint256,string,address)'](node4.nodeId, node4.updatedNodeUri, node4.updatedReceipt)).to.be.revertedWith("NodeRegistry: caller is not node owner");

            await expect(nodeRegistry.connect(addr1)['updateNode(uint256,string,address)'](node4.nodeId, node2.nodeUri, node2.receipt)).to.emit(nodeRegistry, "NodeUpdated").withArgs(node4.nodeId, node2.nodeUri);
            await expect(nodeRegistry.connect(owner)['updateNode(uint256,string,address)'](node5.nodeId, node5.updatedNodeUri, node5.updatedReceipt)).to.emit(nodeRegistry, "NodeUpdated").withArgs(node5.nodeId, node5.updatedNodeUri);
            await expect(nodeRegistry.connect(addr1)['updateNode(uint256,string,address)'](node4.nodeId, node4.updatedNodeUri, node4.updatedReceipt)).to.emit(nodeRegistry, "NodeUpdated").withArgs(node4.nodeId, node4.updatedNodeUri);
            await expect(nodeRegistry.connect(addr2)['updateNode(uint256,string,address)'](node1.nodeId, node1.updatedNodeUri, node1.updatedReceipt)).to.be.revertedWith("NodeRegistry: invalid nodeId");
            // unregister            
            await expect(nodeRegistry.connect(owner)['burn(uint256)'](node6.nodeId)).to.emit(nodeRegistry, "NodeUnregistered").withArgs(node6.nodeId);

            // ********************************************************  Check state  ******************************************************** //
            // get node by id (nodeInfo)
            node_1 = await nodeRegistry.nodeInfo(node1.nodeId);
            expect(node_1.tokenId).to.be.equal(0);
            expect(node_1.tokenURI).to.be.equal('');
            expect(node_1.nodeEntry).to.be.equal('');
            expect(node_1.receiptAddr).to.be.equal(ethers.constants.AddressZero);
            expect(node_1.ownerAddr).to.be.equal(ethers.constants.AddressZero);

            node_2 = await nodeRegistry.nodeInfo(node2.nodeId);
            expect(node_2.tokenId).to.be.equal(0);
            expect(node_2.tokenURI).to.be.equal('');
            expect(node_2.nodeEntry).to.be.equal('');
            expect(node_2.receiptAddr).to.be.equal(ethers.constants.AddressZero);
            expect(node_2.ownerAddr).to.be.equal(ethers.constants.AddressZero);

            node_3 = await nodeRegistry.nodeInfo(node3.nodeId);
            expect(node_3.tokenId).to.be.equal(node3.nodeId);
            expect(node_3.tokenURI).to.be.equal(node3.nodeUri);
            expect(node_3.nodeEntry).to.be.equal(node3.nodeEntry);
            expect(node_3.receiptAddr).to.be.equal(node3.receipt);
            expect(node_3.ownerAddr).to.be.equal(node3.owner);

            node_4 = await nodeRegistry.nodeInfo(node4.nodeId);
            expect(node_4.tokenId).to.be.equal(node4.nodeId);
            expect(node_4.tokenURI).to.be.equal(node4.updatedNodeUri);
            expect(node_4.nodeEntry).to.be.equal(node4.nodeEntry);
            expect(node_4.receiptAddr).to.be.equal(node4.updatedReceipt);
            expect(node_4.ownerAddr).to.be.equal(node4.owner);

            node_5 = await nodeRegistry.nodeInfo(node5.nodeId);
            expect(node_5.tokenId).to.be.equal(node5.nodeId);
            expect(node_5.tokenURI).to.be.equal(node5.updatedNodeUri);
            expect(node_5.nodeEntry).to.be.equal(node5.nodeEntry);
            expect(node_5.receiptAddr).to.be.equal(node5.receipt); // original
            expect(node_5.ownerAddr).to.be.equal(node5.owner);

            node_6 = await nodeRegistry.nodeInfo(node6.nodeId);
            expect(node_6.tokenId).to.be.equal(0);
            expect(node_6.tokenURI).to.be.equal('');
            expect(node_6.nodeEntry).to.be.equal('');
            expect(node_6.receiptAddr).to.be.equal(ethers.constants.AddressZero);
            expect(node_6.ownerAddr).to.be.equal(ethers.constants.AddressZero);

            node_7 = await nodeRegistry.nodeInfo(node7.nodeId);
            expect(node_7.tokenId).to.be.equal(node7.nodeId);
            expect(node_7.tokenURI).to.be.equal(node7.nodeUri);
            expect(node_7.nodeEntry).to.be.equal(node7.nodeEntry);
            expect(node_7.receiptAddr).to.be.equal(node7.receipt);
            expect(node_7.ownerAddr).to.be.equal(node7.owner);

            // get nodes
            // count
            expect(await nodeRegistry.nodeCount()).to.be.equal(4);
            // nodes by index
            expect((await nodeRegistry.nodeByIndex(0)).tokenId).to.be.equal(node5.nodeId);
            expect((await nodeRegistry.nodeByIndex(1)).tokenId).to.be.equal(node4.nodeId);
            expect((await nodeRegistry.nodeByIndex(2)).tokenId).to.be.equal(node3.nodeId);
            expect((await nodeRegistry.nodeByIndex(3)).tokenId).to.be.equal(node7.nodeId);
            await expect(nodeRegistry.nodeByIndex(4)).to.be.revertedWith("EnumerableSet: index out of bounds");
            // nodeIds
            nodes = await nodeRegistry.nodeIds();
            expect(nodes.length).to.be.equal(4);
            expect(nodes[0]).to.be.equal(node5.nodeId);
            expect(nodes[1]).to.be.equal(node4.nodeId);
            expect(nodes[2]).to.be.equal(node3.nodeId);
            expect(nodes[3]).to.be.equal(node7.nodeId);

            // get owend nodes
            // count
            expect(await nodeRegistry.ownedNodeCount(owner.address)).to.be.equal(2);
            expect(await nodeRegistry.ownedNodeCount(addr1.address)).to.be.equal(1);
            expect(await nodeRegistry.ownedNodeCount(addr2.address)).to.be.equal(1);
            // nodes by index
            expect((await nodeRegistry.ownedNodeByIndex(owner.address, 0)).tokenId).to.be.equal(node3.nodeId);
            expect((await nodeRegistry.ownedNodeByIndex(owner.address, 1)).tokenId).to.be.equal(node5.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(owner.address, 2)).to.be.revertedWith("EnumerableSet: index out of bounds");
            expect((await nodeRegistry.ownedNodeByIndex(addr1.address, 0)).tokenId).to.be.equal(node4.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(addr1.address, 1)).to.be.revertedWith("EnumerableSet: index out of bounds");
            expect((await nodeRegistry.ownedNodeByIndex(addr2.address, 0)).tokenId).to.be.equal(node7.nodeId);
            await expect(nodeRegistry.ownedNodeByIndex(addr2.address, 1)).to.be.revertedWith("EnumerableSet: index out of bounds");
            // nodeIds
            ownernodes = await nodeRegistry.ownedNodeIds(owner.address);
            addr1nodes = await nodeRegistry.ownedNodeIds(addr1.address);
            addr2nodes = await nodeRegistry.ownedNodeIds(addr2.address);

            expect(ownernodes[0]).to.be.equal(node3.nodeId);
            expect(ownernodes[1]).to.be.equal(node5.nodeId);
            expect(addr1nodes[0]).to.be.equal(node4.nodeId);
            expect(addr2nodes[0]).to.be.equal(node7.nodeId);
        });

        it("Should be able to reveal / transfer nodes by personal wallet", async function () {
            const registerFee = parseEther('1');
            const node1 = { owner: addr1.address, nodeId: BigNumber.from("1"), nodeUri: "first node uri", nodeEntry: "first node entry", receipt: receipt1.address, quoteToken: ethers.constants.AddressZero, value: registerFee, price: registerFee, fee: registerFee, updatedNodeUri: "updated first node uri", updatedReceipt: receipt1.address }; // Native token (value != 0) - 6 args
            const node2 = { owner: addr2.address, nodeId: BigNumber.from("2"), nodeUri: "second node uri", nodeEntry: "second node entry", receipt: addr2.address, quoteToken: ethers.constants.AddressZero, value: 0, price: registerFee, fee: registerFee, updatedNodeUri: "updated second node uri", updatedReceipt: receipt1.address }; // Native token (value == 0) - 5 args
            let node_1;

            // ********************************************************  Register  ******************************************************** //
            await expect(nodeRegistry.connect(addr1)['mint(uint256,string,string,address,address,uint256)'](node1.nodeId, node1.nodeUri, node1.nodeEntry, node1.receipt, node1.quoteToken, node1.value, { value: node1.price }))
                .to.emit(nodeRegistry, "RegisteredFees").withArgs(node1.nodeId, platform.address, node1.quoteToken, node1.fee)
                .to.emit(nodeRegistry, "NodeRegistered").withArgs(node1.nodeId, node1.nodeUri, node1.nodeEntry, node1.receipt, node1.owner);
            // ********************************************************  Reveal node  ******************************************************** //
            expect(await nodeRegistry.isRevealed()).to.be.equal(0);
            // Transfer node before reveal node
            await expect(nodeRegistry.connect(owner).transferFrom(addr1.address, addr2.address, node1.nodeId)).to.be.revertedWith("ERC721: transfer caller is not owner nor approved");
            await expect(nodeRegistry.connect(addr1).transferFrom(addr1.address, addr2.address, node1.nodeId)).to.be.revertedWith("NodeRegistry: node is not revealed");

            // Reveal node
                // check input value
            await expect(nodeRegistry.connect(addr1).revealNode()).to.be.revertedWith("Ownable: caller is not the owner");
            // reveal node
            await expect(nodeRegistry.connect(owner).revealNode()).to.emit(nodeRegistry, "NodeRevealed").withArgs(1);
            await expect(nodeRegistry.connect(owner).revealNode()).to.be.revertedWith("NodeRegistry: node is already revealed");
            expect(await nodeRegistry.isRevealed()).to.be.equal(1);
            // Transfer node like this: addr1 -> addr2 -> owner -> addr2
            // ********************************************************  Transfer node  ******************************************************** //
            // Transfer (addr1 => addr2)
            await expect(nodeRegistry.connect(owner).transferFrom(addr1.address, addr2.address, node1.nodeId)).to.be.revertedWith("ERC721: transfer caller is not owner nor approved");
            await expect(nodeRegistry.connect(addr1).transferFrom(addr1.address, addr2.address, node1.nodeId)).to.emit(nodeRegistry, "Transfer").withArgs(addr1.address, addr2.address, node1.nodeId);
            // check state            
            node_1 = await nodeRegistry.nodeInfo(node1.nodeId);
            expect(node_1.tokenId).to.be.equal(node1.nodeId);
            expect(node_1.tokenURI).to.be.equal(node1.nodeUri);
            expect(node_1.nodeEntry).to.be.equal(node1.nodeEntry);
            expect(node_1.receiptAddr).to.be.equal(node1.receipt);
            expect(node_1.ownerAddr).to.be.equal(addr2.address);
            // Transfer (addr2 => owner)
            await expect(nodeRegistry.connect(addr1).approve(addr1.address, node1.nodeId)).to.be.revertedWith("ERC721: approve caller is not owner nor approved for all");
            await expect(nodeRegistry.connect(addr2).approve(addr1.address, node1.nodeId)).to.emit(nodeRegistry, "Approval").withArgs(addr2.address, addr1.address, node1.nodeId);
            await expect(nodeRegistry.connect(addr1).transferFrom(addr2.address, owner.address, node1.nodeId)).to.emit(nodeRegistry, "Transfer").withArgs(addr2.address, owner.address, node1.nodeId);
            // check state            
            node_1 = await nodeRegistry.nodeInfo(node1.nodeId);
            expect(node_1.tokenId).to.be.equal(node1.nodeId);
            expect(node_1.tokenURI).to.be.equal(node1.nodeUri);
            expect(node_1.nodeEntry).to.be.equal(node1.nodeEntry);
            expect(node_1.receiptAddr).to.be.equal(node1.receipt);
            expect(node_1.ownerAddr).to.be.equal(owner.address);
            // Transfer (owner => addr2)
            await expect(nodeRegistry.connect(addr2).approve(addr1.address, node1.nodeId)).to.be.revertedWith("ERC721: approve caller is not owner nor approved for all");
            await expect(nodeRegistry.connect(owner).setApprovalForAll(addr1.address, true)).to.emit(nodeRegistry, "ApprovalForAll").withArgs(owner.address, addr1.address, true);
            await expect(nodeRegistry.connect(addr1).approve(addr2.address, node1.nodeId)).to.emit(nodeRegistry, "Approval").withArgs(owner.address, addr2.address, node1.nodeId);
            await expect(nodeRegistry.connect(addr2).transferFrom(owner.address, addr2.address, node1.nodeId)).to.emit(nodeRegistry, "Transfer").withArgs(owner.address, addr2.address, node1.nodeId);
            // check state            
            node_1 = await nodeRegistry.nodeInfo(node1.nodeId);
            expect(node_1.tokenId).to.be.equal(node1.nodeId);
            expect(node_1.tokenURI).to.be.equal(node1.nodeUri);
            expect(node_1.nodeEntry).to.be.equal(node1.nodeEntry);
            expect(node_1.receiptAddr).to.be.equal(node1.receipt);
            expect(node_1.ownerAddr).to.be.equal(addr2.address);

            // ********************************************************  Update  ******************************************************** //
            await expect(nodeRegistry.connect(addr1)['updateNode(uint256,string,address)'](node1.nodeId, node2.nodeUri, node2.receipt)).to.be.revertedWith("NodeRegistry: caller is not node owner");
            await expect(nodeRegistry.connect(addr2)['updateNode(uint256,string,address)'](node1.nodeId, node2.nodeUri, node2.receipt))
                .to.emit(nodeRegistry, "NodeUpdated").withArgs(node1.nodeId, node2.nodeUri);

            // ********************************************************  Check node state  ******************************************************** //
            node_1 = await nodeRegistry.nodeInfo(node1.nodeId);
            expect(node_1.tokenId).to.be.equal(node1.nodeId);
            expect(node_1.tokenURI).to.be.equal(node2.nodeUri);
            expect(node_1.nodeEntry).to.be.equal(node1.nodeEntry);
            expect(node_1.receiptAddr).to.be.equal(node2.receipt);
            expect(node_1.ownerAddr).to.be.equal(addr2.address);
            // ********************************************************  Unregister  ******************************************************** //
            await expect(nodeRegistry.connect(addr1)['burn(uint256)'](node1.nodeId)).to.be.revertedWith("NodeRegistry: caller is not node owner or contract owner");
            // unregister with node owner
            await expect(nodeRegistry.connect(addr2)['burn(uint256)'](node1.nodeId)).to.emit(nodeRegistry, "NodeUnregistered").withArgs(node1.nodeId);
        });

        it("Should be able to manage platform address", async function () {
            // check initial platform fee config set by constructor
            const initPlatformAddr = await nodeRegistry.platformAddress();
            expect(initPlatformAddr).to.be.equal(platform.address);

            // check input value
            await expect(nodeRegistry.connect(addr1).setPlatformAddr(ethers.constants.AddressZero)).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(nodeRegistry.connect(platform).setPlatformAddr(addr1.address)).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(nodeRegistry.connect(addr2).setPlatformAddr(addr1.address)).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(nodeRegistry.connect(owner).setPlatformAddr(ethers.constants.AddressZero)).to.be.revertedWith("NodeRegistry: invalid platform address");
            await expect(nodeRegistry.connect(owner).setPlatformAddr(ethers.constants.AddressZero)).to.be.revertedWith("NodeRegistry: invalid platform address");

            // set platform fee config
            await expect(nodeRegistry.connect(owner).setPlatformAddr(addr2.address)).to.emit(nodeRegistry, 'PlatformFeeChanged').withArgs(addr2.address);

            // check updated platform fee config
            const updatedPlatformAddr = await nodeRegistry.platformAddress();
            expect(updatedPlatformAddr).to.be.equal(addr2.address);
        });

        it("Should be able to upgrade proxy contract", async function () {
            mockNR = await upgrades.upgradeProxy(nodeRegistry.address, MockNR);
            console.log("Original proxy contract deployed to: ", nodeRegistry.address);
            console.log("Upgraded proxy contract deployed to: ", mockNR.address);
            expect(nodeRegistry.address).to.be.equal(mockNR.address);

            const updatedVersion = 2;
            expect(await mockNR.setVersion(updatedVersion)).to.emit(mockNR, "VersionUpdated").withArgs(updatedVersion);
            expect(await mockNR.getVersion()).to.be.equal(updatedVersion);
        });
    });
});
