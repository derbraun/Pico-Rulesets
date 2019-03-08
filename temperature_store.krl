ruleset temperature_store {
  meta {
    shares __testing, temperatures, threshold_violations, inrange_temperatures
    
    provides temperatures, threshold_violations, inrange_temperatures
    
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ { "domain": "wovyn", "type": "new_temperature_reading", "attrs": ["temperature", "timestamp"] },
        { "domain": "wovyn", "type": "threshold_violation", "attrs": ["temperature", "timestamp"] },
        { "domain": "sensor", "type": "reading_reset" },
        { "domain": "inrange", "type": "test"}
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    init_temp = [ { "temperature": "0", "timestamp": "N/A" } ]
    
    temperatures = function(){
      ent:temp
    }
    
    threshold_violations = function(){
      ent:violations
    }
    
    inrange_temperatures = function(){
      temps = temperatures().klog("calling temperature function:");
      threshold = threshold_violations().klog("calling threshold function:");
     
      
      temps.difference(threshold).klog("inrange array: ");
    }
  }
  
  //-----------------------------------------------------------------------------------------------------
  
  rule collect_temperatures{
    select when wovyn new_temperature_reading
    pre{
      temperature = event:attr("temperature").defaultsTo("0")
      timestamp = event:attr("timestamp").defaultsTo("N/A")
      //id = event:attr("id").defaultsTo("_0")
      
    }
    
    send_directive("store_temp",{"Temperature is":temperature, "Timestamp is": timestamp})
    
    fired{
      
      ent:temp := ent:temp.defaultsTo(init_temp, "initialization was needed");
      ent:temp := ent:temp.append({"temperature":temperature , "timestamp": timestamp})
    }
  }
  
  //-------------------------------------------------------------------------------------------------------
  
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
    
    
  rule clear_temperatures{
    select when sensor reading_reset
    
    always{
      clear ent:temp;
      clear ent:violations;
    }
  }
  
  
  rule inrange_test{
    select when inrange test
    
    pre{
      inrange = inrange_temperatures()
      
    }
    
    send_directive("inrange was called. See Klog!")
  }
  
}

