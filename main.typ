#set page(
  paper: "a4",
  margin: (left: 3cm, right: 2cm, top: 3cm, bottom: 2cm),
)

#set text(
  font: "New Computer Modern",
  size: 12pt,
  lang: "en",
)

// Justified text with first-line indent, no spacing between paragraphs

#set par(
  justify: true,
  leading: 0.65em,
  first-line-indent: (amount: 1.25cm, all: true)
)

// Headings: bold, flush left, same font, numbered
#set heading(numbering: "1.1")

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  // v(1.5cm)
  block(width: 100%, {
    set par(first-line-indent: 0pt)
    if it.numbering != none [
      #align(left, text(size: 26pt, weight: "bold")[
        Chapter #counter(heading).display()
      ])
    ]
    v(.25cm)
    align(left, text(size: 26pt, weight: "bold")[#it.body])
  })
  v(.75cm)
}
#show heading.where(level: 2): it => {
  set par(first-line-indent: 0pt)
  text(size: 16pt, weight: "bold")[
    #counter(heading).display() #h(0.5em) #it.body
  ]
}

#show heading.where(level: 3): it => {
  set par(first-line-indent: 0pt)
  text(size: 16pt, weight: "bold")[
    #counter(heading).display() #h(0.5em) #it.body
  ]
}

// Separate show rule for unnumbered headings (ToC, LoF, LoT)
#show heading.where(outlined: false): it => {
  pagebreak(weak: true)
  block(width: 100%, {
    align(left, text(size: 18pt, weight: "bold")[#it.body])
  })
  v(0.5cm)
}

// --- COVER PAGE ---

#align(center)[
  #text(weight: "bold")[
    FEDERAL UNIVERSITY OF ALAGOAS \
    COMPUTING INSTITUTE \
    POSTGRADUATE COORDINATION IN INFORMATICS
  ]

  #v(4cm)

  #text(14pt, weight: "bold")[MASTER’S THESIS PROPOSAL]

  #v(2cm)

  #text(16pt, weight: "bold")[
   // Retargeting-Free Motion Imitation for Cross-Morphological Characters via Latent-Driven RL
   Adversarial Motion Priors for Physics-Based Quadrupedal Locomotion Using Animal Motion Capture Data
  ]

  #v(2cm)

  #text(weight: "bold")[MASTER’S CANDIDATE] \
  HUGO TALLYS MARTINS OLIVEIRA

  #v(2cm)

  #text(weight: "bold")[ADVISOR] \
  GLAUBER RODRIGUES LEITE, DR.

  #v(1fr)

  MACEIÓ, AL \
  JUNE - 2026
]

#pagebreak()

// --- FRONT MATTER (Lists) ---

#set page(numbering: "i")
#counter(page).update(1)

#outline(
  title: "List of Figures", target: figure.where(kind: image)
)
#pagebreak()

#outline(
  title: "List of Tables", target: figure.where(kind: table)
)
#pagebreak()

#outline(title: "Contents", indent: auto)
#pagebreak()

// --- MAIN BODY ---
#set page(numbering: "1")
#counter(page).update(1)
#set heading(numbering: "1.1")
#set par(
  first-line-indent: 20pt,
  justify: true,
)

= Introduction

== The Problem

*New framing*: The problem is that PPO trained with task-only rewards produces physically valid but perceptually unnatural quadruped locomotion. Motion capture data from real animals contains the style information needed to close this gap, but integrating it into the RL loop requires either tedious per-skill reward engineering (DeepMimic) or an adversarial approach (AMP). Applying AMP to quadruped locomotion using real animal mocap (MANN dataset) on a specific robot morphology (Go2) has not been systematically evaluated in the physics-based animation literature.

== Main Objective

*New version*: This work aims to investigate and evaluate the application of Adversarial Motion Priors (AMP) for physics-based quadrupedal locomotion, using real dog motion capture data from the MANN dataset retargeted to a simulated Unitree Go2 character in MuJoCo.

=== Specific Objectives

1. To implement and evaluate a task-reward only PPO baseline for Go2 locomotion.
2. To develop an explicit retargeting pipeline from the MANN dog skeleton to the Go2 morphology.
3. To train and evaluate an AMP policy on the retargeted MANN dataset.
4. To systematically compare AMP against the PPO baseline on motion naturalness, gait quality, and task performance metrics.

/*
OLD RESEARCH SCOPE (MIGHT BE USEFUL REMINDER/MOTIVATION LATER)

1. Understand how operations in the latent space reflect in the character movement
2. To compare with distinct approaches to the problem (skeleton aware, DRL Immitation, classical IK, jacobian optimization)
3.To analyze how semantic intents encoded within a shared, topology-agnostic latent space translate into dynamically feasible character movement.
2. To systematically compare the latent-driven approach against distinct traditional retargeting baselines.
3. To evaluate how working with latent spaces enhances and stabilizes pure physics-based RL approaches.
4. To establish a retargeting-free paradigm where complex animation arises as emergent behavior.
*/

== Relevance of the Proposal

*Frame around:* 

(1) quadruped animation is under-served compared to humanoid, (2) real animal mocap is available but under-utilised for physics-based control, (3) AMP eliminates reward engineering burden, making it practical for diverse datasets.

== Structure

