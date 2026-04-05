# This bot requires the 'message_content' intent.

import os
import re

import discord
import psycopg2
import requests
from discord import app_commands
from discord.ext import commands
from dotenv import load_dotenv

intents = discord.Intents.default()
intents.message_content = True

# client = discord.Client(intents=intents)
client = commands.Bot(command_prefix="$", intents=discord.Intents.all())

load_dotenv()

TOKEN = os.environ["TOKEN"]
DB_CONN_STRING = os.environ["COCKROACH_DB_URL"]


def insert_quotes_to_db(quotes):
    """Insert quotes into the CockroachDB quotes table.
    quotes is a list of ((quote_text, attribute), discord_message_id) tuples.
    """
    try:
        conn = psycopg2.connect(DB_CONN_STRING)
        conn.set_session(autocommit=True)
        cur = conn.cursor()
        for (quote_text, attribute), discord_message_id in quotes:
            try:
                cur.execute(
                    "INSERT INTO quotes (quote, attribute, discord_message_id) VALUES (%s, %s, %s)",
                    (quote_text, attribute, discord_message_id),
                )
            except Exception as ex:
                print(
                    f"Error inserting quote {quote_text} - {attribute} ({discord_message_id}) into database with error: {ex}"
                )
        cur.close()
        conn.close()
        print(f"Inserted {len(quotes)} quote(s) into DB!")
    except Exception as e:
        print(f"DB insert error: {e}")


def get_last_message_id():
    """Get the discord_message_id of the newest entry in the quotes table"""
    try:
        conn = psycopg2.connect(DB_CONN_STRING)
        cur = conn.cursor()
        cur.execute(
            "SELECT discord_message_id FROM quotes ORDER BY created_at DESC LIMIT 1"
        )
        row = cur.fetchone()
        cur.close()
        conn.close()
        if row and row[0]:
            return row[0]
    except Exception as e:
        print(f"DB query error: {e}")
    return None


def update_quotes(quotes):
    try:
        insert_quotes_to_db(quotes)
        _ = requests.get(
            "http://wsb:8080/refreshQuotes"
        )  # Call WSB's API to reload quotes
        print("Called WSB's API")
        _ = requests.get(
            "http://andybot:8080/refreshQuotes"
        )  # Call AndyBot's API to reload quotes
        print("Called AndyBot's API")
    except Exception as e:
        print(e)


async def get_new_quotes(channel):
    print("Getting New Quotes")
    try:
        last_message_id = get_last_message_id()

        # Get messages after the last processed one
        if last_message_id:
            messages = [
                message
                async for message in channel.history(
                    limit=None, after=discord.Object(id=int(last_message_id))
                )
            ]
        else:
            # First time running - get all messages
            messages = [message async for message in channel.history(limit=None)]

        if not messages:
            print("No new quotes to process")
            return 0

        # Sort messages by timestamp (oldest first) so they append in chronological order
        messages.sort(key=lambda m: m.created_at)

        quotes = []
        for message in messages:
            try:
                # if "/" and ":" not in message.content:  # filter out time stamps
                quote_text = message.content
                attribute = ""
                parts = re.split(r'["""][\s\-~]{0,4}<', message.content)
                if len(parts) > 1:
                    quote_text = parts[0].strip() + '"'
                    attribute = parts[1].strip()
                quotes.append(((quote_text, attribute), str(message.id)))
            except Exception as ex:
                print(ex)

        print(f"Got {len(messages)} New Quote(s)")

        # Update DB and tell Bots to refresh
        update_quotes(quotes)
        return len(messages)
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
        numNewQuotes = await get_new_quotes(client.get_channel(908550006678626334))
        await interaction.followup.send(
            f"Refreshed with {numNewQuotes} new Quote(s)!", ephemeral=True
        )
    except Exception as e:
        print(e)


client.run(TOKEN)
