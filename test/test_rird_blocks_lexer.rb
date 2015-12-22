require 'rird/blocks/lexer'
gem 'test-unit'
require 'test/unit'

class TestRirdBlocksLexer < Test::Unit::TestCase
  def assert_line(line, raw_line, tag, lineno: 1, lead_space: :empty, headchar: :empty, inner_space: :empty)
    assert_block do
      assert_equal raw_line, line.string
      assert_equal lineno,   line.lineno
      assert_equal tag,      line.tag
      lead_space  == :empty ? assert_empty(line.lead_space)  : assert_equal(lead_space,  line.lead_space)
      headchar    == :empty ? assert_empty(line.headchar)    : assert_equal(headchar,    line.headchar)
      inner_space == :empty ? assert_empty(line.inner_space) : assert_equal(inner_space, line.inner_space)
      true
    end
  end

  def assert_eof(line)
    assert_block do
      assert_equal :eof, line.tag
      true
    end
  end

  def assert_line_and_eof(lexer, *args, **kwargs)
    assert_block do
      assert_line lexer.read, *args, **kwargs
      assert_eof lexer.read
      true
    end
  end

  def assert_lines(lines, *args_alist)
    assert_block do
      assert_equal lines.size, args_alist.size
      args_alist.zip(lines).each do |args, line|
        assert_line line, *args
      end
      true
    end
  end

  def assert_all_lines(lexer, *args_alist)
    assert_block do
      assert_lines lexer.each.to_a, *args_alist
      assert_eof lexer.read
      true
    end
  end

  def test_whiteline
    lexer = Rird::Blocks::Lexer.new("  \n", "(test)")
    assert_line_and_eof lexer, "  \n", :whiteline
  end

  def test_comment
    lexer = Rird::Blocks::Lexer.new("# comment\n", "(test)")
    assert_line_and_eof lexer, "# comment\n", :comment
  end

  data("Level 1"  => ["= headline\n",     :headline1,  "="],
       "Level 2"  => ["== headline\n",    :headline1,  "=="],
       "Level 3"  => ["=== headline\n",   :headline1,  "==="],
       "Level 4"  => ["==== headline\n",  :headline1,  "===="],
       "Level 5?" => ["===== headline\n", :stringline, :empty],
       "Level 5"  => ["+ headline\n",     :headline2,  "+"],
       "Level 6"  => ["++ headline\n",    :headline2,  "++"],
       "Level 7?" => ["+++ headline\n",   :stringline, :empty])
  def test_headline(data)
    src, tag, headchar = data
    lexer = Rird::Blocks::Lexer.new(src, "(test)")
    assert_line_and_eof lexer, src, tag, headchar: headchar
  end

  def test_include
    lexer = Rird::Blocks::Lexer.new("<<< inc\n", "(test)")
    assert_line_and_eof lexer, "<<< inc\n", :include, headchar: "<<<"
  end

  def test_itemlist
    lexer = Rird::Blocks::Lexer.new("  * item\n", "(test)")
    assert_line_and_eof lexer, "  * item\n", :itemlist, lead_space: "  ", headchar: "*", inner_space: " "
  end

  def test_enumlist
    lexer = Rird::Blocks::Lexer.new("  (1) item\n", "(test)")
    assert_line_and_eof lexer, "  (1) item\n", :enumlist, lead_space: "  ", headchar: "(1)", inner_space: " "
  end

  def test_desclist
    lexer = Rird::Blocks::Lexer.new("  : term\n", "(test)")
    assert_line_and_eof lexer, "  : term\n", :desclist, lead_space: "  ", headchar: ":", inner_space: " "
  end

  def test_methodlist
    lexer = Rird::Blocks::Lexer.new("  --- term\n", "(test)")
    assert_line_and_eof lexer, "  --- term\n", :methodlist, lead_space: "  ", headchar: "---", inner_space: " "
  end

  def test_stringline
    lexer = Rird::Blocks::Lexer.new("stringline\n", "(test)")
    assert_line_and_eof lexer, "stringline\n", :stringline
  end

  def test_stringline_verbatim
    lexer = Rird::Blocks::Lexer.new("  stringline\n", "(test)")
    assert_line_and_eof lexer, "  stringline\n", :stringline, lead_space: "  "
  end

  def test_unread
    lexer = Rird::Blocks::Lexer.new("  stringline\n", "(test)")
    line = lexer.read
    lexer.unread line
    assert_line_and_eof lexer, "  stringline\n", :stringline, lead_space: "  "
  end

  def test_unread_raw
    lexer = Rird::Blocks::Lexer.new("", "(test)")
    lexer.unread "  stringline\n", raw: true
    assert_line_and_eof lexer, "  stringline\n", :stringline, lead_space: "  "
  end

  def test_take_while
    lexer = Rird::Blocks::Lexer.new(<<-EOS, "(test)")
text
# comment
block

next tb
    EOS
    assert_lines(lexer.take_while{|line| line.tag == :stringline || line.tag == :comment },
                 ["text\n",      :stringline, lineno: 1],
                 ["# comment\n", :comment,    lineno: 2],
                 ["block\n",     :stringline, lineno: 3])
    assert_all_lines(lexer,
                     ["\n",        :whiteline,  lineno: 4],
                     ["next tb\n", :stringline, lineno: 5])
  end
end