// TODO (LASTLY)

= Background

This chapter introduces how we represent virtual characters and animate them using a physics based approach guided by machine learning techniques. We begin describing how articulated characters are physically simulated, then formalize how reinforcement learning policies are used to control these characters and how motion imitation can be achieved through the process of reward engineering. To address the limitations of handcrafted objectives, we present Adversarial Motion Priors (AMP) as a principled, data-driven alternative capable of extracting naturalistic style rewards directly from unstructured motion datasets.

== Physics-Based Character Animation

In traditional keyframe animation, the animator is responsible for specifying the exact position and orientation of every armature bone across time. In contrast, procedural physics-based animation shifts this responsibility to a physics based animation system. By explicitly modeling physical properties such as mass, gravity, and inertia, this system automatically calculates how objects should accelerate, collide, and come to rest. This approach allows natural, physically realistic movements to emerge organically from the simulation, freeing the animator from manually crafting complex environmental reactions.

In physics-based character animation, virtual characters are modeled as articulated rigid body systems os simply _articulated figures_. An articulated figure can be thought of as a robot arm or a human arm made of a number of solid rods, referred to as links or bodies, which are connected to each other by joints that can move independently. When all the joints move, the overall motion of an articulated figure can be very complex @erleben_physics-based_2005. Each joint provides the connected segments with specific degrees of freedom: revolute joints allow rotation around a single axis, while ball joints permit rotation around multiple axes. The structural connectivity built into this hierarchy ensures that physical segments remain attached as the joints articulate. Every rigid segment is assigned dynamic properties such as, collision geometry, mass and inertia dictating its resistance to changes in linear and angular velocity.

To animate articulated figures, physics engines continuously integrate both internal joint torques and external forces—such as gravity, friction, and collision over discrete, minuscule time steps to update the character's full dynamic state. Relying purely on traditional kinematics-based approaches to manually calculate and keyframe these complex, frame-by-frame physical interactions would be an overwhelmingly time-consuming task and practically impossible for an human animator. By automatically resolving these intricate physical laws, the engine provide a crucial layer of abstraction that adds another level of realism and dynamism into the simulation.

In the case of articulated figures, movement is driven internally by actuating the mechanical joints using proportional-derivative (PD) controllers. Instead of applying raw forces directly, a PD controller calculates the specific continuous torque required to pull a joint toward a desired target state based on proportional (stiffness) and derivative (damping) gains: 

$ tau = k_p dot.c (q_"target" - q_"current") - k_d dot.c dot(q)_"current" $

In the context of RL, physics engines are essential because they enable the complex, embodied agent-environment interactions necessary to train generalizable intelligence. Rather than requiring the agent to learn a policy involving highly volatile mapping of raw mechanical torques, it is only tasked with outputting kinematic _intents_, the target joint positions or velocities. The PD controller then serves as a localized physical translator that handles the exact force computations, providing an important level of abstraction. This hierarchical separation dramatically accelerates learning speed and enhances training stability, as it allows the RL policy to optimize over a much smoother, lower-dimensional action space while the underlying controller ensures the execution remains physically compliant.

Physics engines provide the foundational computations needed to generate high-complexity 3D training environments, with some frameworks like NVIDIA's PhysX/IsaacGym leveraging GPU acceleration to avoid CPU bottlenecks and significantly scale up parallel RL training. High-fidelity engines, like MuJoCo, also offer the physical accuracy required for robust, transferable RL policies. Selecting and deploying these specialized engines introduces a steep learning curve, particularly for researchers who lack deep domain expertise. The most computationally efficient and physically accurate simulators often suffer from poor usability, scattered documentation, and complex workflows for custom environment design @kaup_review_nodate. 

On the other end of the spectrum, while consumer game engines such as Unity offer highly accessible development workflows, they frequently exhibit limited parallelization scalability and insufficient simulation fidelity, which ultimately compromises the reproducibility of reinforcement learning results. Consequently, choosing an appropriate physics engine requires researchers to navigate an acute trade-off between software usability, computational throughput, and physical accuracy. Consequently, selecting an appropriate physics engine requires researchers to carefully balance development usability, computational throughput, and physical accuracy.

== Reinforcement Learning for Continuous Control

