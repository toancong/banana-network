echo start network
npm run start

echo import admin card
composer card import --file admin@banana-network.card
composer network ping --card admin@banana-network
composer card export -f admin.card -c admin@banana-network
rm admin@banana-network.card

echo import HAGL card
composer participant add -c admin@banana-network -d '{"$class":"org.banana.network.Company", "companyId":"farmer", "name": "HAGL"}'
composer identity issue -c admin@banana-network -u HAGL -a "resource:org.banana.network.Company#farmer"
composer card import --file HAGL@banana-network.card
composer network ping --card HAGL@banana-network
composer card export -f HAGL.card -c HAGL@banana-network
rm HAGL@banana-network.card

echo import Grab card
composer participant add -c admin@banana-network -d '{"$class":"org.banana.network.Company", "companyId":"deliverier", "name": "Grab"}'
composer identity issue -c admin@banana-network -u Grab -a "resource:org.banana.network.Company#deliverier"
composer card import --file Grab@banana-network.card
composer network ping --card Grab@banana-network
composer card export -f Grab.card -c Grab@banana-network
rm Grab@banana-network.card

echo import BigC card
composer participant add -c admin@banana-network -d '{"$class":"org.banana.network.Company", "companyId":"supermarket", "name": "BigC"}'
composer identity issue -c admin@banana-network -u BigC -a "resource:org.banana.network.Company#supermarket"
composer card import --file BigC@banana-network.card
composer network ping --card BigC@banana-network
composer card export -f BigC.card -c BigC@banana-network
rm BigC@banana-network.card

echo Farmer create banana
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

echo Farmer change owner to Deliverier
composer transaction submit --card HAGL@banana-network -d '
{
    "$class": "org.banana.network.ChangeOwnerTransaction",
    "banana": "1",
    "newOwner": "deliverier"
}
'

echo Deliverier change owner to Supermarket
composer transaction submit --card Grab@banana-network -d '
{
    "$class": "org.banana.network.ChangeOwnerTransaction",
    "banana": "1",
    "newOwner": "supermarket"
}
'
