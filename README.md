A port of the [Rimu Markup language](https://srackham.github.io/rimu/) written in the Dart
language.


## Features
Functionally identical to the [TypeScript
implementation](https://github.com/srackham/rimu) version 11.4.x.


## Using the Rimu package
Example usage:

``` dart
import 'package:rimu/rimu.dart';

main(List<String> arguments) {
  print(render('Hello *Rimu*!'));
}
```

See also Rimu [API documentation](https://srackham.github.io/rimu/reference.html#api).


## CLI command
The Dart port of the [Rimu CLI
command](https://srackham.github.io/rimu/reference.html#rimuc-command) can be
run as a script, for example:

    dart ./bin/rimuc.dart --version

Or compiled to a native executable, for example:

    dart compile exe ./bin/rimuc.dart -o ~/local/bin/rimudart


## Building
1. Clone source repo from Github:

        git clone git@github.com:srackham/rimu-dart.git

2. Build and test:

        cd rimu-dart/
        dart pub get
        make


## Learn more
Read the [documentation](https://srackham.github.io/rimu/reference.html) and experiment
with Rimu in the [Rimu
Playground](http://srackham.github.io/rimu/rimuplayground.html).


## Implementation
- The largely one-to-one correspondence between the canonical
  [TypeScript code](https://github.com/srackham/rimu) and the Dart code
  eased porting and debugging.  This will also make it easier to
  cross-port new features and bug-fixes.

- All Rimu implementations share the same JSON driven test suites
  comprising over 300 compatibility checks.