The problem of controlling a physically simulated character can be formally defined as a Markov Decision Process (MDP). At each discrete time step $t$, an agent observes the state of the environment $s_t$ and selects a continuous action $a_t$ according to a policy $pi$. Following the generalized formulation of policy-based reinforcement learning, a policy is parameterized by a dedicated parameter vector $theta in RR^(d')$. This policy maps a given state to a probability distribution over the action space:

$ pi(a | s, theta) = Pr(A_t = a | S_t = s, theta_t = theta) $

The environment transitions to a new state $s_(t+1)$ according to its internal physics dynamics and returns a scalar reward $r_t$ evaluating the desirability of that transition. The agent's objective is to find policy parameters $theta^*$ that maximize the expected cumulative discounted return ($R_t$):

$ J(theta) = bb(E)_(pi_theta) [ sum_(t=0)^T gamma^t r_t ] $ 

where $gamma in [0, 1)$ is the discount factor and $T$ is the episode horizon.

Unlike traditional action-value methods that evaluate and select actions based on estimated state-action utilities, policy gradient architectures learn a direct mapping capable of selecting actions without actively consulting a value function at the time of execution. The agent optimizes the parameter vector by evaluating the gradient of a scalar performance measure $J(theta)$, systematically updating the weights via stochastic gradient ascent:

$ theta_(t+1) = theta_t + alpha nabla hat(J(theta_t)) $

where $hat(J(theta_t))$ is a stochastic estimate whose expectation approximates the gradient of the performance measure with respect to its argument $theta_t$.

For continuous or high-dimensional action spaces, explicitly mapping individual action probabilities becomes intractable. Instead, the policy parameterization is designed to learn the essential statistics of a continuous probability distribution. For instance, a continuous policy can be parameterized as a normal (Gaussian) density function where the mean $mu(s, theta)$ and standard deviation $sigma(s, theta)$ are governed by parametric function approximators (Sutton & Barto, 2018, Ch. 13.7):

$ pi(a | s, theta) = 1 / (sigma(s, theta) sqrt(2 pi)) exp(- (a - mu(s, theta))^2 / (2 sigma(s, theta)^2)) $

To optimize this landscape efficiently, actor-critic frameworks decouple the learning system into an "actor" which encapsulates the parameterized policy for action selection, and a "critic" which approximates a state-value function $hat(v)(s, w)$ to evaluate those selections. The critic does not wait until the end of an episode to score the overall performance, a method also known as Monte Carlo (MC) evaluation. Because simulations contain many random events, waiting until the end to assign a score makes it difficult to determine exactly which individual actions led to success or failure, resulting in a noisy learning signal. Instead, the critic uses temporal difference (TD) bootstrapping, meaning it constantly updates its prediction of the value function at each step, refining its current guess based on its guess for the next state. This approach smooths out the learning signal, providing the actor with immediate and more reliable feedback.

== Proximal Policy Optimization Algorithms

For the continuous, high-dimensional action spaces encountered in character control, Proximal Policy Optimization (PPO) @schulman_proximal_2017 has become the dominant algorithm across both robotics and physics-based animation research, precisely because it is stable enough to train deep neural networks over long horizons without collapsing, yet simple enough to implement and tune. PPO is an actor-critic method that maintains two separate neural networks in an episodic learning setting. The actor network defines our policy $pi_theta$ mapping the current state to a parametrized gaussian distribution over continuous actions from which joint targets are sampled. The critic network $V_phi (s_t)$ is a value estimator that learns to predict the expected cumulative return from any given state, serving as a learned baseline. The critic's predictions are used to compute advantage estimates

$ hat(A)_t = R_t - V_phi (s_t) $

which measures how much better or worse the action actually taken was compared to what the critic expected on average.

A positive advantage means the action led to better-than-expected outcomes and should be reinforced whereas a negative advantage means it should be avoided. The key innovation of PPO is a _clipped surrogate objective_ that prevents destructively large policy updates:

$ L^"CLIP" (theta) = bb(E)_t [ min(r_t (theta) hat(A)_t, "clip"(r_t (theta), 1 - epsilon, 1 + epsilon) hat(A)_t) ] $

where $r_t (theta) = (pi_theta (a_t | s_t)) / (pi_(theta_"old") (a_t | s_t))$ is probability ratio between the updated and previous policy and $epsilon$ (typically 0.2) bounds the update magnitude. This clipping mechanism acts as a conservative guardrail on how far the policy is permitted to move in a single update step avoiding unconstrained gradient steps that risk causing irreversible drops in action probabilities, leading to deterministic policy collapse or highly unstable exploration @schulman_trust_2017. 

Despite this stability, controlling characters trained with PPO faces a fundamental perceptual problem when applied to articulated figures. The algorithm is agnostic to what natural _motion intent_ looks like as it optimizes whatever scalar reward it is given. When that reward is defined purely in terms of task completion such as reach a target velocity, navigate the terrain or stay upright, the policy discovers physically valid solutions that satisfy the objective while looking somewhat awkward to our common sense. Joints snap to extreme angles, limbs swing in mechanically efficient but biologically implausible patterns, and transitions between gaits produce the sudden, discontinuous lurches characteristic of the uncanny valley. 

The root cause is not a failure of the algorithm but a difficulty of reward engineering. Without an explicit signal encoding how a character should move, PPO has no basis for preferring natural motion over any other physically feasible solution. Designing reward functions that fully capture motion intent is notoriously difficult and specific to each problem. This is the central limitation that motion imitation methods, discussed in the following section, are designed to address.

#figure(
  image("diagrams/ppo-overview.pdf", width: 85%),
  caption: [
    PPO algorithm overall structure. Adapted from @kim_ppo_2025. 
  ],
) <fig:ppo_structure>

== Motion Imitation via Reward Engineering

A major milestone in physics based character control through imitation learning was introduced in the DeepMimic framework by @peng_deepmimic_2018. Its central insight is that an RL policy can be trained to reproduce a reference motion clip by structuring the reward function as a kinematic similarity measure between the simulated character and the reference at each time step.

