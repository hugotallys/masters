#set page(
  paper: "a4",
  margin: (left: 3cm, right: 2cm, top: 3cm, bottom: 2cm),
)

#set text(
  font: "New Computer Modern",
  size: 12pt,
  lang: "en",
)

// #set par(justify: true, leading: 0.65em)

// Justified text with first-line indent, no spacing between paragraphs

#set par(
  justify: true,
  first-line-indent: (amount: 1.25cm, all: true)
)

// Headings: bold, flush left, same font, numbered
#set heading(numbering: "1.1")

#show heading.where(level: 1): it => {
  let fontSize = 26pt
  pagebreak(weak: true)
  v(2.5cm)
  set par(first-line-indent: 0pt)
  block[
    #text(size: fontSize, weight: "bold")[Chapter #counter(heading).display()]
    #v(0.25cm)
    #text(size: fontSize, weight: "bold")[#it.body]
  ]
  v(0.55cm)
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

The problem of controlling a physically simulated character is formally defined as a Markov Decision Process (MDP). At each discrete time step $t$, an agent observes the state of the environment $s_t$ and selects a continuous action $a_t$ according to a policy $pi$. Following the generalized formulation of policy-based reinforcement learning, a policy is parameterized by a dedicated parameter vector $theta in RR^(d')$. This policy maps a given state to a probability distribution over the action space:

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

Early approaches to guiding a physics-based character toward natural movement used motion imitation through handcrafted reward functions. In this paradigm, a reference motion clip, typically obtained from motion capture of a real animal @zhang_mode-adaptive_2018, provides a frame-by-frame target trajectory. The reward function measures how closely the simulated character's state matches the reference at each time step, producing a scalar incentive for the policy to reproduce the demonstrated motion.

The _DeepMimic_ framework @peng_deepmimic_2018, while predominantly known for humanoid tracking, demonstrated its versatility by successfully training non-bipedal, quadrupedal characters (such as a simulated dragon), establishing a strong precedent for applying these techniques to complex animal morphologies. The framework decomposes the imitation reward $r^I_t$ into a weighted sum of per-frame error terms:

$ r^I_t = w^p_t dot r^p_t + w^v_t dot r^v_t + w^e_t dot r^e_t + w^c_t dot r^c_t $

Each component penalizes a specific type of deviation from the reference motion data: $r_p$ measures joint orientation error, $r_v$ measures joint velocity error, $r_e$ measures end-effector position error (the spatial distance between the character's feet and the reference foot positions), and $r_c$ measures center-of-mass trajectory error. To map these unbounded distance metrics into a strict reward scale, each term is defined as an exponential decay of the squared kinematic error. As an example, because matching joint orientations is critical for preserving the overall posture of the reference motion, this specific term is assigned a dominant proportional weight of $w^p_t = 0.65$ within the overall reward structure:

$ r^p_t = exp[-alpha_p (sum_j ||hat(q)^j_t minus.o q^j_t||^2)] $

where $alpha_p = 2$ acts as an exponential scale factor, $q^j_t$ and $hat(q)^j_t$ represent the orientations of the $j$th joint from the simulated character and reference motion respectively, $q_1 minus.o q_2$ denotes the quaternion difference, and $||q||$ computes the scalar rotation of a quaternion about its axis in radians.

To enable goal-directed behavior beyond pure imitation, the total reward combines the imitation objective with a task reward $r^G_t$

$ r_t = omega^I dot.c r^I_t + omega^G dot.c r^G_t $

with $omega^I$ and $omega^G$ being their respective weights. The task reward incentivizes high-level objectives such as tracking a commanded velocity, reaching a target position, or navigating terrain. This dual-reward structure allows the policy to deviate from the reference motion when necessary to accomplish the task, while maintaining the stylistic character of the original motion data.

Despite its demonstrated success, reward engineered motion imitation suffers from several documented limitations. First, the reward weights ($w_p, w_v, w_e, w_c$) and sharpness coefficients ($alpha_p, alpha_v, alpha_e, alpha_c$) require careful manual tuning for each motion skill: small perturbations can cause training to diverge or converge to unnatural local minima. Second, each reference clip typically requires a separately trained policy, since the per-frame tracking objective binds the policy tightly to one specific trajectory in which case scaling to large motion datasets demands significant additional machinery for motion selection and blending. Third, the rigid per-frame tracking penalizes physically valid but stylistically different solutions, producing brittle policies that cannot smoothly transition between distinct skills. Finally, when applied to diverse motion datasets containing multiple gaits, the tracking framework requires explicit mechanisms for selecting which clip the character should follow at any given moment, adding engineering complexity for interactivity which scales poorly with dataset size.

== Adversarial Motion Priors

Adversarial Motion Priors (AMP), introduced by @peng_amp_2021, replaces the handcrafted imitation reward with a learned discriminator that automatically captures the statistical characteristics of the reference motion data. The central insight is that natural motion can be defined not by explicit kinematic metrics but by the distribution of state transitions that "look like" the reference data. This approach draws on the adversarial training framework from Generative Adversarial Networks (Goodfellow et al., 2014) and its application to imitation learning in Generative Adversarial Imitation Learning (Ho & Ermon, 2016).

A discriminator network $D_psi (s_t, s_{t+1})$ is trained to distinguish state transition pairs drawn from the reference motion dataset from those generated by the RL policy during simulation. The discriminator is optimized with a least-squares objective augmented by a gradient penalty (Gulrajani et al., 2017) for training stability:

$ L_D = bb(E)_((s, s') tilde cal(M)) [ (D psi(s, s') - 1)^2 ] + bb(E)_((s, s') tilde pi) [ (D psi(s, s') + 1)^2 ] + lambda_"gp" dot bb(E) [ | nabla_psi D_psi |^2 ] $

