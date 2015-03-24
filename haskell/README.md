Slack-save-a-link-bot in Haskell
================================
Saves links to MongoDB from Slack.

## Build
Requires `ghc` and `cabal`.
```bash
cabal sandbox init
cabal install --dependencies-only
cabal build
```

## Run
Compiled server is located at
`./dist/build/slack-save-a-link-bot/slack-save-a-link-bot`.

Need to run a MongoDB instance.

## Develop
Cabal configuration is in `slack-save-a-link-bot.cabal`.

Source code is at `./src/`.

Main file is `./src/Main.hs`.
