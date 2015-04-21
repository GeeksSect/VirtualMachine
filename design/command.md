### This *folder* should contain proposals for code design.

## 1. Command Proposal 

I propose to implement typed commands, it could be done like follows:

#### D:

```d
class Command
{
    ...
};

class GroupedCommands1 : Command
{
    ...
};

class GroupedCommands2 : Command
{
    ...
};

class MOV : GroupedCommands1
{
    ...
};

class ADD : GroupedCommands2
{
    ...
};
```
and then use:
```d

void sw(T : Command)(ref T cmd)
{
    switch(typeid(cmd).name)
    {
        case "models.some.MOV":
            ...
            break;

        case "models.some.ADD":
            ...
            break;

        case "models.some.INC":
            ...
            break;

        default:
            ...
            break;
    }
}

```

#### Or in Scala:
```scala
class Command

class GroupCommand1 extends Command

class GroupCommand2 extends Command

class MOV extends GroupCommand1

class ADD extends GroupCommand2
```
and use:
```scala
def sw: PartialFunction[Command, Unit] = {
    case _: MOV => ...
    case _: ADD => 
      ...
    case _: Command => println("Command")
  }
```

## Votes:

\+ [alexFrankfurt](https://github.com/alexFrankfurt), [krucios](https://github.com/krucios) 

\- [Harald Zealot](https://github.com/HaraldZealot), 



