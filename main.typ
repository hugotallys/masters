#set page(
  paper: "a4",
  margin: (left: 3cm, right: 2cm, top: 3cm, bottom: 2cm),
)

#set text(
  font: "New Computer Modern",
  size: 12pt,
  lang: "en"
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

// --- MACROS ---
#let comment(content) = text(fill: red)[#content]

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

/*
* Books and miscellaneous sources
* Introduction to Autonomous Mobile Robots (Intelligent Robotics and Autonomous Agents) 2nd Edition (Locomotion)
  MORE BOOKS
* What I need to discuss the subject ?
*/

== Kinematics Based Animation

/*
  Recommended References:
  
  Book: Computer Animation: Algorithms and Techniques by Rick Parent. (Note: This book is from outside the provided sources but was discussed in our previous conversation as the standard text for IK and 3D animation fundamentals).
  
  Book (Optimization): Practical Methods of Optimization by Roger Fletcher or Practical Optimization by Phillip Gill et al., which are cited in foundational retargeting literature.
*/

//Skeleton Hierarchies and Graphs: Explain how articulated figures are defined by a hierarchical structure of joints (nodes) and bones (edges), represented as Directed Acyclic Graphs (DAGs).

Representing the body morphology of animals, humanoid robots or articulated characters can be achieved by using hierarchical linkages represented as Directed Acyclic Graphs (DAGs) or tree structures. In this graphical representation, the nodes correspond to individual joints or end-effectors, while the edges (or arcs) represent the rigid bones or armatures connecting them. The hierarchy is anchored by a single root node, typically located at the character's pelvis, which establishes the figure's global position and orientation in the coordinate system.

The structural relationship between these elements is defined by kinematic chains, which are paths traversing from the root node down to the leaf nodes, such as the hands or feet. As the tree is traversed, transformations are passed down the hierarchy. For instance, a rotation applied to a parent node (e.g., a hip joint) automatically transforms all of its subsequent child nodes (e.g., the leg, knee, and foot), preserving the rigid structure of the limbs.

// Forward and Inverse Kinematics (IK): Explain Forward Kinematics (calculating end-effector positions from joint angles) and Inverse Kinematics (calculating joint angles to reach a target position).

Two primary approaches are considered when animating the hierarchical graph: *Forward Kinematics* (FK) and *Inverse Kinematics* (IK). Forward kinematics is the process of calculating the exact spatial position and orientation of an end-effector based on a given set of joint angles. By traversing the skeletal tree from the root downward and sequentially applying rotational matrices at each joint, the system computes the final posture of the entire body. While computationally straightforward, manually specifying the angle for every degree of freedom to reach a specific target makes FK an incredibly tedious trial-and-error process for animators. 

Conversely, Inverse Kinematics automates this process by calculating the necessary joint configurations required to position an end-effector at a specific, user-defined target coordinate. Instead of rotating joints manually, the user simply places the hand or foot where it needs to be, and the system mathematically solves for the internal pose. Because articulated figures like humans have many degrees of freedom (due to kinematic redundancy), IK problems are frequently under-constrained, meaning there are multiple valid joint configurations that can reach the same spatial target. 

To solve these complex IK problems where analytic solutions are impossible, classical approaches rely on iterative numerical methods, such as calculating the Jacobian matrix, a transformation that maps the velocities of the joint angles to the spatial velocities of the end-effector, allowing the system to incrementally "nudge" the joints until the limb reaches the target configuration within an acceptable tolerance. 

// Mathematical Optimization in Retargeting: Explain how early retargeting methods used spacetime constraints and numerical optimization to solve IK problems, enforcing rules like foot-ground contact.

When transferring motion from one character to another with different bodily proportions, explicit mathematical optimization is heavily utilized to adapt the kinematics. A foundational classical method is the use of spacetime constraints, which formulates motion retargeting as a constrained numerical optimization problem solved simultaneously over the entire duration of the animation sequence. Unlike per-frame IK solvers that can introduce high-frequency jitter or "snapping" artifacts, the spacetime approach evaluates multiple frames at once to minimize an objective function—such as minimizing the magnitude of changes or energy consumption—ensuring that the resulting motion preserves the smooth frequency characteristics of the original performance.

