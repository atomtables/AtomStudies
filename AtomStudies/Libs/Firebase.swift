//
//  Firebase.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 2/2/2025.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

enum FirebaseError: Error {
    case DataError(String)
}

public class User: Codable {
    public var firstName: String = ""
    public var lastName: String = ""

    init() {}

    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}

public enum LessonDifficulty: Int, Codable {
    case easy
    case medium
    case hard
}

public enum LessonType: Int, Codable {
    case lesson
    case quiz
    case test
}

public struct Lesson: Codable {
    public let type: LessonType
    public let difficulty: LessonDifficulty
    public let length: Int
    public let name: String
    public let unit: Int
    public let block: Int
    public let section: Int?
    public let content: [LessonContent]
    public let image: String
}

public enum LessonContentType: String, Codable {
    case text
    case question
}

public struct LessonContent: Codable {
    public let type: LessonContentType // enum
    public let image: String?
    public let title: String?
    public let content: String?
    public let choices: [String]?
    public let correct: Int?

    init(
        type: LessonContentType,
        image: String?,
        title: String?,
        content: String?
    ) {
        self.type = type
        self.image = image
        self.title = title
        self.content = content

        self.choices = nil
        self.correct = nil
    }
    init(
        type: LessonContentType,
        image: String?,
        title: String?,
        choices: [String]?,
        correct: Int?
    ) {
        self.type = type
        self.image = image
        self.title = title
        self.choices = choices
        self.correct = correct

        self.content = nil
    }
}

public struct CurriculumProgress: Codable {
    public var unit: Int
    public var block: Int
    public var lesson: Int
}

public struct UnitProgress {
    public struct BlockProgress {
        var currentSection: Int
        var isCompleted: Bool = false
        var block: Int
    }
    var isCompleted: Bool = false
    var blocks: [BlockProgress]
    var currentBlock: BlockProgress {
        blocks.first {!$0.isCompleted}!
    }
    var unit: Int
}

public struct Award {
    let image: String?
    let name: String
    let desc: String
}

@Observable public class FirebaseViewData {
    public static var main: FirebaseViewData = FirebaseViewData();

    public var initialised: Bool = false;
    public var loggingIn: Bool = false;
    public var loggedIn: Bool = false;
    public var errorFetchingPreviews: Bool = false;

    public var previews: [CurriculumUnit]?
    public var progress: [UnitProgress]?

    public var isLessonShown: Bool = false
    public var unit: Int = 0
    public var block: Int = 0
    public var section: Int? = 0
}

public class Firebase {
    public static var main: Firebase!;
    public static let db = Firestore.firestore();

    public var initialised: Bool = true {
        didSet {
            withAnimation() {
                FirebaseViewData.main.initialised = self.initialised;
            }
        }
    }
    public var loggingIn: Bool = false {
        didSet {
            withAnimation() {
                FirebaseViewData.main.loggingIn = self.loggingIn;
            }
        }
    }
    public var loggedIn: Bool = false {
        didSet {
            withAnimation() {
                FirebaseViewData.main.loggedIn = self.loggedIn;
            }
        }
    }
    public var errorFetchingPreviews: Bool = false {
        didSet {
            withAnimation() {
                FirebaseViewData.main.errorFetchingPreviews = self.errorFetchingPreviews
            }
        }
    };
    public var previews: [CurriculumUnit]? {
        didSet {
            withAnimation() {
                FirebaseViewData.main.previews = self.previews;
            }
        }
    }
    public var progress: [UnitProgress]? {
        didSet {
            withAnimation() {
                FirebaseViewData.main.progress = self.progress;
            }
        }
    }

    public var uid: String = ""
    public var email: String = ""
    public var user: User = User();

    public init() {
        print("proper init")
        withAnimation { FirebaseViewData.main.initialised = true; }
        Task {
            do {
                if let user = Auth.auth().currentUser {
                    self.loggingIn = true

                    self.uid = user.uid
                    self.email = user.email ?? ""

                    self.user = try await fetch()
                    self.loggingIn = false
                    self.loggedIn = true
                }
            } catch {
                print(error)
            }
        }
    }

    let DEBUG = false

    public func login(email: String, password: String) async throws {
        print(email, password)
        guard !FirebaseViewData.main.loggedIn else {
            print("Already logged in: \(self.email)")
            return;
        }

        if DEBUG {
            self.uid = UUID().uuidString
            self.email = email
            self.user = User(firstName: "Adithiya", lastName: "Venkatakrishnan")

            self.loggedIn = true
            self.loggingIn = true
        } else {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            self.uid = authResult.user.uid
            self.email = authResult.user.email ?? ""
            self.user = try await fetch()

            self.loggedIn = true
            self.loggingIn = true

            print("Logged in: \(self.email)")
        }
    }

