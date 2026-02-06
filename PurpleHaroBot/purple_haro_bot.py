import discord
import requests
import os
import pandas as pd
import nltk

from nltk.sentiment.vader import SentimentIntensityAnalyzer

from nltk.corpus import stopwords

from nltk.tokenize import word_tokenize

from nltk.stem import WordNetLemmatizer

nltk.download('all')

df = pd.read_csv('https://raw.githubusercontent.com/pycaret/pycaret/master/datasets/amazon.csv')
analyzer = SentimentIntensityAnalyzer()

intents = discord.Intents.default()
intents.message_content = True

client = discord.Client(intents=intents)
token_file = open("auth.txt", 'r', encoding="utf-8")
token = token_file.read()


def preprocess_text(text):
    tokens = word_tokenize(text.lower())
    filtered_tokens = [token for token in tokens if token not in stopwords.words('english')]

    lemmatizer = WordNetLemmatizer()
    lemmatized_tokens = [lemmatizer.lemmatize(token) for token in filtered_tokens]

    processed_text = ' '.join(lemmatized_tokens)
    return processed_text

def get_sentiment(text):
    scores = analyzer.polarity_scores(text)
    sentiment = 1 if scores['pos'] > 0 else 0
    return sentiment

@client.event
async def on_ready():
    print(f'We have logged in as {client.user}')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    processedText = preprocess_text(message.content)
    print(processedText)
    sentimentScore = get_sentiment(processedText)
    print(sentimentScore)

    if(sentimentScore == 0):
        await message.channel.send('Kill yourself! Kill yourself!')

client.run(token)