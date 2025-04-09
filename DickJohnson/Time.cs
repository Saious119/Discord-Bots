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
        DateTime today = DateTime.Now;
        while (true)
        {
            if (today.Day != DateTime.Now.Day)
            {
                Console.WriteLine("It's a new day, clearing list at {0}", DateTime.Now);
                CockPosters = new List<string>();
                bigCockPoster = null;
                today = DateTime.Now;
            }
            Thread.Sleep(1000);
        }
    }
}