In DeepMimic, each reference motion is represented as a sequence of target
poses ${ hat(q)_t }$, where each $hat(q)_t$ encodes the full kinematic
configuration of the character at frame $t$. A control policy
$pi(a_t | s_t, g_t)$ maps both the current physical state $s_t$ and a
task-specific goal $g_t$ to a distribution over joint actions $a_t$. The state
$s_t$ is a proprioceptive description of the character's body configuration,
comprising the relative positions of each link with respect to the root joint
(usually designated as the pelvis), their orientations expressed as quaternions, and their linear and angular velocities, all computed in the character's local coordinate frame @peng_deepmimic_2018.

To make the policy aware of where it currently sits within the motion sequence a phase variable $phi in [0, 1]$ is included among the
state features, where $phi = 0$ denotes the start of a motion and $phi = 1$
denotes the end. For cyclic motions, $phi$ is reset to zero after each
complete cycle. Without $phi$, the policy would have no mechanism to distinguish, the same joint configuration occurring at the beginning, middle or end of a clip and would fail to reproduce temporally coherent motion.

The goal signal $g_t$ serves as a conditioning input at every time step to specify the character's high-level objective, such as a target heading direction for locomotion tasks, while simultaneously defining the task-specific reward $r^G_t$ used after each transition to incentivize task completion. This architectural distinction forms the foundation of _Goal-Conditioned Reinforcement Learning_ (GCRL). By feeding the goal as an explicit input rather than relying solely on the reward signal, the policy is not locked into fixed behaviors, allowing the character to dynamically adapt to novel goals at runtime.

The total reward at each time step $t$ is a weighted combination of an
imitation objective $r^I_t$ and the task objective $r^G_t$

$ r_t = omega^I dot r^I_t + omega^G dot r^G_t $

where $omega^I$ and $omega^G$ are scalar weights. In its original formulation,
$omega^I = 0.7$ and $omega^G = 0.3$ for all tasks @peng_deepmimic_2018. For the target heading task, $r^G_t$ takes the form:

$ r^G_t = exp[-2.5 thin max(0, v^* - v_t^top d^*_t)^2] $

where $v^*$ is the desired speed, $v_t$ is the character's center of mass
velocity, and $d^*_t$ is the unit vector specifying the target direction
@peng_deepmimic_2018. This reward penalizes the character for travelling
slower than the desired speed along the target heading, without penalizing it
for exceeding that speed.

The imitation objective $r^I_t$ encourages the character to match specific
kinematic characteristics of the reference pose $hat(q)_t$ at each step,
and is decomposed as:

$ r^I_t = w^p dot r^p_t + w^v dot r^v_t + w^e dot r^e_t + w^c dot r^c_t $

with component weights $w^p = 0.65$, $w^v = 0.1$, $w^e = 0.15$,
$w^c = 0.1$ @peng_deepmimic_2018. Each component penalizes a specific type
of kinematic deviation. The pose reward $r^p_t$ measures the angular
discrepancy between the simulated and reference joint orientations:

$ r^p_t = exp[-alpha_p (sum_j || hat(q)^j_t minus.o q^j_t ||^2)] $

where $alpha_p = 2$ is an exponential factor, $q^j_t$ and
$hat(q)^j_t$ are the orientations of the $j$-th joint from the simulated
character and reference motion respectively, $q_1 minus.o q_2$ denotes the
quaternion difference and $|| q ||$ computes the scalar rotation of a
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

Despite producing highly natural motion for individual skills, the DeepMimic
paradigm imposes some constraints that limit its scalability. First, the per-clip reward structure requires a separate, independently trained
policy for each reference motion clip. The phase variable $phi$ explicitly
synchronizes the policy with a single temporal sequence, making it
structurally impossible for one policy to generalize across multiple clips
without additional mechanisms @peng_deepmimic_2018. Second, the reward
weights ($w^p$, $w^v$, $w^e$, $w^c$) and its coefficients
($alpha_p$, $alpha_v$, $alpha_e$, $alpha_c$) require careful manual tuning
for each individual skills: small perturbations can cause training to diverge
or converge to degenerate local minima. Third, the rigid per-frame tracking penalizes physically valid but stylistically different solutions, producing brittle policies that cannot smoothly transition between distinct skills. The multi-clip extensions proposed in DeepMimic such as multi-clip rewards, skill selectors, and composite policies provide partial workarounds, but require additional engineering and do not scale gracefully to large unstructured motion libraries @peng_deepmimic_2018. These limitations collectively motivate the adversarial approach described in the following section.

== Adversarial Motion Priors

Adversarial Motion Priors (AMP), introduced by @peng_amp_2021, addresses the scalability limitations of reward-engineered imitation by extending the standard goal-conditioned reinforcement learning formulation. Specifically, it replaces handcrafted multi-term imitation objectives with a learned adversarial discriminator that automatically captures the statistical characteristics of unstructured reference motion data. Fundamentally, AMP operates on the premise that natural motion can be formulated as a distribution of state transitions matching those within a reference dataset. To align the simulated character's behavior with this distribution, the framework builds upon the adversarial training paradigm of Generative Adversarial Networks (GANs) @goodfellow_generative_2020 and its specific extension to imitation learning via Generative Adversarial Imitation Learning (GAIL) @ho_generative_2016

