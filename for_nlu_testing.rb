book = Book.first

api_location = "https://gateway.watsonplatform.net/natural-language-understanding/api/v1/analyze?version=2017-02-27"
		
if book.scraped_content_url != nil
	read_location = "&url=" + book.scraped_content_url 
else
	read_location = "&url=" + book.url 
end

api_params = "&features=keywords,entities&entities.emotion=true&entities.sentiment=true&keywords.emotion=true&keywords.sentiment=true"

full_query = api_location + read_location + api_params

auth = {:user => ENV['NLU_USERNAME'], :password => ENV['NLU_PASSWORD']}
headers = { "Accept" => "application/json"}

query_results = Unirest.get(full_query,	
	auth: auth, 
	headers: headers
).body