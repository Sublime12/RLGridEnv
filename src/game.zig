const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const Random = std.Random;
const math = std.math;
const assert = std.debug.assert;

const LENGTH = 10;
pub const Environnement = struct {
    // player one
    // player two
    // player {
    //   initial_position himself, other_player,
    //   init(position0, position1)
    //   get_action(state) return action
    //   other_player_action(action)
    //   reward(number)
    //   points_rewarded
    // }
    // State {
    //   position courante
    //   action precedente de l'adversaire
    //   nb_points_gagnee_adversaire
    // }
    // Env {
    //   board,
    //   map(target_position -> reward)
    //   nb_rewards = n
    //   reward_player1
    //   reward_player2
    //   player1
    //   player2
    //   hidden_state (player1, player2, targets, score_player1, score_player2)
    //   play() plays the game according to the current player
    //      -> get current player
    //      -> get_action_from current player
    //      -> notify the current player with the reward
    //      -> notify the adversary with the action played by the current user
    //   set_player1(Player)
    //   set_player2(Player)
    //   undo_move()
    // }
    const Turn = enum { first, second };
    const Self = @This();
    const TargetsMap = std.AutoHashMap(Position, i32);
    const Played = struct {
        action: Action,
        reward: i32,
        has_reward: bool,
    };
    const GameHistory = std.ArrayList(Played);

    board: [LENGTH][LENGTH][LENGTH]u32,
    targets: TargetsMap,
    game_history: GameHistory,
    nb_rewards: ?u32,
    player1: ?Player,
    player2: ?Player,
    position_p1: Position,
    position_p2: Position,
    reward_player1: i32,
    reward_player2: i32,
    started: bool,
    playerTurn: Turn,
    last_action_p1: ?Action,
    last_action_p2: ?Action,
    adversary_last_reward_p1: ?i32,
    adversary_last_reward_p2: ?i32,

    rand: Random,

    pub fn init(
        allocator: Allocator,
        rand: Random,
        default: u32,
    ) Self {
        var env = Self{
            .board = undefined,
            .targets = TargetsMap.init(allocator),
            .game_history = GameHistory.init(allocator),
            .player1 = null,
            .player2 = null,
            .position_p1 = undefined,
            .position_p2 = undefined,
            .reward_player1 = 0,
            .reward_player2 = 0,
            .nb_rewards = null,
            .started = false,
            .rand = rand,
            .playerTurn = Turn.first,
            .last_action_p1 = null,
            .last_action_p2 = null,
            .adversary_last_reward_p1 = null,
            .adversary_last_reward_p2 = null,
        };

        for (0..LENGTH) |i| {
            for (0..LENGTH) |j| {
                for (0..LENGTH) |k| {
                    env.board[i][j][k] = default;
                }
            }
        }
        return env;
    }

    pub fn setPlayer1(self: *Self, player: Player) void {
        self.player1 = player;
    }

    pub fn setPlayer2(self: *Self, player: Player) void {
        self.player2 = player;
    }

    pub fn start(self: *Environnement) !void {
        assert(self.player1 != null);
        assert(self.player2 != null);

        // initialize position players 1 and 2

        const x1 = self.rand.intRangeLessThan(i32, 0, 10);
        const y1 = self.rand.intRangeLessThan(i32, 0, 10);
        const z1 = self.rand.intRangeLessThan(i32, 0, 10);

        const x2 = self.rand.intRangeLessThan(i32, 0, 10);
        const y2 = self.rand.intRangeLessThan(i32, 0, 10);
        const z2 = self.rand.intRangeLessThan(i32, 0, 10);

        self.position_p1 = Position.create(x1, y1, z1);
        self.position_p2 = Position.create(x2, y2, z2);

        self.player1.?.begin(self.position_p1, self.position_p2);
        self.player1.?.begin(self.position_p2, self.position_p1);

        // init boards with rand values
        var nb_rewards: u32 = 0;
        for (0..LENGTH) |i| {
            for (0..LENGTH) |j| {
                for (0..LENGTH) |k| {
                    if (self.rand.float(f32) < 0.15) {
                        const target = self.rand.intRangeAtMost(i32, 1, 15);
                        self.board[i][j][k] = @intCast(target);

                        const position = Position.create(
                            @intCast(i),
                            @intCast(j),
                            @intCast(k),
                        );
                        try self.targets.put(position, target);
                        nb_rewards += 1;
                    }
                }
            }
        }
        // init nb_reward
        self.nb_rewards = nb_rewards;

        self.started = true;
    }

    pub fn deinit(self: *Environnement) void {
        self.targets.deinit();
        self.game_history.deinit();
    }

    pub fn play(self: *Self) !void {
        // var i: i32 = 0;
        while (true) {
            // defer i += 1;
            const adversary_last_action = if (self.playerTurn == Turn.first)
                self.last_action_p1
            else
                self.last_action_p2;

            const adversary_last_reward = if (self.playerTurn == Turn.first)
                self.adversary_last_reward_p1
            else
                self.adversary_last_reward_p2;

            const current_position = if (self.playerTurn == Turn.first)
                self.position_p1
            else
                self.position_p2;

            const player1 = &self.player1.?;
            const player2 = &self.player2.?;

            const player = if (self.playerTurn == Turn.first)
                player1
            else
                player2;

            const other_player = if (self.playerTurn == Turn.first)
                player2
            else
                player1;

            const state = State{
                .current_position = current_position,
                .adversary_last_action = adversary_last_action,
                .adversary_reward = adversary_last_reward,
            };
            const action = player.getAction(&state, self);
            const result = try self.playStep(action);

            player.reward(result.reward);
            other_player.otherPlayerAction(action);
            if (result.ended) {
                break;
            }
        }

        // print("Nb iterations: {}\n", .{i});
    }

    const PlayResult = struct {
        reward: i32,
        ended: bool,
    };

    pub fn playStep(self: *Self, action: Action) !PlayResult {
        assert(self.started);

        const current_position = if (self.playerTurn == Turn.first)
            &self.position_p1
        else
            &self.position_p2;
        const other_position = if (self.playerTurn == Turn.first)
            &self.position_p2
        else
            &self.position_p1;

        var temp_new_position = current_position.moveBy(action);

        var reward: ?i32 = null;

        var effective_action = action;
        var has_reward = false;
        // Conflict
        if (std.meta.eql(temp_new_position, other_position.*)) {
            const conflicted_action = action.negate();
            effective_action = conflicted_action;
            temp_new_position = current_position.moveBy(conflicted_action);
            reward = -1;
        }
        if (self.targets.get(temp_new_position)) |rew| {
            defer _ = self.targets.remove(temp_new_position);
            reward = rew;
            self.nb_rewards.? -= 1;
            has_reward = true;
            print("Player {} turn won: {}\n", .{ self.playerTurn, rew });
        } else {
            reward = 0;
        }

        current_position.update(&temp_new_position);
        // other_player.otherPlayerAction(action);

        self.playerTurn = if (self.playerTurn == Turn.first)
            Turn.second
        else
            Turn.first;

        const game_ended = self.nb_rewards == 0;
        assert(reward != null);

        try self.game_history.append(.{
            .reward = reward.?,
            .action = effective_action,
            .has_reward = has_reward,
        });
        return .{
            .reward = reward.?,
            .ended = game_ended,
        };
    }

    // Do not call this function if game_history is empty
    // Generally that means your algo is not correct
    pub fn undo(self: *Self) !void {
        if (self.game_history.popOrNull()) |history| {
            self.playerTurn = if (self.playerTurn == Turn.first)
                Turn.second
            else
                Turn.first;
            const position = if (self.playerTurn == Turn.first)
                &self.position_p1
            else
                &self.position_p2;

            if (history.has_reward) {
                try self.targets.putNoClobber(position.*, history.reward);
                self.nb_rewards.? += 1;
            }
            position.x -= history.action.dx;
            position.y -= history.action.dy;
            position.z -= history.action.dz;
        } else {
            unreachable;
        }
    }
};

