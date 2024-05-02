# Chronicle::Email
[![Gem Version](https://badge.fury.io/rb/chronicle-email.svg)](https://badge.fury.io/rb/chronicle-email)

Extract and work with your email using the command line with this plugin for [chronicle-etl](https://github.com/chronicle-app/chronicle-etl).

## Usage

```sh
# Install chronicle-etl and this plugin
$ gem install chronicle-etl
$ chronicle-etl plugins:install email
```

### Extracting email from IMAP

For Gmail accounts, you can create an [app password](https://myaccount.google.com/apppasswords); your email address is your username.

```sh
# Save username and password
$ chronicle-etl secrets:set imap username foo@gmail.com
$ chronicle-etl secrets:set imap password APPPASSWORD

# Then, retrieve your email from the last five days
$ chronicle-etl --extractor email:imap --schema chronicle --since 5d

# If you don't want to save your credentials as a secret, you can just pass
# them to the extractor directly
$ chronicle-etl --extractor email:imap --schema chronicle --since 5d --loader json \
    --extractor-opts username:foo@gmail.com --password:APPPASSWORD
```

### Processing email from an .mbox file
The MBOX format is used to archive an email mailbox. [Google Takeout](https://takeout.google.com/settings/takeout) exports emails from gmail in this format.

```sh
# Retrieve the subject lines of all emails in test.mbox
$ chronicle-etl --extractor email:mbox --input ~/Downloads/inbox.mbox --fields subject
```

## Available Connectors
### Extractors

#### `imap`
Extractor for importing recent emails from an IMAP server.

##### Settings

- `since`: Retrieve emails since this date
- `until`: Retrieve emails until this date
- `username`
- `password`
- `host`: (default: imap.gmail.com)
- `port`: (default: 993) Use 143 for unencrypted connections
- `mailbox`: (default: "[Gmail]/All Mail")
- `search_query`: When using Gmail, you can pass in a search query (`from:foo has:attachment`) to filter messages by

For accessing Gmail, you can create a one-time [app password](https://myaccount.google.com/apppasswords). Your email address is your username.

#### `mbox`
Extractor for importing emails from an MBOX file

##### Settings
- `input`: A path to an .mbox file

### Transformers

#### `email`
Transform an email (in the form of a string) into Chronicle Schema

##### Settings
- `body_as_markdown`: (default: false) Whether to convert the email body into markdown
- `remove_signature`: (default: true) Whether to attempt to strip out the email signature (using the [`email_reply_parser`](https://github.com/github/email_reply_parser) gem)
