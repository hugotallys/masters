#set page(
  paper: "a4",
  margin: (left: 3cm, right: 2cm, top: 3cm, bottom: 2cm),
)

#set text(
  font: "New Computer Modern",
  size: 12pt,
  lang: "en",
)

#set par(justify: true, leading: 0.65em)

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
    Retargeting-Free Motion Imitation for Cross-Morphological Characters via Latent-Driven RL
  ]

  #v(2cm)

  #text(weight: "bold")[MASTER’S CANDIDATE] \
  HUGO TALLYS MARTINS OLIVEIRA

  #v(2cm)

  #text(weight: "bold")[ADVISOR] \
  GLAUBER RODRIGUES LEITE, DR.

  #v(1fr)

  MACEIÓ, AL \
  MARCH - 2026
]

#pagebreak()

// --- FRONT MATTER (Lists) ---

#set page(numbering: "i")
#counter(page).update(1)

#outline(title: "List of Figures", target: figure.where(kind: image))
#pagebreak()

#outline(title: "List of Tables", target: figure.where(kind: table))
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

// Highlight here SPORE Game motivation (how motion retargeting was made back then)

== The Problem

Leveraging the vast amount of available human motion capture data to make physically simulated characters or robots move, consists in a challenge due to the discrepancies between the source and the target bodies morphology. Even when transferring motion to humanoid robots that share a similar structural topology, significant discrepancies exist in bone lengths, mass distributions, and actuator limitations. This challenge is massively exacerbated in cross-morphological scenarios, where the target skeleton may possess entirely different joint counts, extra appendages, or non-homeomorphic structures, completely lacking a one-to-one anatomical correspondence with the human source. Consequently, a motion that is perfectly balanced and natural for a human performer may become physically infeasible when mapped to a robot with different dynamic constraints.

To overcome this problem, the standard approach relies on explicit kinematic retargeting, which uses numerical optimization and Inverse Kinematics (IK) to geometrically map human joint positions and orientations to the target character. However, because these classical solvers focus almost exclusively on geometric alignment and ignore critical dynamic forces such as momentum and torque limits, they frequently introduce severe artifacts into the reference trajectories, including foot sliding, ground penetration and self-intersections. The core problem lies in the persistent reliance on explicit joint-to-joint geometric mapping as an intermediate step. Therefore, we propose a retargeting-free paradigm that bypasses this intermediate retargeting stage. By instead encoding the source motion into a topology-agnostic latent space, the semantic intent of the movement can be used to directly condition a physics-based Reinforcement Learning (RL) policy, allowing dynamically feasible and artifact-free movement to emerge natively through the agent's interaction with the environment.

== Main Objective

This work aims to investigate and develop a retargeting-free framework for cross-morphological motion synthesis, leveraging topology-agnostic latent space alignment to directly guide physics-based Deep Reinforcement Learning (DRL) policies. Instead of relying on explicit kinematic mapping, this study will explore how physical movement can emerge naturally from an agent interpreting abstract motion intents and interacting within a simulated environment.

=== Specific Objectives

/* 1. Understand how operations in the latent space reflect in the character movement
2. To compare with distinct approaches to the problem (skeleton aware, DRL Immitation, classical IK, jacobian optimization)
3.
4. */

1. To analyze how semantic intents encoded within a shared, topology-agnostic latent space translate into dynamically feasible character movement.
2. To systematically compare the latent-driven approach against distinct traditional retargeting baselines.
3. To evaluate how working with latent spaces enhances and stabilizes pure physics-based RL approaches.
4. To establish a retargeting-free paradigm where complex animation arises as emergent behavior.

== Relevance of the Proposal

// TODO

== Structure

// TODO

= Background

This chapter introduces the concepts regarding how we represent virtual characters and animate them using a physics based approach guided by machine learning techniques. We begin describing how articulated characters are physically simulated, then formalize how reinforcement learning policies are used to control these characters, describing how motion capture data guides the learning process through reward engineering. Then we present adversarial motion priors as a principled alternative to handcrafted rewards, and finally introduce discrete latent representations as a mechanism for structuring the latent motion space.

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

