import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

(:test)
class RaceScreenTest {

    (:test)
    function testFirstFixPassesStraightThrough(logger as Logger) as Boolean {
        var filter = new MotionFilter();
        filter.update(5.0, Math.toRadians(90), 0.0);
        logger.debug(filter.getSogKnots() + " kn " + filter.getCogDegrees());
        return (filter.getSogKnots() - 9.72).abs() < 0.01 && filter.getCogDegrees() == 90;
    }

    // A one-second step moves about a third of the way: the "5-period" EMA.
    (:test)
    function testOneSecondStepMovesAboutAThird(logger as Logger) as Boolean {
        var filter = new MotionFilter();
        filter.update(0.0, 0.0, 0.0);
        filter.update(10.0 / MotionFilter.KNOTS_PER_MPS, 0.0, 1.0);
        logger.debug(filter.getSogKnots() + " kn");
        return (filter.getSogKnots() - 3.30).abs() < 0.05;
    }

    // Most recent fixes dominate: after 7 s at a new SOG it is 1 - e^(-7/2.5),
    // ~94% of the way there.
    (:test)
    function testSettlesWithinAboutSevenSeconds(logger as Logger) as Boolean {
        var filter = new MotionFilter();
        filter.update(0.0, 0.0, 0.0);
        for (var i = 0; i < 7; i++) {
            filter.update(10.0 / MotionFilter.KNOTS_PER_MPS, 0.0, 1.0);
        }
        logger.debug(filter.getSogKnots() + " kn");
        return (filter.getSogKnots() - 9.39).abs() < 0.05;
    }

    // Averaging 350 and 010 must give north, not south.
    (:test)
    function testCogWrapsThroughNorth(logger as Logger) as Boolean {
        var filter = new MotionFilter();
        filter.update(3.0, Math.toRadians(350), 0.0);
        for (var i = 0; i < 20; i++) {
            filter.update(3.0, Math.toRadians(i % 2 == 0 ? 10 : 350), 1.0);
        }
        var cog = filter.getCogDegrees();
        logger.debug("cog " + cog);
        return cog != null && (cog <= 5 || cog >= 355);
    }

    // Tacking through 90 degrees at constant speed must not sag SOG.
    (:test)
    function testSogHoldsThroughATack(logger as Logger) as Boolean {
        var filter = new MotionFilter();
        filter.update(3.0, Math.toRadians(45), 0.0);
        filter.update(3.0, Math.toRadians(315), 1.0);
        filter.update(3.0, Math.toRadians(315), 1.0);
        logger.debug(filter.getSogKnots() + " kn");
        return (filter.getSogKnots() - 3.0 * MotionFilter.KNOTS_PER_MPS).abs() < 0.01;
    }

    (:test)
    function testLongGapRestartsFromNewFix(logger as Logger) as Boolean {
        var filter = new MotionFilter();
        filter.update(0.0, 0.0, 0.0);
        filter.update(5.0, 0.0, 30.0);
        return (filter.getSogKnots() - 5.0 * MotionFilter.KNOTS_PER_MPS).abs() < 0.01;
    }

    (:test)
    function testNoCogWhenAlmostStopped(logger as Logger) as Boolean {
        var filter = new MotionFilter();
        filter.update(0.1, Math.toRadians(123), 0.0);
        return filter.getCogDegrees() == null;
    }

    (:test)
    function testRaceStartsOnlyOnTheCrossing(logger as Logger) as Boolean {
        return TimePickerDelegate.didRaceStart(-1, 0)
            && !TimePickerDelegate.didRaceStart(null, 0)
            && !TimePickerDelegate.didRaceStart(-5, -4)
            && !TimePickerDelegate.didRaceStart(3, 4);
    }

    (:test)
    function testFormatting(logger as Logger) as Boolean {
        return RaceView.formatCog(45).equals("045")
            && RaceView.formatCog(null).equals("---")
            && RaceView.formatSog(6.44).equals("6.4")
            && RaceView.formatSog(null).equals("-.-");
    }
}
