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
bot.on("message",async msg => {	
    if(msg.content.includes("OwO, what's this?") || msg.content.includes("Θωθ, what's this?")){ //trigger
	    console.log("OwO Triggered");
		var found = false;
        var msgSplit = msg.content.split("? ", 2); //[0] = trigger [1] = query
	    //const messages = msg.channel.messages.fetch({ limit: 2 });
	    //const lastMessage = messages.last();
	    if(msgSplit[1] == "" || msgSplit[1] == " "){
		    exit(1);
	    }
	    console.log("request is: "+msgSplit[1]);
        var WikiData = await WikiSearch(msgSplit[1]);
        if(WikiData != null){
            msg.channel.send("Yes, I know of this topic, here:");
            msg.channel.send(WikiData);
            found = true;
        }
        var UrbanData = await UrbanDicSearch(msgSplit[1]);
	    sleep(2000);
        if(UrbanData != null){
            msg.channel.send("Yes, I know of this topic, here:");
            msg.channel.send(UrbanData);
            found = true;
        }
		if(found == false){
        	console.log("Your search page DOES NOT exists on English Wikipedia or Urban Dictionary" );
        	msg.channel.send("Hmmmm, Θωθ does not know of this.");
		}
    }
});

async function WikiSearch(searchTerm){
    var returnString = null;
    var params = { //sent to api
        action: "query",
        list: "search",
        srsearch: searchTerm,
        format: "json"
    };
    url = url + "?origin=*";
    Object.keys(params).forEach(function(key){url += "&" + key + "=" + params[key];});

    const response = await fetch(url)
        .then(function(response){return response.json();})
        .then(function(response) {
            if (response.query.search[0].title === searchTerm){ //if there is a page match
                console.log("Your search page exists on English Wikipedia" );
                //msg.channel.send("Yes, I know of this topic, here:");
                returnString = "https://wikipedia.org/wiki/"+response.query.search[0].title.replace(" ","_");
            }
            else {
                console.log("Your search page DOES NOT exists on English Wikipedia" );
            }
        })
        .catch(function(error){console.log(error);});
    return returnString;
}

async function UrbanDicSearch(searchTerm){
    console.log("in func");
    var def = null; 
    const data = await ud.define(searchTerm).then((results) => {
        console.log("HERE");
	    console.log('define (promise)');

        Object.entries(results[0]).forEach(([key, prop]) => {
            console.log(`${key}: ${prop}`);
            if(key == "definition"){
	            console.log("prop = "+prop);
	            def = prop;
                console.log("def = "+def);
                if(def != null){
                    def.replace("[", "");
                    def.replace("]", "");
                    def = searchTerm+": "+def;
                }
                return def;
            }
        })
    }).catch((error) => {
        console.error(`define (promise) - error ${error.message}`)
    })
    console.log(data);
    console.log("def = "+def);
    if(def != null){
        def.replace("[", "");
        def.replace("]", "");
        def = searchTerm+": "+def;
    }
    return def;
}

bot.login(auth.token)