As illustrated in @fig:amp_structure, the policy $pi_theta (a_t | s_t, g_t)$ operates within
a physics simulation environment, receiving at each time step a proprioceptive
state $s_t$ that encodes root kinematics, joint angles and velocities in
the character's local coordinate frame, alongside its task goal $g_t$. The policy maps this observation to a Gaussian distribution over joint angle targets $a_t$, which are then executed through
PD controllers to produce physically consistent torques. In
contrast to DeepMimic, AMP omits the phase variable $phi$ from the state
representation entirely, since the adversarial objective does not require
temporal synchronization between the simulated character and any specific
reference clip.

To evaluate motion quality without explicit manual reward engineering, AMP introduces a data-driven motion prior. This component utilizes an adversarial discriminator network, $D_psi (s_t, s_{t+1}) in [0, 1]$, which is trained jointly with the policy. The discriminator is optimized to distinguish state transition pairs drawn from a reference motion capture dataset $cal(M)$ from those generated by the policy's rollout distribution $pi$. To ensure training stability, the network minimizes a least-squares adversarial objective augmented by a gradient penalty @gulrajani_improved_2017:

$ cal(L)_D = bb(E)_((s,s') tilde cal(M)) [(D_psi (s,s') - 1)^2]
           + bb(E)_((s,s') tilde pi) [(D_psi (s,s') + 1)^2]
           + lambda_"gp" dot bb(E)[|| nabla_psi D_psi ||^2] $

where $lambda_"gp"$ represents the gradient penalty coefficient, which serves as the most critical hyperparameter for stabilizing adversarial training. 

The discriminator's output is converted into a style reward signal for the RL policy, approaching $1$ when the policy produces transitions that the discriminator classifies as similar to the reference data, and $0$ for transitions that deviate from the reference distribution:

$ r^S_t (s_t, s_(t+1)) = max(0, 1 - 0.25 dot (D_psi (s_t, s_(t+1)) - 1)^2) $

The dataset $cal(M)$ is accessed by randomly sampling consecutive frame pairs
$(s, s') tilde cal(M)$ without requiring clip boundaries, temporal
annotations, or skill labels, which allows the discriminator to capture the
full statistical character of the motion library rather than enforcing
correspondence with any individual sequence. This is a fundamental advantage over _DeepMimic_, since the policy is not penalized for being at the wrong frame of a specific clip, but rather for producing transitions that fall outside the statistical distribution of all reference motions. The policy can therefore autonomously discover how to compose and blend behaviors from a diverse dataset, without requiring explicit motion selection or blending machinery.

This adversarial style signal is combined with a task reward $r^G_t$ that
evaluates the character's progress toward the goal $g_t$. The total reward $r_t = w^S dot r^S_t + w^G dot r^G_t$ aggregates both objectives through scalar weights $w^S$ and $w^G$, and is
fed back through PPO to update the policy parameters $theta$. The state representation $s$ used by the discriminator is a design choice that determines what aspects of motion are judged. Typical representations include root height, root orientation, body linear and angular velocities, joint positions relative to the root, joint velocities, and foot contact states. When the reference motion data and the simulated character share the same skeletal structure, these features can be extracted directly from both sources without any intermediate processing.

The AMP formulation eliminates all three limitations of DeepMimic identified in Section 2.4. First, because the discriminator evaluates randomly sampled transition pairs $(s_t, s_(t+1))$ independently of clip boundaries and without a phase variable, a single policy can be trained on an entire unstructured motion library simultaneously, without requiring separate per-clip policies or a clip selection mechanism @peng_amp_2021. Second, because the style reward is produced by a learned adversarial function rather than a handcrafted multi-term formula, no manual reward weight specification is required beyond the single scalar $w^S$. Third, because the motion prior evaluates task-agnostic observation features without requiring temporal synchronization, the system eliminates the need for manual clip annotation, segmentation, or alignment of the reference motions. The discriminator automatically learns to compose and transition between distinct behaviors directly from the raw dataset.

While AMP provides a highly flexible and automated alternative to manual reward engineering, the framework possesses a few known limitations. When trained on highly diverse datasets encompassing multiple distinct behaviors, the adversarial discriminator evaluates motions globally, acting strictly as a data distribution evaluator without explicitly separating or indexing the available skills. In practice, this lack of explicit structure can sometimes precipitate mode collapse, wherein the policy shortcuts the learning process by converging onto a single, highly stable dominant gait, ignoring other behaviors in the dataset. Consequently, interactive controllability relies heavily on the task reward channel (such as a target velocity vector) to coax the policy into different behaviors. Although addressing this mode collapse and the lack of explicit skill request mechanisms remains an active area for future work in representation learning, vanilla AMP remains exceptionally effective for extracting generalized, naturalistic priors for targeted motor domains such as quadrupedal locomotion.

#figure(
  image("figures/amp.png", width: 75%),
  caption: [
    Overview of the Adversarial Motion Priors (AMP) framework. The policy is trained on a combined task reward for achieving a goal and a style reward from a learned discriminator evaluating motion naturalness. Adapted from @peng_amp_2021.
  ],
) <fig:amp_structure>

== Structured Latent Motion Representations

