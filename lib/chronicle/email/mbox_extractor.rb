require 'chronicle/etl'
require 'mail'
require 'tempfile'

module Chronicle
  module Email
    class MboxExtractor < Chronicle::Etl::Extractor
      # mbox format is a bunch of emails concatanated together, separated
      # by a line that starts with "From "
      NEW_EMAIL_REGEX = Regexp.new('^From [^\s]+ .{24}')

      def results_count
        file = File.open(@options[:filename])
        count = 0
        file.each do |line|
          count += 1 if line =~ NEW_EMAIL_REGEX
        end
        return count
      end

      def extract
        file = File.open(@options[:filename])
        tmp = Tempfile.new('chronicile-mbox')

        file.each do |line|
          if line =~ NEW_EMAIL_REGEX
            if File.size(tmp) > 0
              tmp.rewind
              email = tmp.read
              yield email
              tmp.truncate(0)
              tmp.rewind
            end
          end
          tmp.write(line)
        end
        file.close
      end
    end
  end
end
