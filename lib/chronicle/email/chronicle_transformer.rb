require 'chronicle/etl'
require 'mail'
require 'timeout'
require 'email_reply_parser'

module Chronicle
  module Email
    class ChronicleTransformer < Chronicle::Etl::Transformer
      def transform data
        message = Mail.new(data.b)
        build_messaged(message)
      end

      def build_messaged message
        {
          type: 'activities',
          attributes: {
            verb: 'messaged',
            end_at: message.date,
            provider: 'email',
            provider_id: message.message_id,
          },
          meta: { dedupe_on: 'verb,provider,provider_id'},
          relationships: {
            actor: { data: build_actor(message) },
            involved: { data: build_message(message) }
          }
        }
      end

      def build_actor message
        # sometimes From: fields are malformed and we can't build an
        # actor out of it.
        return unless message[:from] && message[:from].addrs && message[:from].addrs.any?

        {
          type: 'entities',
          attributes: {
            represents: 'identity',
            provider: 'email',
            slug: message[:from].addrs.first.address,
            title: message[:from].addrs.first.display_name
          },
          meta: { dedupe_on: 'represents,provider,slug'}
        }
      end

      def build_message message
        {
          type: 'entities',
          attributes: {
            represents: 'message',
            title: clean_subject(message.subject),
            body: clean_body(message),
            provider: 'email',
            provider_id: message.message_id
          },
          meta: { dedupe_on: 'represents,provider,provider_id'},
          relationships: {
            consumers: { data: build_consumers(message) },
            antecedents: { data: build_references(message) },
            owners: { data: build_account(message) },
            # contains: { data: build_attachments(message) }
          }
        }
      end

      def build_account message
        return unless account_email = [message.header['delivered-to']].flatten[0]&.value

        {
          type: 'entities',
          attributes: {
            represents: 'identity',
            provider: 'email',
            slug: account_email
          },
          meta: { dedupe_on: 'provider,slug,represents' }
        }
      end

      def build_consumers(message)
        to = []
        to += message[:to].addrs if message[:to]
        to += message[:cc].addrs.flatten.compact if message[:cc]

        to.collect do |consumer|
          {
            type: 'entities',
            attributes: {
              represents: 'identity',
              provider: 'email',
              slug: consumer.address,
              title: consumer.display_name
            },
            meta: { dedupe_on: 'provider,slug' }
          }
        end
      end

      def build_references(message)
        references = [message.references].flatten.compact
        references.collect{|reference|
          {
            type: 'entities',
            attributes: {
              represents: 'message',
              provider: 'email',
              provider_id: reference
            },
            meta: { dedupe_on: 'represents,provider,provider_id' }
          }
        }
      end

      def clean_subject(subject)
        subject&.encode("UTF-8", invalid: :replace, undef: :replace)
      end

      def clean_body message
        # FIXME: this all needs to be refactored

        if message.multipart?
          body = message.text_part&.decoded rescue Mail::UnknownEncodingType
        else
          body = message.body&.decoded rescue Mail::UnknownEncodingType
        end

        if body && body != ""
          begin
            # regex in EmailReplyParse gem seems to get into infinite loops with
            # certain long bodies that have binary data
            parsed_body = Timeout::timeout(5) do
              EmailReplyParser.parse_reply(body)
            end
          rescue Timeout::Error => e
            return nil
          rescue StandardError => e  # Whackamole game with these parsing / encoding problems
            return nil
          end

          # Force UTF-8 encoding
          return parsed_body.encode("UTF-8", invalid: :replace, undef: :replace)
        else
          return nil
        end
      end
    end
  end
end
