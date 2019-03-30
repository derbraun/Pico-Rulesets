ruleset manage_sensors {
  meta {
    shares __testing, sensors, get_children, get_all_temps, get_temp_report, get_latest_reports
    use module io.picolabs.wrangler alias wrangler
    use module temperature_store alias temp
    use module io.picolabs.subscription alias Subscriptions
  
    provides get_children, sensors, get_all_temps, get_temp_report
     
  }
  global {

    init_sensor = [ { "name": "Initialization", "eci": ""} ]
    
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "sensors"},
        { "name": "get_children"},
        { "name": "get_all_temps"},
        { "name": "get_temp_report"},
        { "name": "get_latest_reports"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ {"domain": "sensor", "type": "new_sensor", "attrs": ["name"]},
        {"domain": "sensor", "type": "unneeded_sensor", "attrs": ["name"]},
        {"domain": "sensor", "type": "subscribe", "attrs": ["eci"]},
        {"domain": "sensor", "type": "subscribe", "attrs": ["eci", "Tx_host"]},
        {"domain": "explicit", "type": "report"}
        
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    get_temp_report = function(){
      ent:temp_report.decode()
    }
    
    get_children = function(){
      wrangler:children()
    }
    
    sensors = function(){
      //ent:sensors
      Subscriptions:established()
      
    }
    
    
    get_all_temps = function(){
      
      //arr = ent:sensors.values().klog();
      
      arr = Subscriptions:established().klog("Subscriptions: ");
      
      arr.map(function(sub){
        
        eci = sub{["Tx"]}.klog("Eci for Sub:");
        http:get("http://localhost:8080/sky/cloud/" + eci +"/temperature_store/temperatures")
      }).klog();
    
      
    }
    
    get_latest_reports = function(){
      ent:ledger
      
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
      not_child = event:attr("Child").klog("is_child: ")
    }
    
    if not_child then
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
  
  // -------------------------------------------------
  
  rule request_report{
    select when explicit report
    
    foreach Subscriptions:established() setting (sensor, index)
    pre{
      rcn = index.klog("rcn: ")
      eci = sensor{"Tx"}.klog("eci for sensor: ")
    }
    
    if(not rcn.isnull()) then
      event:send({
        "eci": eci, "eid": "report",
        "domain": "temp", "type": "report",
        "attrs":{
            "rcn": rcn
          }
      })
      
    always{
      ent:number_reported := 0;
    }
    
  }
  
  //-------------------------------------------------------------------------------
  
  rule catch_temp_reports{
    select when temp_report created
    pre{
      rcn = event:attr("rcn").klog("returned rcn:")
      temp_report = event:attr("temperatures").klog("returned report:")
      
    }
    
    noop()
    
    always{
      ent:number_reported := ent:number_reported + 1;
      ent:temp_report := ent:temp_report.defaultsTo({});
      ent:temp_report := ent:temp_report.put(rcn,temp_report);
      
       raise temp_report event "report_added" 
      
    }
    
  }
  
  //--------------------------------------------------------------------------------
  
  rule check_report_status{
    select when temp_report report_added
  
    
    pre{
      total_sensors = Subscriptions:established().length().klog("Total Sensors:");
      
    }
    
    if total_sensors <= ent:number_reported then
      noop();
      
    fired{
        raise temp_report event "processed"
    }
    
  }
  
  //-----------------------------------------------------------------------

  rule add_temp_report{
    select when temp_report processed
    pre{
      report_record = {}
      report_record{["temperature_sensors"]} = Subscriptions:established().length().klog("temperature sensors")
      report_record{["responding"]} = ent:number_reported.klog("responding sensors")
      report_record{["temperatures"]} = ent:temp_report
      
      full_report = {}
      full_report{time:now()} = report_record.klog("report_record:")
    }
    
 
    always{
  
      ent:ledger := ent:ledger.defaultsTo([]);
      ent:ledger := ent:ledger.append(full_report);
      
      //clean up
      clear ent:number_reported;
      clear ent:temp_report;
    }
  }
  
  
}

