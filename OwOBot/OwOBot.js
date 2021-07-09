var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var opus = require('opusscript');
var sleep = require('system-sleep');
var axios = require("axios").default;
const ud = require('urban-dictionary')
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
                    var UrbanData = UrbanDicSearchC(msgSplit[1]);
		    sleep(2000);
                    if(UrbanData != null){
                        var UrbanDef = UrbanData.definition;
                        msg.channel.send(msgSplit[1]+": "+UrbanDef);
                    }
                    else{
                        console.log("Your search page DOES NOT exists on English Wikipedia or Urban Dictionary" );
                        msg.channel.send("Hmmmm, Θωθ does not know of this.");
                    }
                }
            })
            .catch(function(error){console.log(error);});
    }
});

function UrbanDicSearchC(searchTerm){
    ud.define(searchTerm, (error, results) => {
        if (error) {
          console.error(`define (callback) error - ${error.message}`)
          return null;
        }
      
        console.log('define (callback)')
      
        Object.entries(results[0]).forEach(([key, prop]) => {
          console.log(`${key}: ${prop}`)
        })
        return results[0];
      })
    return null;
}

function UrbanDicSearchP(searchTerm){
    console.log(searchTerm);
    ud.define(searchTerm.toString()).then((results) => {
        console.log(searchTerm.toString());
	console.log('define (promise)')
      
        Object.entries(results[0]).forEach(([key, prop]) => {
            console.log(`${key}: ${prop}`)
        })
        return results[0];
    }).catch((error) => {
        console.error(`define (promise) - error ${error.message}`)
        return null;
    })
}

bot.login(auth.token)
