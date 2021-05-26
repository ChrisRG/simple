# Building up the SIMPLE language

To test the language, we can use the main Ruby REPL, IRB.

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
