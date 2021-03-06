import {ethers} from 'hardhat';

export enum VoteOption {
  None,
  Abstain,
  Yes,
  No,
}

const toBn = ethers.BigNumber.from;
const bigExp = (x: number, y: number) => toBn(x).mul(toBn(10).pow(toBn(y)));
export const pct16 = (x: number) => bigExp(x, 16);

export const VOTING_EVENTS = {
  CONFIG_UPDATED: 'ConfigUpdated',
  VOTE_STARTED: 'VoteCreated',
  VOTE_CAST: 'VoteCast',
  VOTE_EXECUTED: 'VoteExecuted',
};
