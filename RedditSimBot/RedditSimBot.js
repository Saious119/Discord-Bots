var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var mongo = require('mongodb');

const upVote = '⬆️';
const downVote = ':arrow_down:';

const { Client, GatewayIntentBits } = require('discord.js');
const { Console } = require("winston/lib/winston/transports");
const client = new Client({ 
    intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.GuildMessageReactions, GatewayIntentBits.GuildEmojisAndStickers],
    partials: [Discord.Partials.Message, Discord.Partials.Channel, Discord.Partials.Reaction],
});
//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";

var bot = client;

bot.on("ready",() => {
    logger.info("Connected");
});
bot.on(Discord.Events.MessageReactionAdd, async(reaction, user) => {
    // When a reaction is received, check if the structure is partial
	if (reaction.partial) {
		// If the message this reaction belongs to was removed, the fetching might result in an API error which should be handled
		try {
			await reaction.fetch();
		} catch (error) {
			console.error('Something went wrong when fetching the message:', error);
			// Return as `reaction.message.author` may be undefined/null
			return;
		}
	}

	// Now the message has been cached and is fully available
	console.log(`${reaction.message.author}(aka ${reaction.message.author.username})'s message "${reaction.message.content}" gained a reaction!`);
	// The reaction is now also fully available and the properties will be reflected accurately:
	console.log(`${reaction.count} user(s) have given the same reaction to this message!`);
    var upOrDown;
    if(reaction.emoji.name == '⬆️'){
        UpdateDB(reaction.message.author, 1);
    }
    else if(reaction.emoji.name == '⬇️'){
        UpdateDB(reaction.message.author, -1);
    }
});
bot.on("message", message => {
    const filter = (reaction, user) => {
        return ['⬆️', downVote].includes(reaction.emoji.name) && user.id === interaction.user.id;
    };
    
    message.awaitReactions({ filter, max: 1, time: 60000, errors: ['time'] })
        .then(collected => {
            const reaction = collected.first();
    
            if (reaction.emoji.name === upVote) {
                console.log("upvote detected");
                message.reply('You reacted with an up vote.');
            } else if (reaction.emoji.name === downVote) {
                message.reply('You reacted with a down vote');
            }
        })
        .catch(collected => {
            message.reply('You reacted with neither a thumbs up, nor a thumbs down.');
        });
});

function UpdateDB(author, upOrDown) {
    var MongoClient = require('mongodb').MongoClient;
    var url = "mongodb://localhost:27017/RedditSim";

    MongoClient.connect(url, function(err, db) {
        if (err) throw err;
        console.log("Database created!");
        var dbo = db.db("RedditSim");
        dbo.createCollection("Users", function(err, res) {
            if (err) throw err;
            console.log("Collection created!");
            db.close();
        });
    });
}
bot.login(auth.token)