The AMP limitations identified previously namely, mode collapse on diverse datasets and the absence of an explicit channel for requesting a specific skill at runtime, relies on the fact vanilla AMP imposes no organized structure over the space of motions contained in $cal(M)$. The discriminator provides a single global verdict on whether a transition is natural, but it offers the policy no compact handle by which a distinct behavior could be selected. A natural remedy is to learn an explicit, structured representation of the motion data in which qualitatively different behaviors — walking, trotting, galloping — occupy distinct, addressable regions. Such a representation can then serve as an additional conditioning input to the control policy, supplying the skill-selection channel that the task reward alone cannot provide. Two broad families of latent representation exist, distinguished by whether the latent variable is continuous or discrete.

=== Continuous Latent Spaces

The Variational Autoencoder (VAE) @kingma_auto-encoding_2022 is a widely accepted generative model commonly utilized to learn continuous latent representations of complex data. A VAE couples an encoder $E_phi$, which maps an input $x$ to a distribution over a latent vector $z in RR^d$, with a decoder $G_theta$, which reconstructs the input from $z$. Rather than encoding $x$ to a single point, the encoder outputs the parameters of a Gaussian posterior $q_phi (z | x) = cal(N)(mu_phi (x), sigma_phi (x))$, from which $z$ is sampled. Training minimizes a reconstruction error together with a Kullback–Leibler regularization term that pulls the posterior toward a standard normal prior $p(z) =  cal(N)(0, I)$:

$ cal(L)_"VAE" = bb(E)_(q_phi (z | x)) [ |x - G_theta(z)|^2 ] + beta dot D_"KL" (q_phi (z | x) || p(z)) $

Because sampling is not differentiable, the VAE employs the reparameterization trick, expressing $z = mu_phi (x) + sigma_phi (x) dot.o epsilon$ with $epsilon ~ cal(N)(0, I)$, so that gradients flow through $mu_phi$ and $sigma_phi$ @kingma_auto-encoding_2022. The KL term encourages a smooth, continuous latent space in which nearby codes decode to similar outputs.

#figure(
  image("figures/vae-trick.png", width: 75%),
  caption: [
    Illustration of the reparameterization trick. By isolating the random noise $epsilon$ from the network's parameters, this technique allows gradients to successfully backpropagate through the mean and variance during training. Adapted from @noauthor_pdf_nodate
  ],
) <fig:vae_trick>

In the context of physics-based control, this continuous structure has been exploited directly: Adversarial Skill Embeddings (ASE) @peng_ase_2022 condition the low-level policy on a continuous latent $z in RR^64$, and Versatile Motion Priors (VMP) (Serifi et al., 2024) condition on a time-varying latent extracted by a VAE over short motion windows. The smoothness that makes such spaces easy to interpolate is, however, a liability when the dataset contains qualitatively distinct behaviors. Interpolating between the latent code for a walk and the code for a gallop produces a blurred, averaged motion rather than a clean switch between the two gaits a problem known as mode-averaging @zhu_neural_2023  (Zhu et al., 2023). For a dataset such as MANN, whose value lies precisely in its discrete repertoire of named gaits, this averaging is undesirable.

Discrete latent representations avoid the mode averaging by replacing the continuous latent vector with an index into a finite codebook of learned prototype vectors. Each input is assigned to exactly one codebook entry, producing a hard partition of the data in which an entry is either selected or not, with no blended intermediates. Vector Quantized Variational Autoencoders (VQ-VAE) @oord_neural_2017 implements this idea with an encoder $E$, a codebook $cal(C) = {e_1, ..., e_K}$ of $K$ vectors in $RR^D$, and a decoder $G$. Given an input $x$, the encoder produces a continuous vector $z_e = E(x)$, which is quantized to its nearest codebook entry

$ z_q = e_k, quad k = arg min_j |z_e - e_j|_2 $

and the decoder reconstructs $hat(x) = G(z_q)$. Likewise in standard VAEs, because the $arg min$ is not differentiable, gradients are passed from decoder input to encoder output unchanged via the straight-through estimator. Training minimizes a reconstruction loss together with two terms that align the codebook and the encoder:

$ cal(L)_"VQ" = underbrace(|x - hat(x)|^2, "reconstruction") + underbrace(|op("sg")[z_e] - z_q|^2, "codebook") + underbrace(beta |z_e - op("sg")[z_q]|^2, "commitment") $

where $"sg"[ thin dot thin ]$ is the stop-gradient operator. The codebook term moves the entries toward the encoder outputs (often replaced in practice by an exponential moving average update for stability), and the commitment term, weighted by $beta$, keeps the encoder from drifting away from the discrete entries it is assigned to.

#figure(
  image("figures/vq-vae.png", width: 45%),
  caption: [
    Architecture of VQ-VAE. The encoded continuous vector $z_e$, is  quantized to the nearest discrete codebook entry to produce $z_q$. Because this quantization step is non-differentiable, a straight-through estimator is used to pass gradients directly from $z_q$ back to $z_e$ during the backward pass.
  ],
) <fig:vq_vae>

= Related Works

/*
 * Include 2 or 3 papers per paragraph
 * Seminal Papers (initiate the research area) -> More recent and relevant papers

 * Include table with relevant techniques (recent ones)

 * End this section with:
 * * Summarize what the articles have in common ? What are their contrubution to answer our research question ? * *
*/

