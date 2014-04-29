import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Extras.Browser 0.2
import QtGraphicalEffects 1.0

import "components"

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "org.kryogenix.siltestbottomedge"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true
    id: main

    width: units.gu(40)
    height: units.gu(75)

    Page {
        title: i18n.tr("")

        UbuntuWebView {
            id: webview
            anchors.fill: parent
            url: "http://ubuntu.com"
        }

        SilBottomEdge {
            id: silbe
            breakpoints: [{bp: 1.5 * main.height / 10, hold: false},
                {bp: 7 * main.height / 10},
                {bp:main.height}]
            blurSource: webview
            helpText: Rectangle {
                width: parent.width
                color: Qt.rgba(0,0,0,0.4)
                height: ht.contentHeight
                Label {
                    id: ht
                    anchors.centerIn: parent
                    fontSize: "x-large"
                    color: "white"
                    text: ""
                }
                visible: ht.text != ""
            }
            property bool isCommitted: true

            onCurrentBreakpointChanged: {
                if (currentBreakpoint == 1) {
                    ht.text = "search";
                } else if (currentBreakpoint == 2) {
                    ht.text = "bookmarks";
                } else {
                    ht.text = "";
                }
            }

            onCommit: {
                silbe.isCommitted = true;
                if (backstripe.status == "back" && silbe.currentBreakpoint == 0) {
                    console.log("go back");
                    webview.goBack();
                } else if (silbe.currentBreakpoint == 2) {
                    searchinput.forceActiveFocus()
                }
                backstripe.status = "";
                ht.text = "";
                backstripe.trapfirstx = true;
            }

            Rectangle {
                id: backstripe
                property string status: ""
                property int firstx: 0
                property bool trapfirstx: true
                property int spacing: 15
                width: parent.width
                function onPointMoved(x,y) {
                    silbe.isCommitted = false;
                    if (silbe.currentBreakpoint != 0) {
                        return;
                    }
                    if (trapfirstx) {
                        firstx = x;
                        trapfirstx = false;
                    }
                    var backLeft = firstx - (current.scaledWidth/2) - backstripe.spacing - (back.originalWidth);
                    if (x < backLeft) {
                        var disp = backLeft - x;
                        back.width = back.originalWidth + disp;
                        var disp_as_fraction = 1 - (disp / backLeft);
                        if (disp_as_fraction < 0.2) disp_as_fraction = 0.2;
                        //back.height = back.originalHeight * disp_as_fraction;
                        backstripe.status = "back"
                        ht.text = "back"
                    } else {
                        back.width = back.originalWidth;
                        back.height = back.originalHeight;
                        backstripe.status = ""
                        ht.text = ""
                    }

                    //    back.x = x - (back.originalWidth/2);
                    //    status = "back"
                    //} else if (x > firstx + (current.scaledWidth/2) + backstripe.spacing + (othertabs.width/2)) {
                    //    othertabs.x = x - (othertabs.width/2);
                    //    status = "othertabs"
                    //} else {
                    //    status = "";
                    //}
                }
                color: Qt.rgba(247,237,227,0.8)
                Rectangle {
                    id: current
                    //height: parent.height * 0.9
                    //width: parent.width / 10
                    height: webview.height
                    width: webview.width
                    property double scaledWidth: parent.width / 10
                    y: parent.height * 0.05
                    x: backstripe.firstx - (scaledWidth/2)
                    color: "red"
                    transform: Scale {
                        id: currentTransform
                        xScale: backstripe.width / 10 / width;
                        yScale: backstripe.height * 0.9 / webview.height
                    }
                    FastBlur {
                        anchors.fill: parent
                        source: webview
                        radius: 0
                        cached: true
                    }
                }
                Rectangle {
                    id: back
                    color: webview.canGoBack ? "black": "black"
                    height: parent.height * 0.9
                    property int originalHeight: parent.height * 0.9
                    width: parent.width / 10
                    property int originalWidth: parent.width / 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: current.left
                    anchors.rightMargin: backstripe.spacing
                }
            }

            Rectangle {
                id: searchbox
                color: backstripe.color
                Label {
                    anchors.centerIn: parent
                    text: "search"
                    fontSize: "x-large"
                    visible: !silbe.isCommitted
                }
                TextInput {
                    id: searchinput
                    anchors.top: parent.top
                    text: ""
                    font.pixelSize: 24
                    visible: silbe.isCommitted
                    width: parent.width * 0.9
                    anchors.horizontalCenter: parent.horizontalCenter
                    focus: visible
                    onAccepted: {
                        if (/(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/.test(searchinput.text)) {
                            webview.url = searchinput.text;
                        } else {
                            webview.url = "https://duckduckgo.com/?q=" + escape(searchinput.text);
                        }
                        silbe.hide();
                    }

                    cursorDelegate: Component {
                        id: cursor
                        Rectangle {
                            id: cursor_rect
                            width: 2
                            height: 30
                            color: "#333"

                            PropertyAnimation on opacity  {
                                easing.type: Easing.OutSine
                                loops: Animation.Infinite
                                from: 0
                                to: 1.0
                                duration: 1000
                            }
                        }
                    }
                }
                ListView {
                    anchors.top: searchinput.bottom
                    anchors.bottom: searchbox.bottom
                    width: parent.width * 0.9
                    anchors.horizontalCenter: parent.horizontalCenter
                    model: XmlListModel {
                        source: "http://suggestqueries.google.com/complete/search?output=toolbar&hl=en&q=" + escape(searchinput.text)
                        query: "/toplevel/CompleteSuggestion/suggestion"
                        XmlRole { name: "suggestion"; query: "@data/string()" }
                    }
                    visible: silbe.isCommitted
                    delegate: Label {
                        fontSize: "x-large"
                        width: searchbox.width
                        text: model.suggestion
                        elide: Text.ElideMiddle
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                webview.url = "https://duckduckgo.com/?q=" + model.suggestion;
                                silbe.hide();
                            }
                        }
                    }
                }
            }

            Rectangle {
                color: backstripe.color
                Text {
                    anchors.centerIn: parent
                    text: "bookmarks"
                }
            }
        }

    }
}
