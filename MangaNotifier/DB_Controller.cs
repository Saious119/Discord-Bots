using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using Newtonsoft.Json.Bson;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MangaNotifier 
{
    public class DB
    {
        public DB()
        {
            var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@mangadb.hrhudi3.mongodb.net/?retryWrites=true&w=majority");
            settings.ServerApi = new ServerApi(ServerApiVersion.V1);
            var client = new MongoClient(settings);
            var database = client.GetDatabase("Notifier");
        }
        public List<string> GetSubscribers(string s)
        {
            List<string> Subscribers = new List<string>();
            var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@mangadb.hrhudi3.mongodb.net/?retryWrites=true&w=majority");
            settings.ServerApi = new ServerApi(ServerApiVersion.V1);
            var client = new MongoClient(settings);
            var database = client.GetDatabase("Notifier");
            IMongoCollection<BsonDocument> collection = null;
            Console.WriteLine("checking for user");
            collection = database.GetCollection<BsonDocument>(s);
            if (collection == null)
            {
                Console.WriteLine("No subscribers for series {0}", s);
            }
            collection = database.GetCollection<BsonDocument>(s);
            Console.WriteLine("got collection");
            var documents = collection.Find(new BsonDocument()).ToList();
            foreach (BsonDocument doc in documents)
            {
                Console.WriteLine(doc.ToString());
            }
        }
        public void AddSubscriber(string sub, string s)
        {
            try
            {
                var settings = MongoClientSettings.FromConnectionString("mongodb+srv://guest:defaultPass@mangadb.hrhudi3.mongodb.net/?retryWrites=true&w=majority");
                settings.ServerApi = new ServerApi(ServerApiVersion.V1);
                var client = new MongoClient(settings);
                var database = client.GetDatabase("Notifier");
                var collection = database.GetCollection<BsonDocument>(s);
                var documents = collection.Find(new BsonDocument()).ToList();
                var newDoc = sub.ToBsonDocument();
                collection.InsertOne(newDoc);
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }
    }
}