export const ADDRESS_ZERO = '0x0000000000000000000000000000000000000000';

// AS do not support initializing Map with data, a cain of sets is used instead
export const VOTER_STATE = new Map<number, string>()
  .set(0, 'None')
  .set(1, 'Abstain')
  .set(2, 'Yes')
  .set(3, 'No');

export const MAJORITY_VOTING_INTERFACE = '0xc52cd5d9';
export const ERC20_VOTING_INTERFACE = '0x27a0eec0';
export const ALLOWLIST_VOTING_INTERFACE = '0x9dd60761';
