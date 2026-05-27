== 2.4 Motion Imitation via Reward Engineering

The first systematic approach to guiding a physics-based character toward
naturalistic movement through motion capture data was introduced by
DeepMimic @peng_deepmimic_2018. Its central insight is that an RL policy can be
made to reproduce a reference motion clip by structuring the reward function
as a kinematic similarity measure between the simulated character and the
reference at each timestep.

=== 2.4.1 Goal-Conditioned Policy and Reference Motion

In DeepMimic, each reference motion is represented as a sequence of target
poses ${ hat(q)_t }$, where each $hat(q)_t$ encodes the full kinematic
configuration of the character at frame $t$. A control policy
$pi(a_t | s_t, g_t)$ maps both the current physical state $s_t$ and a
task-specific goal $g_t$ to a distribution over joint actions $a_t$. The state
$s_t$ is a proprioceptive description of the character's body configuration,
comprising the relative positions of each link with respect to the root joint
(designated as the pelvis), their orientations expressed as quaternions, and
their linear and angular velocities, all computed in the character's local
coordinate frame @peng_deepmimic_2018.

Because the target poses from the reference motion vary continuously with
time, a phase variable $phi in [0, 1]$ is additionally included among the
state features, where $phi = 0$ denotes the start of a motion and $phi = 1$
denotes the end. For cyclic motions, $phi$ is reset to zero after each
complete cycle @peng_deepmimic_2018. This phase signal is indispensable: it
makes the policy aware of where it currently sits within the motion sequence,
allowing it to correctly anticipate and reproduce the timing of each pose.
Without $phi$, the policy would have no mechanism to distinguish, for
instance, the same leg configuration occurring at the beginning of a stride
versus the middle, and would fail to reproduce temporally coherent motion.

The goal signal $g_t$ serves a dual role. It enters the policy network
directly as a conditioning input at every timestep, specifying the high-level
behavioral objective the character should pursue — for instance, a target
heading direction $d^*_t$ for locomotion tasks or a target strike location for
manipulation tasks. Simultaneously, $g_t$ defines the task-specific reward
$r^G_t$, evaluated after each transition, that incentivizes the character to
fulfill that objective. These two roles are architecturally distinct: the
policy observes $g_t$ in order to know *what* to do, and receives $r^G_t$
in order to *learn* to do it effectively. A policy trained without $g_t$ as
an input could not adapt its behavior to novel goals at runtime, even if the
task reward provided a learning signal during training.

=== 2.4.2 Imitation Reward Structure

The total reward at each timestep $t$ is a weighted combination of an
imitation objective $r^I_t$ and a task objective $r^G_t$:

$ r_t = omega^I dot r^I_t + omega^G dot r^G_t $

where $omega^I$ and $omega^G$ are scalar weights. In the original formulation,
$omega^I = 0.7$ and $omega^G = 0.3$ for all tasks @peng_deepmimic_2018. The
task objective $r^G_t$ incentivizes goal fulfillment, such as travelling in
a commanded direction or striking a target. For the target heading task, it
takes the form:

$ r^G_t = exp[-2.5 max(0, v^* - v_t^top d^*_t)^2] $

where $v^*$ is the desired speed, $v_t$ is the character's center-of-mass
velocity, and $d^*_t$ is the unit vector specifying the target direction
@peng_deepmimic_2018. This reward penalizes the character for travelling
slower than the desired speed along the target heading, without penalizing it
for exceeding that speed.

The imitation objective $r^I_t$ encourages the character to match specific
kinematic characteristics of the reference pose $hat(q)_t$ at each step,
and is further decomposed as:

$ r^I_t = w^p dot r^p_t + w^v dot r^v_t + w^e dot r^e_t + w^c dot r^c_t $

with component weights $w^p = 0.65$, $w^v = 0.1$, $w^e = 0.15$,
$w^c = 0.1$ @peng_deepmimic_2018. Each component penalizes a specific type
of kinematic deviation. The pose reward $r^p_t$ measures the angular
discrepancy between the simulated and reference joint orientations:

$ r^p_t = exp[-alpha_p (sum_j || hat(q)^j_t minus.o q^j_t ||^2)] $

where $alpha_p = 2$ is an exponential sharpness factor, $q^j_t$ and
$hat(q)^j_t$ are the orientations of the $j$-th joint from the simulated
character and reference motion respectively, $q_1 minus.o q_2$ denotes the
quaternion difference, and $|| q ||$ computes the scalar rotation of a
quaternion about its axis in radians @peng_deepmimic_2018. The joint velocity
reward $r^v_t$ penalizes deviations in local angular velocities:

