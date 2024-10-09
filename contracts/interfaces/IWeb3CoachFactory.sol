// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWeb3CoachFactory {
    function complete() external;

    function donate(address donor, IERC20 _token, uint256 _amount) external;

    function supervise(address supervisor) external;

    function isValidDonate(IERC20 _token, uint256 _amount) external view returns(bool);

    function incentive() external view returns(address);

    function polyCoachStatus(address coach) external view returns(bool);
}