import Foundation

public enum ExerciseLibrary {

    /// Availability semantics: an exercise is available when the user has no flagged injury
    /// among its contraindications AND its equipment requirement is satisfiable — bodyweight
    /// (`[.none]`) always is; `.fullGym` satisfies everything; otherwise any overlap between
    /// the exercise's acceptable equipment and the user's counts (the set lists alternatives,
    /// e.g. goblet squat works with dumbbells OR a kettlebell).
    public static func available(equipment: Set<Equipment>, injuries: Set<InjuryFlag>) -> [Exercise] {
        all.filter { exercise in
            guard exercise.contraindications.isDisjoint(with: injuries) else { return false }
            if exercise.equipment.contains(.none) { return true }
            if equipment.contains(.fullGym) { return true }
            return !exercise.equipment.isDisjoint(with: equipment)
        }
    }

    public static func exercise(id: String) -> Exercise? {
        all.first { $0.id == id }
    }

    public static let all: [Exercise] = [
        Exercise(
            id: "squat", name: "Bodyweight Squat",
            muscleGroups: [.quads, .glutes],
            equipment: [.none], contraindications: [.knee, .hip],
            met: 5.0, kind: .reps(12),
            instructions: [
                "Stand with feet shoulder-width apart, toes slightly out.",
                "Send hips back and down until thighs are near parallel.",
                "Keep chest up and heels planted.",
                "Drive through the floor to stand tall.",
            ],
            keyframes: ExercisePoses.squat(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "pushUp", name: "Push-Up",
            muscleGroups: [.chest, .arms, .core],
            equipment: [.none], contraindications: [.wrist, .shoulder],
            met: 3.8, kind: .reps(10),
            instructions: [
                "Hands under shoulders, body in one straight line.",
                "Lower your chest until elbows hit ninety degrees.",
                "Press the floor away without letting hips sag.",
            ],
            keyframes: ExercisePoses.pushUp(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "kneePushUp", name: "Knee Push-Up",
            muscleGroups: [.chest, .arms],
            equipment: [.none], contraindications: [.wrist],
            met: 2.8, kind: .reps(12),
            instructions: [
                "From knees, form a straight line knees-to-head.",
                "Lower chest under control, elbows at forty-five degrees.",
                "Push back up and squeeze your chest at the top.",
            ],
            keyframes: ExercisePoses.kneePushUp(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "lunge", name: "Alternating Lunge",
            muscleGroups: [.quads, .glutes],
            equipment: [.none], contraindications: [.knee],
            met: 4.0, kind: .reps(10),
            instructions: [
                "Step forward into a long stance.",
                "Drop the back knee toward the floor.",
                "Both knees at ninety degrees at the bottom.",
                "Push off the front foot to return, then switch.",
            ],
            keyframes: ExercisePoses.lunge(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "gluteBridge", name: "Glute Bridge",
            muscleGroups: [.glutes, .hamstrings],
            equipment: [.none], contraindications: [],
            met: 3.0, kind: .reps(15),
            instructions: [
                "Lie on your back, knees bent, feet flat.",
                "Drive hips up until knees, hips and shoulders align.",
                "Squeeze glutes at the top for one second.",
                "Lower with control.",
            ],
            keyframes: ExercisePoses.gluteBridge(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "plank", name: "Plank",
            muscleGroups: [.core],
            equipment: [.none], contraindications: [.wrist, .shoulder],
            met: 3.0, kind: .timed(seconds: 45),
            instructions: [
                "Forearms or hands under shoulders.",
                "Brace your core like you're about to be poked.",
                "One straight line from head to heels — breathe.",
            ],
            keyframes: ExercisePoses.plank(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "sidePlank", name: "Side Plank",
            muscleGroups: [.core],
            equipment: [.none], contraindications: [.wrist, .shoulder],
            met: 3.0, kind: .timed(seconds: 30),
            instructions: [
                "Stack feet, elbow under shoulder.",
                "Lift hips into one straight line.",
                "Reach the top arm to the ceiling and hold.",
            ],
            keyframes: ExercisePoses.sidePlank(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "mountainClimber", name: "Mountain Climber",
            muscleGroups: [.core, .cardio],
            equipment: [.none], contraindications: [.wrist],
            met: 8.0, kind: .timed(seconds: 30),
            instructions: [
                "Start in a high plank.",
                "Drive one knee to your chest, then switch fast.",
                "Keep hips low and shoulders over wrists.",
            ],
            keyframes: ExercisePoses.mountainClimber(), secondsPerCycle: 1.0
        ),
        Exercise(
            id: "jumpingJack", name: "Jumping Jack",
            muscleGroups: [.cardio, .fullBody],
            equipment: [.none], contraindications: [.knee, .ankle],
            met: 8.0, kind: .timed(seconds: 45),
            instructions: [
                "Jump feet wide while sweeping arms overhead.",
                "Land soft on the balls of your feet.",
                "Snap back to standing and repeat rhythmically.",
            ],
            keyframes: ExercisePoses.jumpingJack(), secondsPerCycle: 1.0
        ),
        Exercise(
            id: "highKnees", name: "High Knees",
            muscleGroups: [.cardio],
            equipment: [.none], contraindications: [.knee, .ankle],
            met: 8.0, kind: .timed(seconds: 30),
            instructions: [
                "Run in place, driving knees to hip height.",
                "Pump the arms in rhythm.",
                "Stay tall — don't lean back.",
            ],
            keyframes: ExercisePoses.highKnees(), secondsPerCycle: 0.8
        ),
        Exercise(
            id: "burpee", name: "Burpee",
            muscleGroups: [.fullBody, .cardio],
            equipment: [.none], contraindications: [.knee, .wrist, .lowerBack],
            met: 8.0, kind: .reps(10),
            instructions: [
                "Squat down, hands to the floor.",
                "Kick back to a plank.",
                "Hop feet back in and jump tall.",
            ],
            keyframes: ExercisePoses.burpee(), secondsPerCycle: 3.5
        ),
        Exercise(
            id: "birdDog", name: "Bird Dog",
            muscleGroups: [.core, .back],
            equipment: [.none], contraindications: [],
            met: 2.8, kind: .reps(10),
            instructions: [
                "On all fours, spine neutral.",
                "Reach opposite arm and leg long.",
                "Pause, return with control, switch sides.",
            ],
            keyframes: ExercisePoses.birdDog(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "deadBug", name: "Dead Bug",
            muscleGroups: [.core],
            equipment: [.none], contraindications: [],
            met: 2.8, kind: .reps(10),
            instructions: [
                "On your back, arms up, knees over hips.",
                "Lower opposite arm and leg toward the floor.",
                "Keep your lower back pressed down.",
            ],
            keyframes: ExercisePoses.deadBug(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "calfRaise", name: "Calf Raise",
            muscleGroups: [.calves],
            equipment: [.none], contraindications: [.ankle],
            met: 3.0, kind: .reps(15),
            instructions: [
                "Stand tall, feet hip-width.",
                "Rise onto the balls of your feet.",
                "Pause at the top, lower slowly.",
            ],
            keyframes: ExercisePoses.calfRaise(), secondsPerCycle: 2.0
        ),
        Exercise(
            id: "wallSit", name: "Wall Sit",
            muscleGroups: [.quads],
            equipment: [.none], contraindications: [.knee],
            met: 3.3, kind: .timed(seconds: 45),
            instructions: [
                "Back flat against a wall.",
                "Slide down until thighs are parallel.",
                "Knees over ankles — hold and breathe.",
            ],
            keyframes: ExercisePoses.wallSit(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "superman", name: "Superman",
            muscleGroups: [.back, .glutes],
            equipment: [.none], contraindications: [.lowerBack, .neck],
            met: 2.8, kind: .reps(12),
            instructions: [
                "Lie face down, arms extended.",
                "Lift arms, chest and legs together.",
                "Hold one second, lower softly.",
            ],
            keyframes: ExercisePoses.superman(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "dbRow", name: "Dumbbell Row",
            muscleGroups: [.back, .arms],
            equipment: [.dumbbells], contraindications: [.lowerBack],
            met: 5.0, kind: .reps(10),
            instructions: [
                "Hinge at the hips, flat back.",
                "Pull the dumbbells to your ribs.",
                "Squeeze shoulder blades, lower slowly.",
            ],
            keyframes: ExercisePoses.dbRow(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "dbShoulderPress", name: "Dumbbell Shoulder Press",
            muscleGroups: [.shoulders, .arms],
            equipment: [.dumbbells], contraindications: [.shoulder, .neck],
            met: 5.0, kind: .reps(10),
            instructions: [
                "Dumbbells at shoulder height, palms forward.",
                "Press straight up without arching your back.",
                "Lower under control to your ears.",
            ],
            keyframes: ExercisePoses.dbShoulderPress(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "dbCurl", name: "Dumbbell Curl",
            muscleGroups: [.arms],
            equipment: [.dumbbells], contraindications: [],
            met: 3.5, kind: .reps(12),
            instructions: [
                "Elbows pinned to your sides.",
                "Curl without swinging the torso.",
                "Lower slowly for a full stretch.",
            ],
            keyframes: ExercisePoses.dbCurl(), secondsPerCycle: 2.0
        ),
        Exercise(
            id: "gobletSquat", name: "Goblet Squat",
            muscleGroups: [.quads, .glutes],
            equipment: [.dumbbells, .kettlebell], contraindications: [.knee, .lowerBack],
            met: 5.0, kind: .reps(10),
            instructions: [
                "Hold the weight at your chest.",
                "Squat between your knees, elbows inside thighs.",
                "Stand tall driving through the heels.",
            ],
            keyframes: ExercisePoses.gobletSquat(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "dbRomanianDeadlift", name: "Romanian Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: [.dumbbells], contraindications: [.lowerBack],
            met: 4.0, kind: .reps(10),
            instructions: [
                "Soft knees, weights against your thighs.",
                "Push hips back, back flat, weights sliding down.",
                "Feel the hamstrings, then squeeze glutes to stand.",
            ],
            keyframes: ExercisePoses.dbRomanianDeadlift(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "lateralRaise", name: "Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: [.dumbbells], contraindications: [.shoulder],
            met: 3.0, kind: .reps(12),
            instructions: [
                "Slight bend in the elbows.",
                "Raise to shoulder height, lead with elbows.",
                "Lower slower than you lift.",
            ],
            keyframes: ExercisePoses.lateralRaise(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "kbSwing", name: "Kettlebell Swing",
            muscleGroups: [.glutes, .hamstrings, .cardio],
            equipment: [.kettlebell], contraindications: [.lowerBack],
            met: 9.5, kind: .reps(15),
            instructions: [
                "Hinge and hike the bell between your legs.",
                "Snap the hips forward — the arms just ride.",
                "Bell floats to chest height, then back into the hinge.",
            ],
            keyframes: ExercisePoses.kbSwing(), secondsPerCycle: 1.5
        ),
        Exercise(
            id: "bandRow", name: "Band Row",
            muscleGroups: [.back, .arms],
            equipment: [.resistanceBands], contraindications: [],
            met: 3.5, kind: .reps(12),
            instructions: [
                "Anchor the band at chest height.",
                "Row elbows past your ribs.",
                "Squeeze the shoulder blades together.",
            ],
            keyframes: ExercisePoses.bandRow(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "bandPullApart", name: "Band Pull-Apart",
            muscleGroups: [.shoulders, .back],
            equipment: [.resistanceBands], contraindications: [.shoulder],
            met: 3.0, kind: .reps(15),
            instructions: [
                "Hold the band at shoulder height, arms long.",
                "Pull apart until it touches your chest.",
                "Control the return — no snapping back.",
            ],
            keyframes: ExercisePoses.bandPullApart(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "pullUp", name: "Pull-Up",
            muscleGroups: [.back, .arms],
            equipment: [.pullUpBar], contraindications: [.shoulder, .wrist],
            met: 8.0, kind: .reps(6),
            instructions: [
                "Hang with hands just outside shoulders.",
                "Pull chest to the bar, elbows down and back.",
                "Lower all the way to a dead hang.",
            ],
            keyframes: ExercisePoses.pullUp(), secondsPerCycle: 3.0
        ),

        // MARK: Squat & lunge variations (Seedance clip set)

        Exercise(
            id: "boxSquat", name: "Box Squat",
            muscleGroups: [.quads, .glutes],
            equipment: [.none], contraindications: [.knee, .hip],
            met: 5.0, kind: .reps(10),
            instructions: [
                "Stand in front of a box or bench, feet shoulder-width.",
                "Sit hips back and down until you lightly touch the box.",
                "Stay braced — don't relax your weight onto it.",
                "Drive through the heels to stand tall.",
            ],
            keyframes: ExercisePoses.squat(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "frontSquat", name: "Front Squat",
            muscleGroups: [.quads, .glutes, .core],
            equipment: [.barbell], contraindications: [.knee, .wrist, .lowerBack],
            met: 5.5, kind: .reps(8),
            instructions: [
                "Rack the bar across the front of your shoulders, elbows high.",
                "Brace hard and sit straight down between your hips.",
                "Keep the chest and elbows up out of the bottom.",
                "Drive through mid-foot to stand.",
            ],
            keyframes: ExercisePoses.gobletSquat(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "bulgarianSplitSquat", name: "Bulgarian Split Squat",
            muscleGroups: [.quads, .glutes],
            equipment: [.none], contraindications: [.knee],
            met: 5.5, kind: .reps(10),
            instructions: [
                "Rest the top of your rear foot on a bench behind you.",
                "Lower straight down over the front leg.",
                "Front knee tracks over the toes, torso tall.",
                "Push through the front heel to rise — switch legs.",
            ],
            keyframes: ExercisePoses.lunge(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "reverseLunge", name: "Reverse Lunge",
            muscleGroups: [.quads, .glutes],
            equipment: [.none], contraindications: [.knee],
            met: 4.5, kind: .reps(10),
            instructions: [
                "Step one foot straight back into a long stance.",
                "Drop the back knee toward the floor.",
                "Both knees at ninety degrees at the bottom.",
                "Drive through the front heel to return — alternate.",
            ],
            keyframes: ExercisePoses.lunge(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "walkingLunge", name: "Walking Lunge",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: [.none], contraindications: [.knee],
            met: 4.5, kind: .reps(10),
            instructions: [
                "Step forward into a long lunge, back knee low.",
                "Push through the front heel to stand.",
                "Bring the back foot through into the next lunge.",
                "Keep walking, tall through the torso.",
            ],
            keyframes: ExercisePoses.lunge(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "deepSquatHold", name: "Deep Squat Hold",
            muscleGroups: [.quads, .glutes],
            equipment: [.none], contraindications: [.knee, .hip],
            met: 3.0, kind: .timed(seconds: 40),
            instructions: [
                "Sink into the bottom of a squat, heels flat.",
                "Elbows inside the knees, chest proud.",
                "Gently press the knees open and breathe.",
                "Hold the position for the full time.",
            ],
            keyframes: ExercisePoses.squat(), secondsPerCycle: 3.0
        ),

        // MARK: Core holds & dynamic core (Seedance clip set)

        Exercise(
            id: "hollowHold", name: "Hollow Hold",
            muscleGroups: [.core],
            equipment: [.none], contraindications: [.lowerBack],
            met: 3.0, kind: .timed(seconds: 30),
            instructions: [
                "Lie on your back, arms reaching overhead.",
                "Press your lower back into the floor.",
                "Lift shoulders and legs into a shallow banana.",
                "Hold, breathing steadily — no arching.",
            ],
            keyframes: ExercisePoses.deadBug(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "lSit", name: "L-Sit",
            muscleGroups: [.core, .quads],
            equipment: [.none], contraindications: [.wrist],
            met: 4.0, kind: .timed(seconds: 20),
            instructions: [
                "Hands planted by your hips, press tall.",
                "Lift your hips and extend both legs out front.",
                "Point the toes, thighs squeezing to an L.",
                "Hold as long as your form stays sharp.",
            ],
            keyframes: ExercisePoses.deadBug(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "vUp", name: "V-Up",
            muscleGroups: [.core],
            equipment: [.none], contraindications: [.lowerBack, .neck],
            met: 4.0, kind: .reps(12),
            instructions: [
                "Lie flat, arms overhead, legs long.",
                "Fold up, reaching your hands toward your toes.",
                "Balance on your hips at the top.",
                "Lower with control — don't drop.",
            ],
            keyframes: ExercisePoses.deadBug(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "candlestick", name: "Candlestick",
            muscleGroups: [.core, .fullBody],
            equipment: [.none], contraindications: [.neck, .lowerBack],
            met: 4.0, kind: .reps(8),
            instructions: [
                "From your back, roll knees over your chest.",
                "Extend the legs and hips toward the ceiling.",
                "Roll back down under control.",
                "Flow up to stand or repeat the roll.",
            ],
            keyframes: ExercisePoses.deadBug(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "kneePlank", name: "Knee Plank",
            muscleGroups: [.core],
            equipment: [.none], contraindications: [.wrist],
            met: 2.8, kind: .timed(seconds: 30),
            instructions: [
                "Forearms down, weight resting on your knees.",
                "Straight line from head to knees.",
                "Brace the core and squeeze the glutes.",
                "Breathe steady and hold the line.",
            ],
            keyframes: ExercisePoses.plank(), secondsPerCycle: 3.0
        ),

        // MARK: Barbell strength (Seedance clip set, batch 2)

        Exercise(
            id: "backSquat", name: "Back Squat",
            muscleGroups: [.quads, .glutes, .core],
            equipment: [.barbell], contraindications: [.knee, .hip, .lowerBack],
            met: 5.0, kind: .reps(8),
            instructions: [
                "Bar on your traps, feet shoulder-width, brace hard.",
                "Sit down between your hips, chest tall.",
                "Break below parallel with control.",
                "Drive through mid-foot to stand.",
            ],
            keyframes: ExercisePoses.gobletSquat(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "overheadSquat", name: "Overhead Squat",
            muscleGroups: [.quads, .glutes, .shoulders, .core],
            equipment: [.barbell], contraindications: [.knee, .shoulder, .lowerBack],
            met: 5.0, kind: .reps(6),
            instructions: [
                "Lock the bar overhead, wide grip, arms active.",
                "Squat to full depth without letting the bar drift.",
                "Keep the torso upright and the bar stacked over mid-foot.",
                "Stand tall, bar steady overhead throughout.",
            ],
            keyframes: ExercisePoses.squat(), secondsPerCycle: 3.0
        ),
        Exercise(
            id: "benchPress", name: "Bench Press",
            muscleGroups: [.chest, .arms, .shoulders],
            equipment: [.barbell, .bench], contraindications: [.shoulder, .wrist],
            met: 5.0, kind: .reps(8),
            instructions: [
                "Flat bench, shoulder blades pinned, feet planted.",
                "Lower the bar to mid-chest under control.",
                "Press to lockout, driving the bar slightly back.",
                "Keep the wrists stacked over the elbows.",
            ],
            keyframes: ExercisePoses.pushUp(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "pushPress", name: "Push Press",
            muscleGroups: [.shoulders, .arms, .quads],
            equipment: [.barbell], contraindications: [.shoulder, .neck, .lowerBack],
            met: 6.0, kind: .reps(6),
            instructions: [
                "Bar racked on the front of the shoulders.",
                "Dip at the knees, then drive explosively.",
                "Punch the bar to lockout overhead.",
                "Lower to the rack and reset each rep.",
            ],
            keyframes: ExercisePoses.dbShoulderPress(), secondsPerCycle: 2.5
        ),
        Exercise(
            id: "chestToBar", name: "Chest-to-Bar Pull-Up",
            muscleGroups: [.back, .arms],
            equipment: [.pullUpBar], contraindications: [.shoulder, .wrist],
            met: 8.0, kind: .reps(5),
            instructions: [
                "Hang with a full grip, shoulders active.",
                "Pull explosively until your chest meets the bar.",
                "Drive the elbows down and back.",
                "Lower all the way to a dead hang.",
            ],
            keyframes: ExercisePoses.pullUp(), secondsPerCycle: 3.0
        ),

        // MARK: Mobility / physical-therapy block (v2)

        Exercise(
            id: "catCow", name: "Cat-Cow",
            muscleGroups: [.back, .core],
            equipment: [.none], contraindications: [.wrist],
            met: 2.5, kind: .timed(seconds: 40),
            instructions: [
                "On all fours, wrists under shoulders.",
                "Inhale: drop the belly, lift your gaze.",
                "Exhale: round the spine, tuck the chin.",
            ],
            keyframes: MobilityPoses.catCow(), secondsPerCycle: 4.0, category: .mobility
        ),
        Exercise(
            id: "childsPose", name: "Child's Pose",
            muscleGroups: [.back],
            equipment: [.none], contraindications: [.knee],
            met: 2.0, kind: .timed(seconds: 40),
            instructions: [
                "Kneel and sit back toward your heels.",
                "Walk your hands long, forehead down.",
                "Breathe into your back for the full hold.",
            ],
            keyframes: MobilityPoses.childsPose(), secondsPerCycle: 4.0, category: .mobility
        ),
        Exercise(
            id: "hipFlexorStretch", name: "Hip Flexor Stretch",
            muscleGroups: [.quads, .glutes],
            equipment: [.none], contraindications: [.knee],
            met: 2.5, kind: .timed(seconds: 30),
            instructions: [
                "Half-kneel with your front foot planted.",
                "Tuck your pelvis and shift gently forward.",
                "Feel the front of the rear hip open — switch sides.",
            ],
            keyframes: MobilityPoses.hipFlexorStretch(), secondsPerCycle: 3.5, category: .mobility
        ),
        Exercise(
            id: "hamstringStretch", name: "Hamstring Stretch",
            muscleGroups: [.hamstrings, .back],
            equipment: [.none], contraindications: [.lowerBack],
            met: 2.5, kind: .timed(seconds: 30),
            instructions: [
                "Soft knees, hinge at the hips with a flat back.",
                "Slide your hands toward your shins.",
                "Stop at a strong stretch, never pain.",
            ],
            keyframes: MobilityPoses.standingHamstringStretch(), secondsPerCycle: 4.0, category: .mobility
        ),
        Exercise(
            id: "shoulderCircles", name: "Shoulder Circles",
            muscleGroups: [.shoulders],
            equipment: [.none], contraindications: [],
            met: 2.5, kind: .timed(seconds: 30),
            instructions: [
                "Stand tall, arms relaxed and long.",
                "Sweep both arms in slow, growing circles.",
                "Reverse direction halfway through.",
            ],
            keyframes: MobilityPoses.shoulderCircles(), secondsPerCycle: 2.5, category: .mobility
        ),
        Exercise(
            id: "ankleCircles", name: "Ankle Circles",
            muscleGroups: [.calves],
            equipment: [.none], contraindications: [],
            met: 2.0, kind: .timed(seconds: 30),
            instructions: [
                "Lift one knee to hip height.",
                "Draw slow circles with your foot.",
                "Both directions, then switch legs.",
            ],
            keyframes: MobilityPoses.ankleCircles(), secondsPerCycle: 2.0, category: .mobility
        ),
        Exercise(
            id: "thoracicRotation", name: "Thoracic Rotation",
            muscleGroups: [.back, .core],
            equipment: [.none], contraindications: [.wrist],
            met: 2.5, kind: .timed(seconds: 30),
            instructions: [
                "From all fours, hand behind your head or reaching.",
                "Rotate your chest open toward the ceiling.",
                "Follow your hand with your eyes — switch sides.",
            ],
            keyframes: MobilityPoses.thoracicRotation(), secondsPerCycle: 3.0, category: .mobility
        ),
        Exercise(
            id: "figureFourStretch", name: "Figure-4 Glute Stretch",
            muscleGroups: [.glutes],
            equipment: [.none], contraindications: [.hip],
            met: 2.0, kind: .timed(seconds: 30),
            instructions: [
                "On your back, cross one ankle over the other knee.",
                "Pull the supporting thigh gently toward you.",
                "Keep your head down and breathe — switch sides.",
            ],
            keyframes: MobilityPoses.figureFourStretch(), secondsPerCycle: 4.0, category: .mobility
        ),
        Exercise(
            id: "calfStretch", name: "Calf Stretch",
            muscleGroups: [.calves],
            equipment: [.none], contraindications: [],
            met: 2.0, kind: .timed(seconds: 30),
            instructions: [
                "Hands on a wall, one leg stepped back.",
                "Press the rear heel into the floor.",
                "Lean in until the calf lengthens — switch sides.",
            ],
            keyframes: MobilityPoses.standingCalfStretch(), secondsPerCycle: 4.0, category: .mobility
        ),
        Exercise(
            id: "worldsGreatestStretch", name: "World's Greatest Stretch",
            muscleGroups: [.fullBody],
            equipment: [.none], contraindications: [.knee, .hip, .wrist],
            met: 3.0, kind: .timed(seconds: 40),
            instructions: [
                "Step into a deep lunge, inside hand planted.",
                "Rotate and reach the free arm to the sky.",
                "Hold, return, and flow to the other side.",
            ],
            keyframes: MobilityPoses.worldsGreatestStretch(), secondsPerCycle: 4.0, category: .mobility
        ),
        Exercise(
            id: "neckRelease", name: "Neck Release",
            muscleGroups: [.shoulders],
            equipment: [.none], contraindications: [],
            met: 2.0, kind: .timed(seconds: 30),
            instructions: [
                "Sit or stand tall, shoulders heavy.",
                "Tilt one ear toward the shoulder.",
                "Hold, breathe, and roll gently to the other side.",
            ],
            keyframes: MobilityPoses.neckRelease(), secondsPerCycle: 5.0, category: .mobility
        ),
    ]
}
