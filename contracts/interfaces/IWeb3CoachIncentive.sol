// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWeb3CoachIncentive {
    function createNewCoach(address vault, address owner) external;

    function complete(address vault) external;

    function supervise(address vault, address account) external;

    function donate(address vault, address account, IERC20 token, uint256 amount) external;
}