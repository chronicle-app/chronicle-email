# Chronicle::Email
[![Gem Version](https://badge.fury.io/rb/chronicle-email.svg)](https://badge.fury.io/rb/chronicle-email)

Extract and work with your email using the command line with this plugin for [chronicle-etl](https://github.com/chronicle-app/chronicle-etl).

## Usage

```sh
# Install chronicle-etl and this plugin
$ gem install chronicle-etl
$ chronicle-etl plugins:install email

# Process emails from an mbox file
$ chronicle-etl --extractor email:mbox -i test.mbox  --transformer email --fields subject
```

## Available Connectors
### Extractors

#### `mbox`
Extractor for importing emails from an mbox file

##### Settings
- `input`: A path to an .mbox file

### Transformers

#### `email`
Transform an email (in the form of a string) into Chronicle Schema

##### Settings
- `body_as_markdown`: (default: false) Whether to convert the email body into markdown
- `remove_signature`: (default: true) Whether to attempt to strip out the email signature (using the [`email_reply_parser`](https://github.com/github/email_reply_parser) gem)

## Roadmap
- Add an IMAP (and gmail) extractor #1