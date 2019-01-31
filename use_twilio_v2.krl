
ruleset io.picolabs.use_twilio_v2 {
  meta {
    key twilio {
          "account_sid": "<your SID goes here>", 
          "auth_token" : "<your auth token goes here>"
    }
    use module io.picolabs.twilio alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
  shares __testing
     
  }
 
  global {
	  __testing = {
		"queries": [
			  {"name":"__testing"}],
		"events":[
			{"domain":"test","type": "new_message",
			"attrs": ["to"], "attrs": ["from"], "attrs": ["message"]}]

	} 

  rule test_send_sms {
    select when test new_message
    twilio:send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }
}