    public func signup(email: String, password: String, user: User) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)

        self.uid = authResult.user.uid
        self.email = authResult.user.email ?? ""
        try self.modify(user: user)

        self.loggedIn = true;
        self.loggingIn = true;
    }

    public func logout() throws {
        try Auth.auth().signOut()

        self.uid = ""
        self.email = ""
        self.loggedIn = false;
    }

    public func fetch() async throws -> User {
        guard let json = try await Firebase.db
            .collection("users")
            .document(uid)
            .getDocument()
            .data()
        else {
            throw FirebaseError.DataError("Document does not exist.")
        }

        return try JSONDecoder().decode(
            User.self,
            from: try JSONSerialization
                .data(
                    withJSONObject: json
                )
        )
    }

    public func fetch() async throws -> [CurriculumUnit] {
        [
            CurriculumUnit(
                number: 1,
                name: "Chemistry at its Base",
                description: "This unit introduces fundamental chemistry concepts, including the nature of chemistry, states of matter, the periodic table, and atomic structure.",
                sublessons: [
                    CurriculumBlock(unit: 1, block: 1, topic: "What is Chemistry?", type: .lesson, length: 2, image: "lesson111"),
                    CurriculumBlock(unit: 1, block: 2, topic: "States of Matter", type: .lesson, length: 3, image: "lesson121"),
                    CurriculumBlock(unit: 1, block: 3, topic: "The Periodic Table", type: .lesson, length: 5, image: "lesson131"),
                    CurriculumBlock(unit: 1, block: 4, topic: "Trends in the Periodic Table Quiz", type: .quiz, length: 1, image: "lesson143"),
                    CurriculumBlock(unit: 1, block: 5, topic: "Atomic Structure", type: .lesson, length: 5, image: "lesson141"),
                    CurriculumBlock(unit: 1, block: 6, topic: "Periodic Table & Atomic Structure Quiz", type: .quiz, length: 1, image: "lesson123"),
                    CurriculumBlock(unit: 1, block: 7, topic: "States of Matter & Reactions Quiz", type: .quiz, length: 1, image: "lesson133"),
                    CurriculumBlock(unit: 1, block: 8, topic: "Final Chemistry Test", type: .test, length: 1, image: "lesson111")
                ]
            ),
            CurriculumUnit(number: 2, name: "Molecules and Reactions",
                           description: "How the building blocks come together to form more useful molecules.", sublessons: [
                            CurriculumBlock(unit: 2, block: 1, topic: "mEquations", type: .lesson, length: 3),
                            CurriculumBlock(unit: 2, block: 2, topic: "mMore equations", type: .lesson, length: 3),
                            CurriculumBlock(unit: 2, block: 3, topic: "mStop and walk", type: .quiz),
                            CurriculumBlock(unit: 2, block: 4, topic: "mNew energy", type: .lesson, length: 3),
                            CurriculumBlock(unit: 2, block: 5, topic: "mWhat is chemistry", type: .lesson, length: 3),
                            CurriculumBlock(unit: 2, block: 6, topic: "mConcept Check 1", type: .quiz),
                            CurriculumBlock(unit: 2, block: 7, topic: "mI;m bored", type: .lesson, length: 3),
                            CurriculumBlock(unit: 2, block: 8, topic: "mDon't make me mad", type: .lesson, length: 3),
                            CurriculumBlock(unit: 2, block: 9, topic: "mprep", type: .quiz),
                            CurriculumBlock(unit: 2, block: 10, topic: "mthe beginning of the end", type: .test),
                           ]),
            CurriculumUnit(number: 3, name: "Chemistry 3",
                           description: "honestly who cares anymore", sublessons: [
                            CurriculumBlock(unit: 3, block: 1, topic: "mEquations", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 2, topic: "mMore equations", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 3, topic: "mStop and walk", type: .quiz),
                            CurriculumBlock(unit: 3, block: 4, topic: "mNew energy", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 5, topic: "mWhat is chemistry", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 6, topic: "mConcept Check 1", type: .quiz),
                            CurriculumBlock(unit: 3, block: 7, topic: "mI;m bored", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 8, topic: "mDon't make me mad", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 9, topic: "mDon't make me madf", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 10, topic: "mprep", type: .quiz),
                            CurriculumBlock(unit: 3, block: 11, topic: "mDon't make me madff", type: .lesson, length: 3),
                            CurriculumBlock(unit: 3, block: 12, topic: "mthe beginning of the end", type: .test),
                           ])
        ]
    }

    public func fetch(unit: Int, block: Int, section: Int?) async throws -> Lesson {
        if unit == 1 && block == 1 && section == 1 {
            return Lesson(
                type: .lesson,
                difficulty: .easy,
                length: 6,  // Increased length to accommodate more content
                name: "Introduction to Chemistry",
                unit: 1,
                block: 1,
                section: 1,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson111",
                        title: "What is Chemistry?",
                        content: "Chemistry is the branch of science that studies the composition, structure, properties, and changes of matter. It explores how substances interact, combine, and transform through chemical reactions. Chemistry is often called the 'central science' because it connects and overlaps with other fields such as biology, physics, and environmental science.\n\nBy understanding chemistry, we can explain everyday phenomena, from why leaves change color in the fall to how batteries generate power. Scientists use chemistry to develop new materials, medicines, and technologies that improve our daily lives."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson111",
                        title: "Branches of Chemistry",
                        content: "Chemistry is divided into several specialized branches, each focusing on different aspects of matter and its interactions:\n\n1. Organic Chemistry – The study of carbon-containing compounds, which form the basis of life and synthetic materials like plastics and pharmaceuticals.\n2. Inorganic Chemistry – The study of non-carbon-based substances, including metals, minerals, and catalysts.\n3. Physical Chemistry – The study of how matter behaves on a molecular and atomic level, including topics like thermodynamics and quantum mechanics.\n4. Analytical Chemistry – The study of techniques for identifying and quantifying the composition of substances, essential for quality control and forensic science.\n5. Biochemistry – The study of chemical processes occurring in living organisms, which helps us understand metabolism, genetics, and disease mechanisms."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson111",
                        title: "Why is Chemistry Important?",
                        content: "Chemistry plays a crucial role in many fields and industries, shaping the world around us:\n\n- Medicine & Healthcare – Chemistry is essential in drug development, disease diagnostics, and medical treatments such as vaccines and antibiotics.\n- Engineering & Technology – Chemists develop materials like semiconductors, polymers, and nanomaterials that drive technological innovations.\n- Agriculture & Food Science – Chemistry helps improve fertilizers, pesticides, and food preservation techniques to ensure global food security.\n- Environmental Science – Chemistry helps us understand and mitigate pollution, develop sustainable energy sources, and combat climate change.\n- Everyday Life – From cooking and cleaning to the materials used in clothing and electronics, chemistry impacts almost every aspect of daily living."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson111",
                        title: "Chemistry in the Modern World",
                        content: "Modern advancements in chemistry have led to groundbreaking discoveries that shape our world. Some of the most significant contributions include:\n\n- Renewable Energy – Development of solar panels, batteries, and hydrogen fuel cells to create sustainable energy sources.\n- Artificial Intelligence & Chemistry – AI-driven models are now used to accelerate drug discovery and material design.\n- Space Exploration – Chemistry enables the development of rocket fuels, life-support systems, and materials for space travel.\n- Green Chemistry – A movement toward designing environmentally friendly chemicals and processes to reduce pollution and waste."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson111",
                        title: "Fun Facts About Chemistry",
                        content: "Here are some fascinating chemistry facts you might not know:\n\n- Water expands when it freezes, which is why ice floats on liquid water.\n- A single teaspoon of honey represents the work of over 12 bees throughout their lifetimes.\n- The human body is composed of about 60% water and contains elements like carbon, oxygen, hydrogen, and trace metals.\n- The smell of rain comes from a chemical called petrichor, released when water interacts with soil bacteria.\n- The strongest acid in the world, fluoroantimonic acid, is over a billion times stronger than stomach acid."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson111",
                        title: "Which is NOT a branch of chemistry?",
                        choices: [
                            "Organic Chemistry",
                            "Inorganic Chemistry",
                            "Physical Chemistry",
                            "Biophysics"
                        ],
                        correct: 3
                    )
                ],
                image: "lesson111"
            )
        }

        if unit == 1 && block == 1 && section == 2 {
            return Lesson(
                type: .lesson,
                difficulty: .easy,
                length: 4,
                name: "The Scientific Method in Chemistry",
                unit: 1,
                block: 1,
                section: 2,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson112",
                        title: "Steps of the Scientific Method",
                        content: "The scientific method is a systematic approach used by scientists to explore observations, answer questions, and test hypotheses. It consists of several key steps:\n\n1. Observation – Identifying a phenomenon or problem that needs explanation.\n2. Question – Forming a clear, specific question based on observations.\n3. Hypothesis Formation – Proposing a testable explanation or prediction.\n4. Experimentation – Conducting experiments to test the hypothesis under controlled conditions.\n5. Data Collection & Analysis – Recording observations and analyzing results.\n6. Conclusion – Drawing conclusions based on the data and determining whether the hypothesis is supported or needs revision.\n7. Communication – Sharing findings with the scientific community for validation and further study."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson112",
                        title: "Experimentation in Chemistry",
                        content: "Experiments are the backbone of chemistry, allowing scientists to test hypotheses, uncover patterns, and refine theories. A well-designed experiment follows a structured plan:\n\n- Independent Variable – The factor that is deliberately changed in an experiment.\n- Dependent Variable – The factor that is measured in response to changes in the independent variable.\n- Control Variables – Factors that are kept constant to ensure a fair test.\n- Repetition & Reproducibility – Conducting multiple trials and ensuring results can be repeated by other scientists.\n\nA good experiment minimizes bias and errors, ensuring that conclusions are based on reliable and accurate data."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson112",
                        title: "Lab Safety",
                        content: "Chemistry labs contain hazardous materials and equipment, making safety a top priority. Here are some essential lab safety rules:\n\n- Wear Protective Gear – Safety goggles, lab coats, and gloves protect against chemical exposure.\n- Know Emergency Procedures – Familiarize yourself with the locations of fire extinguishers, eyewash stations, and emergency exits.\n- Handle Chemicals Safely – Always read labels, use fume hoods when necessary, and never mix chemicals without proper instructions.\n- Dispose of Waste Properly – Follow disposal guidelines for chemicals, glassware, and biohazards.\n- Avoid Food & Drink in the Lab – Prevent contamination and accidental ingestion of hazardous substances.\n\nFollowing these safety precautions helps create a secure and efficient working environment in the lab."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson112",
                        title: "Which step follows forming a hypothesis?",
                        choices: [
                            "Observation",
                            "Experiment",
                            "Conclusion",
                            "Data Analysis"
                        ],
                        correct: 1
                    )
                ],
                image: "lesson112"
            )
        }

        if unit == 1 && block == 2 && section == 1 {
            return Lesson(
                type: .lesson,
                difficulty: .easy,
                length: 6,  // Increased length for better coverage
                name: "The Four States of Matter",
                unit: 1,
                block: 2,
                section: 1,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson121",
                        title: "What is Matter?",
                        content: "Matter is anything that has mass and occupies space. It exists in different forms, known as states of matter, which are determined by the arrangement and movement of particles. The four fundamental states of matter are solid, liquid, gas, and plasma. Each state has distinct properties based on how its particles interact."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson121",
                        title: "Solid State",
                        content: "Solids have a definite shape and volume because their particles are tightly packed in a fixed, orderly arrangement. The strong intermolecular forces between these particles prevent them from moving freely, allowing solids to maintain their structure.\n\nExamples of Solids:\n- Ice\n- Metal\n- Rocks\n- Wood\n\nEven though the particles in a solid vibrate slightly, they do not change positions significantly. This is why solids are rigid and resist changes in shape unless a force is applied."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson121",
                        title: "Liquid State",
                        content: "Liquids have a definite volume but take the shape of their container because their particles are less tightly packed than in solids. The intermolecular forces are weaker, allowing the particles to move around more freely while still staying close together.\n\nExamples of Liquids:\n- Water\n- Oil\n- Mercury\n- Milk\n\nLiquids can flow, be poured, and take on different shapes while maintaining their volume. Surface tension, a property of liquids, allows small objects like insects to walk on water."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson121",
                        title: "Gas State",
                        content: "Gases have neither a definite shape nor a definite volume. Their particles are widely spaced and move freely in all directions, expanding to fill any available space.\n\nExamples of Gases:\n- Oxygen\n- Carbon dioxide\n- Nitrogen\n- Helium\n\nSince gas particles move rapidly and are far apart, gases can be compressed or expanded. This is why gases like oxygen are stored in compressed cylinders for medical use."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson121",
                        title: "Plasma State",
                        content: "Plasma is a high-energy state of matter where atoms lose electrons, creating a mixture of charged particles. It is the most abundant state of matter in the universe, making up stars, including our Sun.\n\nExamples of Plasma:\n- The Sun and other stars\n- Lightning\n- Neon and fluorescent lights\n- Plasma TVs\n\nPlasma conducts electricity and generates magnetic fields, making it essential for technologies like fusion energy research."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson121",
                        title: "Phase Changes",
                        content: "Matter can change between states through physical processes:\n\n- Melting (Solid → Liquid)\n- Freezing (Liquid → Solid)\n- Evaporation (Liquid → Gas)\n- Condensation (Gas → Liquid)\n- Ionization (Gas → Plasma)\n- Recombination (Plasma → Gas)\n\nThese changes occur when energy is added or removed from a substance, affecting the motion of its particles."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson121",
                        title: "Which state of matter has a definite shape?",
                        choices: [
                            "Solid",
                            "Liquid",
                            "Gas",
                            "Plasma"
                        ],
                        correct: 0
                    )
                ],
                image: ""
            )
        }

        if unit == 1 && block == 2 && section == 2 {
            return Lesson(
                type: .lesson,
                difficulty: .medium,
                length: 6,  // Increased length for better explanation
                name: "Energy and States of Matter",
                unit: 1,
                block: 2,
                section: 2,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson122",
                        title: "Kinetic Molecular Theory",
                        content: "The Kinetic Molecular Theory (KMT) explains how particles in matter behave based on their energy and movement. The key ideas of this theory are:\n\n1. All matter is made of tiny particles (atoms and molecules) that are constantly in motion.\n2. The energy of these particles determines the state of matter—solids have the least energy, gases have the most.\n3. Temperature is a measure of the average kinetic energy of particles. The higher the temperature, the faster the particles move.\n\nThis theory helps us understand why solids are rigid, liquids flow, and gases expand to fill a space."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson122",
                        title: "Heat Transfer and Matter",
                        content: "Heat energy affects the movement of particles and can cause a substance to change states. There are three main ways heat transfers:\n\n- Conduction: Direct transfer of heat through contact, like a metal spoon heating up in a hot cup of tea.\n- Convection: Heat transfer through fluids (liquids or gases) due to movement of warm and cool regions, like boiling water.\n- Radiation: Heat transfer through electromagnetic waves, like the warmth of sunlight.\n\nWhen a substance absorbs heat, its particles move faster, increasing the chances of a phase change."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson122",
                        title: "Phase Changes and Energy",
                        content: "Phase changes occur when energy is added or removed, altering the movement of particles:\n\n- Melting (Solid → Liquid): Heat energy weakens the bonds between solid particles, allowing them to move freely.\n- Freezing (Liquid → Solid): When heat is removed, particles slow down and arrange into a fixed structure.\n- Evaporation (Liquid → Gas): Particles at the surface gain enough energy to break free and become gas.\n- Condensation (Gas → Liquid): Cooling gas particles lose energy and form a liquid.\n- Sublimation (Solid → Gas): Some substances, like dry ice, turn directly into gas without becoming liquid.\n- Deposition (Gas → Solid): The opposite of sublimation, like frost forming on a cold surface."
                    ),
                    LessonContent(
                        type: .text,
                        image: nil,
                        title: "Real-World Examples of Phase Changes",
                        content: "Phase changes happen all around us! Here are some real-life examples:\n\n- Ice melting in a drink (Melting)\n- Water forming on a cold soda can (Condensation)\n- Steam rising from a pot of boiling water (Evaporation)\n- Snow forming in clouds from water vapor (Deposition)\n- Dry ice creating fog by turning into gas (Sublimation)\n\nUnderstanding phase changes helps in fields like meteorology, cooking, and engineering."
                    ),
                    LessonContent(
                        type: .text,
                        image: nil,
                        title: "The Role of Energy in Matter",
                        content: "Energy is essential for changing the state of matter. The amount of energy needed depends on the specific heat capacity of a substance—how much heat it takes to change its temperature.\n\nFor example:\n- Water has a high specific heat, meaning it takes a lot of energy to heat up or cool down.\n- Metal heats up quickly because it has a low specific heat.\n\nThis is why water is used in cooling systems and why metals get hot quickly in the sun."
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What happens when heat is added to a solid?",
                        choices: [
                            "It melts",
                            "It freezes",
                            "It condenses",
                            "It evaporates"
                        ],
                        correct: 0
                    )
                ],
                image: "lesson122"
            )
        }

        if unit == 1 && block == 2 && section == 3 {
            return Lesson(
                type: .lesson,
                difficulty: .easy,
                length: 6,  // Increased length for better explanations
                name: "Real-World Examples of States of Matter",
                unit: 1,
                block: 2,
                section: 3,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson123",
                        title: "The Water Cycle: Matter in Motion",
                        content: "One of the most common examples of matter changing states is the water cycle, which describes how water moves through different phases in Earth's atmosphere. The key processes include:\n\n- Evaporation (Liquid → Gas): Heat from the sun causes water in lakes, rivers, and oceans to turn into water vapor.\n- Condensation (Gas → Liquid): As water vapor cools in the atmosphere, it forms clouds.\n- Precipitation (Liquid → Solid or Liquid): Water falls back to Earth as rain, snow, sleet, or hail.\n- Freezing (Liquid → Solid): In colder regions, water freezes to form ice and snow.\n- Melting (Solid → Liquid): Ice and snow melt back into liquid water when temperatures rise.\n\nThe water cycle is a perfect example of how matter transitions between solid, liquid, and gas states in nature!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson123",
                        title: "Plasma: The Most Abundant State of Matter",
                        content: "Although we rarely encounter plasma in everyday life, it is actually the most common state of matter in the universe. Plasma is a superheated state where atoms lose their electrons, creating a mixture of charged particles. Some key examples include:\n\n- The Sun and Other Stars: The sun is a massive ball of plasma where hydrogen atoms undergo nuclear fusion, producing light and heat.\n- Nebulae: These glowing clouds of ionized gas are made of plasma and are where new stars are born.\n- Solar Flares: Explosions on the sun's surface release bursts of plasma that travel through space and can impact Earth's magnetic field.\n\nWithout plasma, the universe as we know it wouldn’t exist!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson123",
                        title: "Lightning: Nature’s Plasma",
                        content: "One of the most dramatic examples of plasma on Earth is lightning. When storm clouds build up a strong electrical charge, the air between them ionizes, creating a plasma channel that allows electricity to flow in the form of a lightning bolt.\n\n- The intense heat of lightning (about 30,000°C, hotter than the sun’s surface!) ionizes the surrounding air, creating a glowing plasma.\n- This is why lightning appears as a bright, glowing flash—it is a strip of ionized gas that temporarily becomes plasma.\n- Thunder is caused by the rapid expansion of air around the lightning bolt due to extreme heat.\n\nNext time you see a lightning storm, remember—you’re witnessing plasma in action!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson123",
                        title: "Everyday Examples of States of Matter",
                        content: "Beyond extreme natural events, states of matter are present in our daily lives. Here are some common examples:\n\n- Solids: Ice cubes, rocks, metal objects, wooden furniture.\n- Liquids: Water, juice, cooking oil, molten lava.\n- Gases: Oxygen we breathe, helium in balloons, steam from a kettle.\n- Plasma: Neon signs, plasma TVs, flames from a fire.\n\nEach state of matter has unique properties, and recognizing them in the world around us helps us understand chemistry in action!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson123",
                        title: "The Role of Energy in Changing States",
                        content: "Energy plays a critical role in changing one state of matter into another. \n\n- Adding energy (like heat) can turn a solid into a liquid (melting) or a liquid into a gas (evaporation).\n- Removing energy (cooling) can turn a gas into a liquid (condensation) or a liquid into a solid (freezing).\n\nFor plasma, even more energy is needed to strip electrons from atoms, creating a charged particle state. This is why plasma occurs in high-energy environments like the sun, lightning, and neon lights."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson123",
                        title: "Which state of matter is lightning an example of?",
                        choices: [
                            "Solid",
                            "Liquid",
                            "Gas",
                            "Plasma"
                        ],
                        correct: 3
                    )
                ],
                image: "lesson123"
            )
        }

        if unit == 1 && block == 3 && section == 1 {
            return Lesson(
                type: .lesson,
                difficulty: .medium,
                length: 5,  // Adjusted for better coverage of concepts
                name: "Organization of the Periodic Table",
                unit: 1,
                block: 3,
                section: 1,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson131",
                        title: "How is the Periodic Table Organized?",
                        content: "The periodic table is a systematic arrangement of elements based on their atomic number, electron configurations, and recurring chemical properties. \n\n- It is divided into groups (columns) and periods (rows).\n- The elements are ordered by atomic number, which represents the number of protons in an atom’s nucleus.\n- This organization helps predict chemical behavior, making the periodic table a powerful tool for scientists."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson131",
                        title: "Groups and Periods: The Table’s Structure",
                        content: "Groups (Columns):\n- The periodic table has 18 vertical columns, called groups.\n- Elements in the same group share similar chemical properties because they have the same number of valence electrons.\n- Example: Group 1 elements (alkali metals) are highly reactive, while Group 18 elements (noble gases) are inert.\n\nPeriods (Rows):\n- The periodic table has 7 horizontal rows, called periods.\n- As you move from left to right across a period, atomic number increases, and elements become less metallic.\n- Example: In Period 3, sodium (Na) is a metal, while chlorine (Cl) is a nonmetal."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson131",
                        title: "Atomic Number and Atomic Mass",
                        content: "Each element on the periodic table is identified by its atomic number, which equals the number of protons in an atom.\n\n- Example: Carbon (C) has an atomic number of 6, meaning it has 6 protons.\n- The atomic mass (measured in atomic mass units, amu) is the weighted average mass of an element’s isotopes.\n- Heavier elements, like uranium (U), have high atomic masses due to more protons and neutrons."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson131",
                        title: "How Element Properties Are Organized",
                        content: "The periodic table is structured so that elements with similar properties are grouped together:\n\n- Metals (left side): Good conductors, malleable, and shiny. Examples: Iron (Fe), Aluminum (Al).\n- Nonmetals (right side): Poor conductors, brittle, and dull. Examples: Oxygen (O), Sulfur (S).\n- Metalloids (stair-step region): Have properties of both metals and nonmetals. Examples: Silicon (Si), Boron (B).\n\nThis organization makes it easier to predict how elements will react in chemical reactions."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson131",
                        title: "What does the atomic number represent?",
                        choices: [
                            "Number of neutrons",
                            "Number of electrons",
                            "Number of protons",
                            "Atomic mass"
                        ],
                        correct: 2
                    )
                ],
                image: "lesson131"
            )
        }

        if unit == 1 && block == 3 && section == 2 {
            return Lesson(
                type: .lesson,
                difficulty: .hard,
                length: 5,  // Increased to better explain complex trends
                name: "Trends in the Periodic Table",
                unit: 1,
                block: 3,
                section: 2,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson132",
                        title: "Understanding Periodic Trends",
                        content: "Elements in the periodic table show predictable trends due to their atomic structure. These trends help scientists understand how elements react and form bonds. The key trends include:\n\n- Atomic radius: Size of an atom.\n- Electronegativity: An atom’s ability to attract electrons.\n- Ionization energy: Energy required to remove an electron.\n- Metallic character: How easily an atom loses electrons.\n\nThese trends change across periods (left to right) and down groups (top to bottom)."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson132",
                        title: "Atomic Radius: How Big is an Atom?",
                        content: "The atomic radius is the distance from an atom’s nucleus to the outermost electron.\n\n- Across a period (→): Atomic radius decreases because more protons pull electrons closer to the nucleus.\n- Down a group (↓): Atomic radius increases because additional energy levels (shells) are added, making the atom larger.\n\nExample: Sodium (Na) is larger than chlorine (Cl) in Period 3, while potassium (K) is larger than sodium (Na) in Group 1."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson132",
                        title: "Electronegativity: The Attraction for Electrons",
                        content: "Electronegativity measures how strongly an atom attracts shared electrons in a chemical bond.\n\n- Across a period (→): Electronegativity increases because atoms have more protons and a greater pull on electrons.\n- Down a group (↓): Electronegativity decreases as the outer electrons are farther from the nucleus and experience less attraction.\n\nExample: Fluorine (F) is the most electronegative element, while francium (Fr) has very low electronegativity."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson132",
                        title: "Ionization Energy: Removing an Electron",
                        content: "Ionization energy is the energy required to remove an electron from an atom.\n\n- Across a period (→): Ionization energy increases because atoms hold their electrons more tightly.\n- Down a group (↓): Ionization energy decreases because outer electrons are farther from the nucleus and easier to remove.\n\nExample: It is harder to remove an electron from neon (Ne) than from sodium (Na), because neon has a full outer shell."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson132",
                        title: "Which trend increases from left to right across a period?",
                        choices: [
                            "Atomic radius",
                            "Electronegativity",
                            "Metallic character",
                            "Reactivity"
                        ],
                        correct: 1
                    )
                ],
                image: "lesson132"
            )
        }

        if unit == 1 && block == 3 && section == 3 {
            return Lesson(
                type: .lesson,
                difficulty: .medium,
                length: 5, // Increased for more in-depth coverage
                name: "Key Element Families",
                unit: 1,
                block: 3,
                section: 3,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson133",
                        title: "Understanding Element Families",
                        content: "Elements in the periodic table are grouped into families based on their properties. Each family has similar reactivity, electron configurations, and uses. The key families include:\n\n- Alkali metals (Group 1): Extremely reactive metals.\n- Alkaline earth metals (Group 2): Reactive metals, but less than alkali metals.\n- Halogens (Group 17): Highly reactive nonmetals.\n- Noble gases (Group 18): Inert, stable gases.\n\nThese families play crucial roles in chemical reactions, industry, and life."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson133",
                        title: "Alkali Metals: The Most Reactive Metals",
                        content: "Alkali metals include lithium (Li), sodium (Na), potassium (K), rubidium (Rb), cesium (Cs), and francium (Fr).\n\n- Highly reactive, especially with water.\n- Soft and shiny metals that can be cut with a knife.\n- React by losing one electron to form +1 ions.\n- Found in compounds like table salt (NaCl) and batteries (Li-ion).\n\n⚠️ Danger! Alkali metals react violently with water, producing hydrogen gas and heat!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson133",
                        title: "Halogens: The Most Reactive Nonmetals",
                        content: "Halogens include fluorine (F), chlorine (Cl), bromine (Br), iodine (I), and astatine (At).\n\n- Highly reactive, especially with alkali metals.\n- Exist in various states: fluorine and chlorine (gases), bromine (liquid), iodine (solid).\n- React by gaining one electron to form -1 ions.\n- Used in disinfectants (chlorine in pools) and toothpaste (fluoride).\n\n💡 Fun Fact: Fluorine is the most reactive element in the periodic table!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson133",
                        title: "Noble Gases: The Inert Elements",
                        content: "Noble gases include helium (He), neon (Ne), argon (Ar), krypton (Kr), xenon (Xe), and radon (Rn).\n\n- Non-reactive due to having full outer electron shells.\n- Exist as colorless, odorless gases at room temperature.\n- Used in neon lights (Ne), helium balloons (He), and welding (Ar).\n- Radon (Rn) is radioactive and can be a health hazard in homes.\n\n✨ Did You Know? Helium is the only noble gas that does not have 8 valence electrons—it has 2!"
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson133",
                        title: "Which family contains highly reactive metals?",
                        choices: [
                            "Alkaline Earth Metals",
                            "Halogens",
                            "Noble Gases",
                            "Alkali Metals"
                        ],
                        correct: 3
                    )
                ],
                image: "lesson133"
            )
        }

        if unit == 1 && block == 3 && section == 4 {
            return Lesson(
                type: .lesson,
                difficulty: .medium,
                length: 5,
                name: "Element Families Quiz 1",
                unit: 1,
                block: 3,
                section: 4,
                content: [
                    LessonContent(
                        type: .question,
                        image: "lesson134",
                        title: "Which element belongs to the alkali metal family?",
                        choices: ["Calcium (Ca)", "Sodium (Na)", "Chlorine (Cl)", "Helium (He)"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson134",
                        title: "What charge do halogens typically form when they react?",
                        choices: ["+1", "-1", "0", "+2"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson134",
                        title: "Which of these element families is the least reactive?",
                        choices: ["Alkali Metals", "Halogens", "Noble Gases", "Alkaline Earth Metals"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson134",
                        title: "What state of matter is bromine (Br) at room temperature?",
                        choices: ["Solid", "Liquid", "Gas", "Plasma"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson134",
                        title: "Which noble gas is commonly used in balloons?",
                        choices: ["Neon (Ne)", "Argon (Ar)", "Helium (He)", "Xenon (Xe)"],
                        correct: 2
                    )
                ],
                image: "lesson134"
            )
        }

        if unit == 1 && block == 3 && section == 5 {
            return Lesson(
                type: .lesson,
                difficulty: .medium,
                length: 5,
                name: "Element Families Quiz 2",
                unit: 1,
                block: 3,
                section: 5,
                content: [
                    LessonContent(
                        type: .question,
                        image: "lesson135",
                        title: "Which element is a halogen?",
                        choices: ["Oxygen (O)", "Fluorine (F)", "Potassium (K)", "Magnesium (Mg)"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson135",
                        title: "What do alkali metals do when they react with water?",
                        choices: [
                            "Stay unchanged",
                            "Form a precipitate",
                            "Explode and produce hydrogen gas",
                            "Turn into noble gases"
                        ],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson135",
                        title: "Which of these is NOT a noble gas?",
                        choices: ["Argon (Ar)", "Krypton (Kr)", "Hydrogen (H)", "Neon (Ne)"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson135",
                        title: "Which group of elements forms +2 ions when they react?",
                        choices: ["Alkali Metals", "Halogens", "Alkaline Earth Metals", "Noble Gases"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson135",
                        title: "Which family is often used in lighting and signs due to its stability?",
                        choices: ["Alkaline Earth Metals", "Halogens", "Noble Gases", "Alkali Metals"],
                        correct: 2
                    )
                ],
                image: "lesson135"
            )
        }

        if unit == 1 && block == 4 && section == nil {
            return Lesson(
                type: .quiz,
                difficulty: .medium,
                length: 10,
                name: "Trends in the Periodic Table Quiz",
                unit: 1,
                block: 4,
                section: nil,
                content: [
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "As you move across a period from left to right in the periodic table, what happens to the atomic radius?",
                        choices: ["It increases", "It decreases", "It stays the same", "It fluctuates"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which of the following elements has the highest electronegativity?",
                        choices: ["Sodium (Na)", "Oxygen (O)", "Fluorine (F)", "Calcium (Ca)"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What trend occurs as you move down a group in the periodic table?",
                        choices: [
                            "Atomic radius decreases",
                            "Electronegativity increases",
                            "Ionization energy increases",
                            "Atomic radius increases"
                        ],
                        correct: 3
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which group in the periodic table contains the most reactive metals?",
                        choices: ["Alkaline Earth Metals", "Noble Gases", "Alkali Metals", "Transition Metals"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What is the trend in ionization energy as you move from left to right across a period?",
                        choices: ["It decreases", "It stays the same", "It increases", "It fluctuates"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which of the following elements has the largest atomic radius?",
                        choices: ["Fluorine (F)", "Neon (Ne)", "Lithium (Li)", "Francium (Fr)"],
                        correct: 3
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which of these elements is likely to have the highest first ionization energy?",
                        choices: ["Sodium (Na)", "Magnesium (Mg)", "Chlorine (Cl)", "Helium (He)"],
                        correct: 3
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "In which direction does electronegativity increase in the periodic table?",
                        choices: ["Down a group", "Across a period from left to right", "Across a period from right to left", "It does not have a trend"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which of the following elements is the least reactive?",
                        choices: ["Fluorine (F)", "Chlorine (Cl)", "Helium (He)", "Sodium (Na)"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which of these is a property of noble gases?",
                        choices: [
                            "They are highly reactive",
                            "They have a full valence shell",
                            "They are metals",
                            "They easily form compounds"
                        ],
                        correct: 1
                    )
                ],
                image: "lesson143"
            )
        }

        if unit == 1 && block == 5 && section == 1 {
            return Lesson(
                type: .lesson,
                difficulty: .easy,
                length: 5, // Increased length for more detail
                name: "Inside the Atom",
                unit: 1,
                block: 5,
                section: 1,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson141",
                        title: "The Structure of an Atom",
                        content: "Atoms are the building blocks of matter. They consist of three main subatomic particles: protons, neutrons, and electrons.\n\nThe atom is made up of a dense nucleus, containing protons and neutrons, surrounded by an electron cloud where electrons move rapidly. Each of these particles plays a crucial role in determining the properties of an element."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson141",
                        title: "Protons: The Identity of an Atom",
                        content: "Protons are positively charged particles found in the nucleus of an atom.\n\n- The number of protons determines the element’s atomic number (e.g., hydrogen has 1 proton, carbon has 6).\n- Protons contribute to the mass of the atom.\n- The positive charge of protons helps hold negatively charged electrons in place.\n\n💡 Fun Fact: Changing the number of protons changes the element itself!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson141",
                        title: "Neutrons: The Stabilizers",
                        content: "Neutrons are neutral particles found in the nucleus alongside protons.\n\n- They help stabilize the nucleus by reducing repulsion between protons.\n- The number of neutrons can vary, creating isotopes (e.g., Carbon-12 and Carbon-14).\n- Neutrons have nearly the same mass as protons but no charge.\n\n⚠️ Did You Know? Some elements have radioactive isotopes because their neutron count makes the nucleus unstable!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson141",
                        title: "Electrons: The Movers and Shakers",
                        content: "Electrons are negatively charged particles that orbit the nucleus in electron shells.\n\n- They are extremely small compared to protons and neutrons.\n- Electrons determine chemical bonding and reactivity.\n- The arrangement of electrons follows the octet rule, influencing how atoms interact.\n\n🔬 Example: When electrons are transferred or shared, chemical reactions occur—like when sodium and chlorine combine to form table salt (NaCl)!"
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson141",
                        title: "What charge does a proton have?",
                        choices: ["Positive", "Negative", "Neutral", "Variable"],
                        correct: 0
                    )
                ],
                image: "lesson141"
            )
        }

        if unit == 1 && block == 5 && section == 2 {
            return Lesson(
                type: .lesson,
                difficulty: .medium,
                length: 5, // Increased length for better clarity
                name: "Electron Configuration",
                unit: 1,
                block: 5,
                section: 2,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson142",
                        title: "Understanding Electron Configuration",
                        content: "Electrons are arranged in specific energy levels around an atom's nucleus. The way these electrons are distributed across different shells and orbitals determines an element's chemical behavior and bonding properties.\n\nThe general rule: Electrons fill lower-energy levels first before moving to higher ones."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson142",
                        title: "Electron Shells and Energy Levels",
                        content: "Electrons occupy shells or energy levels, which are labeled as:\n\n- K-shell (1st shell): Holds up to 2 electrons.\n- L-shell (2nd shell): Holds up to 8 electrons.\n- M-shell (3rd shell): Holds up to 18 electrons.\n- Higher shells follow a similar pattern, following the 2n² rule (where 'n' is the shell number).\n\n🔬 Example: A carbon atom (atomic number 6) has an electron configuration of 2, 4, meaning 2 electrons in the first shell and 4 in the second."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson142",
                        title: "Orbitals: Where Electrons Reside",
                        content: "Orbitals are regions within shells where electrons are most likely to be found. These orbitals are classified as:\n\n- s-orbital: Holds up to 2 electrons.\n- p-orbital: Holds up to 6 electrons.\n- d-orbital: Holds up to 10 electrons.\n- f-orbital: Holds up to 14 electrons.\n\nEach orbital has a unique shape that determines how electrons move and bond with other atoms."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson142",
                        title: "Valence Electrons and Reactivity",
                        content: "Valence electrons are the electrons in the outermost shell of an atom. They play a crucial role in determining:\n\n- Bonding behavior (whether an atom gains, loses, or shares electrons).\n- Chemical reactivity (atoms with a full outer shell are stable, while others seek to gain or lose electrons).\n\n💡 Example: Sodium (Na) has one valence electron and readily loses it to form a Na⁺ ion, making it highly reactive!"
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson142",
                        title: "Which electrons determine an atom’s reactivity?",
                        choices: ["Core electrons", "Inner shell electrons", "Valence electrons", "Free electrons"],
                        correct: 2
                    )
                ],
                image: "lesson142"
            )
        }

        if unit == 1 && block == 5 && section == 3 {
            return Lesson(
                type: .lesson,
                difficulty: .hard,
                length: 5, // Increased length for depth
                name: "Isotopes and Ions",
                unit: 1,
                block: 5,
                section: 3,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson143",
                        title: "What Are Isotopes?",
                        content: "Isotopes are atoms of the same element that have the same number of protons but a different number of neutrons. This difference affects the atom’s mass but not its chemical properties.\n\n🔬 Example: Carbon-12 and Carbon-14 are isotopes of carbon. Both have 6 protons, but Carbon-12 has 6 neutrons, while Carbon-14 has 8 neutrons."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson143",
                        title: "Stable vs. Radioactive Isotopes",
                        content: "Some isotopes are stable, meaning they do not change over time, while others are radioactive, meaning they decay and emit radiation.\n\n💡 Example: Uranium-238 is radioactive and undergoes decay, releasing energy used in nuclear power."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson143",
                        title: "Ions: Gaining and Losing Electrons",
                        content: "Atoms can gain or lose electrons to form ions, which are charged particles.\n\n- Cations: When an atom loses electrons, it becomes positively charged (e.g., Na⁺).\n- Anions: When an atom gains electrons, it becomes negatively charged (e.g., Cl⁻).\n\nThis process, called ionization, is essential for many chemical reactions, including those in the human body!"
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson143",
                        title: "Effects of Ionization",
                        content: "When an atom gains an electron, it gains a negative charge because electrons are negatively charged. This makes it an anion.\n\n⚡ Example: Oxygen typically gains two electrons to form O²⁻, which is essential for breathing and cellular respiration."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson143",
                        title: "What happens when an atom gains an electron?",
                        choices: ["It becomes a positive ion", "It becomes a negative ion", "It remains neutral", "It disappears"],
                        correct: 1
                    )
                ],
                image: "lesson143"
            )
        }

        if unit == 1 && block == 5 && section == 4 {
            return Lesson(
                type: .lesson,
                difficulty: .medium,
                length: 5, // Expanded for clarity
                name: "The Role of Atoms in Chemical Reactions",
                unit: 1,
                block: 5,
                section: 4,
                content: [
                    LessonContent(
                        type: .text,
                        image: "lesson144",
                        title: "What Happens in a Chemical Reaction?",
                        content: "A chemical reaction occurs when atoms rearrange to form new substances. This happens when bonds between atoms break and form in a process that conserves mass according to the Law of Conservation of Matter.\n\n🔥 Example: When hydrogen (H₂) and oxygen (O₂) react, they form water (H₂O) through a chemical reaction."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson144",
                        title: "Ionic Bonds: Electron Transfer",
                        content: "Ionic bonds form when atoms transfer electrons to achieve stability. One atom loses electrons to become a positively charged ion (cation), while another atom gains electrons to become a negatively charged ion (anion).\n\n⚡ Example: Sodium (Na) donates an electron to chlorine (Cl), forming NaCl (table salt)."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson144",
                        title: "Covalent Bonds: Electron Sharing",
                        content: "Covalent bonds form when atoms share electrons instead of transferring them. This type of bond is typically found in molecules made of nonmetals.\n\n💡 Example: Two hydrogen atoms share electrons with an oxygen atom to form H₂O (water)."
                    ),
                    LessonContent(
                        type: .text,
                        image: "lesson144",
                        title: "Types of Chemical Reactions",
                        content: "Chemical reactions can be classified into different types based on how atoms and molecules interact:\n\n- Synthesis Reaction: Two or more elements combine (e.g., A + B → AB).\n- Decomposition Reaction: A compound breaks apart (e.g., AB → A + B).\n- Replacement Reaction: One element replaces another in a compound.\n\n🔬 Example: In rusting, iron reacts with oxygen to form iron oxide (Fe₂O₃)."
                    ),
                    LessonContent(
                        type: .question,
                        image: "lesson144",
                        title: "Which bond involves the sharing of electrons?",
                        choices: ["Ionic", "Covalent", "Metallic", "Hydrogen"],
                        correct: 1
                    )
                ],
                image: "lesson144"
            )
        }

        if unit == 1 && block == 5 && section == 5 {
            return Lesson(
                type: .quiz,
                difficulty: .medium,
                length: 10,
                name: "Atomic Structure Quiz",
                unit: 1,
                block: 5,
                section: 5,
                content: [
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What subatomic particle determines the identity of an atom?",
                        choices: ["Protons", "Neutrons", "Electrons", "Ions"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What is the atomic number of an element?",
                        choices: ["Number of protons", "Number of neutrons", "Number of electrons", "Mass number"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What happens when an atom gains an electron?",
                        choices: ["It becomes a positive ion", "It becomes a negative ion", "It becomes neutral", "It becomes a proton"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What type of bond forms when electrons are shared between atoms?",
                        choices: ["Ionic", "Covalent", "Metallic", "Hydrogen"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which of the following is an isotope of carbon?",
                        choices: ["Carbon-12", "Carbon-14", "Both Carbon-12 and Carbon-14", "Carbon-16"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "How many electrons can the first shell of an atom hold?",
                        choices: ["2", "4", "8", "18"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What is the difference between an ionic and covalent bond?",
                        choices: [
                            "Ionic bonds involve sharing electrons, while covalent bonds involve transferring electrons",
                            "Covalent bonds involve sharing electrons, while ionic bonds involve transferring electrons",
                            "Ionic bonds form between nonmetals, while covalent bonds form between metals",
                            "There is no difference between ionic and covalent bonds"
                        ],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What does the number of protons in an atom determine?",
                        choices: ["The atomic mass", "The atomic number", "The number of electrons", "The isotope type"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which subatomic particle has no charge?",
                        choices: ["Protons", "Neutrons", "Electrons", "Ions"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What happens to an atom during ionization?",
                        choices: ["It gains or loses protons", "It gains or loses neutrons", "It gains or loses electrons", "It loses its identity"],
                        correct: 2
                    )
                ],
                image: "lesson132"
            )
        }

        if unit == 1 && block == 6 && section == nil {
            return Lesson(
                type: .quiz,
                difficulty: .medium,
                length: 10,
                name: "Periodic Table & Atomic Structure Quiz",
                unit: 1,
                block: 6,
                section: nil,
                content: [
                    LessonContent(type: .question, image: nil, title: "What is the lightest element?", choices: ["Oxygen", "Helium", "Hydrogen", "Lithium"], correct: 2),
                    LessonContent(type: .question, image: nil, title: "Which family are noble gases in?", choices: ["Group 1", "Group 14", "Group 18", "Group 8"], correct: 2),
                    LessonContent(type: .question, image: nil, title: "What is the most abundant metal in Earth's crust?", choices: ["Iron", "Aluminum", "Copper", "Zinc"], correct: 1),
                    LessonContent(type: .question, image: nil, title: "Which element has 6 protons?", choices: ["Oxygen", "Carbon", "Nitrogen", "Sulfur"], correct: 1),
                    LessonContent(type: .question, image: nil, title: "What element is liquid at room temperature?", choices: ["Mercury", "Gold", "Lead", "Bromine"], correct: 0),
                    LessonContent(type: .question, image: nil, title: "Which particle has no charge?", choices: ["Proton", "Neutron", "Electron", "Ion"], correct: 1),
                    LessonContent(type: .question, image: nil, title: "What is the maximum number of electrons in the first shell?", choices: ["2", "4", "8", "10"], correct: 0),
                    LessonContent(type: .question, image: nil, title: "What charge does an oxygen ion (O²⁻) have?", choices: ["+2", "-1", "-2", "0"], correct: 2),
                    LessonContent(type: .question, image: nil, title: "What part of the atom determines its chemical properties?", choices: ["Neutrons", "Protons", "Valence electrons", "Nucleus"], correct: 2),
                    LessonContent(type: .question, image: nil, title: "Which element has the highest electronegativity?", choices: ["Oxygen", "Chlorine", "Fluorine", "Nitrogen"], correct: 2)
                ],
                image: "lesson123"
            )
        }

        if unit == 1 && block == 7 && section == nil {
            return Lesson(
                type: .quiz,
                difficulty: .medium,
                length: 10,
                name: "States of Matter & Reactions Quiz",
                unit: 1,
                block: 7,
                section: nil,
                content: [
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which state of matter has neither a definite shape nor a definite volume?",
                        choices: ["Solid", "Liquid", "Gas", "Plasma"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What phase change occurs when a solid transforms directly into a gas without becoming a liquid first?",
                        choices: ["Evaporation", "Condensation", "Sublimation", "Deposition"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which state of matter makes up most of the visible universe, including stars?",
                        choices: ["Solid", "Liquid", "Gas", "Plasma"],
                        correct: 3
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which process describes a liquid turning into a gas at its surface?",
                        choices: ["Sublimation", "Condensation", "Evaporation", "Freezing"],
                        correct: 2
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Glass does not have a regular crystal structure like most solids. What type of solid is it?",
                        choices: ["Crystalline solid", "Liquid", "Gas", "Amorphous solid"],
                        correct: 3
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which of the following best describes the difference between a physical and a chemical change?",
                        choices: [
                            "A chemical change creates new substances with different properties",
                            "A physical change alters atomic structure",
                            "Both involve breaking chemical bonds",
                            "Physical changes are irreversible"
                        ],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What is the atomic number of carbon, representing the number of protons in its nucleus?",
                        choices: ["4", "6", "8", "12"],
                        correct: 1
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which subatomic particle determines the identity of an element?",
                        choices: ["Protons", "Neutrons", "Electrons", "Valence electrons"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What is the smallest unit of an element that retains its chemical properties?",
                        choices: ["Atom", "Molecule", "Ion", "Electron"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "When an atom loses an electron, what happens to its charge?",
                        choices: ["It becomes positive", "It becomes negative", "It remains neutral", "It disappears"],
                        correct: 0
                    )
                ],
                image: "lesson133"
            )
        }



        if unit == 1 && block == 8 && section == nil {
            return Lesson(
                type: .test,
                difficulty: .hard,
                length: 12,
                name: "Final Chemistry Test",
                unit: 1,
                block: 8,
                section: nil,
                content: [
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What is the primary difference between a physical and chemical change?",
                        choices: [
                            "A physical change alters appearance, while a chemical change forms new substances.",
                            "A physical change creates new substances, while a chemical change only alters form.",
                            "They are the same process.",
                            "Neither affects the composition of a substance."
                        ],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "The atomic number of carbon represents the number of which subatomic particle?",
                        choices: ["Protons", "Neutrons", "Electrons", "Quarks"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which subatomic particle determines the identity of an element?",
                        choices: ["Proton", "Neutron", "Electron", "Positron"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What is the smallest unit of matter that retains the properties of an element?",
                        choices: ["Atom", "Molecule", "Proton", "Compound"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What happens to an atom’s charge if it loses an electron?",
                        choices: [
                            "It becomes positively charged.",
                            "It becomes negatively charged.",
                            "It remains neutral.",
                            "Its charge depends on the element."
                        ],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Elements with the same number of protons but different numbers of neutrons are called:",
                        choices: ["Isotopes", "Ions", "Molecules", "Compounds"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which substance is known as the 'universal solvent' due to its ability to dissolve many substances?",
                        choices: ["Water", "Ethanol", "Oil", "Mercury"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which term describes the fundamental building block of all matter?",
                        choices: ["Atom", "Molecule", "Cell", "Compound"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "What type of chemical reaction occurs when iron reacts with oxygen to form rust?",
                        choices: ["Oxidation", "Reduction", "Combustion", "Neutralization"],
                        correct: 0
                    ),
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Avogadro’s number (6.022 × 10^23) represents the number of what in one mole of a substance?",
                        choices: ["Atoms or molecules", "Liters of gas", "Joules of energy", "Neutrons in an atom"],
                        correct: 0
                    ),
                    // New Question 1
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which electrons determine an atom’s chemical reactivity?",
                        choices: ["Core electrons", "Inner shell electrons", "Valence electrons", "Free electrons"],
                        correct: 2
                    ),
                    // New Question 2
                    LessonContent(
                        type: .question,
                        image: nil,
                        title: "Which type of bond involves the transfer of electrons from one atom to another?",
                        choices: ["Covalent", "Ionic", "Metallic", "Hydrogen"],
                        correct: 1
                    )
                ],
                image: "lesson111"
            )
        }

        throw NSError(domain: "Lesson Not Found", code: 404, userInfo: nil)
    }

    // leaderboard
    public func fetch() async throws -> [String] {
        [
            "Amit Patel", "Sunita Sharma", "Rajesh Gupta", "Priya Kapoor", "Vikram Nair", "Sanjay Mehta", "Neha Verma", "Deepak Reddy",
            "Haruto Tanaka", "Yuki Nakamura", "Sakura Takahashi", "Kenji Fujimoto", "Hiroshi Yamamoto", "Ayaka Saito", "Rika Kobayashi",
            "Li Wei", "Zhang Ming", "Chen Jia", "Liu Fang", "Wang Lei", "Huang Yu", "Lin Mei", "Yang Tao",
            "David Johnson", "Michael Smith", "Jessica Brown", "Emily Davis", "Christopher Wilson", "Matthew Thompson", "Ashley Martinez",
            "Ramesh Srinivasan", "Anjali Iyer", "Karthik Choudhary", "Meena Rajan", "Surya Deshmukh", "Pooja Menon", "Arjun Bhat",
            "Taro Suzuki", "Nana Mori", "Daisuke Hayashi", "Emi Yoshida", "Takashi Okamoto", "Rina Shimizu", "Satoshi Endo",
            "Kevin Anderson", "Brandon Clark", "Olivia Walker", "Emma Hall", "Daniel King", "Sophia Young", "Ethan Scott",
            "Wei Zhong", "Xia Mei", "Teng Long", "Hui Min", "Zhao Peng", "Fang Wen", "Cheng Hao", "Zhou Jing",
            "Aarav Malhotra", "Kavita Joshi", "Rohit Agarwal", "Sanya Khanna", "Krishna Venkatesh", "Tanvi Sharma", "Devendra Rao",
            "Hideo Matsumoto", "Yuki Hoshino", "Koji Kuroda", "adithv08@gmail.com", "Shinji Inoue", "Kaori Nishimura", "Takumi Watanabe",
            "Benjamin White", "Madison Green", "Tyler Adams", "Isabella Carter", "James Parker", "Mason Mitchell", "Hannah Roberts",
            "Zhen Li", "Bo Yang", "Shan Wei", "Lei Chen", "Ming Zhao", "Jie Lu", "Hong Xie", "Chun Zhang",
            "Suresh Pillai", "Varun Saxena", "Priyanka Sen", "Anand Ghosh", "Rekha Dutta", "Gopal Yadav", "Shweta Kulkarni",
            "Riku Takeda", "Hana Kondo", "Masaru Kobayashi", "Aya Ota", "Jiro Hashimoto", "Keiko Ueno", "Kenta Iwasaki",
            "Samuel Bell", "Ella Rivera", "Andrew Collins", "Sophia Brooks", "Nathan Ward", "Abigail Hernandez", "Lucas Cooper",
            "Dong Feng", "Ru Yi", "Xian Tao", "Jin Ping", "Zhao Xin", "Mei Hua", "Qiang Sheng", "Shu Fang",
            "Ajay Tripathi", "Swati Narayan", "Rahul Bhardwaj", "Aditi Banerjee", "Nitin Kohli", "Vandana Saxena", "Arvind Das",
            "Takeshi Honda", "Mika Yoshikawa", "Shun Nakano", "Hikaru Fujisawa", "Nao Taniguchi", "Tomo Ishikawa", "Emiko Hara",
            "Henry Wright", "Victoria Edwards", "Liam Thomas", "Scarlett Phillips", "Evan Turner", "Grace Stewart", "Oliver Morris",
            "Qing Shan", "Yan Ping", "Hua Ling", "Xiao Yu", "Jian Min", "Tian Lei", "Hai Bo", "Lian Cheng",
            "Ravi Desai", "Sneha Reddy", "Harish Kulkarni", "Divya Mishra", "Shashank Roy", "Nisha Bansal", "Manoj Shetty",
            "Kazuki Ito", "Miyuki Tsuchiya", "Souta Nishida", "Nozomi Takashima", "Akira Fujii", "Nanami Hayakawa", "Yuya Tokunaga",
            "Brayden Barnes", "Alyssa Reed", "Jordan Perry", "Lily Gray", "Dylan Bennett", "Zoe Hughes", "Carter Foster",
            "Qiang Liang", "Xue Mei", "De Wei", "An Ren", "Fu Lin", "Bao Jian", "Zhi Hui", "Lei Fang",
            "Tushar Gopal", "Ritika Anand", "Aditya Chatterjee", "Meghna Naik", "Anupam Sen", "Charu Malhotra", "Jitendra Singh",
            "Hiroki Yoshimoto", "Aya Takagi", "Ryota Sakurai", "Saori Makino", "Ken Watanabe", "Mari Sakamoto", "Sho Ogawa",
            "Peyton Russell", "Sydney Peterson", "Jason Wood", "Kaitlyn Barnes", "Julian Ross", "Autumn Simmons", "Maverick Sanders",
            "Jian Zhang", "Hui Zhao", "Teng Yuan", "Sheng Fang", "Min Qiao", "Hong Wei", "Chun Xiang", "Xian Long",
            "Sanjana Iyer", "Rohan Verma", "Kiran Sinha", "Rajiv Goyal", "Anushka Nambiar", "Mahesh Prasad", "Lavanya Sekhar",
            "Tomo Yamauchi", "Souta Nakajima", "Haruka Mori", "Shiori Fujikawa", "Yuto Sasaki", "Mei Uehara", "Tsubasa Nakahara",
            "Asher Bell", "Willow Carter", "Logan Chapman", "Brooklyn Evans", "Ryder Foster", "Delilah Green", "Easton Hall"
        ]
    }

    public func fetch() async throws -> [UnitProgress] {
        [
            UnitProgress(isCompleted: false, blocks: [
                .init(currentSection: 2, isCompleted: true, block: 1),
                .init(currentSection: 3, isCompleted: true, block: 2),
                .init(currentSection: 1, isCompleted: false, block: 3),
                .init(currentSection: 0, isCompleted: false, block: 4),
                .init(currentSection: 0, isCompleted: false, block: 5),
                .init(currentSection: 0, isCompleted: false, block: 6),
                .init(currentSection: 0, isCompleted: false, block: 7),
                .init(currentSection: 0, isCompleted: false, block: 8)
            ], unit: 1),
            UnitProgress(isCompleted: false, blocks: [
                .init(currentSection: 0, isCompleted: false, block: 1),
                .init(currentSection: 0, isCompleted: false, block: 2),
                .init(currentSection: 0, isCompleted: false, block: 3),
                .init(currentSection: 0, isCompleted: false, block: 4),
                .init(currentSection: 0, isCompleted: false, block: 5),
                .init(currentSection: 0, isCompleted: false, block: 6),
                .init(currentSection: 0, isCompleted: false, block: 7),
                .init(currentSection: 0, isCompleted: false, block: 8),
                .init(currentSection: 0, isCompleted: false, block: 9),
                .init(currentSection: 0, isCompleted: false, block: 10),
                .init(currentSection: 0, isCompleted: false, block: 11),
                .init(currentSection: 0, isCompleted: false, block: 12),
            ], unit: 2),
            UnitProgress(isCompleted: false, blocks: [
                .init(currentSection: 0, isCompleted: false, block: 1),
                .init(currentSection: 0, isCompleted: false, block: 2),
                .init(currentSection: 0, isCompleted: false, block: 3),
                .init(currentSection: 0, isCompleted: false, block: 4),
                .init(currentSection: 0, isCompleted: false, block: 5),
                .init(currentSection: 0, isCompleted: false, block: 6),
                .init(currentSection: 0, isCompleted: false, block: 7),
                .init(currentSection: 0, isCompleted: false, block: 8),
                .init(currentSection: 0, isCompleted: false, block: 9),
                .init(currentSection: 0, isCompleted: false, block: 10),
                .init(currentSection: 0, isCompleted: false, block: 11),
                .init(currentSection: 0, isCompleted: false, block: 12),
            ], unit: 3)
        ]
    }

    public func fetch() async throws -> [Award] {
        [
            Award(image: "trophy1", name: "Team 11", desc: "You surpassed the global leaderboard with a rank above 100."),
            Award(image: "trophy2", name: "Why man?", desc: "You logged out of this device."),
            Award(image: "trophy3", name: "Socialism", desc: "You added your first friend (and they said yes)."),
            Award(image: "trophy4", name: "Blockades", desc: "You completed your first block."),
            Award(image: "trophy5", name: "First Steps", desc: "You completed your first lesson.")
        ]
    }

    func updatePreviews() {
        Task {
            do {
                self.previews = try await fetch()
                errorFetchingPreviews = false;
            } catch {
                errorFetchingPreviews = true;
            }
        }
    }

    public func modify(user: User) throws {
        self.user = user
        try Firebase.db.collection("users").document(uid).setData(from: user)
    }
}