Within this optimization framework, strict kinematic rules are enforced as mathematical constraints, most notably to guarantee accurate foot-ground contact. If a source motion features a character walking, the optimization solver prevents physics-breaking artifacts by mathematically restricting the feet from sliding, skating, or floating horizontally when they should be firmly planted on the floor. Modern explicit retargeting tools—like Perpetual Humanoid Control (PHC) or ProtoMotionssimilarly rely on minimizing positional and orientational errors between the source and target bodies using differential IK solvers and gradient descent, often followed by a post-processing optimization step to adjust the root height and fix ground penetrations.

Despite their historical success and mathematical precision, optimization-based kinematic retargeting methods frequently require significant manual tuning and heavy post-processing. Because these classical pipelines focus almost exclusively on geometric and positional constraints while ignoring dynamic forces like mass and momentum, they are prone to leaving physically infeasible artifacts—such as self-intersections or unnatural joint snapping—which can severely hinder the success of downstream physics-based tracking policies.

== Physics-Based Animation

/*
  Recommended References:
  
  Book: Rigid Body Dynamics Algorithms by Roy Featherstone. (External standard text from our previous conversation).
  
  Book: Introduction to Autonomous Mobile Robots by Roland Siegwart. (Recommended by your advisor for locomotion basics).
*/

In traditional keyframe animation, the artist is responsible for specifying the exact position and orientation of every armature bone across time. In contrast, procedural physics-based animation shifts this responsibility to a physics based animation system. By explicitly modeling physical properties such as mass, gravity, and inertia, this system automatically calculates how objects should accelerate, collide, and come to rest. This approach allows natural, physically realistic movements to emerge organically from the simulation, freeing the animator from manually crafting complex environmental reactions.

// Rigid Body Systems: Explain how simulated characters are modeled as articulated rigid bodies with specific masses, collision bounds, and degrees of freedom.

In physics-based character animation, virtual humans and robots are typically modeled as articulated rigid body systems. These systems consist of a hierarchical tree of rigid segments (links) connected by joints, such as revolute (rotational) or prismatic (translational). Each joint provides the connected segments with specific degrees of freedom, dictating the exact range and axes of allowable movement. Because the structural connectivity is built directly into the hierarchy, the physical segments stay attached automatically as the joints articulate.

To accurately simulate how these characters react to forces, each rigid segment is assigned specific dynamic properties. Every body part has a defined mass, a center of mass, and an inertia tensor. These properties dictate the segment's resistance to changes in linear and angular velocity. Furthermore, characters are equipped with collision bounds, which can range from simple bounding spheres and boxes to complex polyhedra. These bounds act as the physical shell of the character, allowing the system to detect overlaps and compute the necessary impulse forces to prevent the character from penetrating the ground or passing through other objects (clipping) .

// Physics Simulation and Actuation: Detail how physics engines (e.g., MuJoCo, Isaac Gym) simulate gravity, friction, and collisions, and how joints are actuated using Proportional-Derivative (PD) controllers to apply torques.

To bring these rigid body systems to life, researchers and animators rely on physics engines, such as MuJoCo and NVIDIA PhysX. These engines calculate the continuous time-evolution of the environment by simulating external forces like gravity, friction, and viscous drag. When the character's collision bounds intersect with the environment, the physics engine computes impact responses and contact normals, calculating the exact impulse forces required to push the objects apart or simulate resting contact. By integrating these forces and accelerations over tiny, discrete time steps, the engine automatically updates the character's position and velocity, generating highly realistic interactions.

In these simulations, joints are typically actuated using proportional-derivative (PD) controllers. The PD controller acts essentially as a localized spring-damper system, calculating the necessary torque based on the error between the current joint rotation and the target rotation, scaled by a proportional stiffness gain and a derivative damping gain. This method abstracts away low-level physics nuances, providing stable, direct-drive control over the simulated character movement.