pub const Player = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        begin: *const fn (*anyopaque, position1: Position, position2: Position) void,
        get_action: *const fn (*anyopaque, state: *const State, env: *Environnement) Action,
        other_player_action: *const fn (*anyopaque, action: Action) void,
        reward: *const fn (*anyopaque, reward: i32) void,
    };

    pub fn begin(self: Player, position1: Position, position2: Position) void {
        self.vtable.begin(self.ptr, position1, position2);
    }

    pub fn getAction(self: Player, state: *const State, env: *Environnement) Action {
        return self.vtable.get_action(self.ptr, state, env);
    }

    pub fn otherPlayerAction(self: Player, action: Action) void {
        self.vtable.other_player_action(self.ptr, action);
    }

    pub fn reward(self: Player, _reward: i32) void {
        self.vtable.reward(self.ptr, _reward);
    }
};

pub const Position = struct {
    x: i32,
    y: i32,
    z: i32,
    pub fn create(x: i32, y: i32, z: i32) Position {
        assert(x >= 0 and x < 10);
        assert(y >= 0 and y < 10);
        assert(z >= 0 and z < 10);

        return Position{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn moveBy(self: *Position, action: Action) Position {
        const new_x = math.clamp(self.x + action.dx, 0, LENGTH - 1);
        const new_y = math.clamp(self.y + action.dy, 0, LENGTH - 1);
        const new_z = math.clamp(self.z + action.dz, 0, LENGTH - 1);
        return Position.create(
            new_x,
            new_y,
            new_z,
        );
    }

    pub fn update(self: *Position, other_position: *const Position) void {
        self.x = other_position.x;
        self.y = other_position.y;
        self.z = other_position.z;
    }
};

pub const Action = struct {
    dx: i32,
    dy: i32,
    dz: i32,
    pub fn create(dx: i32, dy: i32, dz: i32) Action {
        assert(@abs(dx) < 2);
        assert(@abs(dy) < 2);
        assert(@abs(dz) < 2);

        return Action{
            .dx = dx,
            .dy = dy,
            .dz = dz,
        };
    }

    pub fn negate(self: *const Action) Action {
        return Action.create(-self.dx, -self.dy, -self.dz);
    }
};

pub const State = struct {
    current_position: Position,
    adversary_last_action: ?Action,
    adversary_reward: ?i32,
};

pub const DummyPlayer = struct {
    const Self = @This();
    position1: ?Position,
    position2: ?Position,
    reward: i32,

    rand: Random,

    pub fn init(random: Random) Self {
        return Self{
            .rand = random,
            .position1 = null,
            .position2 = null,
            .reward = 0,
        };
    }

    pub fn begin(ctx: *anyopaque, pos1: Position, pos2: Position) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.position1 = pos1;
        self.position2 = pos2;
        // print("position 1: {}\nPosition 2: {}\n", .{ pos1, pos2 });
    }

    pub fn getAction(ctx: *anyopaque, state: *const State, env: *Environnement) Action {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = state;
        _ = env;

        const dx = self.rand.intRangeAtMost(i32, -1, 1);
        const dy = self.rand.intRangeAtMost(i32, -1, 1);
        const dz = self.rand.intRangeAtMost(i32, -1, 1);
        const action = Action.create(dx, dy, dz);
        // print("Playing action {}\n", .{ action });
        return action;
    }

    pub fn otherPlayerAction(ctx: *anyopaque, action: Action) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        _ = action;
        // print("Other player action is {}\n", .{action});
    }

    pub fn reward(ctx: *anyopaque, value: i32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.reward += value;
        // print("Reward is {}\n", .{value});
    }

    pub fn player(self: *Self) Player {
        return Player{
            .ptr = self,
            .vtable = &Player.VTable{
                .begin = Self.begin,
                .get_action = Self.getAction,
                .other_player_action = Self.otherPlayerAction,
                .reward = Self.reward,
            },
        };
    }
};