Historically, achieving physically valid locomotion for virtual characters relied heavily on manual design of control architectures. @coros_locomotion_2011 developed an integrated set of gaits and skills for a simulated dog, including walk, trot, pace, canter, gallop, leaps, sitting, lying down and recovery from falls. Their approach used gait graphs, a dual leg frame model, a flexible spine and optimization of virtual forces applied via the Jacobian transpose. While this produced remarkably robust locomotion as the simulated dog could traverse variable terrain and recover from push disturbances, the controllers required extensive manual engineering for each behavior and adding new skills demanded redesigning the control structure from scratch.

// 2018: Deep Reinforcement Learning (RL) and Physics-Based Control

To circumvent this engineering bottleneck, the field shifted toward automated, data-driven paradigms, where motion synthesis is learned through experience using DRL algorithms rather than explicitly programmed. @peng_deepmimic_2018 proposed DeepMimic, a framework that trains RL policies to reproduce reference motion capture clips in physics simulation. By formulating motion imitation as a multi-objective tracking problem, DeepMimic demonstrated that complex locomotion skills could be learned automatically from demonstration data. The framework was applied to both humanoid and quadruped characters, producing a simulated dragon capable of pacing and trotting gaits learned directly from authored keyframe animation data.

Mode-Adaptive Neural Networks (MANN) were introduced by @zhang_mode-adaptive_2018 for quadruped motion control, accompanied by a motion capture dataset of a real dog covering diverse gaits including walk, trot, pace, canter, gallop, jump, sit, and lie down. While MANN itself is a kinematic approach (not physics-based), the accompanying dataset has become a relevant public source of high-quality quadruped motion capture data, and forms the reference motion dataset for the experiments in this thesis. @starke_local_2020 extended the MANN framework with local motion phase features for improved gait representation on the same dataset, demonstrating that better motion feature extraction improves downstream control quality.

@bin_peng_learning_2020 "Learning Agile Robotic Locomotion Skills by Imitating Animals"
DeepMimic applied to quadrupeds (Laikago/A1). Retargeting was used here. Relation to @escontrela_adversarial_2022 applying this to AMP?

@peng_amp_2021 introduced Adversarial Motion Priors (AMP) to eliminate the reward engineering bottleneck. By replacing the handcrafted imitation reward with a learned discriminator trained on unstructured motion clip collections, AMP allowed policies to learn natural locomotion styles without manual reward tuning. The framework was demonstrated on both humanoid characters performing diverse athletic skills and a simulated quadruped dog trained on animal motion capture, establishing that the adversarial approach generalizes across character morphologies.

@escontrela_adversarial_2022 trained an AMP policy on a simulated Unitree A1 robot using only 4.5 seconds of German Shepherd motion capture data, and deployed it on physical hardware. Their results showed that AMP-trained policies achieved significantly lower Cost of Transport (CoT) compared to hand-designed style reward baselines, confirming that the adversarial discriminator captures motion quality effectively even with minimal reference data. This work establishes that AMP is viable for quadruped locomotion on Unitree hardware — the present thesis extends this by using the substantially larger and more diverse MANN dataset, and by targeting the Unitree Go2 morphology.

To demonstrate the practical viability of this approach for robotic control, @escontrela_adversarial_2022 successfully applied the AMP framework to a physical quadruped robot, the Unitree A1. Using a mere 4.5 seconds of motion capture data recorded from a real German Shepherd, their system learned a robust motion prior that completely substituted the need for complex, handcrafted reward functions. The resulting policies transferred effectively from simulation to the real world and yielded highly energy-efficient locomotion strategies. Notably, the policy demonstrated natural, autonomous gait transitions—such as shifting from a pace to a canter as the commanded velocity increased—validating that AMP can distill biologically efficient movement patterns from minimal reference data. Given its focus on adapting dog motion capture to a quadrupedal robotic morphology, this specific application represents the closest prior work to our proposed methodology.

// -- Latent structuring related works

The absence of an explicit skill structure in AMP motivated a line of work that augments adversarial training with a learned latent space, pursued along continuous and discrete tracks. On the continuous track, @peng_ase_2022 introduced Adversarial Skill Embeddings (ASE), extending AMP with a latent variable $z in RR^{64}$ that conditions the low-level policy; a mutual-information objective ensures that different codes yield distinguishable behaviors, and the resulting skill space can be reused across downstream tasks. Tessler et al. (2023) built CALM on the same continuous foundation, adding text or label conditioning so that behaviors can be directed by high-level descriptions. Serifi et al. (2024) proposed Versatile Motion Priors (VMP), which trains a continuous VAE over short motion windows and conditions a tracking policy on the time-varying latent, achieving robust tracking of diverse and unseen motions. These methods share the smoothness of continuous latents and, with it, the mode-averaging tendency that blurs transitions between qualitatively distinct gaits (Zhu et al., 2023).

On the discrete track, Zhu et al. (2023) introduced Neural Categorical Priors (NCP), which uses a VQ-VAE to compress motion into a discrete codebook and then trains a categorical prior over that codebook, with a prior-shifting procedure to prevent skill collapse and a high-level controller that selects entries for downstream tasks. NCP reported substantially improved motion quality and diversity over continuous baselines on humanoid characters. Yao et al. (2024) extended this direction with MoConVQ, which couples a VQ-VAE motion representation with model-based reinforcement learning to learn from tens of hours of unstructured data, yielding a token interface amenable to text-driven generation and integration with language models. Both NCP and MoConVQ were demonstrated exclusively on humanoid characters, and both retain DeepMimic-style tracking rewards during the representation-learning stage rather than an adversarial prior.

