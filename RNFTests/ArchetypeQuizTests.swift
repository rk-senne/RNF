import XCTest
@testable import RNF

final class ArchetypeQuizTests: XCTestCase {

    // MARK: - All 27 Combinations Produce Valid Archetypes (P22-TST-02)

    func testAll27CombinationsProduceValidArchetypes() {
        let axes = StatAxis.allCases
        var resolvedCount = 0

        for a in axes {
            for b in axes {
                for c in axes {
                    let answers = [a, b, c]
                    let archetype = ArchetypeQuiz.resolve(answers: answers)

                    XCTAssertFalse(archetype.id.isEmpty, "Archetype ID should not be empty for \(answers)")
                    XCTAssertFalse(archetype.name.isEmpty, "Archetype name should not be empty for \(answers)")
                    XCTAssertFalse(archetype.title.isEmpty, "Archetype title should not be empty for \(answers)")
                    XCTAssertFalse(archetype.description.isEmpty, "Archetype description should not be empty for \(answers)")
                    XCTAssertFalse(archetype.emoji.isEmpty, "Archetype emoji should not be empty for \(answers)")

                    resolvedCount += 1
                }
            }
        }

        XCTAssertEqual(resolvedCount, 27, "Should resolve exactly 27 combinations (3x3x3)")
    }

    func testArchetypeMapContains27Entries() {
        XCTAssertEqual(ArchetypeQuiz.archetypes.count, 27)
    }

    // MARK: - Specific Archetype Resolutions

    func testBodyBodyBodyResolvesToTitan() {
        let archetype = ArchetypeQuiz.resolve(answers: [.body, .body, .body])
        XCTAssertEqual(archetype.name, "Titan")
        XCTAssertEqual(archetype.primaryStat, .body)
        XCTAssertEqual(archetype.secondaryStat, .body)
        XCTAssertEqual(archetype.tertiaryStat, .body)
    }

    func testMindMindMindResolvesToSage() {
        let archetype = ArchetypeQuiz.resolve(answers: [.mind, .mind, .mind])
        XCTAssertEqual(archetype.name, "Sage")
        XCTAssertEqual(archetype.primaryStat, .mind)
        XCTAssertEqual(archetype.secondaryStat, .mind)
        XCTAssertEqual(archetype.tertiaryStat, .mind)
    }

    func testSpiritSpiritSpiritResolvesToPhoenix() {
        let archetype = ArchetypeQuiz.resolve(answers: [.spirit, .spirit, .spirit])
        XCTAssertEqual(archetype.name, "Phoenix")
        XCTAssertEqual(archetype.primaryStat, .spirit)
        XCTAssertEqual(archetype.secondaryStat, .spirit)
        XCTAssertEqual(archetype.tertiaryStat, .spirit)
    }

    func testBodyMindSpiritResolvesToStrategist() {
        let archetype = ArchetypeQuiz.resolve(answers: [.body, .mind, .spirit])
        XCTAssertEqual(archetype.name, "Strategist")
        XCTAssertEqual(archetype.primaryStat, .body)
        XCTAssertEqual(archetype.secondaryStat, .mind)
    }

    func testSpiritBodyMindResolvesToMonk() {
        let archetype = ArchetypeQuiz.resolve(answers: [.spirit, .body, .mind])
        XCTAssertEqual(archetype.name, "Monk")
        XCTAssertEqual(archetype.primaryStat, .spirit)
        XCTAssertEqual(archetype.secondaryStat, .body)
    }

    func testMindSpiritBodyResolvesToOracle() {
        let archetype = ArchetypeQuiz.resolve(answers: [.mind, .spirit, .body])
        XCTAssertEqual(archetype.name, "Oracle")
        XCTAssertEqual(archetype.primaryStat, .mind)
        XCTAssertEqual(archetype.secondaryStat, .spirit)
    }

    func testBodySpiritMindResolvesToGuardian() {
        let archetype = ArchetypeQuiz.resolve(answers: [.body, .spirit, .mind])
        XCTAssertEqual(archetype.name, "Guardian")
        XCTAssertEqual(archetype.primaryStat, .body)
        XCTAssertEqual(archetype.secondaryStat, .spirit)
    }

