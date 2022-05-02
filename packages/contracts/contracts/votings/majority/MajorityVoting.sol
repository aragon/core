/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "./IMajorityVoting.sol";
import "./../../core/component/MetaTxComponent.sol";
import "./../../utils/TimeHelpers.sol";

/// @title The abstract implementation of majority voting components
/// @author Michael Heuer - Aragon Association - 2022
/// @notice The abstract implementation of majority voting components
/// @dev This component implements the `IMajorityVoting` interface
abstract contract MajorityVoting is IMajorityVoting, MetaTxComponent, TimeHelpers {
    bytes4 internal constant MAJORITY_VOTING_INTERFACE_ID = type(IMajorityVoting).interfaceId;
    bytes32 public constant MODIFY_VOTE_CONFIG = keccak256("MODIFY_VOTE_CONFIG");

    uint64 public constant PCT_BASE = 10**18; // 0% = 0; 1% = 10^16; 100% = 10^18

    mapping(uint256 => Vote) internal votes;

    uint64 public supportRequiredPct;
    uint64 public participationRequiredPct;
    uint64 public minDuration;
    uint256 public votesLength;

    /// @notice Initializes the component
    /// @dev This is required for the UUPS upgradability pattern
    /// @param _dao The IDAO interface of the associated DAO
    /// @param _gsnForwarder The address of the trusted GSN forwarder required for meta transactions
    /// @param _participationRequiredPct The minimal required participation in percent.
    /// @param _supportRequiredPct The minimal required support in percent.
    /// @param _minDuration The minimal duration of a vote
    function __MajorityVoting_init(
        IDAO _dao,
        address _gsnForwarder,
        uint64 _participationRequiredPct,
        uint64 _supportRequiredPct,
        uint64 _minDuration
    ) internal onlyInitializing {
        _registerStandard(MAJORITY_VOTING_INTERFACE_ID);
        _validateAndSetSettings(_participationRequiredPct, _supportRequiredPct, _minDuration);

        __MetaTxComponent_init(_dao, _gsnForwarder);

        emit UpdateConfig(_participationRequiredPct, _supportRequiredPct, _minDuration);
    }

    /// @inheritdoc IMajorityVoting
    function changeVoteConfig(
        uint64 _participationRequiredPct,
        uint64 _supportRequiredPct,
        uint64 _minDuration
    ) external auth(MODIFY_VOTE_CONFIG) {
        _validateAndSetSettings(_participationRequiredPct, _supportRequiredPct, _minDuration);

        emit UpdateConfig(_participationRequiredPct, _supportRequiredPct, _minDuration);
    }

    /// @inheritdoc IMajorityVoting
    function newVote(
        bytes calldata _proposalMetadata,
        IDAO.Action[] calldata _actions,
        uint64 _startDate,
        uint64 _endDate,
        bool _executeIfDecided,
        VoterState _choice
    ) external virtual returns (uint256 voteId);

    /// @inheritdoc IMajorityVoting
    function vote(
        uint256 _voteId,
        VoterState _choice,
        bool _executesIfDecided
    ) external {
        if(_choice != VoterState.None && !_canVote(_voteId, _msgSender())) revert VoteCastForbidden(_voteId, _msgSender());
        _vote(_voteId, _choice, _msgSender(), _executesIfDecided);
    }

    /// @inheritdoc IMajorityVoting
    function execute(uint256 _voteId) public {
        if(!_canExecute(_voteId)) revert VoteExecutionForbidden(_voteId);
        _execute(_voteId);
    }

    /// @inheritdoc IMajorityVoting
    function getVoterState(uint256 _voteId, address _voter) public view returns (VoterState) {
        return votes[_voteId].voters[_voter];
    }

    /// @inheritdoc IMajorityVoting
    function canVote(uint256 _voteId, address _voter) public view returns (bool) {
        return _canVote(_voteId, _voter);
    }

    /// @inheritdoc IMajorityVoting
    function canExecute(uint256 _voteId) public view returns (bool) {
        return _canExecute(_voteId);
    }

    /// @inheritdoc IMajorityVoting
    function getVote(uint256 _voteId)
    public
    view
    returns (
        bool open,
        bool executed,
        uint64 startDate,
        uint64 endDate,
        uint64 snapshotBlock,
        uint64 supportRequired,
        uint64 participationRequired,
        uint256 votingPower,
        uint256 yea,
        uint256 nay,
        uint256 abstain,
        IDAO.Action[] memory actions
    )
    {
        Vote storage vote_ = votes[_voteId];

        open = _isVoteOpen(vote_);
        executed = vote_.executed;
        startDate = vote_.startDate;
        endDate = vote_.endDate;
        snapshotBlock= vote_.snapshotBlock;
        supportRequired = vote_.supportRequiredPct;
        participationRequired = vote_.participationRequiredPct;
        votingPower = vote_.votingPower;
        yea = vote_.yea;
        nay = vote_.nay;
        abstain = vote_.abstain;
        actions = vote_.actions;
    }

    /// @dev Internal function to cast a vote. It assumes the queried vote exists.
    /// @param _voteId voteId
    /// @param _choice Whether voter abstains, supports or not supports to vote.
    /// @param _executesIfDecided if true, and it's the last vote required, immediatelly executes a vote.
    function _vote(
        uint256 _voteId,
        VoterState _choice,
        address _voter,
        bool _executesIfDecided
    ) internal virtual;

    /// @dev Internal function to execute a vote. It assumes the queried vote exists.
    /// @param _voteId the vote Id
    function _execute(uint256 _voteId) internal virtual {
        bytes[] memory execResults = dao.execute(_voteId, votes[_voteId].actions);

        votes[_voteId].executed = true;

        emit ExecuteVote(_voteId, execResults);
    }

    /// @dev Internal function to check if a voter can participate on a vote. It assumes the queried vote exists.
    /// @param _voteId The voteId
    /// @param _voter the address of the voter to check
    /// @return True if the given voter can participate a certain vote, false otherwise
    function _canVote(uint256 _voteId, address _voter) internal view virtual returns (bool);

    /// @dev Internal function to check if a vote can be executed. It assumes the queried vote exists.
    /// @notice If `participationRequiredPct` and `supportRequiredPct` realative to the total `votingPower` are reached,
    ///         the vote is already determined and can be executed immediately even if the voting period has not ended yet.
    /// @param _voteId vote id
    /// @return True if the given vote can be executed, false otherwise
    function _canExecute(uint256 _voteId) internal virtual view returns (bool) {
        Vote storage vote_ = votes[_voteId];

        // Verify that the vote has not been executed already.
        if (vote_.executed) {
            return false;
        }

        // Calculate the participation the total number of votes casted relative
        uint256 participation = _calculatePct(vote_.yea + vote_.nay + vote_.abstain, vote_.votingPower);

        // Early execution criterium: The vote can execute immediately, if the participation and support relative to the 
        // total voting power is larger than the participation and support required, respectively, 
        // even if the voting period has not ended yet.
        if ((participation > vote_.participationRequiredPct) 
        && (_calculatePct(vote_.yea, vote_.votingPower) > vote_.supportRequiredPct)) {
            return true;
        }

        // Verify that the vote has ended.
        if (_isVoteOpen(vote_)) {
            return false;
        }

        // Verify that the total number of votes casted relative to the overall voting power is larger than the required relative participation.
        if (participation <= vote_.participationRequiredPct) {
            return false;
        }

        // Verify that the number of yes votes casted relative to the sum of yes and no votes is larger than the required relative support.
        if (_calculatePct(vote_.yea, vote_.yea + vote_.nay) <= vote_.supportRequiredPct) {
            return false;
        }

        // The criteria above are met and the vote can execute.
        return true;
    }

    /// @dev Internal function to check if a vote is still open
    /// @param vote_ the vote struct
    /// @return True if the given vote is open, false otherwise
    function _isVoteOpen(Vote storage vote_) internal virtual view returns (bool) {
        return getTimestamp64() < vote_.endDate && getTimestamp64() >= vote_.startDate && !vote_.executed;
    }

     /// @dev Calculates the percentage of `_value` relative to `_total`
    /// @param _value the current value
    /// @param _total the total value
    /// @return returns if the _value is _pct or more percentage of _total.
    function _calculatePct(
        uint256 _value,
        uint256 _total
    ) internal pure returns (uint256) {
        if (_total == 0) {
            revert ZeroValueNotAllowed();
        }

        return (_value * PCT_BASE) / _total;
    }

    function _validateAndSetSettings(
        uint64 _participationRequiredPct, 
        uint64 _supportRequiredPct,
        uint64 _minDuration
    ) internal virtual {
        if(_supportRequiredPct > PCT_BASE) {
            revert VoteSupportExceeded({limit: PCT_BASE, actual: _supportRequiredPct});
        }

        if(_participationRequiredPct > PCT_BASE) {
            revert VoteParticipationExceeded({limit: PCT_BASE, actual: _participationRequiredPct});
        }

        if(_minDuration == 0) {
            revert VoteDurationZero();
        }

        participationRequiredPct = _participationRequiredPct;
        supportRequiredPct = _supportRequiredPct;
        minDuration = _minDuration;
    }
}