Applied to motion, the VQ-VAE encoder ingests short temporal windows of kinematic features — root and body velocities, joint configurations, foot-contact patterns — and compresses each window into a discrete token $k$. Several properties make this attractive for quadruped locomotion. First, after training the codebook tends to partition the motion space by behavior without ever being given gait labels: distinct entries come to specialize in distinct gaits (Zhu et al., 2023). Second, the finite codebook acts as a regularizer that discourages memorization of individual clips and encourages generalization. Third, a sequence of tokens is compositional, so a trajectory of skills can be represented as a string of codebook indices (Yao et al., 2024).

= Proposed Method

// Two gaps in this literature define the position of the present work. First, no published method applies a discrete VQ-VAE motion representation to physics-based quadruped locomotion; the discrete-latent results to date are humanoid. Second, the discrete-latent methods that do exist rely on handcrafted tracking rewards in their representation stage, whereas the adversarial prior of AMP removes reward engineering entirely. This thesis targets both gaps: it applies a discrete motion codebook to a quadruped morphology (the Unitree Go2) using real dog motion capture (the MANN dataset of Zhang et al., 2018), and it pairs that codebook with an AMP discriminator rather than a tracking reward. The closest quadruped precedent, Escontrela et al. (2022), establishes that AMP alone produces efficient, naturally transitioning gaits on Unitree hardware from minimal dog mocap, but provides no latent structure and therefore no explicit skill-selection channel — the specific capability this work introduces.

// This token interface is exactly the structure that vanilla AMP lacks. A discrete code $k$ provides an explicit, low-dimensional handle that a high-level controller can set to request a specific gait, while the AMP discriminator continues to supply the naturalness signal. The combination — a discrete codebook for what to do and an adversarial prior for how naturally to do it — is the conceptual basis for the method proposed in this work, and the verification that such a codebook does in fact partition the MANN gaits is the central deliverable of the present proposal.

- Dataset analysis and preprocessing (MANN -> Go2). Explicit retarget and feature extraction. Generated Artifact: Parsed BHV to .npy of feature time series $Phi(s_t)$
- Latent Space Structuring (Motion VQ-VAE) network training. Generated Artifact: Plot each "motion cap feature time window" in 2d (use dimensionality reduction techniques)
- Extending MimicKit framework (Adapt to run on MuJoCo: flexibility between CPU and GPU parallelization). Generated Artifact: github repository
- Adapt AMP training with latent space structuring (main work contribution)

= Preliminary Results

// TODO

#heading(level: 1, numbering: none)[Activity Schedule]

The following tables detail the planned execution of tasks in order to fulfill the research. @tab_activity describes the academic activities to be carried out, which are organized in a monthly schedule as seen in @tab_calendar.

#figure(
  table(
    columns: (auto, auto),
    inset: 10pt,
    align: left,
    [*Activity*], [*Description*],
    [1],
    [Gather datasets (AMASS, LAFAN1, AnimalSyn3D, Unitree G1) and set up simulation environment (IsaacGym, MuJoCo)],

    [2], [Implement the baseline experiments for kinematic and optimization based retargeting],
    [3], [Extract baseline metrics, identify artifacts, and draft proposal text sections],
    [4], [Finalize proposal text, integrate baseline results, and defend the master's proposal],
    [5], [Implement Skeleton-Aware Latent Encoder and MoE-based Teacher Policy],
    [6], [Implement Retargeting-Free Student Policy (Latent-Driven Diffusion)],
    [7], [Implement SOTA implicit/retargeting-free baselines for comparison (GMR, IKMR, MoReFlow)],
    [8], [Conduct final evaluations (zero-shot sim-to-sim in MuJoCo) and ablation studies],
    [9], [Write the master's thesis and generate comparative graphs],
    [10], [Final document editing and defend the master's thesis],
  ),
  caption: [Description of planned research activities.],
) <tab_activity>

#figure(
  table(
    columns: (2fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    inset: 10pt,
    align: center + horizon,

    // Row 1: Main Headers
    [], table.cell(colspan: 10)[*2026*],

    // Row 2: Sub-headers for months
    [*Activity*], [Mar], [Apr], [May], [Jun], [Jul], [Aug], [Sept], [Oct], [Nov], [Dec],

    // Data Rows
    [1], [x], [x], [], [], [], [], [], [], [], [],
    [2], [], [x], [x], [x], [], [], [], [], [], [],
    [3], [], [x], [x], [x], [], [], [], [], [], [],
    [4], [], [], [], [x], [], [], [], [], [], [],
    [5], [], [], [], [], [x], [x], [], [], [], [],
    [6], [], [], [], [], [], [x], [x], [], [], [],
    [7], [], [], [], [], [], [], [x], [x], [x], [],
    [8], [], [], [], [], [], [], [], [x], [x], [],
    [9], [], [], [], [], [], [], [], [], [x], [x],
    [10], [], [], [], [], [], [], [], [], [], [x],
  ),
  caption: [Activity schedule calendar from March to December 2026.],
) <tab_calendar>

#heading(level: 1, numbering: none)[Bibliography]
#bibliography("zotero.bib", style: "apa", title: none)
