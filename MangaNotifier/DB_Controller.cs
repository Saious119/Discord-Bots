using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using Newtonsoft.Json.Bson;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MongoDB.Driver;

namespace MangaNotifier 
{
    public class DB
    {
        public DB()
        {
            var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
            settings.ServerApi = new ServerApi(ServerApiVersion.V1);
            var client = new MongoClient(settings);
            var database = client.GetDatabase("Notifier");
        }
        public List<string> GetSubscribers(Series s)
        {
            try
            {
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var builder = Builders<BsonDocument>.Filter;
                var filter = Builders<BsonDocument>.Filter.Eq("Title", s.Title);
                var collection = database.GetCollection<BsonDocument>("series");
                var documents = collection.Find(filter).ToList();
                foreach (var doc in documents)
                {
                    Console.WriteLine(doc);
                }
                Series Doc = BsonSerializer.Deserialize<Series>(documents.First());
                return Doc.Subscribers;
            }
            catch(Exception e)
            {
                Console.WriteLine(e);
            }
            return new List<string>();
        }
        public void AddSubscriber(string sub, string seriesTitle)
        {
            try
            {
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var builder = Builders<BsonDocument>.Filter;
                var filter = Builders<BsonDocument>.Filter.Eq("Title", seriesTitle); 
                var collection = database.GetCollection<BsonDocument>("series");
                var documents = collection.Find(filter).ToList();
                foreach(var doc in documents)
                {
                    Console.WriteLine(doc);
                }
                Series oldDoc = BsonSerializer.Deserialize<Series>(documents.First());
                oldDoc.Subscribers.Add(sub);
                //var upDoc = documents.Add(sub); //.First.Subscribers.Add(sub);
                var newDoc = oldDoc.ToBsonDocument();
                collection.DeleteOne(filter);
                collection.InsertOne(newDoc);
                Console.WriteLine("sub added");
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }
        public void RemoveSubscriber(string sub, string seriesTitle)
        {
            try
            {
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var builder = Builders<BsonDocument>.Filter;
                var filter = Builders<BsonDocument>.Filter.Eq("Title", seriesTitle);
                var collection = database.GetCollection<BsonDocument>("series");
                var documents = collection.Find(filter).ToList();
                foreach (var doc in documents)
                {
                    Console.WriteLine(doc);
                }
                Series oldDoc = BsonSerializer.Deserialize<Series>(documents.First());
                oldDoc.Subscribers.Remove(sub);
                //var upDoc = documents.Add(sub); //.First.Subscribers.Add(sub);
                var newDoc = oldDoc.ToBsonDocument();
                collection.DeleteOne(filter);
                collection.InsertOne(newDoc);
                Console.WriteLine("sub removed");
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }
        public List<Series> GetAllSeries()
        {
            List<Series> series = new List<Series>();
            try{
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var collection = database.GetCollection<BsonDocument>("series");
                Console.WriteLine("Got Coll!");
                var documents = collection.Find(new BsonDocument()).ToList();
                foreach (var doc in documents)
                {
                    Console.Write(doc);
                    series.Add(BsonSerializer.Deserialize<Series>(doc));
                }
            }
            catch(Exception e)
            {
                Console.WriteLine(e);
            }
            return series;
        }
        public void UpdateLastChapter(Series s)
        {
            try
            {
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var builder = Builders<BsonDocument>.Filter;
                var filter = Builders<BsonDocument>.Filter.Eq("Title", s.Title);
                var collection = database.GetCollection<BsonDocument>("series");
                var documents = collection.Find(filter).ToList();
                foreach (var doc in documents)
                {
                    Console.WriteLine(doc);
                }
                Series oldDoc = BsonSerializer.Deserialize<Series>(documents.First());
                oldDoc.LastChapter = (Convert.ToInt32(oldDoc.LastChapter) + 1).ToString();
                var newDoc = oldDoc.ToBsonDocument();
                Console.WriteLine("going to delete");
                var Dresult = collection.DeleteOne(filter);
                Console.WriteLine("going to insert");
                collection.InsertOne(newDoc);
                Console.WriteLine("Last Chapter Updated for {0}", s.Title);
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }
        public void AddNewSeies(Series s)
        {
            try
            {
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var collection = database.GetCollection<BsonDocument>("series");
                var newDoc = s.ToBsonDocument();
                collection.InsertOne(newDoc);
                Console.WriteLine("Inserted new series: {0}", s.Title);
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
           
            }
        }
        public void RemoveSeries(string title)
        {
            try
            {
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@serverlessinstance.izekv.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var builder = Builders<BsonDocument>.Filter;
                var filter = Builders<BsonDocument>.Filter.Eq("Title", title);
                var collection = database.GetCollection<BsonDocument>("series");
                collection.DeleteOne(filter);
                Console.WriteLine("Removed series: {0}", title);
            }
            catch (Exception e)
            {
                Console.WriteLine(e);

            }
        }
    }
}