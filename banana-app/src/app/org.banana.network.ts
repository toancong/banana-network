import {Asset} from './org.hyperledger.composer.system';
import {Participant} from './org.hyperledger.composer.system';
import {Transaction} from './org.hyperledger.composer.system';
import {Event} from './org.hyperledger.composer.system';
// export namespace org.banana.network{
   export class Banana extends Asset {
      bananaId: string;
      createdAt: Date;
      expiredAt: Date;
      owner: Company;
   }
   export class Company extends Participant {
      companyId: string;
      name: string;
   }
   export class ChangeOwnerTransaction extends Transaction {
      banana: Banana;
      newOwner: Company;
   }
   export class ChangeOwnerEvent extends Event {
      banana: Banana;
      oldOwner: Company;
      newOwner: Company;
   }
// }
