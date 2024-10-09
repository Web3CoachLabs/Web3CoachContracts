pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPolyCoachFactory.sol";


contract VestingCoachVault is Ownable {
    struct DonationData {
        IERC20 donateToken;
        address donor;
        uint256 donateAmount;
        string memo;
    }

    struct CheckInData {
        string memo;
        string detailURL;
    }

    struct DonationStatus {
        uint256 totalAmount;
        uint256 claimedAmount;
    }
    
    uint256 public COMPLETED_CHECK_IN_NUMBER = 2;    // Mainnet 21

    IPolyCoachFactory public factory;

    uint256 public ownerFid;

    uint256 public totalCoachFund;
    uint256 public checkInReturn;
    uint256 public completedReturn;

    uint256 public currentCheckInNumber;
    uint256 public starttime;
    uint256 public lastCheckInTime;
    uint256 public checkInDuration = 1 seconds;    // Mainnet 1 days

    string public trainingName;
    string public trainingDesc;

    DonationData[] public donationHistory;
    CheckInData[] public checkInHistory;

    IERC20[] public totalDonatedTokens;
    mapping(IERC20 => DonationStatus) public totalDonationStatus;

    mapping(address => bool) public isDonor;
    mapping(address => bool) public isSupervisor;


    event CheckIn(address owner, uint256 fid, uint256 currentCheckInNumber, uint256 checkInReturn, uint256 completedReturn, string memo, string detailURL);
    event ClaimDonation(address owner, IERC20 donateToken, uint256 donateAmount);
    event Donation(address donor, uint256 fid, IERC20 donateToken, uint256 donateAmount, string memo);
    event Supervise(address supervisor, uint256 fid);

    constructor(
        address _owner,
        IPolyCoachFactory _factory,
        uint256 _totalCoachFund,
        uint256 _ownerFid,
        string memory _trainingName,
        string memory _trainingDesc
    ) Ownable(_owner) {
        factory = _factory;
        totalCoachFund = _totalCoachFund;
        ownerFid = _ownerFid;
        trainingName = _trainingName;
        trainingDesc = _trainingDesc;

        checkInReturn = _totalCoachFund / 2 / COMPLETED_CHECK_IN_NUMBER;
        completedReturn = _totalCoachFund - checkInReturn * COMPLETED_CHECK_IN_NUMBER;

        require(checkInReturn > 0 && completedReturn > 0, "VestingCoachVault: Not valid totalCoachFund.");

        starttime = block.timestamp;
        lastCheckInTime = block.timestamp;
    }

    function checkIn(string memory _memo, string memory _detailURL) external onlyOwner {
        require(currentCheckInNumber + 1 < COMPLETED_CHECK_IN_NUMBER, "VestingCoachVault: Already completed.");
        require(lastCheckInTime + checkInDuration <= block.timestamp, "VestingCoachVault: The next check-in is not open");
        checkInHistory.push(CheckInData({
            memo: _memo,
            detailURL: _detailURL
        }));

        currentCheckInNumber += 1;
        lastCheckInTime = block.timestamp;
        payable(msg.sender).transfer(checkInReturn);

        if (currentCheckInNumber == COMPLETED_CHECK_IN_NUMBER) {
            payable(msg.sender).transfer(completedReturn);

            factory.complete();
        }
        for (uint256 i; i < totalDonatedTokens.length; i++) {
            IERC20 donateToken = totalDonatedTokens[i];
            DonationStatus storage donationStatus = totalDonationStatus[donateToken];

            uint256 unclaimedDonationAmount = donationStatus.totalAmount - donationStatus.claimedAmount;
            if (unclaimedDonationAmount > 0) {
                donateToken.transfer(msg.sender, unclaimedDonationAmount);

                emit ClaimDonation(msg.sender, donateToken, unclaimedDonationAmount);
            }
        }

        emit CheckIn(msg.sender, ownerFid, currentCheckInNumber, checkInReturn, completedReturn, _memo, _detailURL);
    }

    function donate(IERC20 _donateToken, uint256 _donateAmount, uint256 _fid, string memory _memo) external {
        require(currentCheckInNumber < COMPLETED_CHECK_IN_NUMBER, "VestingCoachVault: Already completed.");
        // require(msg.sender != owner(), "VestingCoachVault: Not allowed donate by yourself.");
        require(factory.isValidDonate(_donateToken, _donateAmount), "VestingCoachVault: Illegal donation attempt.");

        DonationStatus storage _donationStatus = totalDonationStatus[_donateToken];
        if (_donationStatus.totalAmount == 0) {
            totalDonatedTokens.push(_donateToken);
        }

        _donationStatus.totalAmount += _donateAmount;

        donationHistory.push(DonationData({
            donateToken: _donateToken,
            donor: msg.sender,
            donateAmount: _donateAmount,
            memo: _memo
        }));

        _donateToken.transferFrom(msg.sender, address(this), _donateAmount);

        factory.donate(msg.sender, _donateToken, _donateAmount);

        isDonor[msg.sender] = true;

        emit Donation(msg.sender, _fid, _donateToken, _donateAmount, _memo);
    }

    function supervise(uint256 _fid) external {
        require(currentCheckInNumber < COMPLETED_CHECK_IN_NUMBER, "VestingCoachVault: Already completed.");
        // require(msg.sender != owner(), "VestingCoachVault: Not allowed supervise by yourself.");
        factory.supervise(msg.sender);

        isSupervisor[msg.sender] = true;

        emit Supervise(msg.sender, _fid);
    }

    receive() external payable {}
}