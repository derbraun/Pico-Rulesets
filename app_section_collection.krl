ruleset app_section_collection {
  meta {
    shares __testing, sections, showChildren
    use module io.picolabs.wrangler alias wrangler
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
        { "name": "sections"},
        { "name": "showChildren"}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ 
          {"domain": "section", "type": "needed", "attrs": [ "section_id"]},
          {"domain": "collection", "type": "empty", "attrs": []},
          {"domain": "section", "type": "offline", "attrs": ["section_id"]}
        //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    nameFromID = function(section_id){
      "Section " + section_id + " Pico"
    }
    
    showChildren = function(){
      wrangler:children()
    }
    
    sections = function(){
      ent:sections
    }
    
  }
  
  rule section_already_exists {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
    if exists then
      send_directive("section_ready", {"section_id": section_id})
  }
  
  rule section_needed{
    select when section needed
    
    
    /* -----------------------------------------------------
                      Array of Children
    --------------------------------------------------------                  
    pre{
      section_id = event:attr("section_id")
      //checks to see if section_id is already in ent:sections and stores the result into exists
      exists = ent:sections >< section_id
      eci = meta:eci
    }
    
    if exists then
      send_directive("section_ready", {"section_id":section_id})
    
    notfired {
      
      //Unions section_id with ent:sections - adding section_id to ent:sections. This new version of ent:sections is then stored in ent:section
      ent:sections := ent:sections.defaultsTo([]).union([section_id]);
      
      //This is where we create the child pico
      raise wrangler event "child_creation"
        attributes{
          "name": nameFromID(section_id), "color": "#ffff00"
        }
    }
    ------------------------------------------------------*/
    //          Collection of Children
    //------------------------------------------------------
      
    pre{
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
      
    if not exists then
      noop()
    
    fired{
      raise wrangler event "child_creation"
      attributes{
        "name": nameFromID(section_id),
        "color": "#ffff00",
        "section_id": section_id,
        
        // sends the rule id for app_section during pico creation
        "rids": "app_section"
      }
      
    } 
  }


  rule collection_empty {
    select when collection empty
    always{
      ent:sections := {}
    }
  }
  
  
  rule store_new_section {
    select when wrangler child_initialized
    pre{
      the_section = {"id": event:attr("id"), "eci": event:attr("eci")}
      section_id = event:attr("rs_attrs"){"section_id"}
    }
    
    if section_id.klog("found section_id") then
      noop()
    
    
    //Sends a request to wrangler to install app_section onto the child pico 
      // event:send(
      //   {
      //     "eci": the_section{"eci"}, "eid": "install-ruleset",
      //     "domain": "wrangler", "type": "install_rulesets_requested",
      //     "attrs": { "rids": "app_section" }
      //   })
      
    fired{
      ent:sections := ent:sections.defaultsTo({});
      ent:sections{[section_id]} := the_section
    }
    
  }
    
  rule section_offline{
    select when section offline
    pre{
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      child_to_delete = nameFromID(section_id)
    }
    
    if exists then
      send_directive("deleteing_section", {"section_id":section_id})
      
    fired{
      raise wrangler event "child_deletion"
        attributes{
          "name": child_to_delete
        };
      clear ent:sections{[section_id]}
    }
      
  }
  
}

