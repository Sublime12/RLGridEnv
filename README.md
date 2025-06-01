# Formal Specification: Two-Player 3D Grid-World "Weighted-Target" Problem

Below is a fully‐formal specification of the two‐player 3D Grid‐World “weighted‐target” problem, **under the assumption that each agent**:

1.  **Knows its own initial position** $p^{(i)}_{\mathrm{init}}$. 
2.  **Knows the opponent’s initial position** $p^{(j)}_{\mathrm{init}}$. 
3.  **Observes exactly the opponent’s last action** $\Delta^{(j)}_{\,t-1}$ at each turn. 
4.  **Does not observe the opponent’s current position** $p^{(j)}_t$. Instead, it must *estimate* $p^{(j)}_t$ from its knowledge of initial positions, its own actions, and the sequence of observed opponent‐actions so far. 
All other aspects (collision, weighted targets, turn order, etc.) remain as in the standard 3D Grid‐World.
We cast this as a **two‐player partially‐observable turn‐based Markov game**.

---

## Notation

* $X,Y,Z\in\mathbb{N}$: dimensions of the 3D grid.
* $W = \{\, (x,y,z)\in\mathbb{Z}^3 \mid 0\le x<X,\;0\le y<Y,\;0\le z<Z \}$. 
* Player indices: $i\in\{1,2\}$, and $j=3-i$ denotes “the other player.” 
* Initial (hidden) positions: 
    $$
      p^{(i)}_{\mathrm{init}} \;\in\; W,\quad p^{(j)}_{\mathrm{init}} \;\in\; W.
    $$ 
    Each agent $i$ knows both $p^{(i)}_{\mathrm{init}}$ and $p^{(j)}_{\mathrm{init}}$ from the start. 
* Weighted targets: 
    $$
      T_{\mathrm{init}} = \{\tau_1,\tau_2,\dots,\tau_n\} \subset W,\qquad V(\tau_k)\in\mathbb{Z}_{>0}\text{ for each }k.
    $$ 
    At time $t$, the uncollected targets form $T_t\subseteq T_{\mathrm{init}}$. 
* Player $i$’s cumulative score at time $t$: $S^{(i)}_t\in\mathbb{Z}$, initially $S^{(i)}_0=0$. 
* Collision penalty: if a player attempts to move into the other’s current cell, that player is “bounced” one cell backward and incurs a $-1$ penalty. 
* Action‐vectors: 
    $$
      \Delta^{(i)}_t = \bigl(\Delta x^{(i)}_t,\Delta y^{(i)}_t,\Delta z^{(i)}_t\bigr) \;\in\;\{-1,0,1\}^3,
    $$
    meaning “one‐step attempt” (or $(0,0,0)$ for “stay”). 
---

## 1. Full‐State Space $\mathcal{S}$

A *true* (hidden) state at time $t$ is
$$
  s_t \;=\; \bigl(\, p^{(1)}_t,\;p^{(2)}_t,\;T_t,\;S^{(1)}_t,\;S^{(2)}_t \bigr),
$$ 
where

1.  $p^{(i)}_t\in W$ is the current cell of Player $i$. 
2.  $T_t\subseteq T_{\mathrm{init}}$ is the set of targets not yet collected. 
3.  $S^{(i)}_t\in\mathbb{Z}$ is Player $i$’s score. 
**Initial state** $s_0$ is specified by 
$$
  p^{(i)}_0 = p^{(i)}_{\mathrm{init}},\quad T_0 = T_{\mathrm{init}},\quad S^{(i)}_0 = 0\ (i=1,2).
$$ 
---

## 2. Actions $\mathcal{A}^{(i)}$

At each time‐step $t$, Player $i$ chooses
$$
  \Delta^{(i)}_t \;=\; (\Delta x^{(i)}_t,\Delta y^{(i)}_t,\Delta z^{(i)}_t) \;\in\;\{-1,0,1\}^3.
$$ 
* If $\Delta^{(i)}_t=(0,0,0)$, that is “stay in place.” 
* Otherwise, the intended forward‐move is
    $$
      \bigl(x^{(i)}_t + \Delta x^{(i)}_t,\;y^{(i)}_t + \Delta y^{(i)}_t,\;z^{(i)}_t + \Delta z^{(i)}_t\bigr),
    $$
    which is then clamped coordinate‐wise into $[0..\,X-1]\times[0..\,Y-1]\times[0..\,Z-1]$. 