// The Embodiment Gap: Discuss the morphological discrepancies (bone length, mass distribution, actuation limits) that make physical retargeting difficult. 

Even though simulating a character is mechanically straightforward, transferring motion across their morphological structures introduces a challenge known as the _embodiment gap_. When source and target characters share significant morphological discrepancies such as varying bone lengths, disparate joint ranges of motion, distinct overall body shapes, and fundamentally different mass distributions, a posture or movement that is perfectly balanced for the former character may instantly cause a heavier or differently proportioned latter character to lose its center of mass and fall over.

Traditional motion retargeting—which often just blindly copies joint angles or relies purely on kinematic mapping—tends to produce movements that are physically infeasible for the target. To successfully cross the embodiment gap, modern frameworks must go beyond matching visual poses and actively account for the rigid body dynamics, ensuring that the retargeted motion respects the physical constraints and mass distribution of the specific target morphology.

== Reinforcement Learning for Continuous Control

/*
References:
  Book: Reinforcement Learning: An Introduction by Richard S. Sutton and Andrew G. Barto. This is the definitive textbook on the subject and is heavily cited by the state-of-the-art physics-based RL papers in your sources.

  DRL HAndbook etc. ...

*/

// Markov Decision Processes (MDP): Define the RL framework where an agent observes a state st takes an action at according to a policy π, and receives a reward rt.

In the context of controlling a physically simulated character, its motion synthesis is formally defined as a RL problem governed by a Markov Decision Process. Within this framework, an agent observes the state of the environment $s_t$ at a discrete time-step $t$ and takes a continuous action $a_t$ sampled from a control policy $pi(a_t|s_t)$. The environment then transitions to a new state $s_{t+1}$ based on its internal physical dynamics and returns a scalar reward $r_t$ evaluating the desirability of that specific transition. The ultimate goal of the agent is to learn optimal policy parameters that maximize its expected cumulative discounted return over the simulation horizon.

To optimize these highly complex continuous control problems, modern physics-based animation pipelines predominantly employ Proximal Policy Optimization (PPO), an actor-critic algorithm. PPO utilizes a dual-network architecture: an actor network that outputs the policy distribution to select actions, and a critic network (value function) that evaluates the expected return of the current state to reduce variance and guide the actor during training. 

// In our latent-driven two-stage framework, **PPO is specifically used to train an initial "oracle" teacher policy in simulation**. This teacher exploits privileged simulator information to master the physical dynamics, which subsequently provides the precise ground-truth supervision required to train the final deployable, latent-driven student policy.

// State and Action Spaces: Explain how proprioceptive states (joint positions, velocities, root orientation) and target actions (target angles for PD controllers) are formulated for humanoid control.

For humanoid whole-body control, the state space $s_t$ must comprehensively capture the physical configuration of the character within the simulation. This is primarily achieved through proprioceptive states, which encompass the root's translation, global orientation (roll, pitch, yaw), linear and angular velocities, alongside the local positions and velocities of all individual joints. 

// In a latent-driven framework like ours, the state observed by the final deployment policy is deliberately restricted. It is augmented with the **abstract motion latent representation**, serving as a semantic intent or goal signal, as well as a history of recent proprioceptive observations to compensate for the lack of explicit reference trajectories and privileged environmental data.

// On the output side, rather than having a neural network to compute raw actuator torques directly—which is highly unstable

The action space $a_t$ is formulated to specify target joint angles (or positions) for Proportional-Derivative (PD) controllers stationed at each simulated joint. By abstracting away low-level physics nuances like local damping, the use of PD targets significantly improves the learning speed and stability of the RL policy, providing robust, direct-drive control over the complex humanoid morphology.

// Reward Design (Imitation vs. Task): Explain how RL policies are trained to imitate reference motions (tracking joint positions and velocities) while simultaneously achieving tasks (like moving to a target).

In physics-based motion synthesis, reward functions must meticulously engineered to balance two competing objectives: faithfully imitating a reference motion and successfully accomplishing a specific environmental task. In a imitation objective approach, the simulated character is encouraged to match the precise kinematic characteristics of the reference motion data at each time interval. This is typically achieved by computing exponential penalties for deviations in joint orientations, joint velocities, end-effector positions, and center-of-mass trajectories. By heavily rewarding tight tracking of these kinematic features, the policy learns to reproduce the nuanced style, fluidity, and coordinated balance of the original reference data.

