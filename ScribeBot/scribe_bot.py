# This bot requires the 'message_content' intent.

import discord
import requests
import os

intents = discord.Intents.default()
intents.message_content = True

client = discord.Client(intents=intents)
token_file = open("auth.txt", 'r', encoding="utf-8")
token = token_file.read()

def write_wsb_quotes(quotes):
    if os.path.exists("GamerQuotes.txt"):
        os.remove("GamerQuotes.txt")
    file = open("GamerQuotes.txt", "a+", encoding="utf-8")
    for quote in quotes:
        file.writelines(quote+'\n')
    print("WSB Quotes Written to File!")
    response = requests.get("localhost:8081/refreshQuotes") #Call WSB's API to reload the quotes file
    print("Called WSB's API")

def write_andy_quotes(quotes):
    if os.path.exists("AndyQuotes.txt"):
        os.remove("AndyQuotes.txt")
    file = open("AndyQuotes.txt", "a+", encoding="utf-8")
    for quote in quotes:
        file.write(quote+'\n')
    print("Andy Quotes Written to File!")
    response = requests.get("localhost:8080/refreshQuotes") #Call AndyBot's API to reload the quotes file
    print("Called AndyBot's API")

async def get_history_of_quotes_channel(channel):
    print("Getting Quotes")
    messages = [message async for message in channel.history(limit=None)] # messages is now a list of Message.. #None lets us retrieve everything
    wsb_quotes= []
    andy_quotes = []
    for message in messages:
        #do stuff
        if '/' and ':' not in message.content: #filter out time stamps
            message_to_add = message.content
            if " - " in message.content: #filter out quote attributions 
                message_to_add = message.content.split(" - ")[0]
            if " ~ " in message.content:
                message_to_add = message.content.split(" ~ ")[0]
            if '357280188025012252' in message.content: #Check for AndyBot Quote
                andy_quotes.append(message_to_add)
            wsb_quotes.append(message_to_add)

    write_wsb_quotes(wsb_quotes)
    write_andy_quotes(andy_quotes)
    print("Got Quotes")

@client.event
async def on_ready():
    print(f'We have logged in as {client.user}')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    if message.content.startswith('$hello'):
        await message.channel.send('Hello!')
    
    if message.content.startswith("$refreshQuotes"):
        await message.channel.send("Refreshing Quotes, may take a few minutes...")
        await get_history_of_quotes_channel(client.get_channel(908550006678626334))
        await message.channel.send("Refreshed Quotes!")

client.run(token)
