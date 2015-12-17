require 'rird/blocks/lexer'
gem 'test-unit'
require 'test/unit'

class TestRirdBlocksLexer < Test::Unit::TestCase
  def assert_line(lexer, raw_line, tag, lineno: 1, lead_space: :empty, headchar: :empty, inner_space: :empty, is_next_eof: true)
    assert_block do
      line = lexer.read
      assert_equal raw_line, line.string
      assert_equal lineno,   line.lineno
      assert_equal tag,      line.tag
      lead_space  == :empty ? assert_empty(line.lead_space)  : assert_equal(lead_space,  line.lead_space)
      headchar    == :empty ? assert_empty(line.headchar)    : assert_equal(headchar,    line.headchar)
      inner_space == :empty ? assert_empty(line.inner_space) : assert_equal(inner_space, line.inner_space)
      assert_eof(lexer) if is_next_eof
      true
    end
  end

  def assert_eof(lexer)
    assert_equal :eof, lexer.read.tag
    true
  end

  def test_whiteline
    lexer = Rird::Blocks::Lexer.new("  \n", "(test)")
    assert_line lexer, "  \n", :whiteline
  end

  def test_comment
    lexer = Rird::Blocks::Lexer.new("# comment\n", "(test)")
    assert_line lexer, "# comment\n", :comment
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
    assert_line lexer, src, tag, headchar: headchar
  end

  def test_include
    lexer = Rird::Blocks::Lexer.new("<<< inc\n", "(test)")
    assert_line lexer, "<<< inc\n", :include
  end

  def test_itemlist
    lexer = Rird::Blocks::Lexer.new("  * item\n", "(test)")
    assert_line lexer, "  * item\n", :itemlist, lead_space: "  ", headchar: "*", inner_space: " "
  end

  def test_enumlist
    lexer = Rird::Blocks::Lexer.new("  (1) item\n", "(test)")
    assert_line lexer, "  (1) item\n", :enumlist, lead_space: "  ", headchar: "(1)", inner_space: " "
  end

  def test_desclist
    lexer = Rird::Blocks::Lexer.new("  : term\n", "(test)")
    assert_line lexer, "  : term\n", :desclist, lead_space: "  ", headchar: ":", inner_space: " "
  end

  def test_methodlist
    lexer = Rird::Blocks::Lexer.new("  --- term\n", "(test)")
    assert_line lexer, "  --- term\n", :methodlist, lead_space: "  ", headchar: "---", inner_space: " "
  end

  def test_stringline
    lexer = Rird::Blocks::Lexer.new("stringline\n", "(test)")
    assert_line lexer, "stringline\n", :stringline
  end

  def test_stringline_verbatim
    lexer = Rird::Blocks::Lexer.new("  stringline\n", "(test)")
    assert_line lexer, "  stringline\n", :stringline, lead_space: "  "
  end

  def test_unread
    lexer = Rird::Blocks::Lexer.new("  stringline\n", "(test)")
    line = lexer.read
    lexer.unread line
    assert_line lexer, "  stringline\n", :stringline, lead_space: "  "
  end

  def test_unread_raw
    lexer = Rird::Blocks::Lexer.new("", "(test)")
    lexer.unread "  stringline\n", raw: true
    assert_line lexer, "  stringline\n", :stringline, lead_space: "  "
  end
end

