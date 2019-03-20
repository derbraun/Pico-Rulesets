ruleset app_section {
  meta {
    shares __testing, get_section_id

  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "get_section_id"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    get_section_id = function(){
      ent:section_id
    }
  }
  
  rule pico_ruleset_added{
    select when wrangler ruleset_added 
    
    pre {
      section_id = event:attr("section_id")
    }
    always {
      ent:section_id := section_id
    }
  }
}

