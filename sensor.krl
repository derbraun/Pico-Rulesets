ruleset sensor {
  meta {
    shares __testing
    use module sensor_profile
    use module io.picolabs.subscription alias Subscriptions

    
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }

      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ {"domain": "subscribee", "type": "update"}
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
  }
  
  rule pico_ruleset_added {
    select when wrangler ruleset_added where rids >< meta:rid
    pre{
      name = event:attr("name")
      threshold = event:attr("rs_attrs"){"threshold"}
    }
      
    always{
      ent:name := name.defaultsTo("");
      
      raise sensor event "profile_updated"
      attributes{
        "name": ent:name,
        "threshold": threshold,
        "phone_number": "+18018850341"
      }
    }
  }
  
  //------------------------------------------------------------------------------------------
  
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
  //----------------------------------------------------------------------------------------
  
  //Sending an update to subscriber
  rule subscribee_update{
    select when subscribee update
    
    foreach Subscriptions:established("Tx_role", "controller") setting (subscription)
    
    pre{
      test_subs = subscription.klog("subs update")
    }
    
    event:send({
      "eci": subscription{"Tx"}, "eid": "update",
      "domain": "subscriber", "type": "update"
    })
    
  }
  //----------------------------------------------------------------------------------------

}