where $cal(M)$ denotes the reference motion dataset, $pi$ denotes the current policy's rollout distribution, and the gradient penalty coefficient $lambda_"gp"$ is the most critical hyperparameter for training stability.

The discriminator's output is converted into a style reward signal for the RL policy, approaching $1$ when the policy produces transitions that the discriminator classifies as similar to the reference data, and $0$ for transitions that deviate from the reference distribution:

$ r_"style" (s_t, s_(t+1)) = max(0, 1 - 0.25 dot (D_psi (s_t, s_(t+1)) - 1)^2) $

Critically, the AMP discriminator operates on unstructured motion clip collections. It receives randomly sampled transition pairs $(s_t, s_(t+1))$ from the dataset without requiring clip boundaries, temporal annotations, or skill labels. This is a fundamental advantage over _DeepMimic_ style since the policy is not penalized for being at the wrong frame of a specific clip, but rather for producing transitions that fall outside the statistical distribution of all reference motions. The policy can therefore autonomously discover how to compose and blend behaviors from a diverse dataset, without requiring explicit motion selection or blending machinery.

The state representation $s$ used by the discriminator is a design choice that determines what aspects of motion are judged. Typical representations include root height, root orientation, body linear and angular velocities, joint positions relative to the root, joint velocities, and foot contact states. When the reference motion data and the simulated character share the same skeletal structure, these features can be extracted directly from both sources without any intermediate processing.

#figure(
  image("figures/amp.png", width: 80%),
  caption: [
    AMP  strucutre CHANGE CAPTIONS AND FIGURE
  ],
) <fig:amp_structure>

To demonstrate the practical viability of this approach for robotic control, @escontrela_adversarial_2022 successfully applied the AMP framework to a physical quadruped robot, the Unitree A1. Using a mere 4.5 seconds of motion capture data recorded from a real German Shepherd, their system learned a robust motion prior that completely substituted the need for complex, handcrafted reward functions. The resulting policies transferred effectively from simulation to the real world and yielded highly energy-efficient locomotion strategies. Notably, the policy demonstrated natural, autonomous gait transitions—such as shifting from a pace to a canter as the commanded velocity increased—validating that AMP can distill biologically efficient movement patterns from minimal reference data. Given its focus on adapting dog motion capture to a quadrupedal robotic morphology, this specific application represents the closest prior work to our proposed methodology.

While AMP provides a highly flexible and automated alternative to manual reward engineering, the framework possesses a few known limitations. When trained on highly diverse datasets encompassing multiple distinct behaviors, the adversarial discriminator evaluates motions globally, acting strictly as a data distribution evaluator without explicitly separating or indexing the available skills. In practice, this lack of explicit structure can sometimes precipitate mode collapse, wherein the policy shortcuts the learning process by converging onto a single, highly stable dominant gait, ignoring other behaviors in the dataset. Consequently, interactive controllability relies heavily on the task reward channel (such as a target velocity vector) to coax the policy into different behaviors. Although addressing this mode collapse and the lack of explicit skill request mechanisms remains an active area for future work in representation learning, vanilla AMP remains exceptionally effective for extracting generalized, naturalistic priors for targeted motor domains such as quadrupedal locomotion.

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

= Proposed Method

// TODO

= Preliminary Results

// TODO

= Activity schedule

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

#bibliography("zotero.bib", style: "apa")
