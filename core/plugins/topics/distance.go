package topics

import(
  "roscopecoltran/sniperkit-sift/core/plugins/topics/word2vec"
  "fmt"
)

func main() {
  model := new(word2vec.Model)
  model.Load("freebase-vectors-skipgram1000-en.bin")
  seedWords := []string{"/en/united_states", "/en/canada"}
  bestWords := model.MostSimilar(seedWords)
  fmt.Printf("Best Words %+v\n", bestWords)
}