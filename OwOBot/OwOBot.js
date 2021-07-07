var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var opus = require('opusscript');
var sleep = require('system-sleep');
const fs = require('fs');
const { exec } = require('child_process');

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
  //voiceC = client.channels.find('name', 'General');
});
bot.on("message",msg => {	
    if(msg.content.includes("OwO, what's this?")){ //trigger
        var msgSplit = msg.content.split("?"); //[0] = trigger [1] = query
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
                }
            })
            .catch(function(error){console.log(error);});
    }
});