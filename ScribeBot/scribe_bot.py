# This bot requires the 'message_content' intent.

import discord
from discord import app_commands
from discord.ext import commands
import requests
import os

intents = discord.Intents.default()
intents.message_content = True

#client = discord.Client(intents=intents)
client = commands.Bot(command_prefix="$", intents=discord.Intents.all())
token_file = open("auth.txt", 'r', encoding="utf-8")
token = token_file.read()

def write_wsb_quotes(quotes):
    try:
        if os.path.exists("GamerQuotes.txt"):
            os.remove("GamerQuotes.txt")
        file = open("GamerQuotes.txt", "a+", encoding="utf-8")
        for quote in quotes:
            file.writelines(quote+'\n')
        print("WSB Quotes Written to File!")
        response = requests.get("http://localhost:8081/refreshQuotes") #Call WSB's API to reload the quotes file
        print("Called WSB's API")
    except Exception as e:
        print(e)

def write_andy_quotes(quotes):
    try:
        if os.path.exists("AndyQuotes.txt"):
            os.remove("AndyQuotes.txt")
        file = open("AndyQuotes.txt", "a+", encoding="utf-8")
        for quote in quotes:
            file.write(quote+'\n')
        print("Andy Quotes Written to File!")
        response = requests.get("http://localhost:8080/refreshQuotes") #Call AndyBot's API to reload the quotes file
        print("Called AndyBot's API")
    except Exception as e:
        print(e)

async def get_history_of_quotes_channel(channel):
    print("Getting Quotes")
    try:
        messages = [message async for message in channel.history(limit=None)] # messages is now a list of Message.. #None lets us retrieve everything
        wsb_quotes= []
        andy_quotes = []
        for message in messages:
            try:
                #please stop deadnaming my friend :(
                message.content = message.content.replace("ben", "mel")
                message.content = message.content.replace("Ben", "Mel")
                message.content = message.content.replace("BEN", "MEL")
                #do stuff
                if '/' and ':' not in message.content: #filter out time stamps
                    message_to_add = message.content
                    if " - " in message.content: #filter out quote attributions 
                        message_to_add = message.content.split(" - ")[0]
                    if " ~ " in message.content:
                        message_to_add = message.content.split(" ~ ")[0]
                    if '357280188025012252' in message.content: #Check for AndyBot Quote
                        andy_quotes.append(message_to_add)
                    print(message_to_add)
                    wsb_quotes.append(message_to_add)
            except Exception as ex:
                print(ex)
        print("Got Quotes")
        write_wsb_quotes(wsb_quotes)
        write_andy_quotes(andy_quotes)
    except Exception as e:
        print(e)

@client.event
async def on_ready():
    print(f'We have logged in as {client.user}')
    try:
        synced = await client.tree.sync()
        print(f"Synced {len(synced)} command(s)")
    except Exception as e:
        print(e)

@client.tree.command(name="refresh_quotes", description="Refreshes AndyBot and WSB with new quotes")
async def refreshQuotes(interaction: discord.Interaction):
    try:
        await interaction.response.send_message("Refreshing Quotes, may take a few minutes...", ephemeral=True)
        await get_history_of_quotes_channel(client.get_channel(908550006678626334))
        await interaction.followup.send("Refreshed Quotes!", ephemeral=True)
    except Exception as e:
        print(e)

client.run(token)
