ruleset io.picolabs.use_twilio_v2 {
  meta {
    use module io.picolabs.twiliokeys
    use module io.picolabs.twilio alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
             
  shares __testing, messages
     
  }
 
  global {
	  __testing = {
		"queries": [
			  {"name":"__testing"}],
		"events":[
			{"domain":"test","type": "new_message",
			"attrs": ["to", "from", "message"]},
			{"domain":"test","type": "messages",
			  "attrs":["to","from", "pageSize"]
			}]
    }
    
    messages = function(url){
      http:get(url){"content"}.decode()
    }
  }

  rule test_send_sms {
    select when test new_message
    twilio:send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }
  
  rule get_sms_log {
    select when test messages
    pre{
      account_sid = keys:twilio{"account_sid"}
      auth_token = keys:twilio{"auth_token"}
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json>>
      to = event:attr("to") => "to=" + event:attr("to") | ""
      form = event:attr("from") => "from=" + event:attr("from") | ""
      page_size = event:attr("pageSize") => "PageSize=" + event:attr("pageSize") | ""
      query = (page_size && from && to) => "?" + page_size + "&" + from + "&" + to | ""
  
    }
    
    send_directive("message", {"message":messages(base_url+query)})
    always{
      log info query
    }
  }
 
}
