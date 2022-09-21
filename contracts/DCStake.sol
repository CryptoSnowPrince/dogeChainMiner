//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";

contract DCStake is Ownable {
    struct UserInfo {
        uint256 amount;
        uint256 startTime;
        uint256 pendingReward;
    }

    struct PoolInfo {
        uint256 totalAmount;
    }

    uint256 constant lockTime0 = 3 hours;
    uint256 constant lockTime1 = 7 days;
    uint256 constant lockTime2 = 14 days;
    uint256 constant lockTime3 = 28 days;

    uint256 constant rewardRate0 = 4; // 4/8=0.5
    uint256 constant rewardRate1 = 6;
    uint256 constant rewardRate2 = 7;
    uint256 constant rewardRate3 = 8;

    address public treasury;
    IERC20 public token;

    function setTreasury(address _treasury) public onlyOwner {
        require(treasury != _treasury, "DCStake: SAME_ADDRESS");
    }

    // mapping(address => address) public referrals;

    // PoolInfo[] public poolInfo;
    // mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // address payable public treasury;
    // mapping(address => address) public referralsA;
    // mapping(address => uint256) public referralClaim;

    // struct StakeHolder {
    //     uint256 stakingAmount;
    //     uint256 stakingDate;
    //     uint256 stakingDuration;
    //     uint256 claimDate;
    //     uint256 expireDate;
    //     uint256 rewardAmount;
    //     bool isStaker;
    // }

    // mapping(address => mapping(uint256 => StakeHolder)) public stakeHolders;

    // uint256[] internal stakePeriod = [7 days, 14 days, 28 days, 3 hours];
    // uint256[] internal rate = [142, 198, 224, 5];
    // uint256 private decimals = 10**18;
    // uint256 private totalRewardAmount;

    // constructor(address payable _treasury) {
    //     treasury = _treasury;
    // }

    // function staking(
    //     uint256 _amount,
    //     uint256 _duration,
    //     address ref
    // ) public {
    //     if (ref == msg.sender) {
    //         ref = address(0);
    //     }
    //     if (referralsA[msg.sender] == address(0)) {
    //         referralsA[msg.sender] = ref;
    //     }
    //     // require(_amount >= 10000, "Insufficient Stake Amount");
    //     require(_duration < 4, "Duration not match");

    //     StakeHolder storage s = stakeHolders[msg.sender][_duration];
    //     s.stakingAmount = _amount * decimals;
    //     s.stakingDate = block.timestamp;
    //     s.claimDate = block.timestamp;
    //     s.stakingDuration = stakePeriod[_duration];
    //     s.expireDate = s.stakingDate + s.stakingDuration;
    //     s.isStaker = true;
    // }

    // function calculateReward(address account, uint256 _duration)
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     StakeHolder storage s = stakeHolders[account][_duration];
    //     require(s.isStaker == true, "You are not staker.");
    //     bool status = (block.timestamp - s.claimDate) > 7 seconds
    //         ? true
    //         : false;
    //     require(status == true, "Invalid Claim Date");

    //     uint256 currentTime = block.timestamp >= s.expireDate
    //         ? s.expireDate
    //         : block.timestamp;
    //     uint256 _pastTime = currentTime - s.claimDate;
    //     require(_pastTime >= stakePeriod[_duration], "Invalid Claim Date");

    //     uint256 reward = 0;
    //     if (_duration == 3) {
    //         uint256 cnt = _pastTime / (3 * 3600);
    //         reward =
    //             s.stakingAmount +
    //             (rate[_duration] * s.stakingAmount * cnt) /
    //             (1000);
    //     } else {
    //         reward = (s.stakingAmount * rate[_duration]) / 1000;
    //     }

    //     s.claimDate = block.timestamp;
    //     s.isStaker = false;
    //     return reward;
    // }

    // function calculateRewardAll(address account) public pure returns (uint256) {
    //     return
    //         calculateReward(account, 0) +
    //         calculateReward(account, 1) +
    //         calculateReward(account, 2) +
    //         calculateReward(account, 3);
    // }

    // function claim() public {
    //     totalRewardAmount = calculateRewardAll(msg.sender);
    //     uint256 fee = devFee(totalRewardAmount);
    //     (bool sent1, ) = treasury.call{value: 3 * fee}("");
    //     require(sent1, "ETH transfer Fail");

    //     (bool sent, ) = msg.sender.call{value: totalRewardAmount - 4 * fee}("");
    //     require(sent, "ETH transfer Fail");
    // }

    // function devFee(uint256 amount) public pure returns (uint256) {
    //     return (amount * 25) / 1000;
    // }

    // function getBalance() external view returns (uint256) {
    //     return address(this).balance;
    // }
}
