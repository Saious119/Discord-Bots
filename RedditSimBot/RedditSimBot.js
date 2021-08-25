var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");

const upVote = '\:arrow_up:';
const downVote = '\:arrow_down:';


//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";

var bot = new Discord.Client();
var client = new Discord.Client();

bot.on("ready",() => {
    logger.info("Connected");
});
bot.on("message", msg => {
    const filter = (reaction, user) => {
        return [upVote, downVote].includes(reaction.emoji.name) && user.id === interaction.user.id;
    };
    
    message.awaitReactions({ filter, max: 1, time: 60000, errors: ['time'] })
        .then(collected => {
            const reaction = collected.first();
    
            if (reaction.emoji.name === upVote) {
                message.reply('You reacted with an up vote.');
            } else if (reaction.emoji.name === downVote) {
                message.reply('You reacted with a down vote');
            }
        })
        .catch(collected => {
            message.reply('You reacted with neither a thumbs up, nor a thumbs down.');
        });
});

bot.login(auth.token)
