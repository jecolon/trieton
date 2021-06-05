//! Trieton is a Zig implementation of the trie data structure.

const std = @import("std");
const mem = std.mem;
const testing = std.testing;

/// Create a new trie with the given key and value types.
pub fn Trieton(comptime K: type, comptime V: type) type {
    return struct {
        const NodeMap = std.AutoHashMap(K, Node);

        const Node = struct {
            value: ?V,
            children: ?NodeMap,

            fn init() Node {
                return Node{
                    .value = null,
                    .children = null,
                };
            }

            fn deinit(self: *Node) void {
                if (self.children) |*children| {
                    var iter = children.iterator();
                    while (iter.next()) |entry| {
                        entry.value_ptr.deinit();
                    }
                    children.deinit();
                }
            }
        };

        allocator: *mem.Allocator,
        root: Node,

        pub fn init(allocator: *mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .root = Node.init(),
            };
        }

        const Self = @This();

        pub fn deinit(self: *Self) void {
            self.root.deinit();
        }

        /// add a value for the specified key. Keys are slices of the key value type.
        pub fn add(self: *Self, key: []const K, value: V) !void {
            var current = &self.root;

            for (key) |k| {
                if (current.children == null) current.children = NodeMap.init(self.allocator);
                var result = try current.children.?.getOrPut(k);
                if (!result.found_existing) {
                    result.value_ptr.* = Node.init();
                }
                current = result.value_ptr;
            }

            current.value = value;
        }

        /// Lookup is returned from the find method on a successful match. The index field refers to
        /// the index of the element in the key slice that produced the match.
        pub const Lookup = struct {
            index: usize,
            value: V,
        };

        /// finds the matching value for the given key, null otherwise.
        pub fn find(self: Self, key: []const K) ?Lookup {
            var current = &self.root;
            var result: ?Lookup = null;

            for (key) |k, i| {
                if (current.children == null or current.children.?.get(k) == null) break;

                current = &current.children.?.get(k).?;

                if (current.value) |value| {
                    result = .{
                        .index = i,
                        .value = value,
                    };
                }
            }

            return result;
        }
    };
}

test "Byte Trieton" {
    const ByteTrie = Trieton(u8, void);
    const Lookup = ByteTrie.Lookup;

    var byte_trie = ByteTrie.init(std.testing.allocator);
    defer byte_trie.deinit();

    try byte_trie.add(&[_]u8{ 1, 2 }, {});
    try byte_trie.add(&[_]u8{ 1, 2, 3 }, {});

    try testing.expectEqual(Lookup{ .index = 2, .value = {} }, byte_trie.find(&[_]u8{ 1, 2, 3 }).?);
    try testing.expectEqual(Lookup{ .index = 1, .value = {} }, byte_trie.find(&[_]u8{ 1, 2 }).?);
    try testing.expectEqual(byte_trie.find(&[_]u8{1}), null);
}

test "Code Point Map Trieton" {
    const CodePointTrie = Trieton(u21, u21);
    const Lookup = CodePointTrie.Lookup;

    var cpmap_trie = CodePointTrie.init(std.testing.allocator);
    defer cpmap_trie.deinit();

    try cpmap_trie.add(&[_]u21{ 1, 2 }, 0x2112);
    try cpmap_trie.add(&[_]u21{ 1, 2, 3 }, 0x3113);

    try testing.expectEqual(Lookup{ .index = 2, .value = 0x3113 }, cpmap_trie.find(&[_]u21{ 1, 2, 3 }).?);
    try testing.expectEqual(Lookup{ .index = 1, .value = 0x2112 }, cpmap_trie.find(&[_]u21{ 1, 2 }).?);
    try testing.expect(cpmap_trie.find(&[_]u21{1}) == null);
}
