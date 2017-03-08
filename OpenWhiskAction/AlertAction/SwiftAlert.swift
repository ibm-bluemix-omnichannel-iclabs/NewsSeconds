/**
 *
 * main() will be invoked when you Run This Action.
 *
 * @param OpenWhisk actions accept a single parameter,
 *        which must be a JSON object.
 *
 * In this case, the params variable will look like:
 *     { "message": "xxxx" }
 *
 * @return which must be a JSON object.
 *         It will be the output of this action.
 *
 */

import KituraNet
import Foundation
import SwiftyJSON

func CallRest(_ messsage:String){
    
}
func main(args: [String:Any]) -> [String:Any] {
    
    
    //Add Your credentials
    let appSecret = "4ffbc235-290f-4f58-b3d4-2b26cfd5513c"
    let appID = "2913bfe5-a3fc-4401-93ba-0fada156dda0"
    let appRegion = ".ng.bluemix.net"
    
    let newsAPIKey = "377cb76b379e457e905a2728c3aabf63"
    
    
    var str = 0
    var values = 0
    
    var requestOptions: [ClientRequest.Options] = []
    requestOptions.append(.method("GET"))
    requestOptions.append(.schema("https://"))
    requestOptions.append(.hostname("imfpush\(appRegion)"))
    requestOptions.append(.path("/imfpush/v1/apps/\(appID)/tags"))
    requestOptions.append(.headers(["appSecret":appSecret]))
    
    
    let req = HTTP.request(requestOptions) { resp in
        if let resp = resp, resp.statusCode == HTTPStatusCode.OK {
            do {
                var body = Data()
                try resp.readAllData(into: &body)
                let response = JSON(data: body)
                str = response["tags"].count
                str = str - 1
                
                while(str>=0){
                    let tag =  response["tags"][str]["name"].string
                    
                    var url = "/v1/articles?source="+tag!+"&sortBy=top&apiKey=\(newsAPIKey)";
                    print(url)
                    var requestOptions1: [ClientRequest.Options] = []
                    requestOptions1.append(.method("GET"))
                    requestOptions1.append(.schema("https://"))
                    requestOptions1.append(.hostname("newsapi.org"))
                    requestOptions1.append(.path(url))
                    
                    print(tag)
                    str = str - 1;
                    
                    let req1 = HTTP.request(requestOptions1) { resp in
                        
                        if let resp = resp, resp.statusCode == HTTPStatusCode.OK {
                            
                            do {
                                
                                var body = Data()
                                try resp.readAllData(into: &body)
                                let response = JSON(data: body)
                                print(response["articles"][0]["title"].string)
                                values = values+1
                                let messages = response["articles"][0]["title"].string
                                let description = response["articles"][0]["description"].string
                                let newsURL = response["articles"][0]["url"].string
                                let dd = ["data":description!,"newsURL":newsURL!]
                                Whisk.invoke(actionNamed:"/whisk.system/pushnotifications/sendMessage",withParameters:["appSecret":appSecret,"appId":appID,"text":messages!,"apnsPayload":dd,"apnsType":"MIXED","tagNames":[tag!]])
                                
                            } catch{
                                print("Error parsing JSON from response")
                            }
                        }else {
                            if let resp = resp {
                                //request failed
                                print("Error ; status code \(resp.statusCode) returned")
                            } else {
                                print("Error ")
                            }
                        }
                    }
                    req1.end()
                }
                
            } catch {
                print("Error parsing JSON fromresponse")
            }
        } else {
            if let resp = resp {
                //request failed
                print("Error ; status code \(resp.statusCode) returned")
            } else {
                print("Error")
            }
        }
    }
    
    req.end()
    
    return [ "greeting" : values ]
}
