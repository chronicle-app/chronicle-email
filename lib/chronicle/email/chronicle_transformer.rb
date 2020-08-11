require 'chronicle/etl/transformers/transformer'

module Chronicle
  module Email
    class ChronicleTransformer < Chronicle::Etl::Transformers::Transformer
      def transform data
        message = Mail.new(data)
        return {
          data: message.date,
          id: message.message_id,
          title: message.subject
        }
      end
    end
  end
end