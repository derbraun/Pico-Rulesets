ruleset test.subscriber {
  meta {
    
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias Subscriptions
    shares __testing
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ { "domain": "subscriber", "type": "identity"},
        { "domain": "subscriber", "type": "hat_is_lifted"}
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
  }
  
  
  // Have the parent.owner identify me
  rule subscriber_identity{
    select when subscriber identity
    
    event:send({
      "eci": wrangler:parent_eci(), "eid": "subscriber_identity"
    })
  }
  
  // Someone lifted their hat and told subscriber about it
  // Subscriber then tells all it's subscribees that someone lifted their hat
  rule subscriber_hat_lifted{
    select when subscriber hat_is_lifted
    
    //Go through all the established subscriptions whose Tx_role is "test child"
    //the current subscription in the loop is named "subscription"
    foreach Subscriptions:established("Tx_role", "test child") setting (subscription)
    
    pre{
      test_subs = subscription.klog("subs")
    }
    
    event:send({
      "eci": subscription{"Tx"}, "eid": "hat-lifted",
      "domain": "subscriber", "type": "hat_is_lifted"
    })
  }
  
  //Responds to an update from subscribee
  rule subscribee_update{
    select when subscriber update
    
    send_directive("I got an update")
  }
}

