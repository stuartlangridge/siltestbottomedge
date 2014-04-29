import QtQuick 2.2
import QtGraphicalEffects 1.0

Item {
    id: be
    property var breakpoints: []
    anchors.fill: parent
    property alias blurSource: blur.source
    property Item helpText: null
    property int currentBreakpoint: -1
    function hide() {
        overlay.anchors.topMargin = 0;
    }

    signal commit(int height)

    MouseArea {
        id: ma
        cursorShape: Qt.BlankCursor
        property bool isDragging: false
        property var pointMovedHandlers: [];
        propagateComposedEvents: true
        onPressed: {
            if (Math.abs((height + overlay.anchors.topMargin) - mouse.y) < 20) {
                isDragging = true;
            } else {
                mouse.accepted = false;
            }
        }

        onPositionChanged: {
            if (!isDragging) return;
            overlay.anchors.topMargin = -(height - mouse.y);
            ma.pointMovedHandlers.forEach(function(f) { f(mouse.x, mouse.y); });
            var bp = -1;
            for (var i=1; i<parent.breakpoints.length; i++) {
                if ((height - mouse.y) < ((parent.breakpoints[i].bp + parent.breakpoints[i-1].bp) / 2)) {
                    bp = i-1;
                    break;
                }
            }
            if (bp == -1) {
                bp = parent.breakpoints.length-1;
            }
            if (bp != be.currentBreakpoint) be.currentBreakpoint = bp;
        }

        onClicked: mouse.accepted = false;

        onReleased: {
            if (!isDragging) {
                mouse.accepted = false;
                return;
            }
            isDragging = false;
            var found = false;
            for (var i=1; i<parent.breakpoints.length; i++) {
                console.log("Checking", height-mouse.y, "against parent.breakpoints", i-1, i, ((parent.breakpoints[i].bp + parent.breakpoints[i-1].bp) / 2));
                if ((height - mouse.y) < ((parent.breakpoints[i].bp + parent.breakpoints[i-1].bp) / 2)) {
                    console.log("going to stop", i-1, parent.breakpoints[i-1].bp);
                    if (parent.breakpoints[i-1].hold === false) {
                        console.log("That is not a hold point!");
                        overlay.anchors.topMargin = 0;
                    } else {
                        overlay.anchors.topMargin = -parent.breakpoints[i-1].bp;
                    }
                    found = true;
                    break;
                }
            }
            if (!found) {
                console.log("going to last stop", parent.breakpoints[parent.breakpoints.length-1].bp);
                overlay.anchors.topMargin = -parent.breakpoints[parent.breakpoints.length-1].bp;
            }
            be.commit(overlay.anchors.topMargin)
        }
        anchors.fill: parent

        Rectangle {
            id: overlay
            width: parent.width
            height: parent.height
            color: Qt.rgba(0,0,0,0)
            anchors.top: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: 0
            Rectangle {
                color: Qt.rgba(0,0,0,0)
                anchors.fill: parent
                width: overlay.width
                clip: true
                FastBlur {
                    id: blur
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: -(source.height + overlay.anchors.topMargin)
                    height: source.height
                    width: parent.width
                    radius: 20
                }
            }
        }

    }
    Component.onCompleted: {
        var breakpointidx = be.breakpoints.length;
        var appends = [];
        for (var i=be.children.length-1; i>=0; i--) {
            if (be.children[i] != ma) {
                breakpointidx -= 1;
                appends.push({item: be.children[i], height: be.breakpoints[breakpointidx].bp});
            }
        }
        appends.reverse();
        var anchorPoint = overlay.top, prevHeight = 0;
        appends.forEach(function(append) {
            append.item.parent = overlay;
            append.item.anchors.top = anchorPoint;
            append.item.anchors.left = overlay.left;
            append.item.width = overlay.width;
            append.item.height = append.height - prevHeight;
            prevHeight = append.height;
            if (append.item.onPointMoved) {
                ma.pointMovedHandlers.push(append.item.onPointMoved);
            }
            anchorPoint = append.item.bottom;
        });
        if (be.helpText) {
            be.helpText.parent = overlay;
            be.helpText.anchors.horizontalCenter = overlay.horizontalCenter;
            be.helpText.anchors.top = overlay.top;
            be.helpText.anchors.topMargin = -be.helpText.height;
        }
    }
}
