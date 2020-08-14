require 'chronicle/etl'
require 'mail'

module Chronicle
  module Email
    class ChronicleTransformer < Chronicle::Etl::Transformer
      def transform data
        message = Mail.new(data.b)

        {
          date: message.date,
          id: message.message_id,
          title: message.subject
        }
      end
    end
  end
end
