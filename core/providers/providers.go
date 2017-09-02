/*
 * Ferret
 * Copyright (c) 2016 Yieldbot, Inc.
 * For the full copyright and license information, please view the LICENSE.txt file.
 */

// Package providers wraps the provider packages
package providers

import (

	// devops
	"github.com/roscopecoltran/sniperkit-sift/core/providers/consul"

	// vcs
	"github.com/roscopecoltran/sniperkit-sift/core/providers/github"
	"github.com/roscopecoltran/sniperkit-sift/core/providers/gitlab"
	"github.com/roscopecoltran/sniperkit-sift/core/providers/bitbucket"

	// chats
	"github.com/roscopecoltran/sniperkit-sift/core/providers/slack"
	"github.com/roscopecoltran/sniperkit-sift/core/providers/trello"

	// dev
	"github.com/roscopecoltran/sniperkit-sift/core/providers/stackoverflow"
	"github.com/roscopecoltran/sniperkit-sift/core/providers/hackernews"
	"github.com/roscopecoltran/sniperkit-sift/core/providers/reddit"
	"github.com/roscopecoltran/sniperkit-sift/core/providers/answerhub"

	// social media
	"github.com/roscopecoltran/sniperkit-sift/core/providers/twitter"

	// CSHarp
	"github.com/roscopecoltran/sniperkit-sift/core/providers/unity3d"

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
		case "hackernews":
			hackernews.Register(v, f)
		case "stackoverflow":
			stackoverflow.Register(v, f)
		case "twitter":
			twitter.Register(v, f)
		case "hackernews":
			hackernews.Register(v, f)
		case "consul":
			consul.Register(v, f)
		case "github":
			github.Register(v, f)
		case "gitlab":
			gitlab.Register(v, f)
		case "bitbucket":
			bitbucket.Register(v, f)
		case "slack":
			slack.Register(v, f)
		case "trello":
			trello.Register(v, f)
		default:
			panic("invalid provider: " + p)
		}
	}
}