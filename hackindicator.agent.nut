/******************** Library Code ********************/
API_KEY         <- "";
API_SECRET      <- "";
AUTH_TOKEN      <- "";
TOKEN_SECRET    <- "";

class Twitter {
    // OAuth
    _consumerKey = null;
    _consumerSecret = null;
    _accessToken = null;
    _accessSecret = null;
    
    // URLs
    tweetUrl = "https://api.twitter.com/1.1/statuses/update.json";

    constructor (consumerKey, consumerSecret, accessToken, accessSecret) {
        this._consumerKey = consumerKey;
        this._consumerSecret = consumerSecret;
        this._accessToken = accessToken;
        this._accessSecret = accessSecret;
    }

    /***************************************************************************
     * function: Tweet
     *   Posts a tweet to the user's timeline
     * 
     * Params:
     *   status - the tweet
     *   cb - an optional callback
     * 
     * Return:
     *   bool indicating whether the tweet was successful(if no cb was supplied)
     *   nothing(if a callback was supplied)
     **************************************************************************/
    function tweet(status, cb = null) {
        local headers = { };
        
        local request = _oAuth1Request(tweetUrl, headers, { "status": status} );
        if (cb == null) {
            local response = request.sendsync();
            if (response && response.statuscode != 200) {
                server.log(format("Error updating_status tweet. HTTP Status Code %i:\r\n%s", response.statuscode, response.body));
                return false;
            } else {
                return true;
            }
        } else {
            request.sendasync(cb);
        }
    }

    /***** Private Function - Do Not Call *****/
    function _encode(str) {
        return http.urlencode({ s = str }).slice(2);
    }

    function _oAuth1Request(postUrl, headers, data) {
        local time = time();
        local nonce = time;
 
        local parm_string = http.urlencode({ oauth_consumer_key = _consumerKey });
        parm_string += "&" + http.urlencode({ oauth_nonce = nonce });
        parm_string += "&" + http.urlencode({ oauth_signature_method = "HMAC-SHA1" });
        parm_string += "&" + http.urlencode({ oauth_timestamp = time });
        parm_string += "&" + http.urlencode({ oauth_token = _accessToken });
        parm_string += "&" + http.urlencode({ oauth_version = "1.0" });
        parm_string += "&" + http.urlencode(data);
        
        local signature_string = "POST&" + _encode(postUrl) + "&" + _encode(parm_string);
        
        local key = format("%s&%s", _encode(_consumerSecret), _encode(_accessSecret));
        local sha1 = _encode(http.base64encode(http.hash.hmacsha1(signature_string, key)));
        
        local auth_header = "oauth_consumer_key=\""+_consumerKey+"\", ";
        auth_header += "oauth_nonce=\""+nonce+"\", ";
        auth_header += "oauth_signature=\""+sha1+"\", ";
        auth_header += "oauth_signature_method=\""+"HMAC-SHA1"+"\", ";
        auth_header += "oauth_timestamp=\""+time+"\", ";
        auth_header += "oauth_token=\""+_accessToken+"\", ";
        auth_header += "oauth_version=\"1.0\"";
        
        local headers = { 
            "Authorization": "OAuth " + auth_header
        };
        
        local url = postUrl + "?" + http.urlencode(data);
        local request = http.post(url, headers, "");
        return request;
    }
}

/******************** Application Code ********************/
twitter <- Twitter(API_KEY, API_SECRET, AUTH_TOKEN, TOKEN_SECRET);

isHacking <- null;
message <- "";

device.on("hacking", function(data) {
    isHacking = data.state;
    message = format("%s (as of %i) - via an @electricimp agent", (data.state == 0) ? "NOT HACKING" : "HACKING", time())
    if (!data.boot) {
        twitter.tweet(message);
    }
});


const HTML = @"<html>
    <head>
        <title>Hackaday Hacking Indicator</title>
    </head>
    <body>
        <div style='font-size:72px'>%s</div>
    </body>
</html>
";


http.onrequest(function(req, resp) {
    resp.send(200, format(HTML, message));
});

