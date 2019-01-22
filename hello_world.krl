ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    logging on
    shares hello, __testing
  }
  
  global {
    __testing = {
      "queries": [
        {"name": "__testing"},
        {"name": "hello", "args": ["obj"] } 
      ],
      
      "events": [
        {"domain":"echo", "type": "monkey",
          "attrs": ["name"] }
      ]
    }
    
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
  }
  
  rule hello_world {
    select when echo hello
    send_directive("say", {"something": "Hello World"})
  }
  
 
  //Creating a rule that defaults the name value to "monkey" 
  rule hello_monkey {
    select when echo monkey
    
    pre{
      
      text = event:attr("name").defaultsTo("monkey").klog("Passed in the name")
    }
    
    send_directive("say", {"something": "Hello " + text})

  }
  
  //Creating a rule that defaults the name value to "monkey" using conditionals
  rule hello_monkey2 {
    select when echo monkey2
    
    pre{
      
      text = event:attr("name") || "monkey"
 
      log = text.klog("Selected the name")
    }
    
    send_directive("say", {"something": "Hello " + text})

  }
  
  
}
