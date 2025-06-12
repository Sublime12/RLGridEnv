const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const Random = std.Random;
const math = std.math;
const assert = std.debug.assert;

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
    const Self = @This();
    const LENGTH = 10;
    const TargetsMap = std.AutoHashMap(Position, u32);
    board: [LENGTH][LENGTH][LENGTH]u32,
    targets: TargetsMap,
    nb_rewards: ?u32,
    player1: ?Player,
    player2: ?Player,
    position_p1: ?Position,
    position_p2: ?Position,
    reward_player1: i32,
    reward_player2: i32,
    started: bool,

    rand: Random,

    pub fn init(
        allocator: Allocator,
        rand: Random,
        default: u32,
    ) Self {
        var env = Self{
            .board = undefined,
            .targets = TargetsMap.init(allocator),
            .player1 = null,
            .player2 = null,
            .position_p1 = null,
            .position_p2 = null,
            .reward_player1 = 0,
            .reward_player2 = 0,
            .nb_rewards = null,
            .started = false,
            .rand = rand,
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

        const x1 = self.rand.intRangeLessThan(u32, 0, 10);
        const y1 = self.rand.intRangeLessThan(u32, 0, 10);
        const z1 = self.rand.intRangeLessThan(u32, 0, 10);

        const x2 = self.rand.intRangeLessThan(u32, 0, 10);
        const y2 = self.rand.intRangeLessThan(u32, 0, 10);
        const z2 = self.rand.intRangeLessThan(u32, 0, 10);

        self.position_p1 = Position.create(x1, y1, z1);
        self.position_p2 = Position.create(x2, y2, z2);

        self.player1.?.begin(self.position_p1.?, self.position_p2.?);
        self.player1.?.begin(self.position_p2.?, self.position_p1.?);

        // init boards with rand values
        var nb_rewards: u32 = 0;
        for (0..LENGTH) |i| {
            for (0..LENGTH) |j| {
                for (0..LENGTH) |k| {
                    if (self.rand.float(f32) < 0.15) {
                        const target = self.rand.intRangeAtMost(u32, 1, 15);
                        self.board[i][j][k] = target;

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

        // initialize the targets
        var target_iterator = self.targets.iterator();
        while (target_iterator.next()) |item| {
            const key_ptr = item.key_ptr;
            const value_ptr = item.value_ptr;

            print("{} -> {}\n", .{key_ptr.*, value_ptr.*});
        }

        self.started = true;
    }

    pub fn deinit(self: *Environnement) void {
        self.targets.deinit();
    }

    pub fn play(self: *Self) void {
        assert(self.started);

        // const player1 = self.player1.?;
        // const player2 = self.player2.?;

        // create state for this player
        // player1.get_action(state);
    }
};

pub const Player = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        begin: *const fn (*anyopaque, position1: Position, position2: Position) void,
        get_action: *const fn (*anyopaque, state: *const State) Action,
        other_player_action: *const fn (*anyopaque, action: Action) void,
        reward: *const fn (*anyopaque, reward: i32) void,
    };

    pub fn begin(self: Player, position1: Position, position2: Position) void {
        self.vtable.begin(self.ptr, position1, position2);
    }

    pub fn get_action(self: Player, state: *const State) Action {
        return self.vtable.get_action(self.ptr, state);
    }

    pub fn other_player_action(self: Player, action: Action) void {
        self.vtable.other_player_action(self.ptr, action);
    }

    pub fn reward(self: Player, _reward: i32) void {
        self.vtable.reward(self.ptr, _reward);
    }
};

pub const Position = struct {
    x: u32,
    y: u32,
    z: u32,
    pub fn create(x: u32, y: u32, z: u32) Position {
        assert(x >= 0 and x < 10);
        assert(y >= 0 and y < 10);
        assert(z >= 0 and z < 10);

        return Position{
            .x = x,
            .y = y,
            .z = z,
        };
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
};

pub const State = struct {
    current_position: Position,
    adversary_last_action: Action,
    adversary_reward: i32,
};

pub const DummyPlayer = struct {
    const Self = @This();
    position1: ?Position,
    position2: ?Position,

    rand: Random,

    pub fn init(random: Random) Self {
        return Self{
            .rand = random,
            .position1 = null,
            .position2 = null,
        };
    }

    pub fn begin(ctx: *anyopaque, pos1: Position, pos2: Position) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.position1 = pos1;
        self.position2 = pos2;
        // print("position 1: {}\nPosition 2: {}\n", .{ pos1, pos2 });
    }

    pub fn get_action(ctx: *anyopaque, state: *const State) Action {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = state;
        const dx = self.rand.intRangeAtMost(i32, -1, 1);
        const dy = self.rand.intRangeAtMost(i32, -1, 1);
        const dz = self.rand.intRangeAtMost(i32, -1, 1);
        return Action.create(dx, dy, dz);
    }

    pub fn other_player_action(ctx: *anyopaque, action: Action) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        _ = action;
        // print("Other player action is {}\n", .{action});
    }

    pub fn reward(ctx: *anyopaque, value: i32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        _ = value;
        // print("Reward is {}\n", .{value});
    }

    pub fn player(self: *Self) Player {
        return Player{
            .ptr = self,
            .vtable = &.{
                .begin = Self.begin,
                .get_action = Self.get_action,
                .other_player_action = Self.other_player_action,
                .reward = Self.reward,
            },
        };
    }
};
