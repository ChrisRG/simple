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
#         e.g. for Add, the pattern becomes: 
#                 reducible lhs => reduce by instantiating new Add; 
#                 reducible rhs => reduce by instantiating new Add;
#                 two irreducible => add together
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
#         e.g. Reduction pattern:
#                 if expression reducible => reduce expr, environment unchanged
#                 if can't be reduced => update enviro, halt => [DoNothing, { var => expr }]
#   7. Conditional statements: if condition (x) then consequence else alternative
#
#         

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
end

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
