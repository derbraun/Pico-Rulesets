ruleset io.picolabs.twilio {
	meta {
		configure using account_sid = "AC11b00c7da2d7cf1acf8a9a8f80e6e2b0"
				auth_token = "c308708a1fd054d9971cfa9d48e670df"
		provides
			send_sms
		}

	global{
		send_sms = defaction(to,from,message) {
			base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}>>
			http:post(base_url + "Messages.json", form{
				"From":from,
				"To":to,
				"Body":message
			})
		}
	}
}
