//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./Auth.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract DCStake is Auth, Pausable, ReentrancyGuard {
    struct UserInfo {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 pendingReward;
    }

    uint256 constant lockTime0 = 3 hours;
    uint256 constant lockTime1 = 7 days;
    uint256 constant lockTime2 = 14 days;
    uint256 constant lockTime3 = 28 days;

    uint256 constant claimPeriod0 = 3 hours;
    uint256 constant claimPeriod123 = 1 days;

    uint256 constant MIN_DEPOSIT_AMOUNT = 10_000 * 10**18; // minimum deposit limit is 10K. decimals is 18
    uint256 constant DENOMINATOR = 1000; // 1 is 0.1%, 1000 is 100%

    uint256 constant rewardRate0 = 5; // 40/8=5
    uint256 constant rewardRate1 = 60;
    uint256 constant rewardRate2 = 70;
    uint256 constant rewardRate3 = 80;

    uint256 constant devFee = 75;
    uint256 constant contractFee = 25;

    uint256 constant referralsRate = 50;

    address public devAddress;

    IERC20 public token;
    uint256[] public stakedTotalAmounts = [0, 0, 0, 0]; // Total Staked Amounts Array on Each Staking pool

    mapping(address => address) public referrals;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event LogSetToken(address indexed token);
    event LogDevAddress(address indexed devAddress);
    event LogDeposit(
        address indexed user,
        uint256 indexed poolID,
        uint256 indexed amount
    );
    event LogWithdrawReward(
        address indexed user,
        uint256 indexed poolID,
        uint256 indexed pendingReward
    );
    event LogWithdraw(
        address indexed user,
        uint256 indexed poolID,
        uint256 indexed stakedAmount
    );
    event LogFallback(address indexed from, uint256 indexed amount);
    event LogReceive(address indexed from, uint256 indexed amount);

    constructor(IERC20 _token, address _devAddress) {
        setToken(_token);
        setDevAddress(_devAddress);
    }

    function setToken(IERC20 _token) public authorized {
        require(address(token) != address(_token), "DCStake: SAME_ADDRESS");
        token = _token;

        emit LogSetToken(address(token));
    }

    function setDevAddress(address _devAddress) public authorized {
        require(_devAddress != address(0), "DCStake: ZERO_ADDRESS");
        require(devAddress != _devAddress, "DCStake: SAME_ADDRESS");
        devAddress = _devAddress;

        emit LogDevAddress(devAddress);
    }

    function setPause() external authorized {
        _pause();
    }

    function setUnpause() external authorized {
        _unpause();
    }

    // Receive and Fallback functions
    receive() external payable {
        emit LogReceive(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }

    function deposit(
        uint256 _poolID,
        uint256 _amount,
        address _referral
    ) external whenNotPaused nonReentrant {
        require(
            _amount >= MIN_DEPOSIT_AMOUNT,
            "DCStake: LESS_THAN_MIN_DEPOSIT_AMOUNT"
        );
        uint256 _pendingReward = pendingReward(_poolID, msg.sender);

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "DCStake: FAIL_TRANSFERFROM"
        );

        userInfo[_poolID][msg.sender].stakedAmount += _amount;
        userInfo[_poolID][msg.sender].pendingReward += _pendingReward;
        userInfo[_poolID][msg.sender].startTime = block.timestamp;

        stakedTotalAmounts[_poolID] += _amount;

        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _referral;
        }

        emit LogDeposit(msg.sender, _poolID, _amount);
    }

    function pendingReward(uint256 _poolID, address _user)
        public
        view
        returns (uint256 rewardsAmount)
    {
        (, uint256 claimPeriod, uint256 rewardRate) = getPoolParams(_poolID);
        uint256 stakedAmount = userInfo[_poolID][_user].stakedAmount;

        rewardsAmount = userInfo[_poolID][_user].pendingReward;
        if (stakedAmount > 0 && rewardRate > 0) {
            rewardsAmount +=
                (stakedAmount *
                    rewardRate *
                    (block.timestamp - userInfo[_poolID][_user].startTime)) /
                (claimPeriod * DENOMINATOR);
        }
    }

    function _withdrawReward(uint256 _poolID)
        internal
        returns (bool canWithdraw)
    {
        (uint256 lockTime, , ) = getPoolParams(_poolID);

        canWithdraw =
            block.timestamp >=
            userInfo[_poolID][msg.sender].startTime + lockTime;

        if (canWithdraw) {
            uint256 _pendingReward = pendingReward(_poolID, msg.sender);

            userInfo[_poolID][msg.sender].pendingReward = 0;
            userInfo[_poolID][msg.sender].startTime = block.timestamp;

            token.transfer(devAddress, (_pendingReward * devFee) / DENOMINATOR);
            // contractFee will remain in this contract
            token.transfer(
                msg.sender,
                (_pendingReward * (DENOMINATOR - devFee - contractFee)) /
                    DENOMINATOR
            );

            emit LogWithdrawReward(msg.sender, _poolID, _pendingReward);
        }
    }

    function withdrawReward(uint256 _poolID) public whenNotPaused nonReentrant {
        require(_withdrawReward(_poolID), "DCStake: IN_LOCKTIME");
    }

    function withdrawAllReward() public whenNotPaused nonReentrant {
        require(
            _withdrawReward(0) ||
                _withdrawReward(1) ||
                _withdrawReward(2) ||
                _withdrawReward(3),
            "DCStake: IN_LOCKTIME"
        );
    }

    function _withdraw(uint256 _poolID) internal {
        require(_withdrawReward(_poolID), "DCStake: IN_LOCKTIME");

        uint256 stakedAmount = userInfo[_poolID][msg.sender].stakedAmount;

        token.transfer(devAddress, (stakedAmount * devFee) / DENOMINATOR);
        // contractFee will remain in this contract
        token.transfer(
            msg.sender,
            (stakedAmount * (DENOMINATOR - devFee - contractFee)) / DENOMINATOR
        );

        userInfo[_poolID][msg.sender].stakedAmount = 0;

        emit LogWithdraw(msg.sender, _poolID, stakedAmount);
    }

    function withdraw(uint256 _poolID) external whenNotPaused nonReentrant {
        _withdraw(_poolID);
    }

    function withdrawAll() external whenNotPaused nonReentrant {
        _withdraw(0);
        _withdraw(1);
        _withdraw(2);
        _withdraw(3);
    }

    function getPoolParams(uint256 _poolID)
        public
        pure
        returns (
            uint256 lockTime,
            uint256 claimPeriod,
            uint256 rewardRate
        )
    {
        if (_poolID == 0) {
            lockTime = lockTime0;
            claimPeriod = claimPeriod0;
            rewardRate = rewardRate0;
        } else if (_poolID == 1) {
            lockTime = lockTime1;
            claimPeriod = claimPeriod123;
            rewardRate = rewardRate1;
        } else if (_poolID == 2) {
            lockTime = lockTime2;
            claimPeriod = claimPeriod123;
            rewardRate = rewardRate2;
        } else if (_poolID == 3) {
            lockTime = lockTime3;
            claimPeriod = claimPeriod123;
            rewardRate = rewardRate3;
        } else {
            lockTime = 0;
            claimPeriod = 0;
            rewardRate = 0;
        }
    }
}
