// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

interface IPausable {
    /**
     * @dev MUST emit when contract is paused.
     */
    event Paused();

    /**
     * @dev MUST emit when contract is unpaused.
     */
    event Unpaused();

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
     * @notice Pause the vesting release.
     */
    function pause() external;

    /**
     * @notice Unpause the vesting release.
     */
    function unpause() external;
}