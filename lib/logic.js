/**
 * Track the trans of a banana from one trader to another
 * @param {org.banana.network.ChangeOwnerTransaction} trans - the trans to be processed
 * @transaction
 */
async function tradeBanana(trans) {

    // set the new owner of the banana
    const oldOwner      = trans.banana.owner;
    trans.banana.owner  = trans.newOwner;
    const assetRegistry = await getAssetRegistry('org.banana.network.Banana');

    // emit a notification that a trans has occurred
    const event    = getFactory().newEvent('org.banana.network', 'ChangeOwnerEvent');
    event.banana   = trans.banana;
    event.oldOwner = oldOwner;
    event.newOwner = trans.newOwner;
    emit(event);

    // persist the state of the banana
    await assetRegistry.update(trans.banana);
}

/**
 * new a banana
 * @param {org.banana.network.NewBananaTransaction} trans - the trans to be processed
 * @transaction
 */
async function newBanana(trans) {

    const banana     = getFactory().newResource('org.banana.network', 'Banana', trans.bananaId);
    banana.createdAt = new Date();
    banana.expiredAt = trans.expiredAt;
    banana.owner     = getCurrentParticipant();

    const assetRegistry = await getAssetRegistry('org.banana.network.Banana');
    // persist the state of the banana
    await assetRegistry.add(banana);
}
