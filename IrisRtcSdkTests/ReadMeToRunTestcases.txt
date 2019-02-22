
To run the test cases, run the below xcodebuild cmd with the below arguments

xcodebuild test 
-workspace IrisRtcSdk.xcworkspace 
-scheme IrisRtcSdk 
-destination 'platform=iOS Simulator,name=iPhone XR,OS=12.1' 
IRISAUMURL=<auth manager url>
IRISIDMURL=<Identitiy manager url> 
IRISEVMURL=<event manager url> 
IRISNTMURL=<Notification manager url> 
IRISAPPKEY=<developer app key for the said domain> 
IRISAPPSECRET=<developer app secret for the said domain>
IRISUSERID=<emailid for login> 
IRISUSERPWD=<password for email login> 
IRISTONUM=<callee or dialed telephone number>    

