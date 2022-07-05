import {assert, clearStore, test} from 'matchstick-as/assembly/index';
import {Address} from '@graphprotocol/graph-ts';

import {handleNewDAORegistered} from '../../src/registry';
import {DAO_ADDRESS, ADDRESS_ONE} from '../constants';
import {createNewDaoEvent} from './utils';

test('Run registry mappings with mock event', () => {
  // create event
  let newDaoEvent = createNewDaoEvent(DAO_ADDRESS, ADDRESS_ONE, 'mock-Dao');

  // handle event
  handleNewDAORegistered(newDaoEvent);

  let entityID = Address.fromString(DAO_ADDRESS).toHexString();

  // checks
  assert.fieldEquals('Dao', entityID, 'id', entityID);
  assert.fieldEquals(
    'Dao',
    entityID,
    'creator',
    Address.fromString(ADDRESS_ONE).toHexString()
  );
  assert.fieldEquals('Dao', entityID, 'name', 'mock-Dao');

  clearStore();
});
