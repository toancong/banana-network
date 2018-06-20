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

Feature: Sample

    Background:
        Given I have deployed the business network definition ..
        And I have added the following participants of type org.banana.network.Company
            | companyId     |  name         |
            | farmer        | HAGL          |
            | deliverier    | Grab          |
            | supermarket   | BigC          |
        And I have added the following assets of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 1/6/2018      | 10/6/2018     |
            | 2             | farmer        | 5/6/2018      | 15/6/2018     |
        And I have issued the participant org.banana.network.Company#farmer with the identity HAGL
        And I have issued the participant org.banana.network.Company#deliverier with the identity Grab
        And I have issued the participant org.banana.network.Company#supermarket with the identity BigC

    Scenario 1: HAGL can read all of the bananas
        When I use the identity HAGL
        Then I should have the following bananas of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 1/6/2018      | 10/6/2018     |
            | 2             | farmer        | 5/6/2018      | 15/6/2018     |

    Scenario 2: Grab can read all of the bananas
        When I use the identity Grab
        Then I should have the following bananas of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 1/6/2018      | 10/6/2018     |
            | 2             | farmer        | 5/6/2018      | 15/6/2018     |

    Scenario 3: HAGL can add bananas that he owns
        When I use the identity HAGL
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 3             | farmer        | 5/6/2018      | 15/6/2018     |
        Then I should have the following bananas of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 3             | farmer        | 5/6/2018      | 15/6/2018     |

    Scenario 4: HAGL cannot add bananas that Grab owns
        When I use the identity HAGL
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | deliverier    | 5/6/2018      | 15/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 5: Grab cannot add bananas that he owns
        When I use the identity Grab
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | deliverier    | 5/6/2018      | 15/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 6: Grab cannot add bananas that HAGL owns
        When I use the identity Grab
        And I add the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 4             | farmer        | 5/6/2018      | 15/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 7: HAGL can update his bananas
        When I use the identity HAGL
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 1/6/2018      | 15/6/2018     |
        Then I should have the following bananas of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | farmer        | 1/6/2018      | 15/6/2018     |

    Scenario 8: HAGL can submit a transaction for his bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | deliverier    |
        Then I should have the following bananas of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverie     | 1/6/2018      | 15/6/2018     |
        And I should have received the following event of type org.banana.network.ChangeOwnerEvent
            | banana        | oldOwner      | newOwner      |
            | 1             | farmer        | deliverier    |

    Scenario 9: HAGL cannot submit a transaction for Grab's bananas
        When I use the identity HAGL
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | supermarket   |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 10: Grab can submit a transaction for his bananas
        When I use the identity Grab
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 1             | supermarket   |
        Then I should have the following bananas of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | supermarket   | 1/6/2018      | 15/6/2018     |
        And I should have received the following event of type org.banana.network.ChangeOwnerEvent
            | banana        | oldOwner      | newOwner      |
            | 1             | deliverier    | supermarket    |

    Scenario 11: Grab cannot submit a transaction for HAGL's bananas
        When I use the identity Grab
        And I submit the following transaction of type org.banana.network.ChangeOwnerTransaction
            | banana        | newOwner      |
            | 2             | supermarket   |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 12: HAGL cannot update Grab's bananas
        When I use the identity HAGL
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverier    | 1/6/2018      | 20/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 13: Grab cannot update his bananas
        When I use the identity Grab
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 1             | deliverier    | 1/6/2018      | 20/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 14: Grab cannot update HAGL's bananas
        When I use the identity Grab
        And I update the following asset of type org.banana.network.Banana
            | bananaId      | owner         | createdAt     | expiredAt     |
            | 2             | farmer        | 1/6/2018      | 20/6/2018     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 15: HAGL can remove his bananas
        When I use the identity HAGL
        And I remove the following asset of type org.banana.network.Banana
            | bananaId      |
            | 2             |
        Then I should not have the following bananas of type org.banana.network.Banana
            | bananaId      |
            | 2             |

    Scenario 16: HAGL cannot remove Grab's bananas
        When I use the identity HAGL
        And I remove the following asset of type org.banana.network.Banana
            | bananaId |
            | 1       |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 17: Grab cannot remove his bananas
        When I use the identity Grab
        And I remove the following asset of type org.banana.network.Banana
            | bananaId |
            | 1       |
        Then I should not have the following bananas of type org.banana.network.Banana
            | bananaId |
            | 1       |

    Scenario 18: Grab cannot remove HAGL's bananas
        When I use the identity Grab
        And I remove the following asset of type org.banana.network.Banana
            | bananaId |
            | 2       |
        Then I should get an error matching /does not have .* access to resource/

    Scenario 19: BigC can read all of the bananas
    Scenario 20: BigC cannot add his bananas
    Scenario 21: BigC cannot add HAGL's bananas
    Scenario 22: BigC cannot add Grab's bananas
    Scenario 23: BigC cannot update his bananas
    Scenario 24: BigC cannot update HAGL's bananas
    Scenario 25: BigC cannot update Grab's bananas
    Scenario 26: BigC can remove his bananas
    Scenario 27: BigC cannot remove HAGL's bananas
    Scenario 28: BigC cannot remove Grab's bananas
    Scenario 29: BigC cannot submit a transaction for HAGL's bananas
    Scenario 30: BigC cannot submit a transaction for Grab's bananas
