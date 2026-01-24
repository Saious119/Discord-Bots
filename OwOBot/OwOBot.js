//global.fetch = require("node-fetch");
var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var opus = require("opusscript");
var sleep = require("system-sleep");
var axios = require("axios").default;
const fetch = require("node-fetch");

const { Client, Intents } = require("discord.js");
const client = new Client({
  intents: [Intents.FLAGS.GUILDS, Intents.FLAGS.GUILD_MESSAGES],
});

//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console(), {
  colorize: true,
});
logger.level = "debug";
//Robot time
var bot = client;
//var client = new Discord.Client();
var counter = 0;
var isReady = true;

//wikipedia api
var url = "https://en.wikipedia.org/w/api.php";

bot.on("ready", () => {
  logger.info("Connected");
});
bot.on("message", async (msg) => {
  if (
    msg.content.includes("OwO, what's this?") ||
    msg.content.includes("Θωθ, what's this?")
  ) {
    //trigger
    console.log("OwO Triggered");
    var found = false;
    var msgSplit = msg.content.split("? ", 2); //[0] = trigger [1] = query
    //const messages = msg.channel.messages.fetch({ limit: 2 });
    //const lastMessage = messages.last();
    if (msgSplit[1] == "" || msgSplit[1] == " ") {
      exit(1);
    }
    console.log("request is: " + msgSplit[1]);
    var WikiData = await WikiSearch(msgSplit[1]);
    if (WikiData != null) {
      msg.channel.send("Yes, I know of this topic, here:");
      msg.channel.send(WikiData);
      found = true;
    }
    if (found == false) {
      console.log("Your search page DOES NOT exists on English Wikipedia");
      msg.channel.send("Hmmmm, Θωθ does not know of this.");
    }
  }
});

async function WikiSearch(searchTerm) {
  var returnString = null;
  var params = {
    //sent to api
    action: "query",
    list: "search",
    srsearch: searchTerm,
    format: "json",
  };
  url = url + "?origin=*";
  Object.keys(params).forEach(function (key) {
    url += "&" + key + "=" + params[key];
  });

  const response = await fetch(url)
    .then(function (response) {
      return response.json();
    })
    .then(function (response) {
      if (response.query.search[0].title === searchTerm) {
        //if there is a page match
        console.log("Your search page exists on English Wikipedia");
        //msg.channel.send("Yes, I know of this topic, here:");
        returnString =
          "https://wikipedia.org/wiki/" +
          response.query.search[0].title.replaceAll(" ", "_");
      } else {
        console.log("Your search page DOES NOT exists on English Wikipedia");
      }
    })
    .catch(function (error) {
      console.log(error);
    });
  return returnString;
}

bot.login(auth.token);
