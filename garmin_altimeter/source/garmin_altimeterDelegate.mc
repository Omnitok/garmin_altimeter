using Toybox.WatchUi;

class garmin_altimeterDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Down opens the jump-count page.
    function onNextPage() {
        var summaryView = new JumpSummaryView();

        WatchUi.pushView(
            summaryView,
            new JumpSummaryDelegate(summaryView),
            WatchUi.SLIDE_UP
        );

        return true;
    }

    function onMenu() {
        WatchUi.pushView(
            new Rez.Menus.MainMenu(),
            new garmin_altimeterMenuDelegate(),
            WatchUi.SLIDE_UP
        );

        return true;
    }
}