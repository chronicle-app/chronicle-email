require 'chronicle/etl'
require 'mail'
require 'timeout'
require 'email_reply_parser'
require 'reverse_markdown'

module Chronicle
  module Email
    class EmailTransformer < Chronicle::ETL::Transformer
      register_connector do |r|
        r.description = 'an email object'
        r.provider = 'email'
        r.identifier = 'email'
      end

      setting :body_as_markdown, default: false
      setting :remove_signature, default: true

      def transform
        build_messaged
      end

      def id
        message.message_id || raise(Chronicle::ETL::UntransformableRecordError, "Email doesn't have an ID")
      end

      def timestamp
        message.date&.to_time || raise(Chronicle::ETL::UntransformableRecordError, "Email doesn't have a timestamp")
      end

      private

      def message
        @message ||= Mail.new(@extraction.data[:email])
      end

      def build_messaged
        record = ::Chronicle::ETL::Models::Activity.new
        record.verb = 'messaged'
        record.provider = 'email'
        record.provider_id = id
        record.end_at = timestamp

        record.dedupe_on << [:verb, :provider, :provider_id]

        record.actor = build_actor
        record.involved = build_message
        record
      end

      def build_actor
        # sometimes From: fields are malformed and we can't build an
        # actor out of it.
        raise(Chronicle::ETL::UntransformableRecordError, "Can't determine email sender") unless message[:from]&.addrs&.any?

        record = ::Chronicle::ETL::Models::Entity.new
        record.represents = 'identity'
        record.provider = 'email'
        record.slug = message[:from].addrs.first.address
        record.title = message[:from].addrs.first.display_name

        record.dedupe_on << [:represents, :provider, :slug]

        record
      end

      def build_message
        record = ::Chronicle::ETL::Models::Entity.new
        record.represents = 'message'
        record.title = clean_subject(message.subject)
        record.body = clean_body(message)
        record.provider = 'email'
        record.provider_id = id

        # TODO: handle consumer
        # TODO: handle email references
        # TODO: handle email account owner
        # TODO: handle attachments

        record
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
          body = body_to_markdown if @config.body_as_markdown
        end

        return if body == Mail::UnknownEncodingType
        return unless body && body != ""

        body = body_without_signature(body) if @config.remove_signature

        # Force UTF-8 encoding
        body.encode("UTF-8", invalid: :replace, undef: :replace)
      end

      def body_to_markdown(body)
        ReverseMarkdown.convert(body)
      rescue StandardError
        # Fall back to unparsed body? Raise Untransformable error?
      end

      def body_without_signature(body)
        # FIXME: regex in EmailReplyParse gem seems to get into infinite loops
        #   with certain long bodies that have binary data
        parsed_body = Timeout::timeout(5) do
          EmailReplyParser.parse_reply(body)
        end
      rescue Timeout::Error, StandardError => e
        return body
      end
    end
  end
end
