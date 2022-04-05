import {assert, clearStore, test} from 'matchstick-as/assembly/index';
import {Address} from '@graphprotocol/graph-ts';
import {runHandleNewDAORegistered} from './utils';
import {DAO_ADDRESS, ADDRESS_ONE, DAO_TOKEN_ADDRESS} from '../constants';

test('Run registry mappings with mock event', () => {
  // create event and run it's handler
  runHandleNewDAORegistered(
    DAO_ADDRESS,
    ADDRESS_ONE,
    DAO_TOKEN_ADDRESS,
    'mock-Dao'
  );

  let entityID = Address.fromString(DAO_ADDRESS).toHexString();

  // checks
  assert.fieldEquals('Dao', entityID, 'id', entityID);
  assert.fieldEquals(
    'Dao',
    entityID,
    'creator',
    Address.fromString(ADDRESS_ONE).toHexString()
  );
  assert.fieldEquals(
    'Dao',
    entityID,
    'token',
    Address.fromString(DAO_TOKEN_ADDRESS).toHexString()
  );
  assert.fieldEquals('Dao', entityID, 'name', 'mock-Dao');

  clearStore();
});