To optimize this landscape efficiently, actor-critic frameworks decouple the learning system into an "actor" which encapsulates the parameterized policy for action selection, and a "critic" which approximates a state-value function $hat(v)(s, w)$ to evaluate those selections. By utilizing temporal difference (TD) bootstrapping, where value estimates are updated based on the estimated values of subsequent states, the critic dramatically reduces variance issues that arises in standard Monte Carlo (MC) rollouts.

// ADD HERE FIGURE OF ACTOR CRITIC DIAGRAM FROM BARTO & SUTTON

// --- BEGIN 

== Proximal Policy Optimization Algorithms

For the continuous, high-dimensional action spaces encountered in character control, Proximal Policy Optimization (PPO) @schulman_proximal_2017 has become the dominant algorithm across both robotics and physics-based animation research, precisely because it is stable enough to train deep neural networks over long horizons without collapsing, yet simple enough to implement reliably without problem-specific tuning. PPO is an actor-critic method that maintains two separate neural networks in an episodic learning setting. The actor network defines our policy $pi_theta$ mapping the current state to a parametrized gaussian distribution over continuous actions from which joint targets are sampled. The critic network $V_phi (s_t)$ is a value estimator that learns to predict the expected cumulative return from any given state, serving as a learned baseline. The critic's predictions are used to compute _advantage estimates_ $hat(A_t)$

$ hat(A)_t = R_t - V_phi (s_t) $

which measures how much better or worse the action actually taken was compared to what the critic expected on average.

A positive advantage means the action led to better-than-expected outcomes and should be reinforced whereas a negative advantage means it should be avoided. The key innovation of PPO is a _clipped surrogate objective_ that prevents destructively large policy updates:

$ L^"CLIP"(theta) = bb(E)_t [ min(r_t(theta) hat(A)_t, "clip"(r_t(theta), 1 - epsilon, 1 + epsilon) hat(A)_t) ] $

where $r_t (theta) = (pi_theta (a_t | s_t)) / (pi_(theta_"old") (a_t | s_t))$ is probability ratio between the updated and previous policy and $epsilon$ (typically 0.2) bounds the update magnitude. This clipping mechanism acts as a conservative guardrail on how far the policy is permitted to move in a single update step avoiding unconstrained gradient steps that risk causing irreversible drops in action probabilities, leading to deterministic policy collapse or highly unstable exploration @schulman_trust_2017. 

Despite this stability, controlling characters trained with PPO faces a fundamental perceptual problem when applied to articulated figures. The algorithm is agnostic to what natural _motion intent_ looks like as it optimizes whatever scalar reward it is given. When that reward is defined purely in terms of task completion such as reach a target velocity, navigate the terrain or stay upright, the policy discovers physically valid solutions that satisfy the objective while looking somewhat awkward to our common sense. Joints snap to extreme angles, limbs swing in mechanically efficient but biologically implausible patterns, and transitions between gaits produce the sudden, discontinuous lurches characteristic of the uncanny valley. 

The root cause is not a failure of the algorithm but a difficulty of reward engineering: without an explicit signal encoding how a character should move, PPO has no basis for preferring natural motion over any other physically feasible solution. Designing reward functions that fully capture motion intent is notoriously difficult and specific to each problem. This is the central limitation that motion imitation methods, discussed in the following section, are designed to address.

// PPO DIAGRAM FIGURE HERE

== Motion Imitation via Reward Engineering

Early approaches to guiding a physics-based character toward natural movement used motion imitation through handcrafted reward functions. In this paradigm, a reference motion clip, typically obtained from motion capture of a real animal (Zhang et al., 2018), provides a frame-by-frame target trajectory. The reward function measures how closely the simulated character's state matches the reference at each time step, producing a scalar incentive for the policy to reproduce the demonstrated motion.

The standard formulation, established by in the _DeepMimic_ framework, decomposes the imitation reward $r^I_t$ into a weighted sum of per frame error terms:

