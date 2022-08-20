using Discord;
using Discord.WebSocket;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace MangaNotifier
{
    public class Notifier
    {
        DateTime LastChecked { get; set; }

        public Notifier()
        {
            LastChecked = DateTime.MinValue;
        }
        public string StartNotifier()
        {
            string msg = "";
            if ((DateTime.Now - LastChecked).TotalHours > 1)
            {

                DB dB = new DB();
                List<Series> seriesToCheck = dB.GetAllSeries();
                foreach (Series s in seriesToCheck)
                {
                    int newChapter = 0;
                    if (s.LastChapter != null)
                    {
                        newChapter = Convert.ToInt32(s.LastChapter) + 1;
                        Console.WriteLine("newChapter = {0}", newChapter);
                    }
                    HttpWebRequest webRequest = (HttpWebRequest)WebRequest.Create(s.BaseURL + "-" + newChapter);
                    webRequest.AllowAutoRedirect = false;
                    HttpWebResponse response = (HttpWebResponse)webRequest.GetResponse();
                    Console.WriteLine("respons for chapter {0}, for series {1}", newChapter, s.Title);
                    Console.WriteLine((int)response.StatusCode);
                    if ((int)response.StatusCode != 200)
                    {
                        Console.WriteLine("No new Chapters");
                    }
                    else
                    {
                        Console.WriteLine("New Chapter Found!");
                        msg = NotifySubs(s, newChapter.ToString());
                        dB.UpdateLastChapter(s);
                    }
                }
                Console.WriteLine("Checked for updates");
                LastChecked = DateTime.Now;
            }
            
            return msg;

        }
        public string NotifySubs(Series s, string newChapter)
        {
            try
            {
                //var channel = client.GetChannel(id) as IMessageChannel;
                DB db = new DB();
                List<string> subs = db.GetSubscribers(s);
                string msgToSend = "";
                foreach (string sub in subs)
                {
                    msgToSend += ("@" + sub + " ");
                }
                msgToSend += "New chapter for " + s.Title + "!\n";
                msgToSend += s.BaseURL + "-" + newChapter;
                Console.WriteLine("Notified subs");
                Console.WriteLine(msgToSend);
                return msgToSend;
            }
            catch(Exception e)
            {
                Console.WriteLine(e);
            }
            return "";
        }
    }
}
