// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./strategies/VestingCoachVault.sol";
import "./interfaces/IWeb3CoachFactory.sol";
import "./interfaces/IWeb3CoachIncentive.sol";
import "./interfaces/ICoachToken.sol";

contract Web3CoachFactory is Ownable, IWeb3CoachFactory {
    address public pcToken;
    address public incentive;
    uint256 public totalCoach;

    mapping(address => uint256) public donationRules;
    mapping(address => bool) public polyCoachStatus;

    event NewCoach(address owner, uint256 ownerFid, address coach, uint256 totalCoachFund, string trainingName, string trainingDesc);

    modifier isOfficalCoach() {
        require(polyCoachStatus[msg.sender], "Web3CoachFactory: Not offical coach.");
        _;
    }

    constructor(address[] memory _donateTokens, uint256[] memory _minAmounts) Ownable(msg.sender) {
        for (uint256 i; i < _donateTokens.length; i++) {
            donationRules[_donateTokens[i]] = _minAmounts[i];
        }
    }

    function setNewIncentive(address _pcToken, address _incentive) external onlyOwner {
        pcToken = _pcToken;
        incentive = _incentive;
    }

    function createNewCoach(
        uint256 _ownerFid,
        string memory _trainingName,
        string memory _trainingDesc
    ) external payable {
        VestingCoachVault newCoach = new VestingCoachVault(msg.sender, IWeb3CoachFactory(address(this)), msg.value, _ownerFid, _trainingName, _trainingDesc);
        
        payable(address(newCoach)).transfer(msg.value);

        polyCoachStatus[address(newCoach)] = true;
        totalCoach += 1;

        IPCToken(pcToken).setTransferWhitelist(address(newCoach));

        emit NewCoach(msg.sender, _ownerFid, address(newCoach), msg.value, _trainingName, _trainingDesc);
    }

    function setDonationRules(address[] memory _donateTokens, uint256[] memory _minAmounts) external onlyOwner {
        for (uint256 i; i < _donateTokens.length; i++) {
            donationRules[_donateTokens[i]] = _minAmounts[i];
        }
    }

    function complete() external isOfficalCoach {
        IPolyCoachIncentive(incentive).complete(msg.sender);
    }

    function supervise(address account) external isOfficalCoach {
        IPolyCoachIncentive(incentive).supervise(msg.sender, account);
    } 

    function donate(address account, IERC20 token, uint256 amount) external isOfficalCoach {
        IPolyCoachIncentive(incentive).donate(msg.sender, account, token, amount);
    }

    function isValidDonate(IERC20 _token, uint256 _amount) external view returns(bool) {
        return donationRules[address(_token)] > 0 && _amount >= donationRules[address(_token)];
    }
}