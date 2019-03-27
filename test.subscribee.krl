ruleset test.subscribee {
  meta {
    use module io.picolabs.subscription alias Subscriptions
    
    shares __testing, status
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "status"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ {"domain": "subscriber", "type": "trouble"},
        {"domain": "subscribee", "type": "update"}
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    status = function(){
      ent:status.defaultsTo("inactive") + " level " + ent:serial.defaultsTo(0)
    }
  }
  
  //Accept all subscriber requests
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
  
  
  //Recieved a hat lifted event from subscriber
  rule subscriber_hat_lifted{
    select when subscriber hat_is_lifted
    
    fired{
      ent:status := "active";
      ent:serial := ent:serial.defaultsTo(0) + 1
      
    }
  }
  
  //setting to inactive state
  rule subscriber_gets_in_trouble{
    select when subscriber trouble
    
    fired{
      ent:status := "inactive"
    }
  }
  
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
}