Denote 
$$
  \mathcal{A}^{(i)} = \{-1,0,1\}^3,\quad i=1,2.
$$ 
---

## 3. Turn‐Order and Transition Dynamics

Each full time‐step $t = 0,1,2,\dots$ consists of two *ordered sub‐steps*:

1.  **Sub‐step $t.1$ (Player 1 moves)** using $\Delta^{(1)}_t$. 
2.  **Sub‐step $t.2$ (Player 2 moves)** using $\Delta^{(2)}_t$, now against Player 1’s updated cell. 

Below we write $s_t = \bigl(p^{(1)}_t,p^{(2)}_t,T_t,S^{(1)}_t,S^{(2)}_t\bigr)$. 

### 3.1. Sub‐step $t.1$: Player 1’s Move

1.  **Compute forward‐clamped position**
    $$
      \widetilde{p}^{(1)} \;=\; \Bigl(\, \mathrm{clamp}\bigl(x^{(1)}_t + \Delta x^{(1)}_t,\,0,\,X-1\bigr),\, \mathrm{clamp}\bigl(y^{(1)}_t + \Delta y^{(1)}_t,\,0,\,Y-1\bigr),\, \mathrm{clamp}\bigl(z^{(1)}_t + \Delta z^{(1)}_t,\,0,\,Z-1\bigr) \Bigr).
    $$ 
2.  **Collision check** (with Player 2 at $p^{(2)}_t$): 
    * If $\widetilde{p}^{(1)} \neq p^{(2)}_t$, then **no collision**. Set
        $$
          p^{(1)}_{\,t+\tfrac12} \;=\; \widetilde{p}^{(1)}, \quad S^{(1)}_{\,t+\tfrac12} \;=\; S^{(1)}_t.
        $$ 
    * If $\widetilde{p}^{(1)} = p^{(2)}_t$, then **collision**: 
        1.  Bounce backwards by $-\Delta^{(1)}_t$ (clamped):
            $$
              \widehat{p}^{(1)} = \Bigl(\, \mathrm{clamp}\bigl(x^{(1)}_t - \Delta x^{(1)}_t,\,0,\,X-1\bigr),\, \mathrm{clamp}\bigl(y^{(1)}_t - \Delta y^{(1)}_t,\,0,\,Y-1\bigr),\, \mathrm{clamp}\bigl(z^{(1)}_t - \Delta z^{(1)}_t,\,0,\,Z-1\bigr) \Bigr).
            $$ 
        2.  Then 
            $$
              p^{(1)}_{\,t+\tfrac12} = \widehat{p}^{(1)}, \quad S^{(1)}_{\,t+\tfrac12} = S^{(1)}_t - 1.
            $$
    Meanwhile, Player 2 does nothing in this sub‐step: 
    $$
      p^{(2)}_{\,t+\tfrac12} = p^{(2)}_t, \quad S^{(2)}_{\,t+\tfrac12} = S^{(2)}_t.
    $$ 
3.  **Target collection by Player 1**
    If $p^{(1)}_{\,t+\tfrac12} \in T_t$, say $p^{(1)}_{\,t+\tfrac12} = \tau_k$, then Player 1 collects $\tau_k$: 
    $$
      S^{(1)}_{\,t+\tfrac12} \;=\; S^{(1)}_{\,t+\tfrac12} + V(\tau_k), \quad T_{\,t+\tfrac12} = T_t \setminus \{\tau_k\}.
    $$ 
    Otherwise, $T_{\,t+\tfrac12} = T_t$. 

After sub‐step $t.1$, we have the *intermediate state*
$$
  s_{\,t+\tfrac12} = \Bigl( p^{(1)}_{\,t+\tfrac12},\;p^{(2)}_{\,t+\tfrac12},\;T_{\,t+\tfrac12},\;S^{(1)}_{\,t+\tfrac12},\;S^{(2)}_{\,t+\tfrac12} \Bigr).
$$ 
---

### 3.2. Sub‐step $t.2$: Player 2’s Move

Starting from $s_{\,t+\tfrac12}$, let

