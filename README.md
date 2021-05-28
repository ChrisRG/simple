# Building up the SIMPLE language

To test the language, we can use the main Ruby REPL, IRB.

We can either initialize IRB while loading the file directly:
```
irb -r ./expression.rb
```

Otherwise we can load files within IRB:

```
$ irb
>> load './expression.rb'
=> true
>> Add.new(Multiply.new(Number.new(1), Number.new(2)),
  Multiply.new(Number.new(3), Number.new(4))
  )
=> #<struct Add 
    left=#<struct Multiply 
      left=#<struct Number value=1>, 
      right=#<struct Number value=2>
    >, 
    right=#<struct Multiply 
      left=#<struct Number value=3>, 
      right=#<struct Number value=4>
    >
   >
```

### Overview of steps in implementing SIMPLE

Classes for each distinct kind of element of Simple's syntax: numbers, addition, multiplication, etc.

 The Struct class contains getter and setter methods determined by the arguments passed into .new().

 Since Struct has a generic definition of #inspect (i.e. the string representation in IRB) and #to_s (used when printing to standard out), we'll override these methods to make the AST easier to see.

 Order of implementation
   1. Simple structures (i.e. expressions) as classes
   2. Methods for reducing expressions
     2a. distinguish reducible expressions (Add, Multiply) and not (Number) => #reducible?
     2b. implement #reduction on appropriate classes
                 Add reduction pattern: 
                
                  reducible lhs => reduce by instantiating new Add; 
                  reducible rhs => reduce by instantiating new Add;
                  
   3. To maintain state (operation of continuously evaluating expressions) => virtual machine
   4. Add simple values (Boolean) and operations (comparison operators)
   5. Variables
     5a. Reducing vars requires storing mapping of vars with values, i.e. environment => Hash
     5b. Environment => { var_name: expr_object }
     5c. Environment is now passed into every #reduce; VM now holds onto environment
   6. Statements: exprs evaluate to other exprs, statements evaluate to change machine state
     6a. so far only state is environment, so statements will produce new environments
     6b. Simplest statement => DoNothing (halt)
     6c. Assignment statement => Reduce expressions, update environment
         Reduction pattern:

                 if expression reducible => reduce expr, environment unchanged
                 if can't be reduced => update enviro, halt => [DoNothing, { var => expr }]
                 
   7. Conditional statements: if condition (x) then consequence else alternative
         Reduction pattern:
         
                 if condition can be reduced, reduce it => new conditional and unchanged env
                 if condition is true => reduce to consequence statement, unchanged env
                 if condition is false => reudce to alternative statement, unchanged env
                 
         Note: else statements: use an 'if' statement where the alternative is 'do-nothing'
   8. Seqeuence statements: connects two statements
         Reduction pattern: 
         
                 if first statement is 'do-nothing', reduce to second statement and original env
                 if first statement not 'do-nothing', reduce it => new sequence, reduced environment, producing
                 
   9. While statement: contains a condition and a body
         Unroll one level of the while loop, by reducing it to an 'if' statement that performs a single iteration
         Then repeat the original 'while' => check condition, evaluate body, start again
         Reduction pattern:
         
               reduce 'while (condition) { body }' to 'if (condition) { body ; while (condition) { body } } else { do-nothing }'

   10. Add Big-Step semantics (#evaluate) for each class
   11. Add Denotational semantics (#to_ruby) for each class
         Using Ruby's proc (namely proc.call) on an eval (e) function to evaluate within Ruby
