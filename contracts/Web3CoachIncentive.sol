// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWeb3CoachIncentive.sol";


interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}


contract Web3CoachIncentive is Ownable, IWeb3CoachIncentive {
    address public factory;
    IERC20Mintable public pcToken;

    struct AccountRewardsStatus {
        uint256 claimedRewards;
        mapping(address => bool) isClaimedVault;
    }

    struct VaultStatus {
        address owner;
        bool isCompleted;
        uint256 totalDonors;
        uint256 totalSupervisors;
        mapping(address => bool) isSupervised;
        mapping(address => bool) isDonated;
    }

    uint256 rewardsPerDonor = 10e18;
    uint256 rewardsPerSuppervisors = 1e18;
    uint256 baseRewardsCreateVault = 1000e18;
    uint256 public ownerRewardsDivisor = 10;    // 10% 

    mapping(address => AccountRewardsStatus) public accountsRewardsStatus;
    mapping(address => VaultStatus) public vaultsRewardsStatus;

    event ClaimedVault(address account, uint256 fid, address coach, uint256 claimedAmount);

    modifier onlyFactory() {
        require(msg.sender == factory, "PolyCoachVault: Not Factory.");
        _;
    }

    constructor(IERC20Mintable _pcToken, address _factory) Ownable(msg.sender) {
        pcToken = _pcToken;
        factory = _factory;
    }

    function createNewCoach(address vault, address owner) external {
        VaultStatus storage newVault = vaultsRewardsStatus[vault];
        newVault.owner = owner;
    }

    function complete(address vault) external {
        VaultStatus storage targetVault = vaultsRewardsStatus[vault];
        targetVault.isCompleted = true;
    }

    function supervise(address vault, address account) external {
        VaultStatus storage targetVault = vaultsRewardsStatus[vault];
        if (!targetVault.isSupervised[account]) {
            targetVault.isSupervised[account] = true;
            targetVault.totalSupervisors += 1;
        }
    } 

    function donate(address vault, address account, IERC20 token, uint256 amount) external {
        token;
        amount;

        VaultStatus storage targetVault = vaultsRewardsStatus[vault];
        if (!targetVault.isDonated[account]) {
            targetVault.isDonated[account] = true;
            targetVault.totalDonors += 1;
        }
    }

    function claim(uint256 fid, address[] memory targetVaults) external {
        uint256 totalClaimableRewards;
        AccountRewardsStatus storage account = accountsRewardsStatus[msg.sender];

        for (uint256 i; i < targetVaults.length; i++) {
            VaultStatus storage targetVault = vaultsRewardsStatus[targetVaults[i]];
            if (targetVault.isCompleted) {

                if (!account.isClaimedVault[targetVaults[i]]) {
                    uint256 claimableRewards;
                    if (msg.sender == targetVault.owner) {
                        claimableRewards = baseRewardsCreateVault + (targetVault.totalDonors * rewardsPerDonor + targetVault.totalSupervisors * rewardsPerSuppervisors) / ownerRewardsDivisor;
                    } else {
                        if (targetVault.isSupervised[msg.sender]) {
                            claimableRewards += targetVault.totalSupervisors * rewardsPerSuppervisors;
                        }

                        if (targetVault.isDonated[msg.sender]) {
                            claimableRewards += targetVault.totalDonors * rewardsPerDonor;
                        }
                    }

                    totalClaimableRewards += claimableRewards;

                    account.isClaimedVault[targetVaults[i]] = true;

                    if (claimableRewards > 0) {
                        emit ClaimedVault(msg.sender, fid, targetVaults[i], claimableRewards);
                    }
                }
            }
        }

        if (totalClaimableRewards > 0) {
            pcToken.mint(msg.sender, totalClaimableRewards);

            account.claimedRewards += totalClaimableRewards;
        }
    }
}