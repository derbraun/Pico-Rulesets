ruleset wovyn_base {
  meta {
    use module io.picolabs.twiliokeys
    use module io.picolabs.twilio alias twilio
    with account_sid = keys:twilio{"account_sid"}
             auth_token = keys:twilio{"auth_token"}
    
    shares __testing, process_heartbeat, get_threshold, get_sms_number
    provides get_threshold, get_sms_number
    
  }
  
  /****************************************************************************************/
 
  global {
  
    sms_sender = "+14352225537"
    
    
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
       { "domain": "wovyn", "type": "heartbeat", "attrs": [ "info"] }
      ]
    }


    get_threshold = function(){
      ent:temperature_threshold
    };
    
    get_sms_number = function(){
      ent:sms_number
    };
    
  }
  
  /****************************************************************************************/
  
  rule process_heartbeat{
    select when wovyn heartbeat
    
    pre{
      
      heartbeats = event:attrs
      hb = heartbeats{"heartbeat"}
      generic = heartbeats{"genericThing"}
      
    }
    
    if generic then
    
      send_directive("info", {"info": "heartbeat recieved"})
      //send_directive("heartbeat", {"heartbeat": hb{"heartbeat"}});
      
   always{
     raise wovyn event "new_temperature_reading"
     attributes {
       "temperature":event:attrs{["genericThing", "data", "temperature"]}[0]{"temperatureF"}, "timestamp": time:now()
       
     }
     
   }
    
  }
  
  
  /****************************************************************************************/
 
  
  rule find_high_temps{
    select when wovyn new_temperature_reading
    
    pre{
      tempDiff = temperature_threshold <=> event:attrs{"temperature"}
      
    }
    
    // choose tempDiff {
    //   1 => send_directive("No threshold violation found")
    //   0 => send_directive("No threshold violation found")
    //   -1 => send_directive("Threshold violation found!")
    // }
    
    if tempDiff >= 0 then
      send_directive("No threshold violation found")
      
    notfired{
      
      raise wovyn event "threshold_violation"
      attributes{
        "temperature": event:attrs{"temperature"}, 
        "timestamp": event:attrs{"timestamp"},
        "threshold": ent:temperature_threshold
      }
    }
    
  }
  
  /****************************************************************************************/
 
  
  rule threshold_notification{
    select when wovyn threshold_violation
    
    pre{
      message = <<WARNING, at: #{event:attrs{"timestamp"}} the temperature was #{ event:attrs{"temperature"}} which is above the temperature threshold set at: #{event:attrs{"threshold"}}>>
      
    }
    
    twilio:send_sms(ent:sms_number, sms_sender, message)
    //send_directive("error", {"error": message})
            
  }
  
  rule settings_update{
    select when profile update
    
    always{
      ent:temperature_threshold := event:attrs{"threshold"}.defaultsTo(75).klog("Threshold:");
      ent:sms_number := event:attrs{"sms_number"}.defaultsTo("+18018850341").klog("SMS Number:")
    }
  }
  
}


