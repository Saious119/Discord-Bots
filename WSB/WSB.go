package main

//The markov chain code is from bashawhm's github page for his AutoDolly Bot, all credit goes to him

import (
	"context"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/bwmarrin/discordgo"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
)

const LEN int = 100
const MAX_CHAIN int = 8192

var corpus []string
var chain []MarkovNode

func loadQuotesFromDB(conn *pgx.Conn) error {
	rows, err := conn.Query(context.Background(), "SELECT quote FROM quotes")
	if err != nil {
		return err
	}
	defer rows.Close()

	corpus = nil
	for rows.Next() {
		var quote string
		if err := rows.Scan(&quote); err != nil {
			return err
		}
		words := strings.Fields(quote)
		corpus = append(corpus, words...)
	}
	chain = createChain(corpus)
	log.Printf("Loaded %d words from quotes table", len(corpus))
	return rows.Err()
}

func onMessage(s *discordgo.Session, m *discordgo.MessageCreate) {
	if m.Author.ID == s.State.User.ID {
		return
	}

	if strings.Contains(strings.ToLower(m.Content), "gamer") || strings.Contains(strings.ToLower(m.Content), "quote") {
		markov := markov(chain, rand.Intn(LEN))

		s.ChannelMessageSend(m.ChannelID, markov)
	}
}

func main() {
	TOKEN := os.Getenv("TOKEN")
	if TOKEN == "" {
		log.Fatal("TOKEN environment variable is not set")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is not set")
	}

	conn, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer conn.Close(context.Background())

	if err := loadQuotesFromDB(conn); err != nil {
		log.Fatalf("Failed to load quotes: %v", err)
	}

	ds, err := discordgo.New("Bot " + TOKEN)
	if err != nil {
		panic(err)
	}

	ds.AddHandler(onMessage)
	err = ds.Open()
	if err != nil {
		panic(err)
	}

	r := gin.Default()
	r.GET("/refreshQuotes", func(c *gin.Context) {
		if err := loadQuotesFromDB(conn); err != nil {
			log.Printf("Failed to refresh quotes: %v", err)
			c.Status(500)
			return
		}
		c.Status(200)
	})
	r.Run("localhost:8081")

	sc := make(chan os.Signal, 1)
	signal.Notify(sc, syscall.SIGINT, syscall.SIGTERM, os.Interrupt)
	<-sc
}