1.  **Forward‐clamped position**
    $$
      \widetilde{p}^{(2)} = \Bigl(\, \mathrm{clamp}\bigl(x^{(2)}_t + \Delta x^{(2)}_t,\,0,\,X-1\bigr),\, \mathrm{clamp}\bigl(y^{(2)}_t + \Delta y^{(2)}_t,\,0,\,Y-1\bigr),\, \mathrm{clamp}\bigl(z^{(2)}_t + \Delta z^{(2)}_t,\,0,\,Z-1\bigr) \Bigr).
    $$ 
2.  **Collision check** (against Player 1’s updated cell $p^{(1)}_{\,t+\tfrac12}$): 
    * If $\widetilde{p}^{(2)} \neq p^{(1)}_{\,t+\tfrac12}$, **no collision**: 
        $$
          p^{(2)}_{\,t+1} = \widetilde{p}^{(2)}, \quad S^{(2)}_{\,t+1} = S^{(2)}_{\,t+\tfrac12}.
        $$ 
        Meanwhile, $\,p^{(1)}_{\,t+1} = p^{(1)}_{\,t+\tfrac12}$ and $S^{(1)}_{\,t+1} = S^{(1)}_{\,t+\tfrac12}.$ 
    * If $\widetilde{p}^{(2)} = p^{(1)}_{\,t+\tfrac12}$, **collision**: 
        1.  Bounce backwards:
            $$
              \widehat{p}^{(2)} = \Bigl(\, \mathrm{clamp}\bigl(x^{(2)}_t - \Delta x^{(2)}_t,\,0,\,X-1\bigr),\, \mathrm{clamp}\bigl(y^{(2)}_t - \Delta y^{(2)}_t,\,0,\,Y-1\bigr),\, \mathrm{clamp}\bigl(z^{(2)}_t - \Delta z^{(2)}_t,\,0,\,Z-1\bigr) \Bigr).
            $$ 
        2.  Then 
            $$
              p^{(2)}_{\,t+1} = \widehat{p}^{(2)}, \quad S^{(2)}_{\,t+1} = S^{(2)}_{\,t+\tfrac12} - 1,
            $$
            while $\,p^{(1)}_{\,t+1} = p^{(1)}_{\,t+\tfrac12},\; S^{(1)}_{\,t+1} = S^{(1)}_{\,t+\tfrac12}.$ 
3.  **Target collection by Player 2**
    If $p^{(2)}_{\,t+1} \in T_{\,t+\tfrac12}$, say $p^{(2)}_{\,t+1} = \tau_m$, then 
    $$
      S^{(2)}_{\,t+1} = S^{(2)}_{\,t+1} + V(\tau_m), \quad T_{\,t+1} = T_{\,t+\tfrac12} \setminus \{\tau_m\}.
    $$ 
    Otherwise, $T_{\,t+1} = T_{\,t+\tfrac12}$. 

At the end of sub‐step $t.2$, we arrive at the new global state
$$
  s_{\,t+1} = \Bigl( p^{(1)}_{\,t+1},\,p^{(2)}_{\,t+1},\,T_{\,t+1},\,S^{(1)}_{\,t+1},\,S^{(2)}_{\,t+1} \Bigr).
$$ 
Because all updates are deterministic given $(s_t,\Delta^{(1)}_t,\Delta^{(2)}_t)$, the transition kernel $\,P(s_{\,t+1}\mid s_t,\Delta^{(1)}_t,\Delta^{(2)}_t)$ is a point‐mass on this unique $s_{\,t+1}$. 
---

## 4. Reward Functions

At the end of full time‐step $t$, Player $i$ receives reward
$$
  r^{(i)}_{\,t+1} = S^{(i)}_{\text{(after }i\text{ moved)}} \;-\; S^{(i)}_{\text{(just before }i\text{ moved)}} \;\in\;\{-1,\,0,\, +V(\tau)\}.
$$ 
* **If Player $i$ collides** on its sub‐step, then $S^{(i)}$ decreased by 1, so $r^{(i)}_{\,t+1}=-1$. 
* **If Player $i$ collects** a target $\tau$ of value $V(\tau)$, then $r^{(i)}_{\,t+1}=+V(\tau)$. 
* **Otherwise**, $r^{(i)}_{\,t+1}=0$. 
Specifically: 

1.  $r^{(1)}_{\,t+1} = S^{(1)}_{\,t+\frac12} - S^{(1)}_t.$ 
2.  $r^{(2)}_{\,t+1} = S^{(2)}_{\,t+1} - S^{(2)}_{\,t+\frac12}.$ 
---

