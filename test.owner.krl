ruleset test.owner {
  meta {
    
    use module io.picolabs.wrangler alias wrangler
    shares __testing
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ { "domain": "subscriber", "type": "subscriptions"},
        { "domain": "subscriber", "type": "who"}
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
  }
  
  rule subscriber_who{
    select when subscriber who
    pre{
      subscriber = event:attr("eci")
      subscribees = wrangler:children().map(function(v){
          v{"eci"}
      }).filter(function(v){v != subscriber})
    }
    
    always{
      ent:subscriber := subscriber;
      ent:subscribees := subscribees
    }
  }
  
  rule subscriber_subscriptions{
    select when subscriber subscriptions
    
    // For all the subscribees, where current subscribee is named "subscribee" 
    // and the index is named "index"
    foreach ent:subscribees setting(subscribee, index)
    
      //introduce subscriber to subscribees
      //"Hello, I want to subscribe to you"
      event:send({
        "eci": ent:subscriber, "eid": "subscription",
        "domain": "wrangler", "type":"subscription",
        "attrs": {
          "name": "Test Child "+ (index.as("Number") + 1),
          "Rx_role": "controller",
          "Tx_role": "test child",
          "channel_type": "subscription",
          "wellKnown_Tx": "test child"
        }
      })
    
  }
}

