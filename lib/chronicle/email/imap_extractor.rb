require 'net/imap'

module Chronicle
  module Email
    class IMAPExtractor < Chronicle::ETL::Extractor
      register_connector do |r|
        r.provider = 'email'
        r.description = 'imap server'
        r.identifier = 'imap'
      end

      setting :host, required: true, default: 'imap.gmail.com'
      setting :port, type: :numeric, required: true, default: 993
      setting :mailbox, required: true, default: '[Gmail]/All Mail'
      setting :username, required: true
      setting :password, required: true
      setting :search_query

      def prepare
        @connection = create_connection
        @message_ids = fetch_message_ids
      end

      def results_count
        @message_ids.count
      end

      def extract
        @message_ids.each do |message_id|
          message = fetch_message(message_id)
          yield Chronicle::ETL::Extraction.new(data: { email: message.attr["BODY[]"]} )
        end
      end

      private

      def create_connection
        connection = Net::IMAP.new(@config.host, @config.port, true)
        connection.login(@config.username, @config.password)
        connection.select(@config.mailbox)
        connection
      rescue Net::IMAP::NoResponseError => e
        raise(Chronicle::ETL::ExtractionError, "Error connecting to IMAP server. Please check username and password")
      end

      def fetch_message_ids
        keys = gmail_mode? ? search_keys_gmail : search_keys_default
        @connection.search(keys)
      rescue Net::IMAP::BadResponseError => e
        raise(Chronicle::ETL::ExtractionError, "Error searching IMAP server for messages")
      end

      def fetch_message(message_id)
        response = @connection.fetch(message_id, "BODY.PEEK[]")
        raise(Chronicle::ETL::ExtractionError, "Error loading message") unless response

        return response[0]
      end

      def search_keys_gmail
        # Gmail offers an extension to IMAP that lets us use gmail queries
        q = ""

        # First, we ignore drafts beacuse they break a lot of assumptions we
        # make when when processing emails (lack of timestamps, ids, etc)
        q = "-label:draft"

        # We use UNIX timestamps in gmail filters which let us do more precise
        # since/until compared with date-based imap filters
        q += " after:#{@config.since.to_i}" if @config.since
        q += " before:#{@config.until.to_i}" if @config.until
        q += " #{@config.search_query}" if @config.search_query

        ["X-GM-RAW", q]
      end

      def search_keys_default
        keys = []
        # TODO: test out non-gmail IMAP searching (for @config.search_query)
        keys += ['SINCE', Net::IMAP.format_date(@config.since)] if @config.since
        keys += ['BEFORE', Net::IMAP.format_date(@config.until)] if @config.until
      end

      def gmail_mode?
        @config.host == 'imap.gmail.com'
      end
    end
  end
end