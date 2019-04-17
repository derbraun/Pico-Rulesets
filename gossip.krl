ruleset gossip {
  meta {
    shares __testing, get_smart_tracker, get_log, get_latest_log
    use module io.picolabs.subscription alias Subscriptions
    use module io.picolabs.wrangler alias wrangler
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "get_smart_tracker"},
        { "name": "get_log"},
        { "name": "get_latest_log"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [   { "domain": "gossip", "type": "heartbeat", "attrs": ["interval", "amount"]},
          { "domain": "start", "type": "rumor"},
          { "domain": "test", "type": "clear"},
          { "domain": "logid", "type": "clear"},
          {"domain": "gossip", "type": "node", "attrs": ["name"]}
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    
    get_smart_tracker = function(){
      ent:smart_tracker
    }
    
    get_log = function(){
      ent:log
    }
    
    get_latest_log = function(){
      ent:log[ent:log.length() - 1]
    }
    
  }
  //-------------------------------------------------------------------------------------------------------------
  
  rule create_new_node{
    select when gossip node
    pre{
      name = event:attr("name").klog("Name:")
      
    }
    
    fired{
      
      raise wrangler event "child_creation"
        attributes{
          "name": name,
          "color": "#ff44ff",
          
          // sends the rule id for app_section during pico creation
          "rids": ["io.picolabs.logging","wovyn_base", "temperature_store", "sensor", "manage_sensors", "sensor_profile", "gossip"]  
        }
      }
    }
  
  //--------------------------------------------------------------------------------------------------
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
          "name": "node",
          "Rx_role": "controller",
          "Tx_role": "node",
          "channel_type": "subscription",
          "wellKnown_Tx": child,
          "log": ent:log,
          "smart_tracker": ent:smart_tracker
        }
      })
    
    
  }
  
  
  // --------------------------------------------------------------------------------------------------
    rule auto_accept{
    select when wrangler inbound_pending_subscription_added
    pre{
      attributes = event:attrs.klog("subscription:")
    }
    
    always{
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
  //---------------------------------------------------------------------------------------------------
  
  rule initialization {
    select when wrangler subscription_added
    
    pre{
      attrs = event:attrs.klog("attributes: ")
      sub_id = event:attr("Id").klog("subscription ID")
    }
    
    always{
      
      ent:smart_tracker := event:attr("smart_tracker").defaultsTo({});
     // ent:smart_tracker := ent:smart_tracker.put(sub_id, 0).klog("added subscription details");
      ent:log := event:attr("log").defaultsTo([]);
    }
  }
  
  //-------------------------------------------------------------------------------------------------
  
  rule test_initialization {
    select when test clear 
    

    pre{
      sub_id = subs{"Id"}.klog("subscription ID")
    }
    
    always{
      
      ent:smart_tracker := {};
    //  ent:smart_tracker := ent:smart_tracker.put(sub_id, 0).klog("added subscription details")
      ent:log := [];
    }
  }
  
  //--------------------------------------------------------------------------------------------------
   rule update_log {
    select when wovyn heartbeat
  
    pre{
      
    temperature = event:attrs{["genericThing", "data", "temperature"]}[0]{"temperatureF"}.klog("temperature: ")
    timestamp = time:strftime(time:now(), "%c").klog("timestamp:")
    sensor_id = meta:picoId
    
    }
  
    fired{
      app:log_id := app:log_id + 1 || 0;
      ent:log := ent:log.klog("Before Rumor Log");
      ent:log := ent:log.append({}.put("MessageID",app:log_id).put("SensorID", sensor_id).put("Temperature", temperature).put("Timestamp", timestamp));
      ent:log := ent:log.klog("After Rumor Log added");
    }
  
  }
  //---------------------------------------------------------------------------------------------------
  
  rule update{
    select when gossip update
    
    pre{
      seen_msg = event:attr("smart_tracker").klog("smart-tracker log sent from node for gossip")
      rumor = event:attr("gossip").klog("rumor Message").klog("recieved gossip message")
    }
    
    if ent:smart_tracker == seen_msg then
      noop()
      
    notfired{
      
      ent:log := ent:log.append(rumor);
      ent:smart_tracker := seen_msg
    }
  }
  
  
  //-----------------------------------------------------------------------------------------------------
  
  rule cron{
    select when gossip heartbeat
    pre{
      time = {}
      time = time.put(event:attr("interval"), event:attr("amount")).klog("entered time:")
      
    }
    
    always{
      schedule start event "rumor" at time:add(time:now(),time)
    }
  }
  
  //---------------------------------------------------------------------------------------------------------
  
  rule rumor{
    select when start rumor
    
    // sends a rumor
    pre{
      // select neighbor
      subscription_number = Subscriptions:established().length().klog("Number of Subscriptions:")
      neighbor_number = random:integer(subscription_number - 1).klog("Neighbor number: ")
      selected_sub = Subscriptions:established()[neighbor_number].klog("Selected Neighbor Subscription:")
      selected_sub_id = selected_sub{"Id"}.klog("Id for selected subscription: ")
      
      // Debug Values
      smart_tracker = ent:smart_tracker.klog("Current value of the local smart_tracker")
      keys = ent:smart_tracker{selected_sub_id}.klog ("selected sub's keys:")

    }
    
    if ent:smart_tracker{selected_sub_id} == null then
      noop()
      
   notfired{
      ent:smart_tracker{selected_sub_id} := ent:smart_tracker{selected_sub_id} + 1;
      raise gossip event "send"
        attributes{
          "subscription": selected_sub{"Tx"}
        }
      
   }
   
   else{
      ent:smart_tracker{selected_sub_id} := 0;
      raise gossip event "send"
         attributes{
          "subscription": selected_sub{"Tx"}
        }
   }
  }
  // ----------------------------------------------------------------------------------
  rule echo{
    select when gossip echo
    
     pre{
      // select neighbor
      subscription_number = Subscriptions:established().length().klog("Number of Subscriptions:")
      neighbor_number = random:integer(subscription_number - 1).klog("Neighbor number: ")
      selected_sub = Subscriptions:established()[neighbor_number].klog("Selected Neighbor Subscription:")
      selected_sub_id = selected_sub{"Id"}.klog("Id for selected subscription: ")
      
      // Debug Values
      smart_tracker = ent:smart_tracker.klog("Current value of the local smart_tracker")
      keys = ent:smart_tracker{selected_sub_id}.klog ("selected sub's keys:")

    }
    
  }
  
  //------------------------------------------------------------------------------------
  rule send_msg{
    select when gossip send
    
    
    //send gossip:update to subscription
      event:send({
        "eci": event:attrs{"subscription"}, "eid": "update",
        "domain": "gossip", "type": "update",
        "attrs": {
          "smart_tracker": ent:smart_tracker, 
          "gossip": get_latest_log()
        }
      })
  }
  
  
  //--------------------------------------------------------------------------------------
  
  rule clear_log_id{
    select when logid clear
    
    fired{
      app:log_id := 0
    }
  }
}

