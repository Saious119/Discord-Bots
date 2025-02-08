using System;

public class Time
{
    public List<string> CockPosters { get; set; }
    public string bigCockPoster { get; set; }

    public void TimeInit()
    {
        CockPosters = new List<string>();
        bigCockPoster = null;
    }
    public void ClearList()
    {
        Console.WriteLine("Starting up clear list task");
        while (true)
        {
            if ((DateTime.Now.Hour == 0) && (DateTime.Now.Minute == 0) && (DateTime.Now.Second < 5))
            {
                Console.WriteLine("It's midnight, clearing list");
                CockPosters = new List<string>();
                bigCockPoster = null;
                Thread.Sleep(10000);
            }
        }
    }
}
