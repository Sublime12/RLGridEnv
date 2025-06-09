const std = @import("std");
const game = @import("game.zig");
const Environnement = game.Environnement;
const DummyPlayer = game.DummyPlayer;
const Position = game.Position;
const print = std.debug.print;


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const env = Environnement.init(allocator, 0);

    var dummy_player = DummyPlayer{
        .position1 = undefined,
        .position2 = undefined,
    };

    const pos1 = Position{ .x = 1, .y = 2, .z = 3 };
    const pos2 = Position{ .x = 9, .y = 8, .z = 7 };
    const player = dummy_player.player();

    player.begin(pos1, pos2);
    print("Env: {}\n", .{env});
    print("Dummy Player: {}\n", .{dummy_player});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
