# Seeker

[![CircleCI](https://circleci.com/gh/dziemba/seeker.svg?style=svg)](https://circleci.com/gh/dziemba/seeker)

Search GitHub repositories for potential job candidates.

## How It Works

1. Gets all GitHub repositories with the specified minimum amount of stars for the given languages.
2. Gets commit count per user for each of those repositories.
3. Calculates a user's score as the sum of `log(repoStars + 1) * commitCount` over each repo.
4. Calculates a user's language distribution from the repo's language information.
5. Fetches user profile data.
6. Filters out users that don't match location filter or don't have an email address.
7. Prints a TSV table of all users, ranked by their score.

## Quick Example

```bash
docker run \
  -e SEEKER_GITHUB_TOKEN="YOUR-GITHUB-PERSONAL-TOKEN-HERE" \
  -e SEEKER_LOCATIONS="Berlin|San Francisco" \
  -e SEEKER_LANGUAGES="Ruby|Go" \
  -e SEEKER_REPO_MIN_STARS="20000" \
  dziemba/seeker \
  > candidates.tsv
```

This examples looks for Ruby and Go developers in Berlin and San Francisco.

It only considers repositories with more than 20k stars.
This is fast, but excludes a lot of data.
You probably want to set this to a much lower number later on.

## Output Format

The output is a TSV list of user data, printed to STDOUT. Logging information is printed to STDERR.

The format is as follows:

Username | Full Name | Score | Language Distribution | Location | Company | Email | Hireable?
--- | --- | --- | --- | --- | --- | --- | ---
foobar | Foot Bart | 23534 | 70% Go, 20% Ruby, 10% C | Berlin | Initech | foo@example.com | true

## Usage
Set the following environment variables to specify the configuration.

Environment Variable | Description | Example Value
--- | --- | ---
SEEKER_GITHUB_TOKEN | A [GitHub Personal Access Token](https://github.com/settings/tokens) |
SEEKER_LOCATIONS | Location filter, separated by `|`  | `Berlin|San Francisco`
SEEKER_LANGUAGES | Desired programming languages, separated by `|` | `Ruby|Go`
SEEKER_REPO_MIN_STARS | Minimum repo star count | `20`

Then run the executable or use the docker image `dziemba/seeker`.

## Installing

Make sure you have an up-to-date version of
[Go](https://golang.org/) and [Glide](https://github.com/Masterminds/glide) installed.

Run `make deps` to install library dependencies. Run `make build` to build the executable.

See [Makefile](Makefile) for more commands.

## Disclaimer
This tool does not send emails or contacts developers in any other way. It only outputs a list of
publicly accessible user data from GitHub. Please use this tool responsibly and do not spam
everybody!

## Contributing

Feel free to fork and submit Pull Requests!

## License

MIT, see [LICENSE.txt](LICENSE.txt)