$ r^v_t = exp[-alpha_v (sum_j || hat(dot(q))^j_t - dot(q)^j_t ||^2)] $

where $alpha_v = 0.1$ and the target velocity $hat(dot(q))^j_t$ is computed
from the reference data via finite differences. The end-effector reward
$r^e_t$ penalizes mismatches in the world-space positions of the character's
hands and feet:

$ r^e_t = exp[-alpha_e sum_e || hat(p)^e_t - p^e_t ||^2] $

where $alpha_e = 40$ and $p^e_t$ denotes the 3D world position of
end-effector $e in {lr("left foot"), lr("right foot"), lr("left hand"),
lr("right hand")}$ @peng_deepmimic_2018. Finally, the center-of-mass reward
$r^c_t$ penalizes deviations in the root trajectory:

$ r^c_t = exp[-alpha_c || hat(p)^c_t - p^c_t ||^2] $

where $alpha_c = 10$ and $p^c_t$ denotes the center-of-mass position.

=== 2.4.3 Limitations

Despite producing highly natural motion for individual skills, the DeepMimic
paradigm imposes three fundamental constraints that limit its scalability. 
First, the per-clip reward structure requires a separate, independently trained
policy for each reference motion clip. The phase variable $phi$ explicitly
synchronizes the policy with a single temporal sequence, making it
structurally impossible for one policy to generalize across multiple clips
without additional mechanisms @peng_deepmimic_2018. Second, the reward
weights ($w^p$, $w^v$, $w^e$, $w^c$) and sharpness coefficients
($alpha_p$, $alpha_v$, $alpha_e$, $alpha_c$) require careful manual tuning
for each individual skill; small perturbations can cause training to diverge
or converge to degenerate local minima. Third, the datasets must be carefully
processed and retargeted to the specific character morphology before training
begins, since the reward directly compares joint angles between the reference
and simulation. The multi-clip extensions proposed in DeepMimic —
multi-clip rewards, skill selectors, and composite policies — provide partial
workarounds but require additional engineering and do not scale gracefully
to large unstructured motion libraries @peng_deepmimic_2018. These
limitations collectively motivate the adversarial approach described in the
following section.


== 2.5 Adversarial Motion Priors

Adversarial Motion Priors (AMP), introduced by @peng_amp_2021, address the
scalability limitations of reward-engineered imitation by replacing the
handcrafted multi-term objective with a learned discriminator that
automatically captures the statistical characteristics of the reference motion
data. The central insight is that natural motion can be defined not by
explicit per-joint kinematic metrics synchronized to a single clip, but by a
distribution: the set of state transitions that "look like" the reference
data. This approach draws on the adversarial training framework from
Generative Adversarial Networks goodfellow_gan_2014 and its application to
imitation learning in Generative Adversarial Imitation Learning
ho_ermon_2016.

=== 2.5.1 Architecture and Variable Definitions

The full AMP training loop is illustrated in fig_amp and involves the
following components, each of which is defined precisely below.

The *environment* advances the physics simulation by one timestep given an
action $a_t in RR^(n_"act")$, producing a new state $s_{t+1}$ and a
complete state transition $(s_t, s_{t+1})$. Here $n_"act"$ is the
dimensionality of the action space — the number of joint angle targets output
by the policy. For a 12-degree-of-freedom quadruped character, $n_"act" = 12$.

The *state* $s_t in RR^(n_s)$ is a proprioceptive description of the
character's current physical configuration, following the same convention as
DeepMimic: root position and orientation, linear and angular velocities, and
local joint angles and velocities, all expressed in the character's root
coordinate frame @peng_amp_2021. Unlike DeepMimic, AMP does not include a
phase variable $phi$ in $s_t$, because the discriminator does not require
temporal synchronization with a specific clip — it evaluates each transition
independently.

The *policy* $pi_theta(a_t | s_t, g_t)$ is the actor network, parameterized
by weights $theta$, that maps the current state and task goal to a Gaussian
distribution over actions, from which joint angle targets $a_t$ are sampled.
The policy receives two separate inputs at every timestep: the proprioceptive
state $s_t$, and the task goal $g_t$. As discussed in Section 2.4, these
serve distinct roles — $s_t$ describes the current physical configuration
of the character, while $g_t$ specifies the high-level behavioral objective
to be accomplished.

The *task goal* $g_t$ is a runtime-specified conditioning vector that
communicates the desired high-level behavior to the policy. In the locomotion
setting, $g_t = d^*_t in RR^2$ is a unit vector specifying a target heading
direction in the horizontal plane; during training it is randomized at each
episode, and at deployment it is controlled by the user via joystick or a
navigation module @peng_amp_2021. The arrow $g -> pi$ in fig_amp
represents this direct input: the policy network concatenates $g_t$ with
$s_t$ and processes both through its hidden layers to produce action $a_t$.

