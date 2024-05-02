require 'chronicle/etl'
require 'mail'
require 'tempfile'

module Chronicle
  module Email
    class MboxExtractor < Chronicle::ETL::Extractor
      register_connector do |r|
        r.source = :email
        r.type = :message
        r.strategy = :mbox
        r.description = 'an .mbox file'
      end

      setting :input, required: true

      # mbox format is a bunch of emails concatanated together, separated
      # by a line that starts with "From "
      NEW_EMAIL_REGEX = Regexp.new('^From [^\s]+ .{24}')

      def results_count
        File.foreach(@filename).sum do |line|
          line.scan(NEW_EMAIL_REGEX).count
        end
      end

      def prepare
        @filename = @config.input.first
      end

      def extract
        file = File.open(@filename)
        tmp = Tempfile.new('chronicle-mbox')

        # Read the .mbox file line by line and look for a header that indicates
        # the start of a new email. As we read line by line, we save to a tmp
        # file and then read it back when we notice the next header.
        # Doing it this way is a lot faster than saving each line to a
        # a variable, especially when we're reading emails with large binary
        # attachments.
        #
        # TODO: make this thread-safe (one tmp file per email?)
        file.each do |line|
          if line =~ (NEW_EMAIL_REGEX) && File.size(tmp).positive?
            tmp.rewind

            email = Mail.new(tmp.read)
            data = {
              raw: email,
              time: email.date&.to_time,
              subject: email.subject,
              from: email&.from&.join(', '),
              to: email&.to&.join(', ')
            }
            yield build_extraction(data:)
            tmp.truncate(0)
            tmp.rewind
          end
          tmp.write(line)
        end
      ensure
        tmp.close
        tmp.unlink
        file.close
      end
    end
  end
end
