# banana-network

banana


# develop business network

1. build business network

    archive source code into bna file
    ```
    composer archive create -t dir -n .
    ```
    or
    ```
    npm run build
    ```

2. install business network

    install business network to all peer, need peers admin card
    this will upload new network to all peer, but need install or upgrade to effect
    ```
    composer network install -a dist/banana-network.bna -c PeerAdmin@hlfv1
    ```

3. run network

    run new network, need Business admin card
    this will create a NetworkAdmin card for run apps
    ```
    composer network start --networkName banana-network --networkVersion 0.0.11 --card PeerAdmin@hlfv1 --networkAdmin admin --networkAdminEnrollSecret adminpw
    ```
    short version
    ```
    composer network start -n banana-network -V 0.0.11 -c PeerAdmin@hlfv1 -A admin -S adminpw
    ```

    if upgrade use
    ```
    composer network upgrade -c PeerAdmin@hlfv1 -n banana-network -V 0.0.11
    ```

    ping to check a network is running
    ```
    composer network ping --card admin@banana-network
    ```
4. Import network card for the business network administrator
    ```
    composer card import --file admin@banana-network.card
    ```
5. start rest server

    run api apps, need NetworkAdmin card
    ```
    composer-rest-server -c admin@banana-network -n never
    #composer-rest-server -c HAGL@banana-network -n never
    ```

    Browse http://localhost:3000

6. start client app

    run client app, need NetworkAdmin card
    ```
    yo hyperledger-composer:angular
    ```
    ```
    cd angular-app && npm start
    ```

    Browse http://localhost:4200

# Rapid build and deploy

For start network (not yet start) `npm run start`
For upgrade network (started) `npm run upgrade`

# Notes

- import admin network card, this file created by start network
    ```
    composer card import --file admin@banana-network.card
    ```

- if you want use playground you need import the cart

- upgrade tool
    ```
    npm install -g composer-cli composer-rest-server generator-hyperledger-composer yo composer-playground
    ```

- Playground
    ```
    composer-playground
    ```

# Some errors may occur
- Error: Error trying to start business network. Error: No valid responses from any peers.
Response from attempted peer commswas an error: Error: 2 UNKNOWN: chaincode error (status: 500, message: chaincode exists banana-network)
-> when try to start a started network

- Error: Card already exists: admin@banana-network
-> when try import an imported card

- Error: Error trying to upgrade business network. Error: No valid responses from any peers.
Response from attempted peer commswas an error: Error: 2 UNKNOWN: chaincode error (status: 500, message: version already exists for chaincode with name 'banana-network')
-> when try upgrade an upgraded network

- Error: Card not found: admin@banana-network
-> import admin card

- Error: 2 UNKNOWN: error executing chaincode: transaction returned with failure: Error: The current identity, with the name 'admin' and the identifier '57791c6bacec1fe3ea240a5e215174f7474a60075f063238a5fff098508f6193', has not been registered
-> find way to bind identity
```
composer identity issue -c admin@banana-network -f admin@banana-network.card -u admin -a "resource:org.hyperledger.composer.system.NetworkAdmin#admin"

composer identity bind -c admin@banana-network -a "resource:org.hyperledger.composer.system.NetworkAdmin#admin" -e ./admin-pub.pem
```

- Clean and start new servers
```
composer card delete -c PeerAdmin@fabric-network
composer card delete -c admin@banana-network
rm -fr ~/.composer
./stopFabric.sh
./teardownFabric.sh
./downloadFabric.sh
./startFabric.sh
./createPeerAdminCard.sh
```

# Let's try scenario examples
## Seed
```
composer card import --file admin@banana-network.card

composer participant add -c admin@banana-network -d '{"$class":"org.banana.network.Company", "companyId":"farmer", "name": "HAGL"}'
composer participant add -c admin@banana-network -d '{"$class":"org.banana.network.Company", "companyId":"deliverier", "name": "Grab"}'
composer participant add -c admin@banana-network -d '{"$class":"org.banana.network.Company", "companyId":"supermarket", "name": "BigC"}'

composer identity issue -c admin@banana-network -u HAGL -a "resource:org.banana.network.Company#farmer"
composer identity issue -c admin@banana-network -u Grab -a "resource:org.banana.network.Company#deliverier"
composer identity issue -c admin@banana-network -u BigC -a "resource:org.banana.network.Company#supermarket"


composer card import --file HAGL@banana-network.card
composer card import --file Grab@banana-network.card
composer card import --file BigC@banana-network.card
```

1. Farmer create banana
```
composer transaction submit --card HAGL@banana-network -d '
{
    "$class": "org.banana.network.NewBananaTransaction",
    "bananaId": "1",
    "expiredAt": "2018-06-19T18:17:34.613Z"
}
'

composer transaction submit --card HAGL@banana-network -d '
{
    "$class": "org.hyperledger.composer.system.AddAsset",
    "resources": [
        {
            "$class": "org.banana.network.Banana",
            "bananaId": "2",
            "createdAt": "2018-06-21T16:23:46.424Z",
            "expiredAt": "2018-06-21T16:23:46.424Z",
            "owner": "resource:org.banana.network.Company#farmer"
        },
        {
            "$class": "org.banana.network.Banana",
            "bananaId": "3",
            "createdAt": "2018-06-21T16:23:46.424Z",
            "expiredAt": "2018-06-21T16:23:46.424Z",
            "owner": "resource:org.banana.network.Company#farmer"
        },
        {
            "$class": "org.banana.network.Banana",
            "bananaId": "4",
            "createdAt": "2018-06-21T16:23:46.424Z",
            "expiredAt": "2018-06-21T16:23:46.424Z",
            "owner": "resource:org.banana.network.Company#farmer"
        }
    ],
    "targetRegistry": "resource:org.hyperledger.composer.system.AssetRegistry#org.banana.network.Banana"
}
'
```