$ r^I_t = w^p_t dot r^p_t + w^v_t dot r^v_t + w^e_t dot r^e_t + w^c_t dot r^c_t $

Each component penalizes a specific type of deviation from the reference motion data: $r_p$ measures joint orientation error, $r_v$ measures joint velocity error, $r_e$ measures end-effector position error (the spatial distance between the character's feet and the reference foot positions) and $r_c$ measures center-of-mass trajectory error, each term begin formulated as an exponential decay of the squared error. For instance, in order to compute the total joint orientation reward the author uses

$ cases(
  w^p_t = 0.65,
  r^p_t = exp[-alpha_p (sum_j ||hat(q)^j_t minus.o q^j_t||^2)]
) $

where $alpha_p = 2$ is a _sharpness_ coefficient (exponential scale factor), $q^j_t$ and $hat(q)^j_t$ represent the orientations of the $j$th joint from  the simulated character and reference motion respectively, $q_1 minus.o q_2$ denotes the quaternion difference and $||q||$ computes the scalar rotation of a quaternion about its axis in radians @peng_deepmimic_2018.

To enable goal-directed behavior beyond pure imitation, the total reward combines the imitation objective with a task reward $r^G_t$

$ r_t = omega^I dot.c r^I_t + omega^G dot.c r^G_t $

with $omega^I$ and $omega^G$ being their respective weights.

The task reward incentivizes high-level objectives such as tracking a commanded velocity, reaching a target position, or navigating terrain. This dual-reward structure allows the policy to deviate from the reference motion when necessary to accomplish the task, while maintaining the stylistic character of the original motion data.

Despite its demonstrated success, reward engineered motion imitation suffers from several documented limitations @peng_amp_2021. First, the reward weights ($w_p, w_v, w_e, w_c$) and sharpness coefficients ($alpha_p, alpha_v, alpha_e, alpha_c$) require careful manual tuning for each motion skill: small perturbations can cause training to diverge or converge to unnatural local minima. Second, each reference clip typically requires a separately trained policy, since the per-frame tracking objective binds the policy tightly to one specific trajectory in which case scaling to large motion datasets demands significant additional machinery for motion selection and blending. Third, the rigid per-frame tracking penalizes physically valid but stylistically different solutions, producing brittle policies that cannot smoothly transition between distinct skills. Finally, when applied to diverse motion datasets containing multiple gaits, the tracking framework requires explicit mechanisms for selecting which clip the character should follow at any given moment, adding engineering complexity for interactivity which scales poorly with dataset size.

== Motion Retargeting

/*
References:

Seminal Papers (Acting as texts for this niche): Gleicher's Retargetting motion to new characters for historical optimization context, and Skeleton-aware networks for deep motion retargeting by Aberman et al. for the introduction of homeomorphic graph retargeting.
*/

// Homomorphology (Intra-Structural) Retargeting: Explain methods that transfer motion between characters with the same skeletal topology but different bone proportions (e.g., human-to-humanoid).

// Cross-Morphology (Inter-Structural) Retargeting: Define the challenge of transferring motion between fundamentally different skeletons (e.g., biped to quadruped, or completely arbitrary topologies like multi-legged insects).

// Artifacts and Limitations: Detail the common failure modes of direct joint mapping, such as self-penetration, foot sliding, and the loss of semantic meaning when topologies diverge.

Intra-structural retargeting (Homomorphology) refers to the transfer of motion between characters that share the exact same skeletal topology, i.e they have an identical hierarchical blueprint and equivalent kinematic chains—but differ in their bone proportions, overall scale, or body shape. The quintessential example is mapping human motion capture data onto a humanoid robot. Because the source and the target can be represented by equivalent or homeomorphic graphs, there is a direct, one-to-one anatomical correspondence between their parts, such as mapping a human elbow directly to a robot elbow.

Despite operating on identical topological structures, homomorphology retargeting still faces the _embodiment gap_ problem. A human and a humanoid robot might share the same number of limbs, but their mass distributions, center of gravity, and joint ranges of motion differ drastically. Consequently, even when explicit kinematic retargeters perfectly calculate joint angles that match the source poses, the resulting motion often fails to account for the physical constraints of the specific robotic hardware.

Cross-morphological retargeting addresses the vastly more complex challenge of transferring motion between fundamentally different, non-homeomorphic skeletons. In these scenarios, the source and target characters exhibit distinct structural topologies, meaning their kinematic trees cannot be reduced to a shared primal skeleton through simple mathematical edge merging. This includes transferring motion from a bipedal human to a quadrupedal dog, or even more extreme morphological leaps, such as mapping movement to arbitrary multi-legged arthropods or limbless creatures.

The primary barrier in cross-morphology transfer is the complete absence of one-to-one joint correspondence. Because the skeletons differ in bone counts, hierarchical branching, and resting T-poses, traditional explicit IK solvers cannot be directly applied without extensive manual intervention and heuristic mappings. For instance, a system attempting to retarget a human walking motion to an eight-legged spider must mathematically reconcile human bipedal balance with the decentralized, complex phase relations of an arachnid's multiple limbs.

The reliance on direct joint mapping and explicit kinematic retargeting introduces severe and pervasive failure modes into the motion synthesis pipeline. Because classical solvers predominantly focus on minimizing geometric distances while ignoring environmental contact states, the resulting trajectories are plagued by foot sliding, ground penetration, and floating. Furthermore, when topologies diverge or mass volumes are unaccounted for, explicit retargeting frequently yields physically impossible self-intersections and unnatural, abrupt velocity spikes as the IK solver struggles to satisfy conflicting constraints.

To bridge this massive structural divide, modern approaches are shifting away from explicit joint calculations toward learning abstract semantic correspondences. State-of-the-art frameworks achieve this by embedding motions into shared latent spaces, relying on skeleton-aware graph convolutions to form unified topology prototypes, or leveraging diffusion models guided by textual joint descriptions to organically adapt motion motifs across unseen skeletal architectures (AnyTop). These methods prove that successful cross-morphological transfer relies on translating the high-level semantic intent of an action rather than enforcing strict geometric replication.

Beyond visual flaws, a critical limitation of traditional retargeting is the loss of semantic meaning and physical feasibility. Kinematic retargeters inherently lack dynamic constraints—such as momentum, friction, and motor torque limits. When these physically infeasible reference trajectories are passed downstream to a Reinforcement Learning (RL) policy for tracking, they impose a massive burden on the agent. The RL policy is forced to aggressively correct these kinematic errors just to maintain physical balance, which typically requires extensive, task-specific reward engineering, domain randomization, and parameter tuning to prevent the policy from failing completely.

// These limitations highlight the necessity of shifting toward a **retargeting-free, latent-driven approach**. By completely bypassing the error-prone intermediate stage of explicitly mapping human joints to a robot's morphology, our novel methodology eliminates these artifacts at the source. Instead of forcing an RL tracking policy to mimic flawed kinematic data, the retargeting-free paradigm encodes the source motion into an abstract latent intent. The downstream diffusion-based RL policy then uses this latent semantic anchor to organically synthesize raw, executable joint actions through trial-and-error simulation. This allows dynamically feasible, artifact-free movement to emerge natively within the target character's own physical constraints, significantly reducing deployment latency and cumulative tracking errors.

== Shared Latent Manifolds

/*

References:

*Note: Because this specific intersection of VQ-VAEs and physics RL is so new, textbooks do not cover it yet. You must rely on modern seminal papers here.*

Seminal Papers: MoConVQ: Unified Physics-Based Motion Control via Scalable Discrete Representations by Yao et al. (for discrete representations) and RoboGhost: Retargeting-free Humanoid Control via Motion Latent Guidance by Li et al. (for bypassing explicit IK retargeting entirely).

*/

// Latent Space Alignment: Explain how Neural Networks can map raw kinematic data from differently structured skeletons into a unified, low-dimensional deep representation (a shared latent space).

Neural networks facilitate the mapping of raw kinematic data from differently structured skeletons into a unified, low-dimensional deep representation by decoupling the motion's semantic intent from the specific geometry of the source character. When characters share equivalent topological properties—such as homeomorphic skeletons—their kinematic trees can be mathematically reduced to a common primal skeleton through systematic edge merging and pooling operations. By employing skeleton-aware graph convolutional networks, the system explicitly accounts for the hierarchical structure and joint adjacency of the skeleton, allowing the network to extract high-level spatial-temporal features.

Through this process, the neural network learns to disentangle the static shape properties (like bone lengths and proportions) from the dynamic motion properties. The resulting dynamic latent code becomes completely skeleton-agnostic, representing the pure "intent" of the movement. Consequently, motions performed by vastly different characters, such as a human and a humanoid robot, are compressed into the same abstract topological prototype within a shared latent space. This alignment acts as a universal translator, where the essence of the motion is mathematically aligned regardless of the explicit joint counts or bone lengths of the original bodies.

// Discrete and Continuous Representations: Discuss how architectures like Vector Quantized Variational Autoencoders (VQ-VAE) or Flow Matching models encode motions into topology-agnostic "motion tokens".

To efficiently process and transfer complex movements, advanced architectures translate these unified representations into discrete or continuous generative manifolds. Vector Quantized Variational Autoencoders (VQ-VAE) discretize motion by encoding continuous kinematic sequences into a sequence of latent vectors, which are then mapped to the nearest matching entries within a learned codebook. This quantization process produces highly compact "motion tokens" that capture the essential spatiotemporal patterns of a skill while discarding low-level kinematic redundancies and noise. To handle vast and diverse datasets without suffering from codebook collapse, modern systems often employ Residual Vector Quantization (RVQ), which uses a sequence of codebooks to capture motion in a coarse-to-fine manner, exponentially expanding the model's capacity to represent intricate details.

Building upon these tokenized embeddings, continuous generative models like Flow Matching are employed to establish mathematically rigorous correspondences between the varied motion spaces of different characters. Instead of relying on heuristic joint mappings, Flow Matching trains continuous normalizing flows by regressing vector fields to transport the distribution of source motion tokens directly into the target character's token space. By employing conditional coupling, these models can align latent spaces in an unsupervised manner, allowing the system to flexibly target specific alignment objectives, such as preserving local stylistic nuances or ensuring precise world-frame task alignment.

// Latent-Driven Control (Retargeting-Free): Explain the paradigm shift where, instead of explicitly solving IK for retargeting, a generative model outputs a latent embedding that directly conditions a downstream physical RL policy, allowing for zero-shot execution.

Topology-agnostic representations introduces a profound paradigm shift in character animation and robotics: Latent-Driven, Retargeting-Free Control. // Traditionally, deploying motion onto a physically simulated character required a multi-stage pipeline: mathematically decoding the abstract motion back into explicit joint trajectories, solving Inverse Kinematics (IK) optimization problems to retarget those trajectories to a new morphology, and finally forcing a Reinforcement Learning (RL) tracking policy to mimic those specific angles. This explicit kinematic mapping forces the RL policy to aggressively fight against dynamically infeasible artifacts—like foot sliding or self-penetration—introduced by the IK solver, leading to high latency and cumulative tracking errors.
The retargeting-free paradigm completely bypasses this explicit IK decoding stage. Instead of generating a strict trajectory of joint angles for the robot to follow, a continuous autoregressive or diffusion-based generative model outputs a compact motion latent that acts merely as a semantic "intent" or anchor. This abstract latent embedding is fed directly as a conditioning signal into a downstream, physics-based RL policy.

Because the downstream policy—often built on a diffusion model backbone—is trained to denoise executable physical actions directly from its proprioceptive state and this latent intent, the physical translation of the movement emerges natively through trial-and-error simulation. This allows the character to organically execute the requested motion while strictly adhering to its own unique physical constraints, completely eliminating retargeting-induced artifacts and enabling zero-shot, real-time deployment.

= Related Works

/*
 * Papers and reports
 * Include network of papers showing the area of research evolution:
 * Motion retargeting -> Physics based animation/immitation learning -> Motion transfer across morphologies via latent space allignment

 * Include 2 or 3 papers per paragraph
 * Seminal Papers (initiate the research area) -> More recent and relevant papers

 * Include table with relevant techniques (recent ones)

 * End this section with:
 * * Summarize what the articles have in common ? What are their contrubution to answer our research question ? * *
*/

// 1998–2000: Inverse Kinematics and Optimization

Early motion retargeting predominantly relied on classical optimization and handcrafted kinematic constraints to map motions between characters. The work by @gleicher_retargetting_1998 introduced a foundational technique that formulates character motion retargeting as a spacetime optimization problem, ensuring that specific kinematic features and constraints are maintained throughout the animation. In @choi_online_2000 it was proposed an online retargeting method that utilizes inverse kinematics at each frame and then calculates changes in joint angles to maintain end-effector positions while preserving the high-frequency details of the source motion.

// 2018: Deep Reinforcement Learning (RL) and Physics-Based Control

As machine learning advanced, the focus shifted from purely kinematic-optimization solutions to generating physically plausible, interactive movements. The _DeepMimic_ paper by @peng_deepmimic_2018 introduced a framework utilizing example-guided deep reinforcement learning to train physics-based characters. By combining an imitation objective with task-specific goals, their RL approach allowed simulated characters to dynamically learn complex skills by imitating reference motion capture clips.

// 2020–2024: The Shift to Latent Space Alignment

The advent of deep generative models introduced latent space alignment to effectively handle structural disparities between characters. In aberman_skeleton_aware_2020 it was developed a skeleton-aware neural network capable of unpaired motion retargeting between homeomorphic skeletons. Their method encodes structurally different motions into a shared deep latent space corresponding to a common primal skeleton. Expanding on this concept, in @yao_moconvq_2024 it was proposed the _MoConVQ_ framework, which learns scalable, discrete motion representations directly from extensive unstructured datasets. By combining these latent embeddings with model-based RL, MoConVQ provides a unified and intuitive interface for a variety of physics-based control tasks.

// 2025: Advanced Alignment, Robust Tracking, and Latent-Driven Control In 2025, rapid advancements expanded across all control paradigms to bridge the embodiment gap between humans and complex robots:

// Latent Space Alignment:

In gat_anytop_2025 it was presented AnyTop, a diffusion model capable of generating animations for completely non-homeomorphic skeletons (from bipeds to arthropods) by integrating topological information into a transformer-based de-noising network. MoReFlow was introduced by kim_moreflow_2025, an unsupervised framework utilizing flow matching to align the tokenized latent motion spaces of morphologically distinct characters. To combine efficiency with physical feasibility, it was proposed by chen_implicit_2025 Implicit Kinodynamic Motion Retargeting (IKMR), which aligns motion topologies via a dual encoder-decoder and subsequently fine-tunes the decoder using imitation learning to produce physically viable trajectories.

// Optimization & Physics-Based RL:

Classical optimization methods were re-evaluated to aid modern RL tracking. In "Retargeting Matters," it was demonstred by araujo_retargeting_2025 that while RL policies can sometimes overcome retargeting artifacts, generating high-quality reference motions via robust inverse kinematics optimization (their GMR method) significantly improves the success rate of downstream humanoid tracking policies. Parallel to this, in @chen_gmt_2025 it was introduced General Motion Tracking (GMT), leveraging DRL on human reference data to build robust, whole-body controllers capable of managing a highly diverse set of humanoid locomotion skills.

// Latent-Driven Control (Retargeting-Free):
// Real need of this here ? Is there any other exmaple that uses retargeting free approach ?
In @li_language_2025 it was developed a retargeting-free humanoid control framework that, instead of decoding language prompts into human motions and mathematically retargeting them to a robot, their approach feeds semantic latent representations directly into a diffusion-based student policy.
This latent-driven method outputs executable robot actions directly, successfully bypassing cumulative kinematic errors and reducing deployment latency, representing a paradigm shift away from explicit kinematic mapping.

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
