import {Address, BigInt, Bytes, ethereum} from '@graphprotocol/graph-ts';
import {createMockedFunction, newMockEvent} from 'matchstick-as';

import {
  VoteStarted,
  VoteCast,
  VoteExecuted,
  ConfigUpdated,
  UsersAdded,
  UsersRemoved,
  TrustedForwarderSet
} from '../../generated/templates/AllowlistVoting/AllowlistVoting';

// events

export function createNewTrustedForwarderSetEvent(
  forwarderAddress: string,
  contractAddress: string
): TrustedForwarderSet {
  let newTrustedForwarderSetEvent = changetype<TrustedForwarderSet>(
    newMockEvent()
  );

  newTrustedForwarderSetEvent.address = Address.fromString(contractAddress);
  newTrustedForwarderSetEvent.parameters = [];

  let forwarderAddressParam = new ethereum.EventParam(
    'forwarder',
    ethereum.Value.fromAddress(Address.fromString(forwarderAddress))
  );

  newTrustedForwarderSetEvent.parameters.push(forwarderAddressParam);

  return newTrustedForwarderSetEvent;
}

export function createNewVoteStartedEvent(
  voteId: string,
  creator: string,
  description: string,
  contractAddress: string
): VoteStarted {
  let createVoteStartedEvent = changetype<VoteStarted>(newMockEvent());

  createVoteStartedEvent.address = Address.fromString(contractAddress);
  createVoteStartedEvent.parameters = [];

  let voteIdParam = new ethereum.EventParam(
    'voteId',
    ethereum.Value.fromSignedBigInt(BigInt.fromString(voteId))
  );
  let creatorParam = new ethereum.EventParam(
    'creator',
    ethereum.Value.fromAddress(Address.fromString(creator))
  );
  let descriptionParam = new ethereum.EventParam(
    'description',
    ethereum.Value.fromBytes(Bytes.fromUTF8(description))
  );

  createVoteStartedEvent.parameters.push(voteIdParam);
  createVoteStartedEvent.parameters.push(creatorParam);
  createVoteStartedEvent.parameters.push(descriptionParam);

  return createVoteStartedEvent;
}

export function createNewVoteCastEvent(
  voteId: string,
  voter: string,
  creatorChoice: string,
  voteWeight: string,
  contractAddress: string
): VoteCast {
  let createVoteCastEvent = changetype<VoteCast>(newMockEvent());

  createVoteCastEvent.address = Address.fromString(contractAddress);
  createVoteCastEvent.parameters = [];

  let voteIdParam = new ethereum.EventParam(
    'voteId',
    ethereum.Value.fromSignedBigInt(BigInt.fromString(voteId))
  );
  let voterParam = new ethereum.EventParam(
    'voter',
    ethereum.Value.fromAddress(Address.fromString(voter))
  );
  let choiceParam = new ethereum.EventParam(
    'choice',
    ethereum.Value.fromUnsignedBigInt(BigInt.fromString(creatorChoice))
  );
  let voteWeightParam = new ethereum.EventParam(
    'choice',
    ethereum.Value.fromUnsignedBigInt(BigInt.fromString(voteWeight))
  );

  createVoteCastEvent.parameters.push(voteIdParam);
  createVoteCastEvent.parameters.push(voterParam);
  createVoteCastEvent.parameters.push(choiceParam);
  createVoteCastEvent.parameters.push(voteWeightParam);

  return createVoteCastEvent;
}

export function createNewVoteExecutedEvent(
  voteId: string,
  contractAddress: string
): VoteExecuted {
  let createVoteExecutedEvent = changetype<VoteExecuted>(newMockEvent());

  createVoteExecutedEvent.address = Address.fromString(contractAddress);
  createVoteExecutedEvent.parameters = [];

  let voteIdParam = new ethereum.EventParam(
    'voteId',
    ethereum.Value.fromSignedBigInt(BigInt.fromString(voteId))
  );
  let execResultsParam = new ethereum.EventParam(
    'execResults',
    ethereum.Value.fromBytesArray([Bytes.fromUTF8('')])
  );

  createVoteExecutedEvent.parameters.push(voteIdParam);
  createVoteExecutedEvent.parameters.push(execResultsParam);

  return createVoteExecutedEvent;
}

export function createNewConfigUpdatedEvent(
  participationRequiredPct: string,
  supportRequiredPct: string,
  minDuration: string,
  contractAddress: string
): ConfigUpdated {
  let newConfigUpdatedEvent = changetype<ConfigUpdated>(newMockEvent());

  newConfigUpdatedEvent.address = Address.fromString(contractAddress);
  newConfigUpdatedEvent.parameters = [];

  let participationRequiredPctParam = new ethereum.EventParam(
    'participationRequiredPct',
    ethereum.Value.fromSignedBigInt(BigInt.fromString(participationRequiredPct))
  );
  let supportRequiredPctParam = new ethereum.EventParam(
    'supportRequiredPct',
    ethereum.Value.fromSignedBigInt(BigInt.fromString(supportRequiredPct))
  );
  let minDurationParam = new ethereum.EventParam(
    'minDuration',
    ethereum.Value.fromSignedBigInt(BigInt.fromString(minDuration))
  );

  newConfigUpdatedEvent.parameters.push(participationRequiredPctParam);
  newConfigUpdatedEvent.parameters.push(supportRequiredPctParam);
  newConfigUpdatedEvent.parameters.push(minDurationParam);

  return newConfigUpdatedEvent;
}

export function createNewUsersAddedEvent(
  addresses: Address[],
  contractAddress: string
): UsersAdded {
  let newUsersAddedEvent = changetype<UsersAdded>(newMockEvent());

  newUsersAddedEvent.address = Address.fromString(contractAddress);
  newUsersAddedEvent.parameters = [];

  let usersParam = new ethereum.EventParam(
    'users',
    ethereum.Value.fromAddressArray(addresses)
  );

  newUsersAddedEvent.parameters.push(usersParam);

  return newUsersAddedEvent;
}

export function createNewUsersRemovedEvent(
  addresses: Address[],
  contractAddress: string
): UsersRemoved {
  let newUsersRemovedEvent = changetype<UsersRemoved>(newMockEvent());

  newUsersRemovedEvent.address = Address.fromString(contractAddress);
  newUsersRemovedEvent.parameters = [];

  let usersParam = new ethereum.EventParam(
    'users',
    ethereum.Value.fromAddressArray(addresses)
  );

  newUsersRemovedEvent.parameters.push(usersParam);

  return newUsersRemovedEvent;
}

// calls

export function getVotesLengthCall(
  contractAddress: string,
  returns: string
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    'votesLength',
    'votesLength():(uint256)'
  )
    .withArgs([])
    .returns([ethereum.Value.fromSignedBigInt(BigInt.fromString(returns))]);
}
