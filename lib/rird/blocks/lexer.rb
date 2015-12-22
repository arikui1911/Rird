module Rird
  module Blocks
    Line = Struct.new(:string, :lineno, :tag, :lead_space, :headchar, :inner_space) do
      def inner_indent
        "#{lead_space}#{' ' * headchar.size}#{inner_space}"
      end
    end

    class Lexer
      include Enumerable

      def initialize(src, filename, initial_lineno = 1)
        @src      = src
        @filename = filename
        @lineno   = initial_lineno
        @enum     = lex()
        @buf      = []
      end

      def read
        @buf.empty? ? @enum.next : @buf.pop
      end

      def unread(line, raw: false)
        if raw
          line = match(line)
        else
          return nil if line.tag == :eof
        end
        @buf.push line
        nil
      end

      def peek
        @buf.empty? ? read().tap{|line| unread line } : @buf.last
      end

      def each
        return enum_for(__method__) unless block_given?
        loop do
          line = peek()
          break if line.tag == :eof
          yield line
          read
        end
      end

      private

      # !!! This method never ends
      def lex
        return enum_for(__method__) unless block_given?
        @src.each_line do |line|
          yield match(line)
          @lineno += 1
        end
        eof = Line.new("", @lineno, :eof, "", "", "")
        loop { yield eof }
      end

      BLOCKS_RE = {
        whiteline:  /^\s*$/,
        comment:    /^#/,
        headline1:  /^(?<headchar>={1,4})(?!=)\s*\S/,
        headline2:  /^(?<headchar>\+{1,2})(?!\+)\s*\S/,
        include:    /^(?<headchar><<<)\s*\S/,
        itemlist:   /^(?<lead_space>\s*)(?<headchar>\*)(?<inner_space>\s*)\S/,
        enumlist:   /^(?<lead_space>\s*)(?<headchar>\(\d+\))(?<inner_space>\s*)\S/,
        desclist:   /^(?<lead_space>\s*)(?<headchar>:)(?<inner_space>\s*)\S/,
        methodlist: /^(?<lead_space>\s*)(?<headchar>---)(?<inner_space>\s*)\S/,
        stringline: /^(?<lead_space>\s*)\S/,
      }

      def match(raw_line)
        line = Line.new(raw_line, @lineno, nil, "", "", "")
        BLOCKS_RE.each do |tag, re|
          if m = re.match(raw_line)
            line.tag = tag
            case tag
            when :headline1, :headline2, :include
              line.headchar = m["headchar"]
            when :itemlist, :enumlist, :desclist, :methodlist
              line.lead_space = m["lead_space"]
              line.headchar = m["headchar"]
              line.inner_space = m["inner_space"]
            when :stringline
              line.lead_space = m["lead_space"]
            end
            return line
          end
        end
        raise Exception, "must not happen: #{raw_line.inspect}"
      end
    end
  end
end