The *dataset* $cal(M)$ is an unstructured collection of motion capture clips
— in this thesis, the MANN dog dataset zhang_mann_2018. Unlike DeepMimic,
AMP imposes no requirements on clip ordering, clip boundaries, temporal
annotations, or skill labels. The dataset is accessed by randomly sampling
transition pairs $(s, s') ~ cal(M)$, where $s$ and $s'$ are consecutive
frames extracted from any clip.

The *motion prior* $D_psi(s_t, s_{t+1}) in [0, 1]$ is the discriminator
network, parameterized by weights $psi$, that receives a state transition
pair as input and is trained to distinguish transitions drawn from the
reference dataset $cal(M)$ from those generated by the policy during
simulation @peng_amp_2021. It is optimized using a least-squares objective
augmented by a gradient penalty gulrajani_2017 for training stability:

$ cal(L)_D = EE_((s,s') ~ cal(M))[(D_psi (s, s') - 1)^2]
           + EE_((s,s') ~ pi)  [(D_psi (s, s') + 1)^2]
           + lambda_"gp" dot EE[|| nabla_psi D_psi ||^2] $

where $cal(M)$ denotes sampling from the reference dataset, $pi$ denotes
sampling from the current policy's rollout, and $lambda_"gp"$ is the
gradient penalty coefficient — the most critical hyperparameter for
discriminator training stability @peng_amp_2021.

The *style reward* $r^S_t in [0, 1]$ is computed from the discriminator's
output and serves as the learned motion quality signal:

$ r^S_t (s_t, s_{t+1}) = max(0, 1 - 0.25 dot (D_psi (s_t, s_{t+1}) - 1)^2) $

This reward approaches 1 when the policy produces transitions that the
discriminator classifies as indistinguishable from the reference data, and
approaches 0 for transitions that fall outside the reference distribution
@peng_amp_2021. The arrow $r^S_t -> plus.o$ in fig_amp represents
this signal flowing into the reward aggregation node.

The *task reward* $r^G_t in RR$ evaluates the character's progress toward
the high-level goal $g_t$ and takes the same form as in DeepMimic:

$ r^G_t = exp[-2.5 max(0, v^* - v_t^top d^*_t)^2] $

where $v^*$ is the desired speed and $v_t$ is the character's center-of-mass
velocity @peng_amp_2021. The arrow $r^G_t -> plus.o$ in fig_amp
represents this signal entering the reward aggregation node alongside
$r^S_t$.

The *total reward* $r_t$ is the sum of both components, aggregated at the
$plus.o$ node and fed back to update the policy via PPO:

$ r_t = w^S dot r^S_t + w^G dot r^G_t $

where $w^S$ and $w^G$ are scalar weights balancing motion naturalness
against task fulfillment @peng_amp_2021. The arrow $r_t -> pi$ in
fig_amp represents this combined learning signal flowing back to update the
policy parameters $theta$ via PPO.

=== 2.5.2 Key Advantages Over DeepMimic

The AMP formulation eliminates all three limitations of DeepMimic identified
in Section 2.4. First, because the discriminator evaluates randomly sampled
transition pairs $(s_t, s_{t+1})$ independently of clip boundaries and
without a phase variable, a single policy can be trained on an entire
unstructured motion library simultaneously, without requiring separate
per-clip policies or a clip selection mechanism
@peng_amp_2021. Second, because the style reward is produced by a learned
function rather than a handcrafted formula, no manual reward weight
specification is required beyond the single scalar $w^S$. Third, because
the discriminator operates on state transitions rather than absolute poses,
the reference dataset does not need to be precisely retargeted to the
character's morphology at the joint level — the discriminator learns
what constitutes a natural transition directly from the data.

Crucially, both the task goal $g_t$ and the task reward $r^G_t$ remain
present in AMP and serve the same dual purpose as in DeepMimic: $g_t$
directly conditions the policy at runtime to specify *where* the character
should go, while $r^G_t$ provides the learning signal that teaches the
policy to pursue that goal effectively. The style reward $r^S_t$ from the
discriminator adds the complementary signal that teaches the policy *how*
to move, without prescribing specific joint configurations. This separation
of concerns — style from task — is the architectural core of AMP, and
produces policies that are simultaneously physically natural (governed by
$r^S_t$) and goal-directed (governed by $r^G_t$ and $g_t$).

#bibliography("zotero.bib", style: "apa")