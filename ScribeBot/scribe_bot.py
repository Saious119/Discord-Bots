# This bot requires the 'message_content' intent.

import json
import os

import discord
import requests
from discord import app_commands
from discord.ext import commands

intents = discord.Intents.default()
intents.message_content = True

# client = discord.Client(intents=intents)
client = commands.Bot(command_prefix="$", intents=discord.Intents.all())
token_file = open("auth.txt", "r", encoding="utf-8")
token = token_file.read()

LAST_MESSAGE_FILE = "last_message_ids.json"


def load_last_message_ids():
    """Load the last processed message IDs from file"""
    if os.path.exists(LAST_MESSAGE_FILE):
        try:
            with open(LAST_MESSAGE_FILE, "r") as f:
                return json.load(f)
        except:
            return {}
    return {}


def save_last_message_ids(message_ids):
    """Save the last processed message IDs to file"""
    with open(LAST_MESSAGE_FILE, "w") as f:
        json.dump(message_ids, f)


def append_wsb_quotes(quotes):
    try:
        file = open("GamerQuotes.txt", "a", encoding="utf-8")
        for quote in quotes:
            file.write(quote + "\n")
        file.close()
        print(f"Appended {len(quotes)} WSB Quote(s) to File!")
        response = requests.get(
            "http://localhost:8081/refreshQuotes"
        )  # Call WSB's API to reload the quotes file
        print("Called WSB's API")
    except Exception as e:
        print(e)


def append_andy_quotes(quotes):
    try:
        file = open("AndyQuotes.txt", "a", encoding="utf-8")
        for quote in quotes:
            file.write(quote + "\n")
        file.close()
        print(f"Appended {len(quotes)} Andy Quote(s) to File!")
        response = requests.get(
            "http://localhost:8080/refreshQuotes"
        )  # Call AndyBot's API to reload the quotes file
        print("Called AndyBot's API")
    except Exception as e:
        print(e)


async def get_history_of_quotes_channel(channel):
    print("Getting New Quotes")
    try:
        # Load the last processed message ID for this channel
        last_message_ids = load_last_message_ids()
        last_message_id = last_message_ids.get(str(channel.id), None)

        # Get messages after the last processed one
        if last_message_id:
            messages = [
                message
                async for message in channel.history(
                    limit=None, after=discord.Object(id=last_message_id)
                )
            ]
        else:
            # First time running - get all messages
            messages = [message async for message in channel.history(limit=None)]

        if not messages:
            print("No new quotes to process")
            return

        # Sort messages by timestamp (oldest first) so they append in chronological order
        messages.sort(key=lambda m: m.created_at)

        wsb_quotes = []
        andy_quotes = []
        for message in messages:
            try:
                # please stop deadnaming my friend :(
                message.content = message.content.replace("ben", "mel")
                message.content = message.content.replace("Ben", "Mel")
                message.content = message.content.replace("BEN", "MEL")
                # do stuff
                if "/" and ":" not in message.content:  # filter out time stamps
                    message_to_add = message.content
                    if " - " in message.content:  # filter out quote attributions
                        message_to_add = message.content.split(" - ")[0]
                    if "~" in message.content:
                        message_to_add = message.content.split("~")[0]
                    if (
                        "357280188025012252" in message.content
                    ):  # Check for AndyBot Quote
                        andy_quotes.append(message_to_add)
                    wsb_quotes.append(message_to_add)
            except Exception as ex:
                print(ex)

        print(f"Got {len(messages)} New Quote(s)")

        # Append new quotes
        if wsb_quotes:
            append_wsb_quotes(wsb_quotes)
        if andy_quotes:
            append_andy_quotes(andy_quotes)

        # Save the latest message ID
        if messages:
            last_message_ids[str(channel.id)] = messages[-1].id
            save_last_message_ids(last_message_ids)

    except Exception as e:
        print(e)


@client.event
async def on_ready():
    print(f"We have logged in as {client.user}")
    try:
        synced = await client.tree.sync()
        print(f"Synced {len(synced)} command(s)")
    except Exception as e:
        print(e)


@client.tree.command(
    name="refresh_quotes", description="Refreshes AndyBot and WSB with new quotes"
)
async def refreshQuotes(interaction: discord.Interaction):
    try:
        await interaction.response.send_message(
            "Refreshing Quotes, may take a few minutes...", ephemeral=True
        )
        await get_history_of_quotes_channel(client.get_channel(908550006678626334))
        await interaction.followup.send("Refreshed Quotes!", ephemeral=True)
    except Exception as e:
        print(e)


client.run(token)
