/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';
/**
 * Write the unit tests for your transction processor functions here
 */

const AdminConnection = require('composer-admin').AdminConnection;
const BusinessNetworkConnection = require('composer-client').BusinessNetworkConnection;
const { BusinessNetworkDefinition, CertificateUtil, IdCard } = require('composer-common');
const path = require('path');

const chai = require('chai');
chai.should();
chai.use(require('chai-as-promised'));

const namespace = 'org.banana.network';
const assetBananaType = 'Banana';
const assetNS = namespace + '.' + assetBananaType;
const participantCompanyType = 'Company';
const participantNS = namespace + '.' + participantCompanyType;
const transChangeOwnerType = 'ChangeOwnerTransaction';

describe('#' + namespace, () => {
    // In-memory card store for testing so cards are not persisted to the file system
    const cardStore = require('composer-common').NetworkCardStoreManager.getCardStore( { type: 'composer-wallet-inmemory' } );

    // Embedded connection used for local testing
    const connectionProfile = {
        name: 'embedded',
        'x-type': 'embedded'
    };

    // Name of the business network card containing the administrative identity for the business network
    const adminCardName = 'admin';

    // Admin connection to the blockchain, used to deploy the business network
    let adminConnection;

    // This is the business network connection the tests will use.
    let businessNetworkConnection;

    // This is the factory for creating instances of types.
    let factory;

    // These are the identities for HAGL and Grab.
    const farmerCardName = 'HAGL';
    const deliverierCardName = 'Grab';

    // These are a list of receieved events.
    let events;

    let businessNetworkName;

    before(async () => {
        // Generate certificates for use with the embedded connection
        const credentials = CertificateUtil.generate({ commonName: 'admin' });

        // Identity used with the admin connection to deploy business networks
        const deployerMetadata = {
            version: 1,
            userName: 'PeerAdmin',
            roles: [ 'PeerAdmin', 'ChannelAdmin' ]
        };
        const deployerCard = new IdCard(deployerMetadata, connectionProfile);
        deployerCard.setCredentials(credentials);
        const deployerCardName = 'PeerAdmin';

        adminConnection = new AdminConnection({ cardStore: cardStore });

        await adminConnection.importCard(deployerCardName, deployerCard);
        await adminConnection.connect(deployerCardName);
    });

    /**
     *
     * @param {String} cardName The card name to use for this identity
     * @param {Object} identity The identity details
     */
    async function importCardForIdentity(cardName, identity) {
        const metadata = {
            userName: identity.userID,
            version: 1,
            enrollmentSecret: identity.userSecret,
            businessNetwork: businessNetworkName
        };
        const card = new IdCard(metadata, connectionProfile);
        await adminConnection.importCard(cardName, card);
    }

    /**
     *
     * @param {String} id asset id
     * @param {String} ownerId owner Id
     */
    function newAsset(id, ownerId = 'farmer', attrs = {
        createdAt: new Date('6/1/2018'), expiredAt: new Date('6/10/2018'),
    }) {
        const asset = factory.newResource(namespace, assetBananaType, id);
        asset.owner = factory.newRelationship(namespace, participantCompanyType, ownerId);
        for (const key in attrs) {
            if (attrs.hasOwnProperty(key)) {
                asset[key] = attrs[key];
            }
        }
        return asset;
    }

    // This is called before each test is executed.
    beforeEach(async () => {
        // Generate a business network definition from the project directory.
        let businessNetworkDefinition = await BusinessNetworkDefinition.fromDirectory(path.resolve(__dirname, '..'));
        businessNetworkName = businessNetworkDefinition.getName();
        await adminConnection.install(businessNetworkDefinition);
        const startOptions = {
            networkAdmins: [
                {
                    userName: 'admin',
                    enrollmentSecret: 'adminpw'
                }
            ]
        };
        const adminCards = await adminConnection.start(businessNetworkName, businessNetworkDefinition.getVersion(), startOptions);
        await adminConnection.importCard(adminCardName, adminCards.get('admin'));

        // Create and establish a business network connection
        businessNetworkConnection = new BusinessNetworkConnection({ cardStore: cardStore });
        events = [];
        businessNetworkConnection.on('event', event => {
            events.push(event);
        });
        await businessNetworkConnection.connect(adminCardName);

        // Get the factory for the business network.
        factory = businessNetworkConnection.getBusinessNetwork().getFactory();

        const participantRegistry = await businessNetworkConnection.getParticipantRegistry(participantNS);
        // Create the participants.
        const HAGL = factory.newResource(namespace, participantCompanyType, 'farmer');
        HAGL.name = 'HAGL';

        const Grab = factory.newResource(namespace, participantCompanyType, 'deliverier');
        Grab.name = 'Grab';

        participantRegistry.addAll([HAGL, Grab]);

        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        // Create the assets.
        const asset1 = newAsset('1', 'farmer');

        const asset2 = newAsset('2', 'farmer', {
            createdAt: new Date('6/5/2018'),
            expiredAt: new Date('6/15/2018'),
        });

        assetRegistry.addAll([asset1, asset2]);

        // Issue the identities.
        let identity = await businessNetworkConnection.issueIdentity(participantNS + '#farmer', 'HAGL');
        await importCardForIdentity(farmerCardName, identity);
        identity = await businessNetworkConnection.issueIdentity(participantNS + '#deliverier', 'Grab');
        await importCardForIdentity(deliverierCardName, identity);
    });

    /**
     * Reconnect using a different identity.
     * @param {String} cardName The name of the card for the identity to use
     */
    async function useIdentity(cardName) {
        await businessNetworkConnection.disconnect();
        businessNetworkConnection = new BusinessNetworkConnection({ cardStore: cardStore });
        events = [];
        businessNetworkConnection.on('event', (event) => {
            events.push(event);
        });
        await businessNetworkConnection.connect(cardName);
        factory = businessNetworkConnection.getBusinessNetwork().getFactory();
    }

    it('Scenario 1: HAGL can read all of the bananas', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        const assets = await assetRegistry.getAll();

        // Validate the assets.
        assets.should.have.lengthOf(2);
        const asset1 = assets[0];
        asset1.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#farmer');
        asset1.createdAt.should.eql(new Date('6/1/2018'));
        asset1.expiredAt.should.eql(new Date('6/10/2018'));
        const asset2 = assets[1];
        asset2.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#farmer');
        asset2.createdAt.should.eql(new Date('6/5/2018'));
        asset2.expiredAt.should.eql(new Date('6/15/2018'));
    });

    it('Scenario 2: Grab can read all of the bananas', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        const assets = await assetRegistry.getAll();

        // Validate the assets.
        assets.should.have.lengthOf(2);
        const asset1 = assets[0];
        asset1.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#farmer');
        asset1.createdAt.should.eql(new Date('6/1/2018'));
        asset1.expiredAt.should.eql(new Date('6/10/2018'));
        const asset2 = assets[1];
        asset2.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#farmer');
        asset2.createdAt.should.eql(new Date('6/5/2018'));
        asset2.expiredAt.should.eql(new Date('6/15/2018'));
    });

    it('Scenario 3: HAGL can add bananas that he owns', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Create the asset.
        let asset3 = newAsset('3', 'farmer');
        asset3.createdAt = new Date('6/5/2018');
        asset3.expiredAt = new Date('6/15/2018');

        // Add the asset, then get the asset.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        await assetRegistry.add(asset3);

        // Validate the asset.
        asset3 = await assetRegistry.get('3');
        asset3.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#farmer');
        asset3.createdAt.should.eql(new Date('6/5/2018'));
        asset3.expiredAt.should.eql(new Date('6/15/2018'));
    });

    it('Scenario 4: HAGL cannot add bananas that Grab owns', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Create the asset.
        const asset4 = newAsset('4', 'deliverier');

        // Try to add the asset, should fail.
        const assetRegistry = await  businessNetworkConnection.getAssetRegistry(assetNS);
        assetRegistry.add(asset4).should.be.rejectedWith(/does not have .* access to resource/);
    });

    it('Scenario 5: Grab cannot add bananas that he owns', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Create the asset.
        let asset4 = newAsset('4', 'deliverier');

        // Try to add the asset, should fail.
        const assetRegistry = await  businessNetworkConnection.getAssetRegistry(assetNS);
        assetRegistry.add(asset4).should.be.rejectedWith(/does not have .* access to resource/);
    });

    it('Scenario 6: Grab cannot add bananas that HAGL owns', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Create the asset.
        const asset4 = newAsset('4', 'farmer');

        // Try to add the asset, should fail.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        assetRegistry.add(asset4).should.be.rejectedWith(/does not have .* access to resource/);

    });

    it.skip('Scenario 7: HAGL can update his bananas', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Create the asset.
        let asset1 = factory.newResource(namespace, assetBananaType, '1');
        asset1.owner = factory.newRelationship(namespace, participantCompanyType, 'farmer');
        asset1.value = '50';

        // Update the asset, then get the asset.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        await assetRegistry.update(asset1);

        // Validate the asset.
        asset1 = await assetRegistry.get('1');
        asset1.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#farmer');
        asset1.value.should.equal('50');
    });

    it.skip('Scenario 12: HAGL cannot update Grab\'s bananas', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Create the asset.
        const asset2 = factory.newResource(namespace, assetBananaType, '2');
        asset2.owner = factory.newRelationship(namespace, participantCompanyType, 'deliverier');
        asset2.value = '50';

        // Try to update the asset, should fail.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        assetRegistry.update(asset2).should.be.rejectedWith(/does not have .* access to resource/);
    });

    it.skip('Scenario 13: Grab cannot update his bananas', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Create the asset.
        let asset2 = factory.newResource(namespace, assetBananaType, '2');
        asset2.owner = factory.newRelationship(namespace, participantCompanyType, 'deliverier');
        asset2.value = '60';

        // Update the asset, then get the asset.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        await assetRegistry.update(asset2);

        // Validate the asset.
        asset2 = await assetRegistry.get('2');
        asset2.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#deliverier');
        asset2.value.should.equal('60');
    });

    it.skip('Scenario 14: Grab cannot update HAGL\'s bananas', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Create the asset.
        const asset1 = factory.newResource(namespace, assetBananaType, '1');
        asset1.owner = factory.newRelationship(namespace, participantCompanyType, 'farmer');
        asset1.value = '60';

        // Update the asset, then get the asset.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        assetRegistry.update(asset1).should.be.rejectedWith(/does not have .* access to resource/);

    });

    it.skip('Scenario 15: HAGL can remove his bananas', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Remove the asset, then test the asset exists.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        await assetRegistry.remove('1');
        const exists = await assetRegistry.exists('1');
        exists.should.be.false;
    });

    it.skip('Scenario 16: HAGL cannot remove Grab\'s bananas', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Remove the asset, then test the asset exists.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        assetRegistry.remove('2').should.be.rejectedWith(/does not have .* access to resource/);
    });

    it.skip('Scenario 17: Grab cannot remove his bananas', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Remove the asset, then test the asset exists.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        await assetRegistry.remove('2');
        const exists = await assetRegistry.exists('2');
        exists.should.be.false;
    });

    it.skip('Scenario 18: Grab cannot remove HAGL\'s bananas', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Remove the asset, then test the asset exists.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        assetRegistry.remove('1').should.be.rejectedWith(/does not have .* access to resource/);
    });

    it.skip('Scenario 8: HAGL can submit a transaction of change owner for his bananas', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Submit the transaction.
        const transaction = factory.newTransaction(namespace, transChangeOwnerType);
        transaction.asset = factory.newRelationship(namespace, assetBananaType, '1');
        transaction.newValue = '50';
        await businessNetworkConnection.submitTransaction(transaction);

        // Get the asset.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        const asset1 = await assetRegistry.get('1');

        // Validate the asset.
        asset1.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#farmer');
        asset1.value.should.equal('50');

        // Validate the events.
        events.should.have.lengthOf(1);
        const event = events[0];
        event.eventId.should.be.a('string');
        event.timestamp.should.be.an.instanceOf(Date);
        event.asset.getFullyQualifiedIdentifier().should.equal(assetNS + '#1');
        event.oldValue.should.equal('10');
        event.newValue.should.equal('50');
    });

    it.skip('Scenario 9: HAGL cannot submit a transaction of change owner for Grab\'s bananas', async () => {
        // Use the identity for HAGL.
        await useIdentity(farmerCardName);

        // Submit the transaction.
        const transaction = factory.newTransaction(namespace, transChangeOwnerType);
        transaction.asset = factory.newRelationship(namespace, assetBananaType, '2');
        transaction.newValue = '50';
        businessNetworkConnection.submitTransaction(transaction).should.be.rejectedWith(/does not have .* access to resource/);
    });

    it.skip('Scenario 10: Grab can submit a transaction  of change owner for his bananas', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Submit the transaction.
        const transaction = factory.newTransaction(namespace, transChangeOwnerType);
        transaction.asset = factory.newRelationship(namespace, assetBananaType, '2');
        transaction.newValue = '60';
        await businessNetworkConnection.submitTransaction(transaction);

        // Get the asset.
        const assetRegistry = await businessNetworkConnection.getAssetRegistry(assetNS);
        const asset2 = await assetRegistry.get('2');

        // Validate the asset.
        asset2.owner.getFullyQualifiedIdentifier().should.equal(participantNS + '#deliverier');
        asset2.value.should.equal('60');

        // Validate the events.
        events.should.have.lengthOf(1);
        const event = events[0];
        event.eventId.should.be.a('string');
        event.timestamp.should.be.an.instanceOf(Date);
        event.asset.getFullyQualifiedIdentifier().should.equal(assetNS + '#2');
        event.oldValue.should.equal('20');
        event.newValue.should.equal('60');
    });

    it.skip('Scenario 11: Grab cannot submit a transaction for HAGL\'s bananas', async () => {
        // Use the identity for Grab.
        await useIdentity(deliverierCardName);

        // Submit the transaction.
        const transaction = factory.newTransaction(namespace, transChangeOwnerType);
        transaction.asset = factory.newRelationship(namespace, assetBananaType, '1');
        transaction.newValue = '60';
        businessNetworkConnection.submitTransaction(transaction).should.be.rejectedWith(/does not have .* access to resource/);
    });

});
