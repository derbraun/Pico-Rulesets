ruleset sensor_profile {
  meta {
    
    use module io.picolabs.twiliokeys
    use module io.picolabs.twilio alias twilio
    with account_sid = keys:twilio{"account_sid"}
             auth_token = keys:twilio{"auth_token"}
    
    shares __testing, get_profile, get_sms_number, get_threshold, threshold_violations, profile_reset
    provides get_profile
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "get_profile"},
        { "name": "get_sms_number"},
        { "name": "get_threshold"},
        { "name": "threshold_violations"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [   { "domain": "profile", "type": "reset"}
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    init_temp = [ { "temperature": "", "timestamp": "" } ]
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
        .put("sms_number", ent:sms_number)
        .put("threshold", ent:threshold);
        
      profile
    };
    
    threshold_violations = function(){
      ent:violations.defaultsTo([])
    }
    
    get_threshold = function(){
      ent:threshold
    }
    
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
      temperature = event:attrs{"threshold"}.defaultsTo(75).klog("threshold from request:")
      
    }
    
    always{
      ent:sensor_location := location.klog("ent:sensor_location:");
      ent:sensor_name := name.klog("ent:sensor_name");
      ent:sms_number := phone_number.klog("ent:sms_number");
      ent:threshold := temperature.klog("temperature_threshold:")
      
    }
  }
  
  //----------------------------------------------------------------------------------------
    
  rule find_high_temps{
    select when wovyn new_temperature_reading
    
    pre{
      temp = event:attrs{"temperature"}.klog("passed temperature: ")
      tempDiff = ent:threshold - temp
      tempDiff = tempDiff.klog("tempDiff:")
    }
    
    if tempDiff >= 0 then
      noop()
    
    notfired{
      raise wovyn event "threshold_violation"
      attributes {
          "temperature": event:attrs{"temperature"},
          "timestamp": event:attrs{"timestamp"}
        }
    }
    
  }
  
  //------------------------------------------------------------------------------
  rule collect_threshold_violations{
    select when wovyn threshold_violation
     
     pre{
      violation = event:attr("temperature").defaultsTo("0")
      timestamp = event:attr("timestamp").defaultsTo("N/A")
      //id = event:attr("id").defaultsTo("_0")
      
    }
    
    send_directive("store_temp",{"Violation":violation, "Timestamp is": timestamp})
    
    fired{
      ent:violations := ent:violations.defaultsTo(init_temp, "initialization was needed");
      ent:violations := ent:violations.append({"temperature": violation , "timestamp": timestamp})
    }
    
  }
  
  //-------------------------------------------------------------------------------
  
    rule threshold_notification{
    select when wovyn threshold_violation
    
    pre{
      message = <<WARNING, at: #{event:attrs{"timestamp"}} the temperature was #{ event:attrs{"temperature"}} which is above the temperature threshold set at: #{ent:threshold}>>
      sms = ent:sms_number.klog("sms Number: ")
      sms_s = sms_sender.klog("sms sender: ")
    }
    
    twilio:send_sms(ent:sms_number, sms_sender, message)
    //send_directive("error", {"error": message})
    }    
    
// --------------------------------------------------------------------------------
  rule reset_profile{
    select when profile reset
    
    always{
      clear ent:violations;
      ent:sensor_location := default_location;
      ent:sensor_name := "Wovyn_2BD537";
      ent:sms_number := "+18018850341";
      ent:threshold := 75
    }
      
  }

}

