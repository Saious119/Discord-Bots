package main

//This code is from bashawhm's github page for his AutoDolly Bot, all credit goes to him

import (
	"bufio"
	"math/rand"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/bwmarrin/discordgo"
)

const LEN int = 100
const MAX_CHAIN int = 8192

var lyrics []string
var chain []MarkovNode
var buff []byte

func PirateBrain(s *discordgo.Session, m *discordgo.MessageCreate) {
	if m.Author.ID == s.State.User.ID {
		return
	}
	if strings.Contains(m.Author.String(), "VimBot") {
		return
	}

	//NSFW and spam
	if m.ChannelID == "486580756966277120" || m.ChannelID == "486580615425032192" {
		return
	}

	for i := 0; i < len(m.Mentions); i++ {
		if strings.Contains(m.Mentions[i].String(), "GamerQuote") || strings.Contains(m.Mentions[i].String(), "everyone") {
			if strings.Contains(m.Author.String(), "VimBot") {
				continue
			}
			if strings.Contains(m.Author.String(), "PingBot") {
				var responce string = "BC:"
				if m.Content[:3] == "BR:" {
					sin := bufio.NewScanner(strings.NewReader(m.Content))
					sin.Split(bufio.ScanRunes)
					foundBegin := false
					for sin.Scan() {
						if !foundBegin {
							if sin.Text() == ":" {
								foundBegin = true
								continue
							}
						}
						if foundBegin {
							if sin.Text() == ":" {
								break
							}
							responce += sin.Text()
						}
					}
					responce += ":PONG 0000000000"
				}
				s.ChannelMessageSend(m.ChannelID, responce)
				return
			}
			if m.ChannelID != "486580637139075082" { // SPAM Channel
				markov := markov(chain, LEN)
				s.ChannelMessageSend(m.ChannelID, markov)
			} else {
				markov := markov(chain, LEN)
				s.ChannelMessageSend(m.ChannelID, markov)
			}
		}
	}

	if strings.Contains(strings.ToLower(m.Content), "gamer") || strings.Contains(strings.ToLower(m.Content), "quote") {
		markov := markov(chain, LEN)

		s.ChannelMessageSend(m.ChannelID, markov)
	}

}

func main() {
	rand.Seed(int64(time.Now().Nanosecond()))
	//	auth, err := ioutil.ReadFile("auth.txt")
	//	if err != nil {
	//		panic(err)
	//	}

	// Convert []byte to string and print to screen
	TOKEN := "OTY5Mzk5OTQ0ODQ0ODA0MTE2.Yms2DQ.BZUazQ-bktPlg8yT7K4V5Ecm3eY"
	ds, err := discordgo.New("Bot " + TOKEN)
	if err != nil {
		panic(err)
	}

	ds.AddHandler(PirateBrain)
	err = ds.Open()
	if err != nil {
		panic(err)
	}

	file, err := os.Open("GamerQuotes.txt")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	in := bufio.NewScanner(bufio.NewReader(file))
	in.Split(bufio.ScanWords)

	for in.Scan() {
		lyrics = append(lyrics, in.Text())
	}
	chain = createChain(lyrics)

	sc := make(chan os.Signal, 1)
	signal.Notify(sc, syscall.SIGINT, syscall.SIGTERM, os.Interrupt, os.Kill)
	<-sc
}
