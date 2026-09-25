using Toybox.WatchUi;

class JumpSummaryDelegate extends WatchUi.BehaviorDelegate {

    var summaryView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        summaryView = view;
    }

    // Upper-right Start/Enter button.
    function onSelect() {
        var storage = new JumpStorage();

        if (storage.getJumpCount() == 0) {
            return true;
        }

        var listView = new JumpListView();

        WatchUi.pushView(
            listView,
            new JumpListDelegate(listView),
            WatchUi.SLIDE_UP
        );

        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}