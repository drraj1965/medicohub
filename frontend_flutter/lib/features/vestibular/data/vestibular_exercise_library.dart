import '../models/vestibular_exercise.dart';
import '../widgets/vestibular_exercise_stage.dart';

class VestibularExerciseCategory {
  const VestibularExerciseCategory({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

const List<VestibularExerciseCategory> vestibularExerciseCategories =
    <VestibularExerciseCategory>[
  VestibularExerciseCategory(
    title: 'Gaze Stabilization',
    description: 'Exercises that train the eyes and head to work together.',
  ),
  VestibularExerciseCategory(
    title: 'Habituation Exercises',
    description: 'Repeated gentle movements to reduce motion sensitivity.',
  ),
  VestibularExerciseCategory(
    title: 'Positional Maneuvers for BPPV',
    description: 'Specific maneuvers for positional vertigo, ideally guided.',
  ),
  VestibularExerciseCategory(
    title: 'Balance Training',
    description: 'Standing tasks that improve steadiness and confidence.',
  ),
  VestibularExerciseCategory(
    title: 'Walking / Dynamic Gait Exercises',
    description: 'Walking drills that train balance while moving.',
  ),
  VestibularExerciseCategory(
    title: 'Motion Sensitivity Exercises',
    description:
        'Visual and memory-based drills for sensitive balance systems.',
  ),
];

const String _videoPlaceholder = '';

const List<VestibularExercise> vestibularExerciseLibrary = <VestibularExercise>[
  VestibularExercise(
    id: 'vor_x1_horizontal',
    title: 'VOR x1 horizontal',
    category: 'Gaze Stabilization',
    shortDescription:
        'Keep your eyes on a target while turning your head side to side.',
    fullInstructions:
        'Sit upright. Hold a card or focus on a letter at eye level. Keep your eyes fixed on the target while gently turning your head left and right. Move only as fast as you can keep the target clear. Rest if symptoms rise too much.',
    precautions:
        'Use a chair with back support. Stop if symptoms become severe or do not settle with rest.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid during new neurological symptoms, severe neck pain, or sudden hearing loss.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.stationaryLetter,
    targetText: 'X',
  ),
  VestibularExercise(
    id: 'vor_x1_vertical',
    title: 'VOR x1 vertical',
    category: 'Gaze Stabilization',
    shortDescription:
        'Keep your eyes on a target while nodding your head up and down.',
    fullInstructions:
        'Sit upright and focus on a fixed letter or small object. Keep looking at it while gently nodding your head up and down. Keep the target clear and slow down if it blurs.',
    precautions: 'Keep the movement small if your neck is uncomfortable.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with severe neck pain or new neurological symptoms.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.stationaryLetter,
    targetText: 'X',
  ),
  VestibularExercise(
    id: 'vor_x2_horizontal',
    title: 'VOR x2 horizontal',
    category: 'Gaze Stabilization',
    shortDescription:
        'Move your head and target in opposite horizontal directions.',
    fullInstructions:
        'Sit or stand safely. Hold a card at eye level. Move the card to the right while turning your head to the left, then reverse. Keep your eyes on the target. Start slowly.',
    precautions: 'Do this near support. This is more challenging than VOR x1.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid if you cannot stand safely or have severe symptoms.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.horizontalMovingDot,
    targetText: 'CARD',
    targetSpeed: 0.9,
  ),
  VestibularExercise(
    id: 'vor_x2_vertical',
    title: 'VOR x2 vertical',
    category: 'Gaze Stabilization',
    shortDescription:
        'Move your head and target in opposite vertical directions.',
    fullInstructions:
        'Hold a card at eye level. Move the card up as your head nods down, then move the card down as your head nods up. Keep your eyes fixed on the target.',
    precautions:
        'Use small movements and stop if neck pain or severe dizziness occurs.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid with severe neck pain or unsafe balance.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.verticalMovingDot,
    targetText: 'CARD',
    targetSpeed: 0.9,
  ),
  VestibularExercise(
    id: 'eye_movements_up_down',
    title: 'Eye movements up/down',
    category: 'Gaze Stabilization',
    shortDescription: 'Move only your eyes between two vertical targets.',
    fullInstructions:
        'Keep your head still. Look from an upper target to a lower target, then back again. Move your eyes smoothly and rest if symptoms increase.',
    precautions: 'Do not move your head during this exercise.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Stop if you develop double vision or severe headache.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.verticalMovingDot,
    targetSpeed: 0.75,
  ),
  VestibularExercise(
    id: 'eye_movements_side_to_side',
    title: 'Eye movements side-to-side',
    category: 'Gaze Stabilization',
    shortDescription: 'Move only your eyes between left and right targets.',
    fullInstructions:
        'Keep your head still. Look from a target on your left to a target on your right. Continue at a comfortable pace while keeping vision clear.',
    precautions: 'Stop if you notice new double vision.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'New double vision or severe headache needs urgent medical care.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.horizontalMovingDot,
    targetSpeed: 0.75,
  ),
  VestibularExercise(
    id: 'smooth_pursuit_horizontal',
    title: 'Smooth pursuit horizontal',
    category: 'Gaze Stabilization',
    shortDescription: 'Follow a moving target smoothly from side to side.',
    fullInstructions:
        'Keep your head still. Follow the moving dot with your eyes only as it travels left and right. Keep the movement smooth and comfortable.',
    precautions:
        'Slow down if the target blurs or dizziness becomes more than mild to moderate.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Stop for new double vision, severe headache, or faintness.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.horizontalMovingDot,
    targetSpeed: 0.8,
  ),
  VestibularExercise(
    id: 'smooth_pursuit_vertical',
    title: 'Smooth pursuit vertical',
    category: 'Gaze Stabilization',
    shortDescription: 'Follow a moving target smoothly up and down.',
    fullInstructions:
        'Keep your head still. Follow the moving dot with your eyes only as it travels up and down. Keep the movement smooth.',
    precautions:
        'Pause if symptoms build quickly, and restart only when settled.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Stop for new double vision, severe headache, or faintness.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.verticalMovingDot,
    targetSpeed: 0.8,
  ),
  VestibularExercise(
    id: 'saccades_two_targets',
    title: 'Saccades',
    category: 'Gaze Stabilization',
    shortDescription:
        'Shift your eyes between two targets without moving your head.',
    fullInstructions:
        'Keep your head still. Look quickly and accurately between the left and right targets as the highlighted target changes.',
    precautions:
        'Keep movements controlled. Stop if double vision or severe symptoms occur.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Stop for new double vision, severe headache, or faintness.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.twoTargetSaccade,
    targetSpeed: 0.7,
  ),
  VestibularExercise(
    id: 'zig_zag_tracking',
    title: 'Zig-zag tracking',
    category: 'Gaze Stabilization',
    shortDescription: 'Follow a target moving in a zig-zag path.',
    fullInstructions:
        'Keep your head still unless your clinician instructed otherwise. Follow the dot as it moves through a zig-zag path.',
    precautions:
        'This can be visually demanding. Keep symptoms mild to moderate.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Stop for severe dizziness, headache, or visual symptoms.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.zigZagDot,
    targetSpeed: 0.8,
  ),
  VestibularExercise(
    id: 'figure_eight_tracking',
    title: 'Figure-eight tracking',
    category: 'Gaze Stabilization',
    shortDescription: 'Follow a target moving in a figure-eight path.',
    fullInstructions:
        'Keep your head still unless instructed otherwise. Track the dot smoothly as it moves in a figure-eight pattern.',
    precautions:
        'Start slowly and rest if symptoms rise beyond mild to moderate.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Stop for severe dizziness, headache, or visual symptoms.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.figureEightDot,
    targetSpeed: 0.8,
  ),
  VestibularExercise(
    id: 'head_turns_sitting',
    title: 'Head turns sitting',
    category: 'Habituation Exercises',
    shortDescription: 'Turn your head left and right while seated.',
    fullInstructions:
        'Sit safely with feet on the floor. Turn your head left, return to center, then turn right. Keep movements gentle and steady.',
    precautions: 'Use a smaller range if your neck is stiff.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with severe neck pain or new neurological symptoms.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.headTurnCue,
    targetSpeed: 0.75,
  ),
  VestibularExercise(
    id: 'head_nods_sitting',
    title: 'Head nods sitting',
    category: 'Habituation Exercises',
    shortDescription: 'Nod your head up and down while seated.',
    fullInstructions:
        'Sit safely. Look slightly up, return to center, then look slightly down. Keep the movement slow and controlled.',
    precautions: 'Stop if severe dizziness, pain, or faintness occurs.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid with severe neck pain or fainting.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.headNodCue,
    targetSpeed: 0.75,
  ),
  VestibularExercise(
    id: 'shoulder_shrugs',
    title: 'Shoulder shrugs',
    category: 'Habituation Exercises',
    shortDescription: 'Gently lift and lower both shoulders.',
    fullInstructions:
        'Sit upright. Lift both shoulders toward your ears, hold briefly, then relax them down. Breathe normally.',
    precautions: 'Keep the movement comfortable and pain-free.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 10,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if shoulder or neck pain worsens significantly.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.shoulderShrugCue,
    targetSpeed: 0.75,
  ),
  VestibularExercise(
    id: 'trunk_rotation_sitting',
    title: 'Trunk rotation sitting',
    category: 'Habituation Exercises',
    shortDescription: 'Turn your upper body left and right while seated.',
    fullInstructions:
        'Sit with feet supported. Turn your shoulders and trunk gently to one side, return to center, then turn to the other side.',
    precautions: 'Keep movements slow. Hold the chair if needed.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 10,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if you feel faint or cannot sit safely.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.trunkRotationCue,
    targetSpeed: 0.7,
  ),
  VestibularExercise(
    id: 'sit_to_stand',
    title: 'Sit-to-stand',
    category: 'Balance Training',
    shortDescription: 'Practice standing up and sitting down safely.',
    fullInstructions:
        'Sit on a stable chair. Lean forward slightly, stand up, pause, then sit down slowly. Use your hands if needed. Keep a support nearby.',
    precautions: 'Do not rush. Stop if you feel faint or unsafe.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 90,
    recommendedRepetitions: 8,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid if chest pain, fainting, or severe imbalance is present.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.sitToStandCue,
    targetSpeed: 0.55,
  ),
  VestibularExercise(
    id: 'brandt_daroff',
    title: 'Brandt-Daroff exercise',
    category: 'Positional Maneuvers for BPPV',
    shortDescription:
        'A positional exercise sometimes used for BPPV habituation.',
    fullInstructions:
        'Sit on the edge of a bed. Turn your head about 45 degrees to one side, then lie quickly onto the opposite side. Stay until dizziness settles, then sit up. Repeat on the other side if prescribed.',
    precautions:
        'This can provoke vertigo. Perform on a bed with someone nearby if you are unsteady.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 120,
    recommendedRepetitions: 5,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with neck/back problems, new neurological symptoms, fainting, or severe vomiting.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.rollingCue,
    targetSpeed: 0.45,
  ),
  VestibularExercise(
    id: 'self_epley_right',
    title: 'Self Epley maneuver right',
    category: 'Positional Maneuvers for BPPV',
    shortDescription: 'A right-sided canalith repositioning maneuver for BPPV.',
    fullInstructions:
        'Only do this if a clinician has advised right-sided Epley. Sit on a bed, turn your head 45 degrees right, lie back with head supported, then follow the prescribed turning sequence slowly.',
    precautions: 'Use supervision. Stop for severe symptoms or neck pain.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 180,
    recommendedRepetitions: 1,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with neck disease, unstable heart symptoms, new weakness, double vision, or inability to walk.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.rollingCue,
    targetSpeed: 0.35,
  ),
  VestibularExercise(
    id: 'self_epley_left',
    title: 'Self Epley maneuver left',
    category: 'Positional Maneuvers for BPPV',
    shortDescription: 'A left-sided canalith repositioning maneuver for BPPV.',
    fullInstructions:
        'Only do this if a clinician has advised left-sided Epley. Sit on a bed, turn your head 45 degrees left, lie back with head supported, then follow the prescribed turning sequence slowly.',
    precautions: 'Use supervision. Stop for severe symptoms or neck pain.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 180,
    recommendedRepetitions: 1,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with neck disease, unstable heart symptoms, new weakness, double vision, or inability to walk.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.rollingCue,
    targetSpeed: 0.35,
  ),
  VestibularExercise(
    id: 'semont_right',
    title: 'Semont maneuver right',
    category: 'Positional Maneuvers for BPPV',
    shortDescription: 'A rapid positional maneuver for right-sided BPPV.',
    fullInstructions:
        'This maneuver involves moving quickly from sitting to side-lying positions. Perform only if taught by a clinician and with safe support.',
    precautions:
        'High vertigo provocation is possible. Supervision is recommended.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 180,
    recommendedRepetitions: 1,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with neck/back problems, severe vomiting, fainting, or new neurological symptoms.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.rollingCue,
    targetSpeed: 0.5,
  ),
  VestibularExercise(
    id: 'semont_left',
    title: 'Semont maneuver left',
    category: 'Positional Maneuvers for BPPV',
    shortDescription: 'A rapid positional maneuver for left-sided BPPV.',
    fullInstructions:
        'This maneuver involves moving quickly from sitting to side-lying positions. Perform only if taught by a clinician and with safe support.',
    precautions:
        'High vertigo provocation is possible. Supervision is recommended.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 180,
    recommendedRepetitions: 1,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with neck/back problems, severe vomiting, fainting, or new neurological symptoms.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.rollingCue,
    targetSpeed: 0.5,
  ),
  VestibularExercise(
    id: 'half_somersault_foster',
    title: 'Half-somersault / Foster maneuver',
    category: 'Positional Maneuvers for BPPV',
    shortDescription: 'A positional maneuver sometimes used for BPPV.',
    fullInstructions:
        'This requires kneeling and head positioning. Use only if taught by a clinician. Move slowly between positions and have support nearby.',
    precautions:
        'Not suitable for many people with neck, back, knee, or balance problems.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 180,
    recommendedRepetitions: 1,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with neck/back/knee problems, severe imbalance, fainting, or new neurological symptoms.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.bendingCue,
    targetSpeed: 0.45,
  ),
  VestibularExercise(
    id: 'romberg_stance',
    title: 'Romberg stance',
    category: 'Balance Training',
    shortDescription: 'Stand with feet together to train still balance.',
    fullInstructions:
        'Stand near a counter or wall. Place feet together and look forward. Hold the position safely. Start with eyes open.',
    precautions: 'Keep support within reach. Do not close eyes unless advised.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 30,
    recommendedRepetitions: 3,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if you cannot stand safely without help.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.blankBalanceMode,
  ),
  VestibularExercise(
    id: 'tandem_stance',
    title: 'Tandem stance',
    category: 'Balance Training',
    shortDescription: 'Stand with one foot directly in front of the other.',
    fullInstructions:
        'Stand near support. Place one foot in front of the other like standing on a line. Hold as safely as possible, then switch feet.',
    precautions:
        'Use a counter or wall. This is harder than feet-together stance.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 30,
    recommendedRepetitions: 3,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if fall risk is high without supervision.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.blankBalanceMode,
  ),
  VestibularExercise(
    id: 'single_leg_stance',
    title: 'Single-leg stance',
    category: 'Balance Training',
    shortDescription:
        'Stand briefly on one leg while holding support if needed.',
    fullInstructions:
        'Stand beside a firm support. Lift one foot slightly from the floor. Hold briefly, then switch sides.',
    precautions: 'Hold support. Do not attempt if you are unsafe standing.',
    difficultyLevel: 'advanced',
    recommendedDurationSeconds: 20,
    recommendedRepetitions: 3,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid without supervision if you have frequent falls.',
    requiresSupervision: true,
    visualMode: VestibularVisualMode.blankBalanceMode,
  ),
  VestibularExercise(
    id: 'heel_to_toe_walking',
    title: 'Heel-to-toe walking',
    category: 'Walking / Dynamic Gait Exercises',
    shortDescription:
        'Walk in a straight line placing heel directly before toe.',
    fullInstructions:
        'Walk along a hallway or beside a counter. Place the heel of one foot directly in front of the toes of the other foot. Look forward.',
    precautions: 'Use support and avoid cluttered spaces.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 3,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if you cannot walk safely.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.walkingCue,
    targetSpeed: 0.75,
  ),
  VestibularExercise(
    id: 'walking_with_head_turns',
    title: 'Walking with head turns',
    category: 'Walking / Dynamic Gait Exercises',
    shortDescription: 'Walk while gently turning your head side to side.',
    fullInstructions:
        'Walk in a safe hallway. Turn your head left and right every few steps while keeping your path steady.',
    precautions: 'Start slowly. Use supervision if you veer or lose balance.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 3,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid if you cannot walk safely or have severe dizziness.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.headTurnCue,
    targetSpeed: 0.65,
  ),
  VestibularExercise(
    id: 'walking_with_head_nods',
    title: 'Walking with head nods',
    category: 'Walking / Dynamic Gait Exercises',
    shortDescription: 'Walk while gently nodding your head up and down.',
    fullInstructions:
        'Walk in a safe space. Gently look up and down every few steps while keeping your balance and direction.',
    precautions: 'Use small head movements and stop if unsafe.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 3,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid if you cannot walk safely or have severe dizziness.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.headNodCue,
    targetSpeed: 0.65,
  ),
  VestibularExercise(
    id: 'marching_in_place',
    title: 'Marching in place',
    category: 'Walking / Dynamic Gait Exercises',
    shortDescription: 'March on the spot while keeping upright posture.',
    fullInstructions:
        'Stand near support. Lift one knee, lower it, then lift the other. Keep the movement controlled.',
    precautions: 'Hold support if needed. Stop if you feel faint.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if standing balance is unsafe.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.marchingCue,
    targetSpeed: 0.8,
  ),
  VestibularExercise(
    id: 'bending_forward_returning',
    title: 'Bending forward and returning upright',
    category: 'Motion Sensitivity Exercises',
    shortDescription:
        'Practice bending forward and sitting/standing upright again.',
    fullInstructions:
        'Sit or stand safely. Bend forward a small amount, then return upright. Begin with a small range and increase only if comfortable.',
    precautions: 'This may provoke dizziness. Move slowly and use support.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 8,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with fainting, severe back pain, or severe dizziness.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.bendingCue,
    targetSpeed: 0.55,
  ),
  VestibularExercise(
    id: 'rolling_in_bed',
    title: 'Rolling in bed habituation',
    category: 'Motion Sensitivity Exercises',
    shortDescription: 'Practice rolling gently from side to side in bed.',
    fullInstructions:
        'Lie on a bed. Roll gently to one side, pause, return to your back, then roll to the other side. Let symptoms settle between movements.',
    precautions:
        'Use a safe bed surface. Stop if vertigo is severe or prolonged.',
    difficultyLevel: 'beginner',
    recommendedDurationSeconds: 90,
    recommendedRepetitions: 6,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid with severe neck/back pain or new neurological symptoms.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.rollingCue,
    targetSpeed: 0.5,
  ),
  VestibularExercise(
    id: 'visual_motion_sensitivity',
    title: 'Visual motion sensitivity exercise',
    category: 'Motion Sensitivity Exercises',
    shortDescription:
        'Use gentle visual motion exposure to reduce sensitivity.',
    fullInstructions:
        'Look at a simple moving pattern or slowly move a patterned card side to side. Keep exposure brief and stop before symptoms become severe.',
    precautions: 'Avoid intense videos or busy scenes at first.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 45,
    recommendedRepetitions: 2,
    youtubeUrl: _videoPlaceholder,
    contraindications:
        'Avoid if visual motion triggers severe symptoms or migraine.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.optokineticStripes,
    targetSpeed: 0.7,
    backgroundMotionEnabled: true,
  ),
  VestibularExercise(
    id: 'remembered_target',
    title: 'Remembered target exercise',
    category: 'Motion Sensitivity Exercises',
    shortDescription:
        'Look at a target, close eyes, turn head, then return to target.',
    fullInstructions:
        'Look at a target. Close your eyes, turn your head slightly away, then try to return your gaze to where the target was. Open your eyes and check accuracy.',
    precautions: 'Do seated first. Keep movements small.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 8,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if closing eyes makes you unsafe or very dizzy.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.stationaryDot,
  ),
  VestibularExercise(
    id: 'imaginary_target',
    title: 'Imaginary target exercise',
    category: 'Motion Sensitivity Exercises',
    shortDescription: 'Imagine a fixed target while moving your head gently.',
    fullInstructions:
        'Sit upright. Imagine a target directly ahead. Slowly turn your head while keeping your imagined gaze stable, then return to center.',
    precautions: 'Keep it gentle and brief at first.',
    difficultyLevel: 'intermediate',
    recommendedDurationSeconds: 60,
    recommendedRepetitions: 8,
    youtubeUrl: _videoPlaceholder,
    contraindications: 'Avoid if symptoms rise sharply or do not settle.',
    requiresSupervision: false,
    visualMode: VestibularVisualMode.stationaryDot,
  ),
];

List<VestibularExercise> exercisesForCategory(String category) {
  return vestibularExerciseLibrary
      .where((exercise) => exercise.category == category)
      .toList(growable: false);
}
