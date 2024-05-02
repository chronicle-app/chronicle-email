require 'chronicle/etl'
require 'chronicle/models'
require 'timeout'
require 'email_reply_parser'
require 'reverse_markdown'

module Chronicle
  module Email
    class EmailTransformer < Chronicle::ETL::Transformer
      register_connector do |r|
        r.source = :email
        r.type = :message
        r.description = 'an email object'
        r.from_schema = :extraction
        r.to_schema = :chronicle
      end

      setting :body_as_markdown, default: false
      setting :remove_signature, default: true

      def transform(record)
        build_messaged(record.data[:raw])
      end

      private

      def build_messaged(email)
        timestamp = email.date&.to_time || raise(Chronicle::ETL::UntransformableRecordError,
          "Email doesn't have a timestamp")

        email.message_id || raise(Chronicle::ETL::UntransformableRecordError, "Email doesn't have an ID")

        Chronicle::Models::CommunicateAction.new do |r|
          r.end_time = timestamp
          r.agent = build_agent(email[:from])
          r.source = 'email'
          r.source_id = email.message_id
          r.object = build_message(email)
        end
      end

      def build_agent(from)
        raise(Chronicle::ETL::UntransformableRecordError, "Can't determine email sender") unless from&.addrs&.any?

        build_person(from.addrs.first)
      end

      def build_message(email)
        Chronicle::Models::Message.new do |r|
          r.name = clean_subject(email.subject)
          r.text = clean_body(email)
          r.source = 'email'
          r.source_id = email.message_id

          r.recipient = email[:to]&.addrs&.map { |addr| build_person(addr) }

          # TODO: handle email references
          # TODO: handle email account owner
          # TODO: handle attachments

          r.dedupe_on << %i[source source_id type]
        end
      end

      def build_person(addr)
        Chronicle::Models::Person.new do |r|
          r.source = 'email'
          r.slug = addr.address
          r.name = addr.display_name
          r.dedupe_on << %i[represents provider slug]
        end
      end

      def clean_subject(subject)
        subject&.encode('UTF-8', invalid: :replace, undef: :replace)
      end

      def clean_body(message)
        # FIXME: this all needs to be refactored
        if message.multipart?
          body = begin
            message.text_part&.decoded
          rescue StandardError
            Mail::UnknownEncodingType
          end
        else
          body = begin
            message.body&.decoded
          rescue StandardError
            Mail::UnknownEncodingType
          end
          body = body_to_markdown if @config.body_as_markdown
        end

        return if body == Mail::UnknownEncodingType
        return unless body && body != ''

        body = body_without_signature(body) if @config.remove_signature

        # Force UTF-8 encoding
        body.encode('UTF-8', invalid: :replace, undef: :replace)
      end

      def body_to_markdown(body)
        ReverseMarkdown.convert(body)
      rescue StandardError
        # Fall back to unparsed body? Raise Untransformable error?
      end

      def body_without_signature(body)
        # FIXME: regex in EmailReplyParse gem seems to get into infinite loops
        #   with certain long bodies that have binary data
        Timeout.timeout(5) do
          EmailReplyParser.parse_reply(body)
        end
      rescue Timeout::Error, StandardError
        body
      end
    end
  end
end
