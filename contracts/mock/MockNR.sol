// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "../nodes/NodeRegistry.sol";

contract MockNR is NodeRegistry {

    event VersionUpdated(uint256 newVersion);
    
    uint256 private _version;

    constructor(uint256 lastTokenId, address platformAddr, uint256 platformFee) NodeRegistry(lastTokenId, platformAddr, platformFee){
    }

    /**
     * @notice Creates a node registry contract with platform address info.
     */

    function getVersion() external view returns (uint256) {
        return _version;
    }

    function setVersion(uint256 version) external {
        _version = version;
        emit VersionUpdated(version);
    }
}


