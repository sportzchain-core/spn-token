//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./VerifiedAccount.sol";
import "./roles/GrantorRole.sol";
import "./interface/IERC20Vestable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ERC20Vestable is VerifiedAccount, GrantorRole, IERC20Vestable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 private _token;

    uint32 private constant THOUSAND_YEARS_DAYS = 365243;
    uint32 private constant TEN_YEARS_DAYS = THOUSAND_YEARS_DAYS / 100;
    uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint32 private constant JAN_1_2000_SECONDS = 946684800;
    uint32 private constant JAN_1_2000_DAYS = JAN_1_2000_SECONDS / SECONDS_PER_DAY;
    uint32 private constant JAN_1_3000_DAYS = JAN_1_2000_DAYS + THOUSAND_YEARS_DAYS;

    struct vestingSchedule {
        bool isValid;
        bool isRevocable;
        uint32 cliffDuration;
        uint32 duration;
        uint32 interval;
    }

    struct tokenGrant {
        bool isActive;
        bool wasRevoked;
        uint32 startDay;
        uint256 amount;
        address vestingLocation;
        address grantor;
    }

    mapping(address => vestingSchedule) private _vestingSchedules;
    mapping(address => tokenGrant) private _tokenGrants;


    modifier onlyIfFundsAvailableNow(
        address account,
        uint256 amount
    ) {
        // Distinguish insufficient overall balance from insufficient vested funds balance in failure msg.
        require(_fundsAreAvailableOn(account, amount, today()),
            _token.balanceOf(account) < amount ? "insufficient funds" : "insufficient vested funds");
        _;
    }


    constructor (
        IERC20 myToken
    ){
        _token = myToken;
    }

    function token()
    public view returns (IERC20) {
        return _token;
    }

    function _setVestingSchedule(
        address vestingLocation,
        uint32 cliffDuration,
        uint32 duration,
        uint32 interval,
        bool isRevocable
    )
    internal
    returns (bool ok) {
        require(
            duration > 0 && duration <= TEN_YEARS_DAYS
            && cliffDuration < duration
            && interval >= 1,
            "invalid vesting schedule"
        );

        require(
            duration % interval == 0 && cliffDuration % interval == 0,
            "invalid cliff/duration for interval"
        );

        _vestingSchedules[vestingLocation] = vestingSchedule(
            true,
            isRevocable,
            cliffDuration, duration, interval
        );

        // Emit the event and return success.
        emit VestingScheduleCreated(
            vestingLocation,
            cliffDuration, duration, interval,
            isRevocable);
        return true;
    }

    function _hasVestingSchedule(
        address account
    )
    internal
    view
    returns (bool ok) {
        return _vestingSchedules[account].isValid;
    }


    function getIntrinsicVestingSchedule(
        address grantHolder
    )
    public
    view
    override
    onlyGrantorOrSelf(grantHolder)
    returns (
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalDays
    )
    {
        return (
        _vestingSchedules[grantHolder].duration,
        _vestingSchedules[grantHolder].cliffDuration,
        _vestingSchedules[grantHolder].interval
        );
    }


    function _grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        address vestingLocation,
        address grantor
    )
    internal
    returns (bool ok) {
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

        require(
            vestingAmount <= totalAmount && vestingAmount > 0
            && startDay >= JAN_1_2000_DAYS && startDay < JAN_1_3000_DAYS,
            "invalid vesting params");

        require(_hasVestingSchedule(vestingLocation), "no such vesting schedule");

        require(totalAmount <= _token.balanceOf(address(grantor)));

        _token.transferFrom(grantor,beneficiary,totalAmount);

        _tokenGrants[beneficiary] = tokenGrant(
            true,
            false,
            startDay,
            vestingAmount,
            vestingLocation,
            grantor
        );

        emit VestingTokensGranted(beneficiary, vestingAmount, startDay, vestingLocation, grantor);
        return true;
    }

    function grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) public override onlyGrantor returns (bool ok) {
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

        // The vesting schedule is unique to this wallet and so will be stored here,
        _setVestingSchedule(beneficiary, cliffDuration, duration, interval, isRevocable);

        // Issue grantor tokens to the beneficiary, using beneficiary's own vesting schedule.
        _grantVestingTokens(beneficiary, totalAmount, vestingAmount, startDay, beneficiary, msg.sender);
        return true;
    }

    function safeGrantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    )
    public
    onlyGrantor
    onlyExistingAccount(beneficiary)
    returns (bool ok) {

        return grantVestingTokens(
            beneficiary, totalAmount, vestingAmount,
            startDay, duration, cliffDuration, interval,
            isRevocable);
    }


    function today()
    public
    override
    view
    returns (uint32 dayNumber) {
        return uint32(block.timestamp / SECONDS_PER_DAY);
    }

    function _effectiveDay(
        uint32 onDayOrToday
    )
    internal
    view
    returns (uint32 dayNumber) {
        return onDayOrToday == 0 ? today() : onDayOrToday;
    }


    function _getNotVestedAmount(
        address grantHolder,
        uint32 onDayOrToday
    )
    internal
    view
    returns (uint256 amountNotVested) {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
        uint32 onDay = _effectiveDay(onDayOrToday);

        if (!grant.isActive || onDay < grant.startDay + vesting.cliffDuration) { // If there's no schedule, or before the vesting cliff, then the full amount is not vested.
            // None are vested (all are not vested)
            return grant.amount;
        } else if (onDay >= grant.startDay + vesting.duration) { // If after end of vesting, then the not vested amount is zero (all are vested).
            // All are vested (none are not vested)
            return uint256(0);
        } else  { // Otherwise a fractional amount is vested.
            // Compute the exact number of days vested.
            uint32 daysVested = onDay - grant.startDay;
            // Adjust result rounding down to take into consideration the interval.
            uint32 effectiveDaysVested = (daysVested / vesting.interval) * vesting.interval;

            uint256 vested = grant.amount.mul(effectiveDaysVested).div(vesting.duration);
            return grant.amount.sub(vested);
        }
    }


    function _getAvailableAmount(
        address grantHolder,
        uint32 onDay
    )
    internal
    view
    returns (uint256 amountAvailable) {
        uint256 totalTokens = _token.balanceOf(grantHolder);
        uint256 vested = totalTokens.sub(_getNotVestedAmount(grantHolder, onDay));
        return vested;
    }


    function vestingForAccountAsOf(
        address grantHolder,
        uint32 onDayOrToday
    )
    public
    view
    override
    onlyGrantorOrSelf(grantHolder)
    returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    )
    {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
        uint256 notVestedAmount = _getNotVestedAmount(grantHolder, onDayOrToday);
        uint256 grantAmount = grant.amount;

        return (
            grantAmount.sub(notVestedAmount),
            notVestedAmount,
            grantAmount,
            grant.startDay,
            vesting.duration,
            vesting.cliffDuration,
            vesting.interval,
            grant.isActive,
            grant.wasRevoked
        );
    }


    function vestingAsOf(
        uint32 onDayOrToday
    )
    public
    override
    view
    returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    )
    {
        return vestingForAccountAsOf(msg.sender, onDayOrToday);
    }

    function _fundsAreAvailableOn(
        address account,
        uint256 amount,
        uint32 onDay
    )
    internal
    view
    returns (bool ok) {
        return (amount <= _getAvailableAmount(account, onDay));
    }

    function revokeGrant(
        address grantHolder,
        uint32 onDay
    )
    public
    override
    onlyGrantor
    returns (bool ok) {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
        uint256 notVestedAmount;

        // Make sure grantor can only revoke from own pool.
        require(msg.sender == owner() || msg.sender == grant.grantor, "not allowed");
        // Make sure a vesting schedule has previously been set.
        require(grant.isActive, "no active grant");
        // Make sure it's revocable.
        require(vesting.isRevocable, "irrevocable");
        // Fail on likely erroneous input.
        require(onDay <= grant.startDay + vesting.duration, "no effect");
        // Don"t let grantor revoke anf portion of vested amount.
        require(onDay >= today(), "cannot revoke vested holdings");

        notVestedAmount = _getNotVestedAmount(grantHolder, onDay);

        // Use ERC20 _approve() to forcibly approve grantor to take back not-vested tokens from grantHolder.
        _token.approve(grantHolder,notVestedAmount);

        /* Emits an Approval Event. */
        _token.transferFrom(grantHolder, grant.grantor, notVestedAmount);
        /* Emits a Transfer and an Approval Event. */

        // Kill the grant by updating wasRevoked and isActive.
        _tokenGrants[grantHolder].wasRevoked = true;
        _tokenGrants[grantHolder].isActive = false;

        emit GrantRevoked(grantHolder, onDay);
        /* Emits the GrantRevoked event. */
        return true;
    }

}