## 5. Observation Spaces $\mathcal{O}^{(i)}$

Because each agent **does know both initial positions** but **does not see the opponent’s current position**, we define: 

* At the start of time‐step $t$, Player $i$ has just observed the environment up to the end of step $t-1$. Its observation $o^{(i)}_t$ is: 
    $$
      o^{(i)}_t = \Bigl(\, p^{(i)}_t,\, p^{(i)}_{\mathrm{init}},\, p^{(j)}_{\mathrm{init}},\, \Delta^{(j)}_{\,t-1},\, T_t \Bigr),
    $$
    where $j=3-i$. 
Concretely, Player $i$ sees: 

1.  **Its own current position** $p^{(i)}_t$. 
2.  **Its own (true) initial position** $p^{(i)}_{\mathrm{init}}$. 
3.  **The opponent’s initial position** $p^{(j)}_{\mathrm{init}}$. 
4.  **The opponent’s most‐recent action** $\Delta^{(j)}_{\,t-1}$. 
5.  **The full set of remaining targets** $T_t$ along with their weights $V(\cdot)$. 
Critically, Player $i$ does *not* observe $p^{(j)}_t$ directly. It must *estimate* $p^{(j)}_t$ using the known initial positions and the history of observed opponent‐actions. 
Formally, 
$$
  \mathcal{O}^{(i)} = W \; \times \; W \; \times \; W \; \times \; \{-1,0,1\}^3 \; \times \; 2^{\,T_{\mathrm{init}}\times\mathbb{Z}_{>0}}\!,
$$ 
and 
$$
  O^{(i)}\bigl(s_t,\,\Delta^{(1)}_{t-1},\,\Delta^{(2)}_{t-1}\bigr) \;=\; \Bigl(\,p^{(i)}_t,\;p^{(i)}_{\mathrm{init}},\;p^{(j)}_{\mathrm{init}},\;\Delta^{(j)}_{\,t-1},\;T_t\Bigr).
$$ 
---

## 6. Belief and Estimation of $p^{(j)}_t$

Since Player $i$ does not directly observe $p^{(j)}_t$, it maintains a *belief* (a distribution) over the possible current positions of $j$. 
In principle, at each time $t$, Player $i$ knows: 

1.  $p^{(j)}_{\mathrm{init}}$ at $t=0$. 
2.  The entire sequence of observed opponent‐actions $\{\Delta^{(j)}_{\,0},\,\Delta^{(j)}_{\,1},\,\dots,\,\Delta^{(j)}_{\,t-1}\}$ up to the previous step. 
3.  The deterministic transition rules of the environment. 

Hence, Player $i$ can compute exactly 
$$
  \widehat{p}^{(j)}_t = \mathrm{simulate}\bigl(p^{(j)}_{\mathrm{init}};\;\Delta^{(j)}_{\,0},\,\Delta^{(j)}_{\,1},\,\dots,\,\Delta^{(j)}_{\,t-1}\bigr),
$$
where “$\mathrm{simulate}$” means “apply each observed $\Delta^{(j)}$ in turn, clamping/collision‐checking against the *estimated* position of Player $i$ in each sub‐step.” 
But since Player $i$ also must track its own estimated position (which it knows exactly), there is no stochasticity: Player $i$ can keep a running update for “what Player $j$ must be doing,” given that $i$ knows every collision event that $j$ would have experienced. 
In other words: 

* At time $t=0$, Player $i$ sets $\widehat{p}^{(j)}_0 = p^{(j)}_{\mathrm{init}}$. 
* For each $t=0,1,\dots,$ when $\Delta^{(j)}_t$ becomes known (one step later), Player $i$ does exactly the same “collision + clamp + bounce” computation that the environment would do for Player $j$ at sub‐step $t.1$ or $t.2$, using rather: 
    1.  $p^{(j)}_{\mathrm{est}}\,(\text{previous})$. 
    2.  $\Delta^{(j)}_{\,t}$. 
    3.  The *true* position of Player $i$ at the corresponding sub‐step (which $i$ knows, since it controls itself). 
