module Rird
  module Blocks
    class Compiler
      def compile(lexer)
        compile_blocks lexer, ""
      end

      attr_accessor :warn_proc

      private

      WARN_DEFAULT = ->(lexer, msg){
        $stderr.puts "#{lexer.filename}:#{lexer.peek.lineno}: #{msg}"
      }

      def warning(lexer, msg)
        (warn_proc || WARN_DEFAULT).call(lexer, msg)
      end

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

      def compile_headline1(lexer, _)
        do_compile_headline lexer, 0
      end

      def do_compile_headline(lexer, geta)
        line  = lexer.read
        level = line.headchar.size + geta
        text  = headchar_trailer(line)
        {headline: {line: line.lineno, level: level, text: text}}
      end

      def compile_include(lexer, _)
        line = lexer.read
        arg  = headchar_trailer(line)
        {include: {line: line.lineno, arg: arg}}
      end

      def compile_itemlist(lexer, _)
        do_compile_list :itemlist, lexer
      end

      def compile_enumlist(lexer, _)
        do_compile_list :enumlist, lexer
      end

      def do_compile_list(list_tag, lexer)
        first = lexer.peek
        items = []
        loop do
          line = lexer.peek
          break if line.tag == :eof
          break unless line.lead_space.size == first.lead_space.size && line.tag == list_tag
          items << do_compile_listitem(list_tag, lexer)
        end
        {list_tag => {line: first.lineno, items: items.compact}}
      end

      def do_compile_listitem(list_tag, lexer)
        first = lexer.read
        inner = inner_indent("#{first.lead_space}#{' ' * first.headchar.size}#{first.inner_space}")
        lexer.unread "#{inner}#{first.string[inner.size..-1]}"
        lead_textblock = compile_stringline(lexer, inner)
        blocks = compile_blocks(lexer, inner){|line|
          line.tag == list_tag && line.lead_space.size == first.lead_space.size
        }
        blocks.unshift(lead_textblock)

        # skip trailing comment and whiteline after listitem
        loop do
          line = line.read
          break if line.tag == :eof
          unless line.tag == :comment || line.tag == :whiteline
            lexer.unread line
            break
          end
        end

        blocks
      end

      def compile_desclist(lexer, _)
        do_compile_dlist :desclist, lexer
      end

      def compile_methodlist(lexer, baseline)
        baseline.empty? or
          warning(lexer, "MethodList meight be allowed only to be toplevel in future release.")
        do_compile_dlist :methodlist, lexer
      end

      # FIXME: must skip trailing comment and whiteline after term or desc
      def compile_dlist(list_tag, lexer)
        first = lexer.peek
        items = []
        loop do
          term_line = lexer.read
          break if term_line.tag == :eof
          unless term_line.lead_space.size == first.lead_space.size && term_line.tag == list_tag
            lexer.unread term_line
            break
          end
          inner = inner_indent(term_line)
          term  = term_line.string[inner.size..-1]
          desc  = compile_blocks(lexer, nil){|line|
            line.tag == list_tag && line.lead_space.size == term_line.lead_space.size
          }
          items << [term, desc]
        end
        {list_tag => {line: first.lineno, items: items.compact}}
      end

      def compile_stringline(lexer, baseline)
        first = lexer.peek
        return do_compile_verbatim(lexer) unless first.lead_space == baseline
        lines = lexer.take_while{|line|
          case line.tag
          when :comment
            true
          when :stringline
            line.lead_space == baseline
          end
        }
        content = lines.map{|line| line.string[baseline.size..-1] }.join
        {textblock: {line: first.lineno, content: content}}
      end

  def compile_verbatim(f)
    first = f.peek
    buf = []
    while line = f.gets
      case line.tag
      when :stringline
        unless line.lead_space.size >= first.lead_space.size
          f.ungets line
          break
        end
        buf << line.string[first.lead_space.size..-1]
      when :comment
        ;
      else
        f.ungets line
        break
      end
    end
    {verbatim: {line: first.lineno, content: buf.join}}
  end

      def headchar_trailer(line)
        line.string[line.headchar.size..-1].strip
      end

      def inner_indent(line)
        "#{line.lead_space}#{' ' * line.headchar.size}#{line.inner_space}"
      end
    end
  end
end
