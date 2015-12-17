module Rird
  module Blocks
    class Compiler
      def compile(lexer)
        compile_blocks lexer, ""
      end

      private

      def compile_blocks(lexer, baseline)
        blocks = []
        loop do
          line = lexer.read
          case line.tag
          when :eof then break
          when :comment, :whiteline then next
          end
          lexer.unread line
          break if block_given? && yield(line)
          baseline ||= line.lead_space
          break if line.lead_space.size < baseline.size
          blocks << send("compile_#{line.tag}", lexer, baseline)
        end
        blocks.compact
      end
    end
  end
end