Hence at each step, there is **no actual uncertainty** in $p^{(j)}_t$; it is deterministically reconstructible from the known initial positions and the observed opponent‐actions, together with known turn‐order. The only “challenge” is that Player $i$ only learns $\Delta^{(j)}_t$ one sub‐step later—still, that is enough to update $\widehat{p}^{(j)}_{\,t+1}$ exactly. 
---

## 7. Complete Game Definition

We now summarize the environment as a two‐player, turn‐based **partially observable** Markov game with: 

1.  **State space** 
    $$
      \mathcal{S} = \bigl\{\, (\,p^{(1)},\,p^{(2)},\,T,\,S^{(1)},\,S^{(2)}\,) \mid p^{(i)}\in W,\;T\subseteq T_{\mathrm{init}},\;S^{(i)}\in\mathbb{Z} \bigr\}.
    $$ 
2.  **Action spaces** 
    $$
      \mathcal{A}^{(i)} = \{-1,\,0,\,1\}^3,\qquad i=1,2.
    $$ 
3.  **Transition function** 
    Deterministic, defined by the two sub‐steps (Player 1’s move, then Player 2’s move) as in Section 3. 
4.  **Reward functions** 
    $$
      R^{(1)}\bigl(s_t,\Delta^{(1)}_t,\Delta^{(2)}_t,s_{\,t+1}\bigr) = r^{(1)}_{\,t+1}\in\{-1,0,+V(\tau)\},
    $$ 
    $$
      R^{(2)}\bigl(s_t,\Delta^{(1)}_t,\Delta^{(2)}_t,s_{\,t+1}\bigr) = r^{(2)}_{\,t+1}\in\{-1,0,+V(\tau)\},
    $$ 
    as defined in Section 4. 
5.  **Observation functions** 
    $$
      O^{(1)}\bigl(s_t,\Delta^{(1)}_{t-1},\Delta^{(2)}_{t-1}\bigr) = \bigl(p^{(1)}_t,\;p^{(1)}_{\mathrm{init}},\;p^{(2)}_{\mathrm{init}},\;\Delta^{(2)}_{\,t-1},\;T_t\bigr),
    $$ 
    $$
      O^{(2)}\bigl(s_t,\Delta^{(1)}_{t-1},\Delta^{(2)}_{t-1}\bigr) = \bigl(p^{(2)}_t,\;p^{(2)}_{\mathrm{init}},\;p^{(1)}_{\mathrm{init}},\;\Delta^{(1)}_{\,t-1},\;T_t\bigr).
    $$ 
    Each agent $i$ sees its own current cell, both initial positions, the opponent’s last action, and the remaining targets—**but not** $p^{(j)}_t$. 
6.  **Termination** 
    The episode ends at the first $t+1$ such that either 
    * $T_{\,t+1} = \varnothing$ (all targets are gone), or 
    * $t+1 = T_{\max}$ (if a fixed horizon is imposed). 
7.  **Discount factor** 
    Typically $\gamma=1$ for an undiscounted finite horizon, or $\gamma<1$ otherwise. 
---

## 8. Belief Update (Estimating the Opponent’s Position)

Although each agent does not directly see the opponent’s current cell $p^{(j)}_t$, it knows: 

* The true value of $p^{(j)}_{\mathrm{init}}$. 
* The entire sequence of observed opponent‐actions $\Delta^{(j)}_0,\,\Delta^{(j)}_1,\,\dots,\,\Delta^{(j)}_{\,t-1}$. 
* Its own true state and actions, so it knows exactly which collisions or clamps would have affected $j$. 
Therefore, each agent can maintain a **deterministic estimate** 
$$
  \widehat{p}^{(j)}_t = \mathrm{UpdatePosition}\bigl(\,p^{(j)}_{\mathrm{init}};\;\Delta^{(j)}_0,\Delta^{(j)}_1,\dots,\Delta^{(j)}_{\,t-1}\bigr),
$$ 
where “$\mathrm{UpdatePosition}$” means: apply each $\Delta^{(j)}_k$ in turn, 

1.  Clamp to $[0..\,X-1]\times[0..\,Y-1]\times[0..\,Z-1]$. 
2.  If the clamped cell would collide with the *estimated* position of $i$ at that same sub‐step, bounce backwards by $-\Delta^{(j)}_k$. 
Since agent $i$ always knows its own exact position (it controls it), this reconstruction is exact. 
Hence the environment is deterministic from the vantage of each agent’s belief: at time $t$, agent $i$ knows exactly $\widehat{p}^{(j)}_t = p^{(j)}_t$. 
---

