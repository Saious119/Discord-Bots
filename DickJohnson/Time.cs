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
        DateTime midnight = new System.DateTime(2022, 1, 31, 14, 0, 0, 0);
        while (true)
        {
            if (DateTime.Now.Hour == midnight.Hour)
            {
                Console.WriteLine("It's midnight, clearing list");
                CockPosters = new List<string>();
                bigCockPoster = null;
            }
        }
    }
}
