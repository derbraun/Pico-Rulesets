ruleset io.picolabs.twilio {
  meta {
    shares __testing
    
    use module io.picolabs.twiliokeys
    use module io.picolabs.twilio alias twilio
      with account_sid = keys:twilio{"account_sid"}
           auth_token = keys:twilio{"auth_token"}

   }
  }
