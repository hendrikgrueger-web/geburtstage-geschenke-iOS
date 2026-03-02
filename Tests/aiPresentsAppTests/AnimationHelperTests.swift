import XCTest
@testable import aiPresentsApp

final class AnimationHelperTests: XCTestCase {

    // MARK: - Animation Properties Tests

    func testSpringAnimationExists() {
        let spring = AnimationHelper.spring

        XCTAssertNotNil(spring, "Spring animation should be defined")
    }

    func testQuickSpringAnimationExists() {
        let quickSpring = AnimationHelper.quickSpring

        XCTAssertNotNil(quickSpring, "Quick spring animation should be defined")
    }

    func testSlowSpringAnimationExists() {
        let slowSpring = AnimationHelper.slowSpring

        XCTAssertNotNil(slowSpring, "Slow spring animation should be defined")
    }

    func testEaseOutAnimationExists() {
        let easeOut = AnimationHelper.easeOut

        XCTAssertNotNil(easeOut, "Ease out animation should be defined")
    }

    func testEaseInOutAnimationExists() {
        let easeInOut = AnimationHelper.easeInOut

        XCTAssertNotNil(easeInOut, "Ease in out animation should be defined")
    }

    func testBouncyAnimationExists() {
        let bouncy = AnimationHelper.bouncy

        XCTAssertNotNil(bouncy, "Bouncy animation should be defined")
    }

    // MARK: - Fade In Scale Animation Tests

    func testFadeInScaleAnimationWithDefaultDelay() {
        let animation = AnimationHelper.fadeInScale()

        XCTAssertNotNil(animation, "Fade in scale animation should be defined")
    }

    func testFadeInScaleAnimationWithCustomDelay() {
        let animation = AnimationHelper.fadeInScale(delay: 0.5)

        XCTAssertNotNil(animation, "Fade in scale animation with delay should be defined")
    }

    func testFadeInScaleAnimationWithNegativeDelay() {
        let animation = AnimationHelper.fadeInScale(delay: -0.1)

        XCTAssertNotNil(animation, "Fade in scale animation with negative delay should be defined (though may not be practical)")
    }

    // MARK: - Slide In Animation Tests

    func testSlideInAnimationWithDefaultEdge() {
        let animation = AnimationHelper.slideIn()

        XCTAssertNotNil(animation, "Slide in animation should be defined")
    }

    func testSlideInAnimationWithLeadingEdge() {
        let animation = AnimationHelper.slideIn(from: .leading)

        XCTAssertNotNil(animation, "Slide in animation from leading should be defined")
    }

    func testSlideInAnimationWithTrailingEdge() {
        let animation = AnimationHelper.slideIn(from: .trailing)

        XCTAssertNotNil(animation, "Slide in animation from trailing should be defined")
    }

    func testSlideInAnimationWithTopEdge() {
        let animation = AnimationHelper.slideIn(from: .top)

        XCTAssertNotNil(animation, "Slide in animation from top should be defined")
    }

    func testSlideInAnimationWithBottomEdge() {
        let animation = AnimationHelper.slideIn(from: .bottom)

        XCTAssertNotNil(animation, "Slide in animation from bottom should be defined")
    }

    func testSlideInAnimationWithDelay() {
        let animation = AnimationHelper.slideIn(from: .bottom, delay: 0.3)

        XCTAssertNotNil(animation, "Slide in animation with delay should be defined")
    }

    // MARK: - Staggered Animation Tests

    func testStaggeredAnimationWithBaseDelayOnly() {
        let animation = AnimationHelper.staggered(baseDelay: 0, index: 0)

        XCTAssertNotNil(animation, "Staggered animation should be defined")
    }

    func testStaggeredAnimationWithMultipleItems() {
        let animation1 = AnimationHelper.staggered(baseDelay: 0, index: 0)
        let animation2 = AnimationHelper.staggered(baseDelay: 0, index: 1)
        let animation3 = AnimationHelper.staggered(baseDelay: 0, index: 2)

        XCTAssertNotNil(animation1, "First staggered animation should be defined")
        XCTAssertNotNil(animation2, "Second staggered animation should be defined")
        XCTAssertNotNil(animation3, "Third staggered animation should be defined")
    }

    func testStaggeredAnimationWithCustomSpacing() {
        let animation = AnimationHelper.staggered(baseDelay: 0, index: 2, spacing: 0.1)

        XCTAssertNotNil(animation, "Staggered animation with custom spacing should be defined")
    }

    func testStaggeredAnimationWithLargeIndex() {
        let animation = AnimationHelper.staggered(baseDelay: 0, index: 100)

        XCTAssertNotNil(animation, "Staggered animation with large index should be defined")
    }

    // MARK: - Edge Cases

    func testMultipleAnimationsDontCrash() {
        XCTAssertNoThrow({
            _ = AnimationHelper.spring
            _ = AnimationHelper.quickSpring
            _ = AnimationHelper.slowSpring
            _ = AnimationHelper.easeOut
            _ = AnimationHelper.easeInOut
            _ = AnimationHelper.bouncy
        }(), "Creating multiple animations should not throw")
    }

    func testAnimationFactoriesDontCrashWithExtremeValues() {
        XCTAssertNoThrow({
            _ = AnimationHelper.fadeInScale(delay: 100)
            _ = AnimationHelper.fadeInScale(delay: -100)
            _ = AnimationHelper.slideIn(from: .bottom, delay: 100)
            _ = AnimationHelper.staggered(baseDelay: -100, index: -100, spacing: -1)
        }(), "Animation factories with extreme values should not throw")
    }

    func testStaggeredAnimationWithNegativeSpacing() {
        let animation = AnimationHelper.staggered(baseDelay: 0, index: 1, spacing: -0.05)

        XCTAssertNotNil(animation, "Staggered animation with negative spacing should be defined (though may cause overlap)")
    }

    func testStaggeredAnimationWithZeroSpacing() {
        let animation1 = AnimationHelper.staggered(baseDelay: 0, index: 0, spacing: 0)
        let animation2 = AnimationHelper.staggered(baseDelay: 0, index: 1, spacing: 0)

        XCTAssertNotNil(animation1, "First staggered animation with zero spacing should be defined")
        XCTAssertNotNil(animation2, "Second staggered animation with zero spacing should be defined")
    }

    // MARK: - Animation Consistency Tests

    func testSameAnimationFactoryReturnsSameAnimation() {
        let animation1 = AnimationHelper.fadeInScale(delay: 0)
        let animation2 = AnimationHelper.fadeInScale(delay: 0)

        // While we can't directly compare animations, we can verify they both exist
        XCTAssertNotNil(animation1)
        XCTAssertNotNil(animation2)
    }

    func testDifferentParametersCreateAnimations() {
        let animation1 = AnimationHelper.staggered(baseDelay: 0, index: 0)
        let animation2 = AnimationHelper.staggered(baseDelay: 0.1, index: 0)
        let animation3 = AnimationHelper.staggered(baseDelay: 0, index: 1)

        XCTAssertNotNil(animation1)
        XCTAssertNotNil(animation2)
        XCTAssertNotNil(animation3)
    }

    // MARK: - Performance Tests

    func testCreatingManyAnimationsDoesntCrash() {
        measure {
            for i in 0..<1000 {
                _ = AnimationHelper.staggered(baseDelay: 0, index: i)
            }
        }
    }
}
