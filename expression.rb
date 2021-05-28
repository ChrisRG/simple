## Expressions
#   Number
#   Add
#   Multiply
#   Boolean
#   LessThan
#   Variable

class Number < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "#{self}"
  end

  def reducible?
    false
  end

  def evaluate(environment)
    self
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class Add < Struct.new(:left, :right)
  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right)
    elsif right.reducible?
      Add.new(left, right.reduce(environment))
    else
      Number.new(left.value + right.value)
    end
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
  end
end

class Multiply < Struct.new(:left, :right)
  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Multiply.new(left.reduce(environment), right)
    elsif right.reducible?
      Multiply.new(left, right.reduce(environment))
    else
      Number.new(left.value * right.value)
    end
  end
  
  def evaluate
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "#{self}"
  end

  def reducible?
    false
  end

  def evaluate(environment)
    self
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      LessThan.new(left.reduce(environment), right)
    elsif right.reducible?
      LessThan.new(left, right.reduce(environment))
    else
      Boolean.new(left.value < right.value)
    end
  end

  def evaluate
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
  end
end

class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    environment[name]
  end

  def evaluate(environment)
    environment[name]
  end

  def to_ruby
    "-> e { e[#{name.inspect}] }"
  end
end
