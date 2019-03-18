ruleset sensor_profile {
  meta {
    use module wovyn_base
    
    shares __testing, get_profile
    provides get_profile
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    default_location = {
      "description":"Timbuktu",
      "imageURL":"http://www.wovyn.com/assets/img/wovyn-logo-small.png",
      "latitude":"16.77078",
      "longitude":"-3.00819"
    };
    
    get_profile = function(){
      profile = {}
        .put("location", ent:sensor_location)
        .put("name", ent:sensor_name);
        
      profile
    }

  }
  
  
  
  rule profile_update{
    select when sensor profile_updated
    pre{
      
      location = event:attrs{"location"}.defaultsTo(default_location).klog("location: ")
      name = event:attrs{"name"}.defaultsTo("Wovyn_2BD537").klog("Name:")
    }
    
    
    always{
      ent:sensor_location := location.klog("ent:sensor_location:");
      ent:sensor_name := name.klog("ent:sensor_name");
      
      raise profile event "update"
      attributes{
        "threshold":event:attrs{"threshold"}.defaultsTo(75),
        "sms_number": event:attrs{"phone_number"}.defaultsTo("+18018850341")
      }
    }
  }
}