Conversely, the task objective incentivizes the agent to fulfill high-level goals, such as moving towards a specific target heading, striking an object, or traversing irregular terrain. Because blindly imitating a reference motion is often insufficient to accomplish complex or novel tasks, the total reward is calculated as a weighted sum of both the imitation and task objectives. This dual-reward structure provides the RL policy with the flexibility to deviate slightly from the original reference motion when necessary, allowing it to naturally develop new, physically valid strategies to satisfy the task constraints while preserving the overarching stylistic intent of the source data.

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

The advent of deep generative models introduced latent space alignment to effectively handle structural disparities between characters. In @aberman_skeleton_aware_2020 it was developed a skeleton-aware neural network capable of unpaired motion retargeting between homeomorphic skeletons. Their method encodes structurally different motions into a shared deep latent space corresponding to a common primal skeleton. Expanding on this concept, in @yao_moconvq_2024 it was proposed the _MoConVQ_ framework, which learns scalable, discrete motion representations directly from extensive unstructured datasets. By combining these latent embeddings with model-based RL, MoConVQ provides a unified and intuitive interface for a variety of physics-based control tasks.

// 2025: Advanced Alignment, Robust Tracking, and Latent-Driven Control In 2025, rapid advancements expanded across all control paradigms to bridge the embodiment gap between humans and complex robots:

// Latent Space Alignment:

In @gat_anytop_2025 it was presented AnyTop, a diffusion model capable of generating animations for completely non-homeomorphic skeletons (from bipeds to arthropods) by integrating topological information into a transformer-based de-noising network. MoReFlow was introduced by @kim_moreflow_2025, an unsupervised framework utilizing flow matching to align the tokenized latent motion spaces of morphologically distinct characters. To combine efficiency with physical feasibility, it was proposed by @chen_implicit_2025 Implicit Kinodynamic Motion Retargeting (IKMR), which aligns motion topologies via a dual encoder-decoder and subsequently fine-tunes the decoder using imitation learning to produce physically viable trajectories.

// Optimization & Physics-Based RL: 

Classical optimization methods were re-evaluated to aid modern RL tracking. In "Retargeting Matters," it was demonstred by @araujo_retargeting_2025 that while RL policies can sometimes overcome retargeting artifacts, generating high-quality reference motions via robust inverse kinematics optimization (their GMR method) significantly improves the success rate of downstream humanoid tracking policies. Parallel to this, in @chen_gmt_2025 it was introduced General Motion Tracking (GMT), leveraging DRL on human reference data to build robust, whole-body controllers capable of managing a highly diverse set of humanoid locomotion skills.

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
    [1], [Gather datasets (AMASS, LAFAN1, AnimalSyn3D, Unitree G1) and set up simulation environment (IsaacGym, MuJoCo)],
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
    [1],  [x], [x],  [],  [],  [],  [],  [],  [],  [],  [],
    [2],  [], [x],  [x],  [x],  [],  [],  [],  [],  [],  [],
    [3],  [],  [x], [x], [x],  [],  [],  [],  [],  [],  [],
    [4],  [],  [],  [], [x], [],  [],  [],  [],  [],  [],
    [5],  [],  [],  [],  [],  [x], [x],  [],  [],  [],  [],
    [6],  [],  [],  [],  [],  [],  [x], [x],  [],  [],  [],
    [7],  [],  [],  [],  [],  [],  [],  [x], [x],  [x],  [],
    [8],  [],  [],  [],  [],  [],  [],  [],  [x], [x],  [],
    [9],  [],  [],  [],  [],  [],  [],  [],  [],  [x], [x],
    [10], [],  [],  [],  [],  [],  [],  [],  [],  [],  [x],
  ),
  caption: [Activity schedule calendar from March to December 2026.],
) <tab_calendar>

#bibliography("works.bib", style: "apa")