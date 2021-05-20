const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn Trieton(comptime K: type, comptime V: type) type {
    return struct {
        const NodeMap = std.AutoHashMap(K, Node);

        const Node = struct {
            value: ?V,
            children: ?NodeMap,

            pub fn init() Node {
                return Node{
                    .value = null,
                    .children = null,
                };
            }

            pub fn deinit(self: *Node) void {
                if (self.children) |*children| {
                    var iter = children.iterator();
                    while (iter.next()) |entry| {
                        entry.value.deinit();
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

        pub fn add(self: *Self, key: []const K, value: V) !void {
            var current = &self.root;

            for (key) |k| {
                if (current.children == null) current.children = NodeMap.init(self.allocator);
                var result = try current.children.?.getOrPut(k);
                if (!result.found_existing) {
                    result.entry.value = Node.init();
                }
                current = &result.entry.value;
            }

            current.value = value;
        }

        pub const Lookup = struct {
            index: usize,
            value: V,
        };

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

    testing.expectEqual(Lookup{ .index = 2, .value = {} }, byte_trie.find(&[_]u8{ 1, 2, 3 }).?);
    testing.expectEqual(Lookup{ .index = 1, .value = {} }, byte_trie.find(&[_]u8{ 1, 2 }).?);
    testing.expectEqual(byte_trie.find(&[_]u8{1}), null);
}

test "Code Point Map Trieton" {
    const CodePointTrie = Trieton(u21, u21);
    const Lookup = CodePointTrie.Lookup;

    var cpmap_trie = CodePointTrie.init(std.testing.allocator);
    defer cpmap_trie.deinit();

    try cpmap_trie.add(&[_]u21{ 1, 2 }, 0x2112);
    try cpmap_trie.add(&[_]u21{ 1, 2, 3 }, 0x3113);

    testing.expectEqual(Lookup{ .index = 2, .value = 0x3113 }, cpmap_trie.find(&[_]u21{ 1, 2, 3 }).?);
    testing.expectEqual(Lookup{ .index = 1, .value = 0x2112 }, cpmap_trie.find(&[_]u21{ 1, 2 }).?);
    testing.expect(cpmap_trie.find(&[_]u21{1}) == null);
}