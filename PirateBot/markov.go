package main

import (
	"bufio"
	"math/rand"
	"strings"
)

type MarkovNode struct {
	value string
	next  []string
}

func genChain(frozen string) []MarkovNode {
	sin := bufio.NewScanner(strings.NewReader(frozen))
	sin.Split(bufio.ScanWords)
	var inputTokens []string
	for sin.Scan() {
		inputTokens = append(inputTokens, sin.Text())
	}
	chain := createChain(inputTokens)
	return chain
}

func getNode(chain []MarkovNode, key string) MarkovNode {
	for _, node := range chain {
		if node.value == key {
			return node
		}
	}
	return MarkovNode{value: key}
}

func isIn(chain []MarkovNode, node MarkovNode) (bool, int) {
	for i, curr := range chain {
		if node.value == curr.value {
			return true, i
		}
	}
	return false, -1
}

func createChain(input []string) []MarkovNode {
	var chain []MarkovNode
	for i := 0; i < len(input); i++ {
		node := getNode(chain, input[i])
		if i+1 < len(input) {
			node.next = append(node.next, input[i+1])
		}
		in, i := isIn(chain, node)
		if !in {
			chain = append(chain, node)
		} else {
			chain[i] = node
		}
	}
	return chain
}

func addToChain(chain []MarkovNode, input []string) []MarkovNode {
	for i := 0; i < len(input); i++ {
		node := getNode(chain, input[i])
		if i+1 < len(input) {
			node.next = append(node.next, input[i+1])
		}
		in, i := isIn(chain, node)
		if !in {
			chain = append(chain, node)
		} else {
			chain[i] = node
		}
	}
	return chain
}

func markov(chain []MarkovNode, length int) string {
	var output string = chain[rand.Int()%len(chain)].value
	next := output
	for i := 0; i < length; i++ {
		node := getNode(chain, next)
		var nextToken string
		if len(node.next) != 0 {
			nextToken = node.next[rand.Int()%len(node.next)]
		}
		output += " " + nextToken
		next = nextToken
	}
	return output
}