    func testMindBodySpiritResolvesToArchitect() {
        let archetype = ArchetypeQuiz.resolve(answers: [.mind, .body, .spirit])
        XCTAssertEqual(archetype.name, "Architect")
        XCTAssertEqual(archetype.primaryStat, .mind)
        XCTAssertEqual(archetype.secondaryStat, .body)
    }

    func testSpiritMindBodyResolvesToMystic() {
        let archetype = ArchetypeQuiz.resolve(answers: [.spirit, .mind, .body])
        XCTAssertEqual(archetype.name, "Mystic")
        XCTAssertEqual(archetype.primaryStat, .spirit)
        XCTAssertEqual(archetype.secondaryStat, .mind)
    }

    // MARK: - Edge Cases

    func testEmptyAnswersFallsBackToSage() {
        let archetype = ArchetypeQuiz.resolve(answers: [])
        XCTAssertEqual(archetype.name, "Sage")
    }

    func testIncompleteAnswersFallsBackToSage() {
        let archetype = ArchetypeQuiz.resolve(answers: [.body])
        XCTAssertEqual(archetype.name, "Sage")
    }

    func testTwoAnswersFallsBackToSage() {
        let archetype = ArchetypeQuiz.resolve(answers: [.body, .mind])
        XCTAssertEqual(archetype.name, "Sage")
    }

    // MARK: - Stat Distribution

    func testStatDistributionAllBody() {
        let dist = ArchetypeQuiz.statDistribution(answers: [.body, .body, .body])
        XCTAssertEqual(dist[.body], 6)
        XCTAssertEqual(dist[.mind], 0)
        XCTAssertEqual(dist[.spirit], 0)
    }

    func testStatDistributionMixed() {
        let dist = ArchetypeQuiz.statDistribution(answers: [.body, .mind, .spirit])
        XCTAssertEqual(dist[.body], 3)
        XCTAssertEqual(dist[.mind], 2)
        XCTAssertEqual(dist[.spirit], 1)
    }

    func testStatDistributionTotalIsSix() {
        let axes = StatAxis.allCases
        for a in axes {
            for b in axes {
                for c in axes {
                    let dist = ArchetypeQuiz.statDistribution(answers: [a, b, c])
                    let total = (dist[.body] ?? 0) + (dist[.mind] ?? 0) + (dist[.spirit] ?? 0)
                    XCTAssertEqual(total, 6, "Total should be 6 for [\(a), \(b), \(c)]")
                }
            }
        }
    }

    // MARK: - Quiz Questions Structure

    func testQuizHasThreeQuestions() {
        XCTAssertEqual(ArchetypeQuiz.questions.count, 3)
    }

    func testEachQuestionHasThreeOptions() {
        for question in ArchetypeQuiz.questions {
            XCTAssertEqual(question.options.count, 3, "Question \(question.id) should have 3 options")
        }
    }

    func testEachQuestionCoversAllAxes() {
        for question in ArchetypeQuiz.questions {
            let axes = Set(question.options.map(\.axis))
            XCTAssertEqual(axes, Set(StatAxis.allCases), "Question \(question.id) should cover all axes")
        }
    }

    func testAllOptionsHaveUniqueIDs() {
        let allIDs = ArchetypeQuiz.questions.flatMap { $0.options.map(\.id) }
        XCTAssertEqual(Set(allIDs).count, allIDs.count)
    }

    // MARK: - Archetype ID Matches Key

    func testArchetypeIDMatchesCombinationKey() {
        let axes = StatAxis.allCases
        for a in axes {
            for b in axes {
                for c in axes {
                    let key = "\(a.rawValue)_\(b.rawValue)_\(c.rawValue)"
                    let archetype = ArchetypeQuiz.resolve(answers: [a, b, c])
                    XCTAssertEqual(archetype.id, key)
                }
            }
        }
    }
}
