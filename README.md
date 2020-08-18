# Chronicle::Email

Email importer for [chronicle-etl](https://github.com/chronicle-app/chronicle-etl)

## Available classes
- `email:mbox` - Extractor for processing .mbox files
- `email:chronicle` - Transformer that converts an email into a chronicle schema

## Usage

```bash
gem install chronicle-etl
gem install chronicle-email

chronicle-etl --extractor email:mbox --extractor-opts filename:"./mail.mbox" --transformer email:chronicle --loader stdout
```