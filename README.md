# Trieton
Trieton is a simple Trie data structure implementation in Zig. Behavior is similar to a hash map, with
peculiar differences. See examples below.

## Integrating Trieton in your Project
In a `libs` subdirectory under the root of your project, clone this repository via

```sh
$  git clone https://github.com/jecolon/trieton.git
```

Now in your build.zig, you can add:

```zig
exe.addPackagePath("Trieton", "libs/trieton/src/trieton.zig");
```

to the `exe` section for the executable where you wish to have Zighlander available. Now in the code, you
can import the function like this:

```zig
const Trieton = @import("Trieton").Trieton;
```

Finally, you can build the project with:

```sh
$ zig build
```

Note that to build in realase modes, either specify them in the `build.zig` file or on the command line
via the `-Drelease-fast=true`, `-Drelease-small=true`, `-Drelease-safe=true` options to `zig build`.

## Usage
```zig
const Trieton = @import("Trieton").Trieton;

test "Byte Trieton" {
    // For convenience, obtain the types to be used.
    // The Trieton function will produce a trie for the given key and value types.
    const ByteTrie = Trieton(u8, usize);

    // The Lookup struct is the result of a call to the find method if a match is found, null otherwiswe. 
    // It includes the index of the key element that produced the match, and the value stored for 
    // that key.
    const Lookup = ByteTrie.Lookup;

    // Setup the trie.
    var byte_trie = ByteTrie.init(std.testing.allocator);
    defer byte_trie.deinit();

    // Add some elements. Keys are slices of the type specified when calling the Trieton function.
    try byte_trie.add(&[_]u8{ 1, 2 }, 2112);
    try byte_trie.add(&[_]u8{ 1, 2, 3 }, 42);

    testing.expectEqual(Lookup{ .index = 2, .value = 42 }, byte_trie.find(&[_]u8{ 1, 2, 3 }).?);
    testing.expectEqual(Lookup{ .index = 1, .value = 2112 }, byte_trie.find(&[_]u8{ 1, 2 }).?);
    testing.expectEqual(byte_trie.find(&[_]u8{1}), null);
}
```
