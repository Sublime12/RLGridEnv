const std = @import("std");
const game = @import("game.zig");
const Environnement = game.Environnement;
const DummyPlayer = game.DummyPlayer;
const Position = game.Position;

const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {}

test "initialize game" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    var prng = std.rand.DefaultPrng.init(0);
    const rand = prng.random();

    var dummy_player1 = DummyPlayer.init(rand);
    var dummy_player2 = DummyPlayer.init(rand);

    const player1 = dummy_player1.player();
    const player2 = dummy_player2.player();

    var env = Environnement.init(allocator, rand, 0);
    env.setPlayer1(player1);
    env.setPlayer2(player2);
    env.start();

    assert(std.meta.eql(env.position_p1, Position.create(2, 7, 9)));
    assert(std.meta.eql(env.position_p2, Position.create(2, 6, 3)));
}
