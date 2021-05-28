# Classes for each distinct kind of element of Simple's syntax: numbers, addition, multiplication, etc.
#
# The Struct class contains getter and setter methods determined by the arguments passed into .new().
#
# Since Struct has a generic definition of #inspect (i.e. the string representation in IRB) and #to_s (used when printing to standard out), we'll override these methods to make the AST easier to see.
#
# Order of implementation
#   1. Simple structures (i.e. expressions) as classes
#   2. Methods for reducing expressions
#     2a. distinguish reducible expressions (Add, Multiply) and not (Number) => #reducible?
#     2b. implement #reduction on appropriate classes
#                 Add reduction pattern: 
#                  reducible lhs => reduce by instantiating new Add; 
#                  reducible rhs => reduce by instantiating new Add;
#                  two irreducible => add together
#   3. To maintain state (operation of continuously evaluating expressions) => virtual machine
#   4. Add simple values (Boolean) and operations (comparison operators)
#   5. Variables
#     5a. Reducing vars requires storing mapping of vars with values, i.e. environment => Hash
#     5b. Environment => { var_name: expr_object }
#     5c. Environment is now passed into every #reduce; VM now holds onto environment
#   6. Statements: exprs evaluate to other exprs, statements evaluate to change machine state
#     6a. so far only state is environment, so statements will produce new environments
#     6b. Simplest statement => DoNothing (halt)
#     6c. Assignment statement => Reduce expressions, update environment
#         Reduction pattern:
#                 if expression reducible => reduce expr, environment unchanged
#                 if can't be reduced => update enviro, halt => [DoNothing, { var => expr }]
#   7. Conditional statements: if condition (x) then consequence else alternative
#         Reduction pattern:
#                 if condition can be reduced, reduce it => new conditional and unchanged env
#                 if condition is true => reduce to consequence statement, unchanged env
#                 if condition is false => reudce to alternative statement, unchanged env
#         Note: else statements: use an 'if' statement where the alternative is 'do-nothing'
#   8. Seqeuence statements: connects two statements
#         Reduction pattern: 
#                 if first statement is 'do-nothing', reduce to second statement and original env
#                 if first statement not 'do-nothing', reduce it => new sequence, reduced environment, producing
#   9. While statement: contains a condition and a body
#         Unroll one level of the while loop, by reducing it to an 'if' statement that performs a single iteration
#         Then repeat the original 'while' => check condition, evaluate body, start again
#         Reduction pattern:
#               reduce 'while (condition) { body }' to 
#                 'if (condition) { body ; while (condition) { body } } else { do-nothing }'
#
#   10. Add Big-Step semantics (#evaluate) for each class
#   11. Add Denotational semantics (#to_ruby) for each class
#         Using proc (namely proc.call) on an eval (e) function to evaluate within Ruby

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

## Statements

class DoNothing
  def to_s
    "do-nothing"
  end

  def inspect
    "#{self}"
  end

  def ==(other_statement)
    other_statement.instance_of?(DoNothing)
  end

  def reducible?
    false
  end

  def evaluate(environment)
    environment
  end

  def to_ruby
    '-> e { e }'
  end
end

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge({ name => expression })]
    end
  end

  def evaluate(environment)
    environment.merge({ name => expression.evaluate(environment) })
  end

  def to_ruby
    "-> e { e.merge({ #{name.inspect} => (#{expression.to_ruby}).call(e) }) }"
  end
end

class If < Struct.new(:condition, :consequence, :alternative)
  def to_s
    "if (#{condition}) { #{consequence} } else { #{alternative} }"
  end

  def inspect 
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if condition.reducible?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    else
      case condition
      when Boolean.new(true)
        [consequence, environment]
      when Boolean.new(false)
        [alternative, environment]
      end
    end
  end

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      consequence.evaluate(environment)
    when Boolean.new(false)
      alternative.evaluate(environment)
    end
  end

  def to_ruby
    "-> e { if (#{condition.to_ruby}).call(e)" +
      " then (#{consequence.to_ruby}).call(e)" +
      " else (#{alternative.to_ruby}).call(e)" +
      " end }"
  end
end

class Sequence < Struct.new(:first, :second)
  def to_s
    "#{first}; #{second}"
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    case first
    when DoNothing.new
      [second, environment]
    else
      reduced_first, reduced_environment = first.reduce(environment)
      [Sequence.new(reduced_first, second), reduced_environment]
    end
  end

  def evaluate(environment)
    second.evaluate(first.evaluate(environment))
  end

  def to_ruby
    "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
  end
end

class While < Struct.new(:condition, :body)
  def to_s
    "while (#{condition}) { #{body} }"
  end

  def inspect
    "#{self}"
  end

  def reducible?
    true
  end

  def reduce(environment)
    [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
  end

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      evaluate(body.evaluate(environment))
    when Boolean.new(false)
      environment
    end
  end

  def to_ruby
    "-> e {" +
      " while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e); end;" +
      " e" +
      " }"
  end
end

## Virtual Machine ##

class Machine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end
  
  def run
    while statement.reducible?
      puts "#{statement}, #{environment}"
      step
    end

    puts "#{statement}, #{environment}"
  end
end
