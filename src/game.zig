const std = @import("std");
const print = std.debug.print;

pub const Environnement = struct {
    const Self = @This();

    const LENGTH = 10;
    board: [LENGTH][LENGTH][LENGTH]u32,
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
    pub fn init(default: u32) Self {
        var env = Self{
            .board = undefined,
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
};

pub const Player = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        begin: *const fn (*anyopaque, position1: Position, position2: Position) void,
        get_action: *const fn (*anyopaque, state: *State) Action,
        other_player_action: *const fn (*anyopaque, action: Action) void,
        reward: *const fn (*anyopaque, reward: i32) void,
    };

    pub fn begin(self: Player, position1: Position, position2: Position) void {
        self.vtable.begin(self.ptr, position1, position2);
    }
};

pub const Position = struct { x: u32, y: u32, z: u32 };
pub const Action = struct { dx: u32, dy: u32, dz: u32 };

pub const State = struct {
    current_position: Position,
    adversary_last_action: Action,
    adversary_reward: i32,
};

pub const DummyPlayer = struct {
    const Self = @This();
    position1: Position,
    position2: Position,

    pub fn begin(ctx: *anyopaque, pos1: Position, pos2: Position) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.position1 = pos1;
        self.position2 = pos2;
        print("position 1: {}\nPosition 2: {}\n", .{ pos1, pos2 });
    }

    pub fn get_action(ctx: *anyopaque, state: *State) Action {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        print("State is {}\n", .{state});
        return Action{ .dx = 0, .dy = 0, .dz = 0 };
    }

    pub fn other_player_action(ctx: *anyopaque, action: Action) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;

        print("Other player action is {}\n", .{action});
    }

    pub fn reward(ctx: *anyopaque, value: i32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;

        print("Reward is {}\n", .{value});
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
