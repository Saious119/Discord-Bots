using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MangaNotifier
{
    public class Series
    {
        [BsonId]
        public ObjectId? id { get; set; }
        [BsonElement("BaseURL")]
        public string? BaseURL { get; set; }
        [BsonElement("Title")]
        public string? Title { get; set; }
        [BsonElement("LastChapter")]
        public string? LastChapter { get; set; }
        [BsonElement("Subscribers")]
        public List<string>? Subscribers { get; set; }

    }
}