## 9. Summary of Key Points

1.  **Grid** 
    $$
      W = \{\,0,\dots,X-1\}\times\{\,0,\dots,Y-1\}\times\{\,0,\dots,Z-1\}.
    $$ 
2.  **Initial Positions** 
    Each player $i$ knows both $p^{(1)}_{\mathrm{init}}$ and $p^{(2)}_{\mathrm{init}}$, and those remain fixed. 
3.  **Turn Order** 
    * Sub‐step $t.1$: Player 1 chooses $\Delta^{(1)}_t$; environment updates $p^{(1)}, S^{(1)}, T$. 
    * Sub‐step $t.2$: Player 2 chooses $\Delta^{(2)}_t$; environment updates $p^{(2)}, S^{(2)}, T$. 
4.  **Collision** 
    If the mover’s clamped “forward” position equals the other player’s current cell, the mover is bounced backwards by $-\Delta$ (clamped) and receives $-1$ point. 
    No collection occurs on a backward‐bounce. 
5.  **Targets** 
    Each $\tau_k\in T$ has value $V(\tau_k)$. 
    If a player lands (without collision) on $\tau_k$, that player gains $+V(\tau_k)$ and $\tau_k$ is removed from $T$. 
6.  **Rewards** 
    At step $t$, Player 1’s reward $r^{(1)}_{\,t+1} = S^{(1)}_{\,t+\frac12} - S^{(1)}_t\in\{-1,0,+V(\tau)\}$. 
    Player 2’s reward $r^{(2)}_{\,t+1} = S^{(2)}_{\,t+1} - S^{(2)}_{\,t+\frac12}\in\{-1,0,+V(\tau)\}$. 
7.  **Observation for Player $i$** 
    $$
      o^{(i)}_t = \bigl(p^{(i)}_t,\;p^{(i)}_{\mathrm{init}},\;p^{(j)}_{\mathrm{init}},\;\Delta^{(j)}_{\,t-1},\;T_t\bigr).
    $$ 
    * Knows its own current position $p^{(i)}_t$. 
    * Knows both initial positions $p^{(i)}_{\mathrm{init}},\,p^{(j)}_{\mathrm{init}}$. 
    * Knows the opponent’s last action $\Delta^{(j)}_{\,t-1}$. 
    * Sees all remaining targets $T_t$ with their values. 
8.  **Belief / Estimation** 
    From these observations, Player $i$ can reconstruct exactly the opponent’s current cell $p^{(j)}_t$ by starting from $p^{(j)}_{\mathrm{init}}$ and sequentially applying each observed $\Delta^{(j)}_k$ (with the same “collision‐bounce” logic, using $i$’s own true position). 
9.  **Termination** 
    Episode ends at the first $t+1$ such that $\,T_{\,t+1} = \varnothing$ (all targets collected) or $t+1 = T_{\max}$ (if a finite horizon is imposed). 
10. **Discount Factor** 
    One typically takes $\gamma=1$ for an undiscounted episodic setting, or any $\gamma<1$ otherwise. 
---

In this formulation, **each agent fully knows**: 

* Its own and the opponent’s **initial** positions ($p^{(i)}_{\mathrm{init}}, p^{(j)}_{\mathrm{init}}$). 
* Its own **current** position $p^{(i)}_t$. 
* The opponent’s **last** action $\Delta^{(j)}_{\,t-1}$. 
* The set of all **remaining targets** (and their weights). 

What an agent **does not see** directly is the opponent’s current position $p^{(j)}_t$. However, because it knows: 

1.  $p^{(j)}_{\mathrm{init}}$; 
2.  all the opponent’s past actions $\Delta^{(j)}_0,\ldots,\Delta^{(j)}_{t-1}$ (revealed one‐at‐a‐time); and 
3.  its own true positions (so it knows exactly when/where opponent collisions would have occurred), 

the agent can reconstruct $p^{(j)}_t$ exactly in a deterministic fashion. 
In that sense, this is only *partially* observable if you insist that “current opponent position” isn’t directly given as part of $o^{(i)}_t$—yet it remains *inferable* from the available information. 
This completes the formal, math‐style definition of the problem under your specified informational assumptions.