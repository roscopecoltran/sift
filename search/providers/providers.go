/*
 * Ferret
 * Copyright (c) 2016 Yieldbot, Inc.
 * For the full copyright and license information, please view the LICENSE.txt file.
 */

// Package providers wraps the provider packages
package providers

import (
	"github.com/roscopecoltran/sniperkit-sift/search/providers/answerhub"
	"github.com/roscopecoltran/sniperkit-sift/search/providers/reddit"
	"github.com/roscopecoltran/sniperkit-sift/search/providers/hackernews"
	"github.com/roscopecoltran/sniperkit-sift/search/providers/stackoverflow"
	"github.com/roscopecoltran/sniperkit-sift/search/providers/consul"
	"github.com/roscopecoltran/sniperkit-sift/search/providers/github"
	"github.com/roscopecoltran/sniperkit-sift/search/providers/slack"
	"github.com/roscopecoltran/sniperkit-sift/search/providers/trello"
)

// Register registers the providers
func Register(args []map[string]interface{}, f func(interface{}) error) {
	for _, v := range args {
		p, ok := v["Provider"].(string)
		if !ok {
			continue
		}

		switch p {
		case "answerhub":
			answerhub.Register(v, f)
		case "reddit":
			reddit.Register(v, f)
		case "stackoverflow":
			stackoverflow.Register(v, f)
		case "consul":
			consul.Register(v, f)
		case "github":
			github.Register(v, f)
		case "slack":
			slack.Register(v, f)
		case "trello":
			trello.Register(v, f)
		default:
			panic("invalid provider: " + p)
		}
	}
}