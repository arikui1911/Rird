require 'rird/blocks/compiler'
require 'rird/blocks/lexer'
gem 'test-unit'
require 'test/unit'

class TestRirdBlocksCompiler < Test::Unit::TestCase
  def test_headline
    lexer = Rird::Blocks::Lexer.new("= headline\n", "(test)")
    compiler = Rird::Blocks::Compiler.new
    blocks = compiler.compile(lexer)
    assert_equal 1, blocks.size
    assert_equal({headline: {line: 1, level: 1, text: "headline"}}, blocks.first)
  end

  def test_include
    lexer = Rird::Blocks::Lexer.new("<<< include\n", "(test)")
    compiler = Rird::Blocks::Compiler.new
    blocks = compiler.compile(lexer)
    assert_equal 1, blocks.size
    assert_equal({include: {line: 1, arg: "include"}}, blocks.first)
  end
end

