var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var opus = require('opusscript');
var sleep = require('system-sleep');
var axios = require("axios").default;
const fetch = require("node-fetch");

//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";
//Robot time
var bot = new Discord.Client();
var client = new Discord.Client();
var counter = 0;
var isReady = true;

//wikipedia api
var url = "https://en.wikipedia.org/w/api.php";

bot.on("ready",() => {
  logger.info("Connected");
});
bot.on("message",msg => {	
    if(msg.content.includes("OwO, what's this?") || msg.content.includes("Θωθ, what's this?")){ //trigger
	console.log("OwO Triggered");
    var msgSplit = msg.content.split("? ", 2); //[0] = trigger [1] = query
	//const messages = msg.channel.messages.fetch({ limit: 2 });
	//const lastMessage = messages.last();
	if(msgSplit[1] == "" || msgSplit[1] == " "){
		exit(1);
	}
	//msgSplit.split(/" "/(.+));
	console.log("request is: ");
	console.log(msgSplit[1]);
        var params = { //sent to api
            action: "query",
            list: "search",
            srsearch: msgSplit[1],
            format: "json"
        };
        url = url + "?origin=*";
        Object.keys(params).forEach(function(key){url += "&" + key + "=" + params[key];});

        fetch(url)
            .then(function(response){return response.json();})
            .then(function(response) {
                if (response.query.search[0].title === msgSplit[1]){ //if there is a page match
                    console.log("Your search page exists on English Wikipedia" );
		            msg.channel.send("Yes, I know of this topic, here:");
		            msg.channel.send("https://wikipedia.org/wiki/"+response.query.search[0].title.replace(" ","_"));
                }
                else {
                    console.log("Your search page DOES NOT exists on English Wikipedia" );
                    var UrbanData = UrbanDicSearch(msgSplit[1]);
                    msg.channel.send("Hmmmm, Θωθ does not know of this.");
                }
            })
            .catch(function(error){console.log(error);});
    }
});

function UrbanDicSearch(searchTerm){
    var options = {
        method: 'GET',
        url: 'https://mashape-community-urban-dictionary.p.rapidapi.com/define',
        params: {term: 'wat'},
        headers: {'x-rapidapi-host': 'mashape-community-urban-dictionary.p.rapidapi.com'}
      };
      
      axios.request(options).then(function (response) {
          console.log(response.data);
          return response.data;
      }).catch(function (error) {
          console.error(error);
          return null;
      });
}

bot.login(auth.token)