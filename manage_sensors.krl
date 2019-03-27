ruleset manage_sensors {
  meta {
    shares __testing, sensors, get_children, get_threshold, get_all_temps
    use module io.picolabs.wrangler alias wrangler
    use module temperature_store alias temp
    use module io.picolabs.subscription alias Subscriptions
    
    provides get_children, sensors, get_threshold, get_all_temps
     
  }
  global {
    temperature_threshold = 78
    init_sensor = [ { "name": "Initialization", "eci": ""} ]
    
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "sensors"},
        { "name": "get_children"},
        { "name": "get_all_temps"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ {"domain": "sensor", "type": "new_sensor", "attrs": ["name"]},
        {"domain": "sensor", "type": "unneeded_sensor", "attrs": ["name"]},
        {"domain": "sensor", "type": "subscribe", "attrs": ["eci"]},
        {"domain": "sensor", "type": "subscribe", "attrs": ["eci", "Tx_host"]}
        
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    get_children = function(){
      wrangler:children()
    }
    
    sensors = function(){
      //ent:sensors
      Subscriptions:established()
      
    }
    
    get_threshold = function(){
      temperature_threshold
    }
    
    get_all_temps = function(){
      
      //arr = ent:sensors.values().klog();
      
      arr = Subscriptions:established().klog("Subscriptions: ");
      
      arr.map(function(sub){
        
        eci = sub{["Tx"]}.klog("Eci for Sub:");
        http:get("http://localhost:8080/sky/cloud/" + eci +"/temperature_store/temperatures")
      }).klog();
    
      
    }
  }
  
  //-------------------------------------------------------------
  
  rule sensor_already_exists {
    select when sensor new_sensor
    pre {
      name = event:attr("name")
      exists = ent:sensors >< name
    }
    if exists then
      send_directive("section_ready", "Name is already taken")
  }
  
  //-----------------------------------------------------
  
  rule create_new_sensor{
    select when sensor new_sensor
    pre{
      name = event:attr("name").klog("Name:")
      
    }
    
    fired{
      
    raise wrangler event "child_creation"
      attributes{
        "name": name,
        "color": "#ffff44",
        "threshold": temperature_threshold,

        // sends the rule id for app_section during pico creation
        "rids": ["io.picolabs.logging","wovyn_base", "temperature_store", "sensor"]  
      }
    }
  }
  
  //----------------------------------------------------------
  
  rule set_subscription{
    select when wrangler child_initialized
    
    pre{
      eci = wrangler:myself(){"eci"}
      child = event:attr("eci").klog("Child eci:")
    }
    
  
    event:send({
      "eci": eci, "eid": "subscription",
      "domain": "wrangler", "type":"subscription",
        "attrs": {
          "name": "sensor",
          "Rx_role": "controller",
          "Tx_role": "sensor",
          "channel_type": "subscription",
          "wellKnown_Tx": child
        }
      })
    
    
  }
  
  //----------------------------------------------------------
  rule store_new_sensor{
    select when wrangler child_initialized
    pre{
      eci =  event:attr("eci")
      name = event:attr("name")

      exists = ent:sensors >< name
    }
    
    
    if exists.klog("found name") then
      noop()
      // event:send(
      //   {
      //     "eci": eci, "eid": "install-ruleset",
      //     "domain": "wrangler", "type":"install_rulesets_requested",
      //     "attrs": { "rids": ["wovyn_base", "temperature_store","sensor_profile", "sensor"]}
      //   })
    
    notfired{
      
     ent:sensors := ent:sensors.defaultsTo({}, "This sensor is initialized").klog("initialized:");  
     ent:sensors{[name]} := eci

    }
    
  }
  
  //-----------------------------------------------------------------
  
  rule sensor_unneeded{
    select when sensor unneeded_sensor
    pre{
      name = event:attr("name")
      exists = ent:sensors >< name
      
    }
    
    if exists then
      send_directive("deleteing_section", {"name":name})
      
    fired{
      raise wrangler event "child_deletion"
        attributes{
          "name": name
        };
      clear ent:sensors{[name]}
    }
      
  }
  
  //------------------------------------------------------------------
  //Responds to an update from subscribee
  rule subscribee_update{
    select when subscriber update
    
    send_directive("I got an update")
  }
  
  //-------------------------------------------------------------------
  rule add_subscriber{
    select when sensor subscribe
    
    pre{
      eci = wrangler:myself(){"eci"}
      sub = event:attr("eci").klog("Subscriber eci:")
    }
    
  
    event:send({
      "eci": eci, "eid": "subscription",
      "domain": "wrangler", "type":"subscription",
        "attrs": {
          "name": "sensor",
          "Rx_role": "controller",
          "Tx_role": "sensor",
          "channel_type": "subscription",
          "wellKnown_Tx": sub
        }
      })
  }
  
  //------------------------------------------------------------------------
  
  rule add_subscriber_local{
        select when sensor subscribe
    
    pre{
      eci = wrangler:myself(){"eci"}
      sub = event:attr("eci").klog("Subscriber eci:")
      tx_host = event:attr("Tx_host").klog("tx_host:")
    }
    
  
    event:send({
      "eci": eci, "eid": "subscription",
      "domain": "wrangler", "type":"subscription",
        "attrs": {
          "Tx_host": tx_host,
          "name": "sensor",
          "Rx_role": "controller",
          "Tx_role": "sensor",
          "channel_type": "subscription",
          "wellKnown_Tx": sub
        }
      })
  }
  
  
}

