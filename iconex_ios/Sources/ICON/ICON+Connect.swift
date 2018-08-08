/*
 * Copyright 2018 ICON Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import Foundation
import Alamofire
import Alamofire_Synchronous
import BigInt

extension ICON {
    typealias ICONBalance = [String: BigUInt]
    
    
    func getExchangeList(list: String) -> [String: ExchangeInfo]? {
        let request = ICON.ExchangeRequest(list: list)
        
        let response = Alamofire.request(request).responseData()
        
        guard let value = response.value else { return nil }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ExchangeResponse.self, from: value)
            
            var exchangeDic = [String: ExchangeInfo]()
            
            for info in result.data {
                exchangeDic[info.tradeName] = info
            }
            
            return exchangeDic
        } catch {
            
        }
        
        return nil
    }
}

extension ICON.Wallet {
    func getBalance() -> BigUInt? {
        guard let address = self.address else { return nil }
        let request = ICON.BalanceRequest(id: getID(), address: address)
        
        let response = Alamofire.request(request).responseJSON()
        
        guard let json = response.value as? [String: Any], let value = json["result"] as? String else { return nil }
        
        return BigUInt(value, radix: 16)
    }
    
}


extension Array where Element: ICON.Wallet {
    func getAllBalances() {
        
    }
}
