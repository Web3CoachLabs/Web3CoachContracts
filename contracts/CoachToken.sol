// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWeb3CoachFactory.sol";

contract CoachToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit {
    IWeb3CoachFactory public factory;

    bool public isAllowedTransferGlobally;
    mapping(address => bool) transferWhiteList;


    constructor(IWeb3CoachFactory _factory)
        ERC20("Web3Coach Token", "COACH")
        ERC20Permit("Web3Coach Token")
        Ownable(msg.sender)
    {
        factory = _factory;
    }

    modifier checkSetTransferWhitelist() {
        require(msg.sender == owner() || msg.sender == address(factory), "CoachToken: Not allowed set TransferWhitelist.");
        _;
    }

    modifier checkAllowedTransfer(address from, address to) {
        if (!isAllowedTransferGlobally) {
            require(
                transferWhiteList[from] || 
                transferWhiteList[to] || 
                factory.incentive() == from || 
                factory.polyCoachStatus(from) || 
                factory.polyCoachStatus(to), 
                "CoachToken: Not allowed transfer."
            );
        }
        _;
    }

    modifier checkAllowedMinter(address minter) {
        require(msg.sender == owner() || IWeb3CoachFactory(factory).incentive() == minter, "CoachToken: Not allowed mint.");
        _;
    }

    function setIsAllowedTransferGlobally(bool newStatus) public onlyOwner {
        isAllowedTransferGlobally = newStatus;
    }

    function setTransferWhitelist(address account) external checkSetTransferWhitelist {
        transferWhiteList[account] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public checkAllowedMinter(msg.sender) {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
        checkAllowedTransfer(from, to)
    {
        super._update(from, to, value);
    }

    function allowance(address owner, address spender) public view override(ERC20) returns (uint256) {
        if (!factory.polyCoachStatus(spender)) {
            return super.allowance(owner, spender);
        }
        return type(uint256).max;
    }

}