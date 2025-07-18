const std = @import("std");
const game = @import("game.zig");
const Environnement = game.Environnement;
const DummyPlayer = game.DummyPlayer;
const Position = game.Position;

const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var prng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    const rand = prng.random();

    var p1: i32 = 0;
    var p2: i32 = 0;

    for (0..5000) |_| {
        var dummy_player1 = DummyPlayer.init(rand);
        var dummy_player2 = DummyPlayer.init(rand);

        const player1 = dummy_player1.player();
        const player2 = dummy_player2.player();

        var env = Environnement.init(allocator, rand, 0);
        defer env.deinit();

        env.setPlayer1(player1);
        env.setPlayer2(player2);
        try env.start();

        _ = try env.play();

        if (dummy_player1.reward > dummy_player2.reward) {
            p1 += 1;
        } else if (dummy_player1.reward < dummy_player2.reward) {
            p2 += 1;
        }
    }
    const fp1: f32 = @floatFromInt(p1);
    const fp2: f32 = @floatFromInt(p2);

    const ratio_p1: f64 = fp1 / (fp1 + fp2);
    const ratio_p2: f64 = fp2 / (fp1 + fp2);
    print("Nb wins p1: {}\n", .{p1});
    print("Nb wins p2: {}\n", .{p2});
    print("Percentages p1, p2, {d:.4} {d:.4}", .{ ratio_p1, ratio_p2 });
}

test "initialize game" {
    const allocator = std.testing.allocator;
    // const allocator = gpa.allocator();
    // defer _ = allocator.deinit();
    var prng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    const rand = prng.random();

    var dummy_player1 = DummyPlayer.init(rand);
    var dummy_player2 = DummyPlayer.init(rand);

    const player1 = dummy_player1.player();
    const player2 = dummy_player2.player();

    var env = Environnement.init(allocator, rand, 0);
    defer env.deinit();
    env.setPlayer1(player1);
    env.setPlayer2(player2);
    try env.start();

    // assert(std.meta.eql(env.position_p1, Position.create(2, 7, 9)));
    // assert(std.meta.eql(env.position_p2, Position.create(2, 6, 3)));
    _ = try env.play();

    print("Dum p1 reward: {}\n", .{dummy_player1.reward});
    print("Dum p2 reward: {}\n", .{dummy_player2.reward});
    print(
        "Winner is: {s}\n",
        .{if (dummy_player1.reward > dummy_player2.reward) "p1" else "p2"},
    );
}
