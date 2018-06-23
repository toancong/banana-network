#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Feature: banana

    Background:
        Given I have deployed the business network definition ..
        And I have added the following participants of type org.banana.network.Company
            | companyId     |  name         |
            | farmer        | HAGL          |
            | deliverier    | Grab          |
            | supermarket   | BigC          |
        And I have added the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 6/1/2018      | 6/10/2018     |
            | 2             | farmer        | 6/5/2018      | 6/15/2018     |
        And I have issued the participant org.banana.network.Company#farmer with the identity HAGL
        And I have issued the participant org.banana.network.Company#deliverier with the identity Grab
        And I have issued the participant org.banana.network.Company#supermarket with the identity BigC

    Scenario: Scenario 1: HAGL can read all of the bananas
        When I use the identity HAGL
        Then I should have the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 6/1/2018      | 6/10/2018     |
            | 2             | farmer        | 6/5/2018      | 6/15/2018     |

    Scenario: Scenario 2: Grab can read all of the bananas
        When I use the identity Grab
        Then I should have the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 6/1/2018      | 6/10/2018     |
            | 2             | farmer        | 6/5/2018      | 6/15/2018     |

    Scenario: Scenario 3: HAGL can add bananas that he owns
        When I use the identity HAGL
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 3             | farmer        | 6/5/2018      | 6/15/2018     |
        Then I should have the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 3             | farmer        | 6/5/2018      | 6/15/2018     |

    Scenario: Scenario 4: HAGL cannot add bananas that Grab owns
        When I use the identity HAGL
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | deliverier    | 6/5/2018      | 6/15/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 5: Grab cannot add bananas that he owns
        When I use the identity Grab
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | deliverier    | 6/5/2018      | 6/15/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 6: Grab cannot add bananas that HAGL owns
        When I use the identity Grab
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | farmer        | 6/5/2018      | 6/15/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 7: HAGL can update his bananas
        When I use the identity HAGL
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 6/1/2018      | 6/15/2018     |
        Then I should have the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 6/1/2018      | 6/15/2018     |

    Scenario: Scenario 8: HAGL can submit a transaction of change owner for his bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        Then I should have the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverier    | 6/1/2018      | 6/10/2018     |
        And I should have received the following event of type org.banana.network.ChangeOwnerEvent
            | banana        | oldOwner      | newOwner      |
            | 1             | farmer        | deliverier    |

    Scenario: Scenario 9: HAGL cannot submit a transaction of change owner for Grab's bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | supermarket   |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 10: Grab can submit a transaction of change owner for his bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity Grab
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | supermarket   |
        Then I should have the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | supermarket   | 6/1/2018      | 6/10/2018     |
        And I should have received the following event of type org.banana.network.ChangeOwnerEvent
            | banana        | oldOwner      | newOwner      |
            | 1             | deliverier    | supermarket    |

    Scenario: Scenario 11: Grab cannot submit a transaction of change owner for HAGL's bananas
        When I use the identity Grab
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 2             | supermarket   |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 12: HAGL cannot update Grab's bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity HAGL
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverier    | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 13: Grab cannot update his bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity Grab
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverier    | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 14: Grab cannot update HAGL's bananas
        When I use the identity Grab
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 2             | farmer        | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 15: HAGL can remove his bananas
        When I use the identity HAGL
        And I remove the following asset of type org.banana.network.Banana
            | bananaId      |
            | 2             |
        Then I should not have the following assets of type org.banana.network.Banana
            | bananaId      |
            | 2             |

    Scenario: Scenario 16: HAGL cannot remove Grab's bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        And I remove the following asset of type org.banana.network.Banana
            | bananaId |
            | 1        |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 17: Grab cannot remove his bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity Grab
        And I remove the following asset of type org.banana.network.Banana
            | bananaId |
            | 1        |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 18: Grab cannot remove HAGL's bananas
        When I use the identity Grab
        And I remove the following asset of type org.banana.network.Banana
            | bananaId |
            | 2        |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 19: BigC can read all of the bananas
        When I use the identity BigC
        Then I should have the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 6/1/2018      | 6/10/2018     |
            | 2             | farmer        | 6/5/2018      | 6/15/2018     |

    Scenario: Scenario 20: BigC cannot add his bananas
        When I use the identity BigC
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | supermarket   | 6/5/2018      | 6/15/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 21: BigC cannot add HAGL's bananas
        When I use the identity BigC
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | farmer        | 6/5/2018      | 6/15/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 22: BigC cannot add Grab's bananas
        When I use the identity BigC
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | deliverier    | 6/5/2018      | 6/15/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 23: BigC cannot update his bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity Grab
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | supermarket   |
        When I use the identity BigC
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | supermarket   | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 24: BigC cannot update HAGL's bananas
        When I use the identity BigC
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 25: BigC cannot update Grab's bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity BigC
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverier    | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 27: BigC cannot remove HAGL's bananas
        When I use the identity BigC
        And I remove the following asset of type org.banana.network.Banana
            | bananaId      |
            | 1             |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 28: BigC cannot remove Grab's bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity BigC
        And I remove the following asset of type org.banana.network.Banana
            | bananaId      |
            | 1             |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 29: BigC cannot submit a transaction of change owner for HAGL's bananas
        When I use the identity Bigc
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | farmer        |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 30: BigC cannot submit a transaction of change owner for Grab's bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        When I use the identity Bigc
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | farmer        |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 31: HAGL cannot add directly owner to Grab
        When I use the identity HAGL
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | deliverier    | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 32: HAGL cannot update directly owner to Grab
        When I use the identity HAGL
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverier    | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 33: HAGL cannot add directly owner to BigC
        When I use the identity HAGL
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | supermarket   | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Scenario 34: HAGL cannot update directly owner to BigC
        When I use the identity HAGL
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | supermarket   | 6/1/2018      | 10/6/2018     |
        Then I should get an error matching /does not have .* access to resource/
