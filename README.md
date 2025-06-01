# Two-Player 3D Grid-World “Weighted-Target” Problem

## Table of Contents
1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Notation](#notation)  
4. [State Space](#state-space)  
5. [Actions](#actions)  
6. [Turn Order & Transition Dynamics](#turn-order--transition-dynamics)  
   - [Player 1’s Move (Sub-step t.1)](#player-1s-move-sub-step-t1)  
   - [Player 2’s Move (Sub-step t.2)](#player-2s-move-sub-step-t2)  
7. [Reward Functions](#reward-functions)  
8. [Observation Space](#observation-space)  
9. [Belief & Opponent Position Estimation](#belief--opponent-position-estimation)  
10. [Complete Game Definition](#complete-game-definition)  
11. [Termination & Discount Factor](#termination--discount-factor)  

---

## Overview

This repository specifies a two-player, turn-based, partially-observable Markov game on a discrete 3D grid. Each player:

1. Knows its own **initial position** _(and the opponent’s initial position)_.
2. Observes only the opponent’s **last action** (not the opponent’s current position).
3. Must **estimate** the opponent’s current position using:
   - Known initial positions.
   - The history of observed opponent actions.
   - The deterministic transition rules (including collision logic).

Players move through cells on a finite 3D grid, collect “weighted targets,” and incur collision penalties if they attempt to move into the same cell as the opponent. This README formalizes:

- The grid and state representation.  
- Action sets and turn order.  
- Transition rules (including collisions and target collection).  
- Reward definitions.  
- What each player observes (own position, remaining targets, and opponent’s last action).  
- How to estimate the opponent’s hidden current position.  

---

## Prerequisites

- Familiarity with Markov Decision Processes (MDPs) and Markov games.  
- Comfort reading mathematical notation (set theory, indices, simple matrix/vector operations).  
- Basic understanding of partially-observable games (belief states).  

_No code or external dependencies are provided here—this is a formal problem specification. Any implementation (Python, C++, etc.) should follow the definitions below._

---

## Notation

- Let \(X, Y, Z \in \mathbb{N}\) be the dimensions of the 3D grid.  
- Define the set of valid grid cells:
  \[
    W \;=\; \{\, (x,y,z)\in\mathbb{Z}^3 \mid 0 \le x < X,\;0 \le y < Y,\;0 \le z < Z \}\,.
  \]
- There are two players, indexed \(i \in \{1,2\}\). Define \(j = 3 - i\) to denote “the other player.”  
- Each player \(i\) has an **initial position**:
  \[
    p_{\mathrm{init}}^{(i)} \;\in\; W,\quad p_{\mathrm{init}}^{(j)} \;\in\; W.
  \]
  Both \(p_{\mathrm{init}}^{(1)}\) and \(p_{\mathrm{init}}^{(2)}\) are known to each agent from the outset.  
- A finite set of **weighted targets** is placed on distinct grid cells:
  \[
    T_{\mathrm{init}} \;=\; \{\,\tau_1,\tau_2,\dots,\tau_n\}\;\subset\;W,
    \qquad
    V(\tau_k)\in \mathbb{Z}_{>0}\quad\text{for }k=1,\dots,n.
  \]
  At time \(t\), the subset of uncollected targets is denoted \(T_t \subseteq T_{\mathrm{init}}\).  
- Player \(i\)’s **cumulative score** at time \(t\) is 
  \[
    S_t^{(i)}\;\in\;\mathbb{Z},\quad S_0^{(i)} = 0.
  \]
- If a player attempts to move into the opponent’s current cell, a **collision** occurs. The mover is “bounced” one cell backward and loses 1 point (\(-1\) penalty).  
- At each turn, Player \(i\) chooses an **action vector**
  \[
    \Delta_t^{(i)} 
    \;=\; 
    \bigl(\Delta x_t^{(i)},\,\Delta y_t^{(i)},\,\Delta z_t^{(i)}\bigr)
    \;\in\; \{-1,\,0,\,1\}^3.
  \]
  - \((0,0,0)\) means “stay in place.”  
  - Otherwise, the player attempts to move one step along each coordinate \(\Delta x,\Delta y,\Delta z\).  

---

## State Space

Define the **full (hidden) state** at time \(t\) as:
\[
  s_t 
  \;=\; 
  \bigl(\,
    p_t^{(1)},\,p_t^{(2)},\,T_t,\,S_t^{(1)},\,S_t^{(2)}
  \bigr),
\]
where:

1. \(p_t^{(i)} \in W\) is Player \(i\)’s current position.  
2. \(T_t \subseteq T_{\mathrm{init}}\) is the set of targets not yet collected.  
3. \(S_t^{(i)} \in \mathbb{Z}\) is Player \(i\)’s cumulative score.  

- **Initial state** \(s_0\) has:
  \[
    p_0^{(i)} = p_{\mathrm{init}}^{(i)}, \quad
    T_0 = T_{\mathrm{init}}, \quad
    S_0^{(i)} = 0 \quad (i=1,2).
  \]

Because neither player directly observes \(s_t\) in its entirety (especially the opponent’s \(p_t^{(j)}\)), this is a partially observable Markov game.

---

## Actions

At each discrete time step \(t = 0,1,2,\dots\), Player \(i\) chooses:
\[
  \Delta_t^{(i)} \;=\; (\Delta x_t^{(i)},\,\Delta y_t^{(i)},\,\Delta z_t^{(i)})
  \;\in\;\{-1,\,0,\,1\}^3.
\]
- If \(\Delta_t^{(i)} = (0,0,0)\), the player **stays** in its current cell.  
- Otherwise, the **intended forward move** is
  \[
    \bigl(x_t^{(i)} + \Delta x_t^{(i)},\,y_t^{(i)} + \Delta y_t^{(i)},\,z_t^{(i)} + \Delta z_t^{(i)}\bigr).
  \]
  This is then **clamped** coordinate-wise into the valid range \([0..\,X-1]\times[0..\,Y-1]\times[0..\,Z-1]\).  

Denote the action space of each player by
\[
  \mathcal{A}^{(i)} \;=\; \{-1,0,1\}^3, \quad i=1,2.
\]

---

## Turn Order & Transition Dynamics

Each full time step \(t\) consists of two ordered sub-steps:

1. **Sub-step t.1**: Player 1 moves (using \(\Delta_t^{(1)}\)).  
2. **Sub-step t.2**: Player 2 moves (using \(\Delta_t^{(2)}\)), after seeing Player 1’s updated position.

Write the state just before sub-step t.1 as:
\[
  s_t = \bigl(p_t^{(1)},\,p_t^{(2)},\,T_t,\,S_t^{(1)},\,S_t^{(2)}\bigr).
\]

### Player 1’s Move (Sub-step t.1)

1. **Compute forward-clamped position**:
   \[
     \widetilde{p}^{(1)}
     \;=\; 
     \Bigl(\,
       \mathrm{clamp}(x_t^{(1)} + \Delta x_t^{(1)},0,X-1),\,
       \mathrm{clamp}(y_t^{(1)} + \Delta y_t^{(1)},0,Y-1),\,
       \mathrm{clamp}(z_t^{(1)} + \Delta z_t^{(1)},0,Z-1)
     \Bigr).
   \]
2. **Collision check** against Player 2 at \(p_t^{(2)}\):
   - If \(\widetilde{p}^{(1)} \neq p_t^{(2)}\), **no collision**:
     \[
       p_{\,t+\tfrac12}^{(1)} = \widetilde{p}^{(1)}, 
       \quad
       S_{\,t+\tfrac12}^{(1)} = S_t^{(1)}.
     \]
   - If \(\widetilde{p}^{(1)} = p_t^{(2)}\), **collision**:
     1. **Bounce backward** by \(-\Delta_t^{(1)}\), then clamp:
        \[
          \widehat{p}^{(1)} 
          = 
          \Bigl(\,
            \mathrm{clamp}(x_t^{(1)} - \Delta x_t^{(1)},0,X-1),\,
            \mathrm{clamp}(y_t^{(1)} - \Delta y_t^{(1)},0,Y-1),\,
            \mathrm{clamp}(z_t^{(1)} - \Delta z_t^{(1)},0,Z-1)
          \Bigr).
        \]
     2. Assign:
        \[
          p_{\,t+\tfrac12}^{(1)} = \widehat{p}^{(1)}, 
          \quad
          S_{\,t+\tfrac12}^{(1)} = S_t^{(1)} - 1.
        \]
   Meanwhile, Player 2’s sub-step is not yet executed:
   \[
     p_{\,t+\tfrac12}^{(2)} = p_t^{(2)}, 
     \quad
     S_{\,t+\tfrac12}^{(2)} = S_t^{(2)}.
   \]
3. **Target collection by Player 1**:
   - If \(p_{\,t+\tfrac12}^{(1)} \in T_t\), say it equals \(\tau_k\), then:
     \[
       S_{\,t+\tfrac12}^{(1)} 
       \;=\; 
       S_{\,t+\tfrac12}^{(1)} + V(\tau_k),
       \quad
       T_{\,t+\tfrac12} = T_t \setminus \{\tau_k\}.
     \]
   - Otherwise: \(T_{\,t+\tfrac12} = T_t\).

The **intermediate state** after sub-step t.1 is:
\[
  s_{\,t+\tfrac12} 
  = 
  \Bigl(
    p^{(1)}_{\,t+\tfrac12},\,p^{(2)}_{\,t+\tfrac12},\,T_{\,t+\tfrac12},\,S^{(1)}_{\,t+\tfrac12},\,S^{(2)}_{\,t+\tfrac12}
  \Bigr).
\]

---

### Player 2’s Move (Sub-step t.2)

Starting from \(s_{\,t+\tfrac12}\), Player 2 executes \(\Delta_t^{(2)}\):

1. **Compute forward-clamped position**:
   \[
     \widetilde{p}^{(2)}
     = 
     \Bigl(\,
       \mathrm{clamp}(x_t^{(2)} + \Delta x_t^{(2)},0,X-1),\,
       \mathrm{clamp}(y_t^{(2)} + \Delta y_t^{(2)},0,Y-1),\,
       \mathrm{clamp}(z_t^{(2)} + \Delta z_t^{(2)},0,Z-1)
     \Bigr).
   \]
2. **Collision check** against Player 1’s updated cell \(p_{\,t+\tfrac12}^{(1)}\):
   - If \(\widetilde{p}^{(2)} \neq p_{\,t+\tfrac12}^{(1)}\), **no collision**:
     \[
       p_{\,t+1}^{(2)} = \widetilde{p}^{(2)}, 
       \quad 
       S_{\,t+1}^{(2)} = S_{\,t+\tfrac12}^{(2)}.
     \]
     Meanwhile:
     \[
       p_{\,t+1}^{(1)} = p_{\,t+\tfrac12}^{(1)}, 
       \quad
       S_{\,t+1}^{(1)} = S_{\,t+\tfrac12}^{(1)}.
     \]
   - If \(\widetilde{p}^{(2)} = p_{\,t+\tfrac12}^{(1)}\), **collision**:
     1. **Bounce backward**:
        \[
          \widehat{p}^{(2)} 
          = 
          \Bigl(\,
            \mathrm{clamp}(x_t^{(2)} - \Delta x_t^{(2)},0,X-1),\,
            \mathrm{clamp}(y_t^{(2)} - \Delta y_t^{(2)},0,Y-1),\,
            \mathrm{clamp}(z_t^{(2)} - \Delta z_t^{(2)},0,Z-1)
          \Bigr).
        \]
     2. Assign:
        \[
          p_{\,t+1}^{(2)} = \widehat{p}^{(2)}, 
          \quad
          S_{\,t+1}^{(2)} = S_{\,t+\tfrac12}^{(2)} - 1,
        \]
        and
        \[
          p_{\,t+1}^{(1)} = p_{\,t+\tfrac12}^{(1)}, 
          \quad
          S_{\,t+1}^{(1)} = S_{\,t+\tfrac12}^{(1)}.
        \]
3. **Target collection by Player 2**:
   - If \(p_{\,t+1}^{(2)} \in T_{\,t+\tfrac12}\), say it equals \(\tau_m\), then:
     \[
       S_{\,t+1}^{(2)} 
       = 
       S_{\,t+1}^{(2)} + V(\tau_m), 
       \quad 
       T_{\,t+1} = T_{\,t+\tfrac12} \setminus \{\tau_m\}.
     \]
   - Otherwise: \(T_{\,t+1} = T_{\,t+\tfrac12}\).

At the end of sub-step t.2, the **new global state** is:
\[
  s_{\,t+1} 
  = 
  \bigl(\,
    p_{\,t+1}^{(1)},\;p_{\,t+1}^{(2)},\;T_{\,t+1},\;S_{\,t+1}^{(1)},\;S_{\,t+1}^{(2)}
  \bigr).
\]

Because all updates are deterministic given \((s_t,\Delta_t^{(1)},\Delta_t^{(2)})\), the transition kernel
\(\;P(s_{\,t+1}\mid s_t,\Delta_t^{(1)},\Delta_t^{(2)})\) 
is a point-mass on this unique \(s_{\,t+1}\).

---

## Reward Functions

After each full time step \(t\), Player \(i\) receives reward
\[
  r_{\,t+1}^{(i)} 
  \;=\; 
  S^{(i)}_{\text{(after }i\text{ moved)}} 
  \;-\; 
  S^{(i)}_{\text{(just before }i\text{ moved)}} 
  \;\in\;\{-1,\;0,\;+\!V(\tau)\}.
\]

- If Player \(i\) **collides**, then \(S^{(i)}\) decreases by 1 → \(r_{\,t+1}^{(i)} = -1\).  
- If Player \(i\) **collects** a target \(\tau\) of value \(V(\tau)\), then \(r_{\,t+1}^{(i)} = +V(\tau)\).  
- Otherwise (no collision or collection) → \(r_{\,t+1}^{(i)} = 0\).  

Concretely:
1. For Player 1:
   \[
     r^{(1)}_{\,t+1} 
     = 
     S^{(1)}_{\,t+\tfrac12} \;-\; S^{(1)}_{\,t}.
   \]
2. For Player 2:
   \[
     r^{(2)}_{\,t+1} 
     = 
     S^{(2)}_{\,t+1} \;-\; S^{(2)}_{\,t+\tfrac12}.
   \]

---

## Observation Space

Each player does **not** observe the opponent’s current position \(p_t^{(j)}\). Instead, at the start of time step \(t\), Player \(i\) has just observed everything up to time \(t-1\). Its observation is:

\[
  o_t^{(i)} 
  = 
  \Bigl(\,
    p_t^{(i)},\; 
    p_{\mathrm{init}}^{(i)},\; 
    p_{\mathrm{init}}^{(j)},\; 
    \Delta_{\,t-1}^{(j)},\; 
    T_t
  \Bigr),
\]
where \(j = 3 - i\). Concretely, Player \(i\) observes:

1. **Own current position** \(p_t^{(i)}\).  
2. **Own initial position** \(p_{\mathrm{init}}^{(i)}\).  
3. **Opponent’s initial position** \(p_{\mathrm{init}}^{(j)}\).  
4. **Opponent’s most recent action** \(\Delta_{\,t-1}^{(j)}\).  
5. **Full set of remaining targets** \(T_t\), including each target’s weight \(V(\cdot)\).

Formally, the **observation space** for Player \(i\) is:
\[
  \mathcal{O}^{(i)} 
  = 
  W \;\times\; W \;\times\; W \;\times\; \{-1,0,1\}^3 \;\times\; 2^{\,T_{\mathrm{init}}\times\mathbb{Z}_{>0}}.
\]
The deterministic **observation function** is:
\[
  O^{(i)}\bigl(s_t,\Delta_{\,t-1}^{(1)},\Delta_{\,t-1}^{(2)}\bigr)
  \;=\; 
  \bigl(p_t^{(i)},\,p_{\mathrm{init}}^{(i)},\,p_{\mathrm{init}}^{(j)},\,\Delta_{\,t-1}^{(j)},\,T_t\bigr).
\]

---

## Belief & Opponent Position Estimation

Although Player \(i\) does not directly see \(p_t^{(j)}\), it can build a **belief** (in this case, a deterministic estimate) of the opponent’s current position because:

1. Player \(i\) **knows** the opponent’s initial position \(p_{\mathrm{init}}^{(j)}\).  
2. Player \(i\) has observed the entire sequence of the opponent’s past actions:
   \[
     \{\Delta_0^{(j)},\,\Delta_1^{(j)},\,\dots,\,\Delta_{\,t-1}^{(j)}\}.
   \]
3. Player \(i\) controls its own position at each sub-step, so it knows exactly when/where a collision would have occurred for Player \(j\).

Thus, Player \(i\) can compute:
\[
  \widehat{p}_t^{(j)} 
  = 
  \mathrm{simulate}\bigl(p_{\mathrm{init}}^{(j)};\,\Delta_0^{(j)},\,\Delta_1^{(j)},\,\dots,\,\Delta_{\,t-1}^{(j)}\bigr),
\]
where the **“simulate”** procedure applies each observed \(\Delta_k^{(j)}\) in chronological order, performing:

1. **Clamp** the intended move into \([0..\,X-1]\times[0..\,Y-1]\times[0..\,Z-1]\).  
2. If the clamped cell collides with the (already known) position of Player \(i\) at that sub-step, **bounce** backward by \(-\Delta_k^{(j)}\) (and clamp again).  

Because Player \(i\) knows its own position history exactly, there is **no actual uncertainty**: \(\widehat{p}_t^{(j)} = p_t^{(j)}\). The opponent’s current cell is fully reconstructible once \(\Delta_{\,t-1}^{(j)}\) becomes known.  

---

## Complete Game Definition

Summarizing the environment as a two-player, turn-based, partially-observable Markov game:

1. **State space**  
   \[
     \mathcal{S} 
     = \bigl\{\,(p^{(1)},\,p^{(2)},\,T,\,S^{(1)},\,S^{(2)}) 
       \mid 
       p^{(i)} \in W,\;T \subseteq T_{\mathrm{init}},\;S^{(i)} \in \mathbb{Z}
     \bigr\}.
   \]
2. **Action spaces**  
   \[
     \mathcal{A}^{(1)} = \mathcal{A}^{(2)} = \{-1,\,0,\,1\}^3.
   \]
3. **Transition function**  
   Deterministic, given by applying sub-steps t.1 (Player 1) then t.2 (Player 2) as described above.  
4. **Reward functions**  
   \[
     R^{(1)}(s_t,\Delta_t^{(1)},\Delta_t^{(2)},s_{\,t+1}) = r^{(1)}_{\,t+1} \in \{-1,0,+V(\tau)\}, 
   \]  
   \[
     R^{(2)}(s_t,\Delta_t^{(1)},\Delta_t^{(2)},s_{\,t+1}) = r^{(2)}_{\,t+1} \in \{-1,0,+V(\tau)\}.
   \]
5. **Observation functions**  
   \[
     O^{(1)}\bigl(s_t,\Delta_{\,t-1}^{(1)},\Delta_{\,t-1}^{(2)}\bigr)
     = 
     \bigl(p_t^{(1)},\,p_{\mathrm{init}}^{(1)},\,p_{\mathrm{init}}^{(2)},\,\Delta_{\,t-1}^{(2)},\,T_t\bigr),
   \]  
   \[
     O^{(2)}\bigl(s_t,\Delta_{\,t-1}^{(1)},\Delta_{\,t-1}^{(2)}\bigr)
     = 
     \bigl(p_t^{(2)},\,p_{\mathrm{init}}^{(2)},\,p_{\mathrm{init}}^{(1)},\,\Delta_{\,t-1}^{(1)},\,T_t\bigr).
   \]
6. **Belief update**  
   Each agent maintains \(\widehat{p}_t^{(j)}\) by simulating all past observed \(\Delta^{(j)}\) with deterministic “clamp + collision + bounce” rules.  
7. **Termination**  
   The episode ends when either:
   - \(T_{\,t} = \varnothing\) (all targets collected), or  
   - \(t\) reaches a predetermined maximum \(T_{\max}\).  
8. **Discount factor**  
   Typically \(\gamma = 1\) (undiscounted, finite horizon), or any \(\gamma < 1\) for discounted settings.

---

## Termination & Discount Factor

- **Termination**  
  The game stops at the first \(t\) such that either:
  1. All targets have been collected: \(T_t = \varnothing\).  
  2. The time horizon \(t = T_{\max}\) is reached (if a hard cap is imposed).

- **Discount Factor**  
  For most episodic evaluations, use \(\gamma = 1\). If a discounted infinite-horizon variant is desired, choose \(\gamma \in [0,1)\).  

---

## Summary of Key Points

1. **Grid**  
   \[
     W = \{\,0,\dots,X-1\}\times\{\,0,\dots,Y-1\}\times\{\,0,\dots,Z-1\}.
   \]
2. **Initial Positions**  
   Each player \(i\) knows both \(p_{\mathrm{init}}^{(1)}\) and \(p_{\mathrm{init}}^{(2)}\).  
3. **Turn Order**  
   - Sub-step t.1: Player 1 picks \(\Delta_t^{(1)}\).  
   - Sub-step t.2: Player 2 picks \(\Delta_t^{(2)}\).  
4. **Collision**  
   - If a mover’s forward move would land on the opponent’s current cell, bounce backward by \(-\Delta\) and incur \(-1\) reward. No target collection happens on a bounce.  
5. **Targets**  
   - Each \(\tau_k \in T\) has weight \(V(\tau_k)\).  
   - Landing (without collision) on \(\tau_k\) gives \(+\!V(\tau_k)\) and removes \(\tau_k\).  
6. **Rewards**  
   - At step \(t\), Player 1’s reward \(r_{\,t+1}^{(1)} = S_{\,t+\tfrac12}^{(1)} - S_t^{(1)} \in \{-1,0,+V(\tau)\}\).  
   - Player 2’s reward \(r_{\,t+1}^{(2)} = S_{\,t+1}^{(2)} - S_{\,t+\tfrac12}^{(2)} \in \{-1,0,+V(\tau)\}\).  
7. **Observation for Player \(i\)**  
   \[
     o_t^{(i)} 
     = 
     \bigl(p_t^{(i)},\,p_{\mathrm{init}}^{(i)},\,p_{\mathrm{init}}^{(j)},\,\Delta_{\,t-1}^{(j)},\,T_t\bigr).
   \]
   - Sees own current position, both initial positions, opponent’s last action, and the set of remaining targets.  
8. **Belief / Estimation**  
   - Player \(i\) reconstructs \(\widehat{p}_t^{(j)}\) via deterministic simulation of past \(\Delta^{(j)}\) with the same clash‐and‐bounce logic.  
   - Because Player \(i\) knows its own positions exactly, there is no residual uncertainty: \(\widehat{p}_t^{(j)} = p_t^{(j)}\).  
9. **Termination**  
   - Occurs when all targets are gone or a fixed horizon is reached.  
10. **Discount**  
    - Typically \(\gamma=1\) for an undiscounted finite horizon; otherwise \(\gamma<1\).

---

**This completes the formal README-style specification of the two-player 3D Grid-World “weighted-target” problem under the assumption that each agent knows both initial positions, observes only the opponent’s last action, and must estimate the opponent’s current position via deterministic simulation.**  
