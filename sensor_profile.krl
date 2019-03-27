ruleset sensor_profile {
  meta {
    
    use module io.picolabs.twiliokeys
    use module io.picolabs.twilio alias twilio
    with account_sid = keys:twilio{"account_sid"}
             auth_token = keys:twilio{"auth_token"}
    
    shares __testing, get_profile, get_sms_number
    provides get_profile
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "get_profile"},
        { "name": "get_sms_number"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    sms_sender = "+14352225537"
    
    default_location = {
      "description":"Timbuktu",
      "imageURL":"http://www.wovyn.com/assets/img/wovyn-logo-small.png",
      "latitude":"16.77078",
      "longitude":"-3.00819"
    };
    
    get_profile = function(){
      profile = {}
        .put("location", ent:sensor_location)
        .put("name", ent:sensor_name)
        .put("sms_number", ent:sms_number);
        
      profile
    };
    
    get_sms_number = function(){
      ent:sms_number
    }

  }
  
  //---------------------------------------------------------------------------------
  
  rule profile_update{
    select when sensor profile_updated
    pre{
      
      location = event:attrs{"location"}.defaultsTo(default_location).klog("location: ")
      name = event:attrs{"name"}.defaultsTo("Wovyn_2BD537").klog("Name:")
      phone_number = event:attrs{"phone_number"}.defaultsTo("+18018850341").klog("sms number:")
      
    }
    
    always{
      ent:sensor_location := location.klog("ent:sensor_location:");
      ent:sensor_name := name.klog("ent:sensor_name");
      ent:sms_number := phone_number.klog("ent:sms_number");
      
      raise profile event "update"
      attributes{
        "threshold":event:attrs{"threshold"}.defaultsTo(75)
        //"sms_number": event:attrs{"phone_number"}.defaultsTo("+18018850341")
      }
    }
  }
  
  //-------------------------------------------------------------------------------
  
    rule threshold_notification{
    select when wovyn threshold_violation
    
    pre{
      message = <<WARNING, at: #{event:attrs{"timestamp"}} the temperature was #{ event:attrs{"temperature"}} which is above the temperature threshold set at: #{event:attrs{"threshold"}}>>
      sms = ent:sms_number.klog("sms Number: ")
      sms_s = sms_sender.klog("sms sender: ")
    }
    
    twilio:send_sms(ent:sms_number, sms_sender, message)
    //send_directive("error", {"error": message})
    }      
}

