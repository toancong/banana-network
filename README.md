# banana-network

Banana network architecture
![Banana network architecture](https://github.com/toancong/banana-network/raw/master/banana-network-architecture.png "Banana network architecture")

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

    run api apps, need a card which require minimum permission to generate api
    ```
    composer-rest-server -c admin@banana-network -n never
    ```
    or
    ```
    source .env && composer-rest-server
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

# Test

```
npm run test
```
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

- Clean and start new servers
```
rm -fr ~/.composer
./stopFabric.sh
./teardownFabric.sh
./downloadFabric.sh
./startFabric.sh
./createPeerAdminCard.sh
```

# Some errors may occur
- Error: Error trying to start business network. Error: No valid responses from any peers.
Response from attempted peer commswas an error: Error: 2 UNKNOWN: chaincode error (status: 500, message: chaincode exists banana-network)
-> cause: when try to start a started network
-> solve: use upgrade command instead

- Error: Card already exists: admin@banana-network
-> cause: when try import an imported card
-> solve: ensure don't re-import the card

- Error: Error trying to upgrade business network. Error: No valid responses from any peers.
Response from attempted peer commswas an error: Error: 2 UNKNOWN: chaincode error (status: 500, message: version already exists for chaincode with name 'banana-network')
-> cause: when try upgrade an upgraded network
-> solve: ensure upgrade properly network's version

- Error: Card not found: admin@banana-network
-> cause: not yet import admin card
-> solve: use import command

- Error: 2 UNKNOWN: error executing chaincode: transaction returned with failure: Error: The current identity, with the name 'admin' and the identifier '57791c6bacec1fe3ea240a5e215174f7474a60075f063238a5fff098508f6193', has not been registered
-> cause: import a wrong card
-> issue: correct card

- Error: Error trying login and get user Context. Error: Error trying to enroll user or load channel configuration. Error: Enrollment failed with errors [[{"code":20,"message":"Authorization failure"}]] and error in CA "POST /api/v1/enroll 401 24 "Login failure: The identity UserId has already enrolled 1 times, it has reached its maximum enrollment allowance" or card imported sucessfully even run delete and import again
-> cause: a card imported but enrolled before or import a wrong card
-> solve: run delete card and import right one again

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

composer network ping --card HAGL@banana-network
composer network ping --card Grab@banana-network
composer network ping --card BigC@banana-network

composer card export -f HAGL.card -c HAGL@banana-network
composer card export -f Grab.card -c Grab@banana-network
composer card export -f BigC.card -c BigC@banana-network
composer card export -f admin.card -c admin@banana-network
```

```
# 1. Farmer create banana
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

# 2. Farmer change owner to Deliverier
composer transaction submit --card HAGL@banana-network -d '
{
    "$class": "org.banana.network.ChangeOwnerTransaction",
    "banana": "1",
    "newOwner": "deliverier"
}
'

#3. Deliverier change owner to Supermarket
composer transaction submit --card Grab@banana-network -d '
{
    "$class": "org.banana.network.ChangeOwnerTransaction",
    "banana": "1",
    "newOwner": "supermarket"
}
'
```
