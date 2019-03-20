ruleset sensor {
  meta {
    shares __testing
    use module sensor_profile
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
  }
  
  rule pico_ruleset_added {
    select when wrangler ruleset_added where rids>< meta:rid
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
  
  
}

