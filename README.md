# sprite-d
A tiny and featureless dependency injection for D Language

## Example

```d
import std.stdio;
import sprite;

class Printer {
    public void print(string message) {
        writefln("Print message: [ %s ]", message);
    }
}

class Spooler {
    @Inject
    private Printer printer;

    public void print(string message) {
        printer.print(message);
    }
}

class TextEditor: HavePostConstruct {
    @Inject
    private Spooler spooler;
    private string message;

    public void write(string message) {
        this.message = message;
    }

    public void print() {
        spooler.print(message);
    }

    void postConstruct() {
        writeln("TextEditor ready!");
    }
}

void main() {
    auto distiller = new shared Distiller();

    distiller << new TextEditor;
    distiller << new Printer;
    distiller << new Spooler;

    auto editor = cast (TextEditor) distiller;
    
    editor.write("Hello, D Language");
    editor.print();
}
```