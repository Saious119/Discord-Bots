using System;

public class Time
{
    public List<string> CockPosters { get; set; }
    public string bigCockPoster { get; set; }
    public DateTime today { get; set; }
    private TimeZoneInfo eastern = TimeZoneInfo.FindSystemTimeZoneById("America/New_York");

    public void TimeInit()
    {
        CockPosters = new List<string>();
        bigCockPoster = null;
        today = DateTime.Now;
    }
    public void ClearList()
    {
        Console.WriteLine("Starting up clear list task");
        while (true)
        {
            DateTime easternTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, eastern);
            if (today.Day != easternTime.Day)
            {
                Console.WriteLine("It's a new day, clearing list at {0}", easternTime);
                CockPosters = new List<string>();
                bigCockPoster = null;
                today = easternTime;
            }
            Thread.Sleep(1000);
        }
    }
}
