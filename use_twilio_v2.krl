
ruleset io.picolabs.use_twilio_v2 {
  meta {
	
	use module io.picolabs.twilokeys
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
			"attrs": ["to","from","message"]},
		
			{"domain":"test","type":"get_message",
			"attrs":["msg_id"]}
		]}
		
	messages = function(msg_id, send_num, recv_num){

		if msg_id then
			twilio:get_sms(event:attr("msg_id"))
	
		else{
			twilio:get_sms_list(event:attr("send_num"),
					    event:attr("recv_num"))
		}
	}
	

  rule test_send_sms {
    select when test new_message
    twilio:send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }

}
