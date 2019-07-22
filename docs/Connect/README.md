# ICONex Connect for iOS
ICONex Connect is a simple protocol for supporting 3rd party applications who want send transactions, ICX or IRC tokens via ICONex wallet.

## Features
* Get address of ICON wallet which managed by ICONex.
* Request send transaction.

## Basic Transmission Protocol
* Request

```iconex://[Command]?data=[Base64-encoded JSON object]```

```Swift
let call = CallTransaction()
    .from(wallet.address)
    .to(scoreAddress)
    .stepLimit(BigUInt(1000000))
    .nid(self.iconService.nid)
    .nonce("0x1")
    .method("transfer")
    .params(["_to": to, "_value": "0x1234"])

guard let txData = try? call.toDic() else { return }

var json = ["jsonrpc": "2.0", "method": "icx_sendTransaction", "id": 1234] as [String: Any]
json["params"] = txData

var params = ["redirect": "your-app-scheme://"] as [String: Any]

params["payload"] = json

guard let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) else { return }

let encoded = data.base64EncodedString()
let items = [URLQueryItem(name: "data", value: encoded)]

var component = URLComponents(string: "iconex://")!
component.host = "JSON-RPC"
component.queryItems = items

UIApplication.shared.open(component.url!, options: [:], completionHandler: nil)
```

* Response
`your-app-scheme://?data=Base64EncodedString`

## JSON-RPC object

Base64 encoded ICON JSON-RPC API

[https://github.com/icon-project/icon-rpc-server/blob/master/docs/icon-json-rpc-v3.md](https://github.com/icon-project/icon-rpc-server/blob/master/docs/icon-json-rpc-v3.md)

## Commands
| Action | Description |
| ------ | ----------- |
| bind | Request wallet address |
| JSON-RPC | Send transaction via ICONex Connect |

### Command: bind
* Return selected wallet's address.

#### Request
| Key | Value type | Description | Required |
| --- | --- | --- | --- |
| redirect | Redirect URL | Target URL to send a selected wallet address | Mendatory |

#### Response
| Key | Value type | Description | Required |
| --- | --- | --- | --- |
| code | Int | Result code | Mendatory |
| message | String | Simplified result message | Mendatory |
| result | String | Selected wallet address | Optional |

#### Result Code
| Code | Message | Description |
| ---- | ---- | ---- |
| -2000 | ICONex has no ICX wallet. | ICONex has no ICX wallet for support. |
| Etc. | Refer to Common Result Code | - |

#### Example

```Swift
//Request
{
    "redirect": "your-app-scheme://"
}

// Response - success
{
    "code": 0,
    "message": "Success"
    "result": "hx1234..."
}

//Response - fail
{
    "code": -1,
    "message": "Operation canceled by user."
}
```

### Command: JSON-RPC
* Request send transaction via ICONex.

#### Request
| Key | Value type | Description | Required |
| --- | --- | --- | --- |
| payload | JSON | Base64-encoded JSON-RPC object string | Mendatory | 
| redirect | Redirect URL | Target URL to send a transaction hash | Mendatory |

#### Response
| Key | Value type | Description | Required |
| --- | --- | --- | --- |
| code | Int | Result code | Mendatory |
| message | String | Implified result message | Mendatory |
| result | String | Received transaction hash after send a transaction | Optional |

#### Result Code
| Code | Message | Description |
| --- | --- | --- |
| -3000 | Not found wallet($walletAddress) | $walletAddress does not exist. |
| extra | Refer to Common Result Code |

#### Example
```Swift
// Request
{
    "payload": {base64 encoded JSON-RPC object String},
    "redirect": "your-app-scheme://"
}

// Success; Send transaation
{
    "code": 0,
    "message": "success",
    "result": "0xabcd1234..."
}

// Fail
{
    "code": -3000,
    "message": "Not found wallet (hx1234abcd...)"
}
```

## Common Result Code
| Code | Message | 
| --- | --- | 
| 0 | Success |
| -1 | Operation canceled by user. |
| -1000 | Command not found. | 
| -1001 | Invalid request. Could not find data. |
| -1002 | Invalid base64 encoded string. | 
| -1003 | Invalid Command |
| -1004 | Invalid JSON syntax. |
| -2000 | Have no wallet |
| -3000 | Not found wallet($walletAddress)
| -9999 | Unspecified error |