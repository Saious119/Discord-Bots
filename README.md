# Discord-Bots
A collection of all the discord bots I've made

## 🚀 Kubernetes Deployment

All bots are now containerized and ready to deploy to your k3s cluster!

### Quick Start

```bash
# Build all Docker images
./build-all.sh          # Linux/Mac
# OR
.\build-all.ps1         # Windows

# Deploy to k3s
cd kubernetes
./deploy-all.sh
```

### Documentation

- **[Quick Start Guide](DEPLOYMENT-QUICKSTART.md)** - Quick reference for deployment
- **[Setup Complete Guide](KUBERNETES-SETUP-COMPLETE.md)** - Overview of what's been set up
- **[Full Kubernetes Guide](kubernetes/README.md)** - Comprehensive deployment documentation
- **[Secret Management](kubernetes/secrets/README.md)** - Managing bot tokens and credentials

### Managing Bots

```bash
cd kubernetes

# View all deployed bots
./bot-manager.sh list

# Check bot status
./bot-manager.sh status andybot

# View logs
./bot-manager.sh logs andybot -f

# Restart a bot
./bot-manager.sh restart andybot

# Rebuild and redeploy
./bot-manager.sh rebuild andybot
```

### Bot Inventory

**Total: 18 Discord Bots** organized by language:

- **Go (3):** AndyBot, PirateBot, WSB
- **C# (5):** BrainCellBot, DickJohnson, HouseMog, MangaNotifier, MovieNightBot
- **Node.js (8):** OwOBot, OyVeyBot, RedditSimBot, TarotBot, UwUBot, JailBot, JonTronBot, TerryDavisBot
- **Python (2):** ScribeBot, PurpleHaroBot

All bots have Dockerfiles and are ready for Kubernetes deployment!

---

## 📖 Bot Descriptions

## UwUBot
### Description
A general annoyance bot based on the UwU/OwO meme. you can use UwUBot help to get a list of commands. 
It will generally reply to any message it receives with a variety of responses, and can even join voice chats to play audio clips. you can also say the word image and it will send to you a random image scrapped from 4chan as long as the image was tagged with either UwU or OwO and was posted in a or jp. 

### Special Requirements 
UwUBot will require my specific fork of the python 4scanner package inorder to use the image function. 

## Terry Davis Bot
### Description 
A Bot that sends quotes said by late programmer Terry Davis, inventor of TempleOS, whenever his name is mentioned. **Warning** it is important to note that Terry Davis has said some things that other may find offensive, this is not representative of my beliefs, however I do find the quotes to be occassionally humorous and representative of Terry Davis.

## JonTron Bot
### Description
The same as Terry Davis Bot but for the famous youtuber JonTron. 

## Tarot Bot
### Description
A bot that will give you your fortune. All you have to say is "Give me a fortune". Right now it only does single card fortunes, the hope is that in the near future it will also do 2 card and full 10 card readings. 

## Jail Bot (Under Construction)
### Description
Interacting with UwUBot will give you a cringe role for a certain amount of time, then remove it. Currently it can give you the role, but crashes when removing it. 

## OwOBot / ΘωθBot
### Description
A bot that is a pun on the Egyption God of Knowledge's name in Greek being written at Θωθ. Asking Θωθ, what's this? <query> or OwO, what's this? <query> will use the wikipedia API to search for a valid wikipedia page and send it to you if one is found.  
  
## PirateBot
### Description
A bot that uses a markov chain to combine words from OnePieceQuotes.txt to create new sentences (sorta) you can @ it or say One Piece to trigger it
### How to Build
go build PirateBot.go markov.go 
./PirateBot

## WSB (WAA Simulation bot)
### Description
A bot that uses the same markov chain as pirate bot but with quotes from the WAA server

## AndyBot
### Description
A bot that uses the same markov chain as pirate bot but with quotes specifically from Andy in the WAA server

## ScribeBot
### Description
A bot that reads the quotes text channel of my server then outputs text files for WSB and AndyBot

## OyVeyBot
### Description
when you say Oy Vey this bot will comfort you with Matzo Ball Soup and Bagels

## DickJohnson
### Description
a .NET bot that rewards you for posting in the daily channel in WAA and punishes you for double posting

## Manga Notifier (Under Construction)
### Description
A bot you can subscribe manga series to and get notified when new chapters release

## BrainCellBot
### Description
Give the collective braincell to someone and keep track of who has the brain cell

## RedditSimBot (Under Construction)
### Description
A bot that allows your to upvote or downvote messages and keep track of each users "Discord Karma"

## Purple Haro Bot
### Description
A python bot inspired by the Purple Haro in Mobile Suit Gundam 00, this used the NLTK library to get the sentiment value of a given message and respond

## Scribe Bot
### Description
A bot that scrapes a channel for quotes to update the sources for WSB and AndyBot

## HouseMog
### Description
A bot that reminds you to visit your house in FF XIV so you don't loose it, Kupo!

## Movie Night Bot
### Description
Keep track of what movies are coming up for your monthly movie night with the boys