test "undo should revert the game state to previous move" {
    const allocator = std.testing.allocator;

    // Fixed seed for reproducibility
    var prng = std.rand.DefaultPrng.init(0);
    const rand = prng.random();

    var env = Environnement.init(allocator, rand, 0);
    defer env.deinit();

    var dummy1 = DummyPlayer.init(rand);
    var dummy2 = DummyPlayer.init(rand);

    env.setPlayer1(dummy1.player());
    env.setPlayer2(dummy2.player());

    try env.start();

    const original_position_p1 = env.position_p1;
    const original_position_p2 = env.position_p2;
    const original_nb_rewards = env.nb_rewards.?;

    const action = Action.create(1, 0, 0);
    _ = try env.playStep(action);

    const updated_position = env.position_p1;

    std.testing.expect(!std.meta.eql(updated_position, original_position_p1)) catch return error.TestFail;
    try env.undo();

    std.testing.expect(std.meta.eql(env.position_p1, original_position_p1)) catch return error.TestFail;

    std.testing.expect(std.meta.eql(env.position_p2, original_position_p2)) catch return error.TestFail;

    std.testing.expectEqual(env.nb_rewards.?, original_nb_rewards) catch return error.TestFail;

    std.testing.expectEqual(env.playerTurn, Environnement.Turn.first) catch return error.TestFail;
}
