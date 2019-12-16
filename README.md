A port of the [Rimu Markup language](http://rimumarkup.org) written in the Dart
language.


## Features
Functionally identical to the [JavaScript
implementation](https://github.com/srackham/rimu) version 11.1 with the
following exceptions:

- Does not support deprecated _Expression macro values_.
- Does not support deprecated _Imported Layouts_.


## Usage
Example usage:

``` dart
import 'package:rimu/rimu.dart' as rimu;

main(List<String> arguments) {
  print(rimu.render('Hello *Rimu*!'));
}
```

See also Rimu
[API documentation](http://rimumarkup.org/reference.html#api).


## CLI command
The [Rimu CLI command](http://rimumarkup.org/reference.html#rimuc-command) is `rimuc.dart`.

Run it using the Dart `pub` command e.g.

    pub global activate rimu
    echo 'Hello *Rimu*!' | pub run rimuc


## Building
1. Clone source repo from Github:

    git clone git@github.com:srackham/rimu-dart.git

2. Build and test:

        cd rimu-dart/
        pub get
        make


## Learn more
Read the [documentation](http://rimumarkup.org/reference.html) and experiment
with Rimu in the [Rimu
Playground](http://srackham.github.io/rimu/rimuplayground.html).

See the Rimu [Change Log](http://srackham.github.io/rimu/changelog.html) for the
latest changes.


## Implementation
- The largely one-to-one correspondence between the canonical
  [TypeScript code](https://github.com/srackham/rimu) and the Dart code
  eased porting and debugging.  This will also make it easier to
  cross-port new features and bug-fixes.

- All Rimu implementations share the same JSON driven test suites
  comprising over 300 compatibility checks.