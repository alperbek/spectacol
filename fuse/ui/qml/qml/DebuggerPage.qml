/*
    Copyright (c) 2015, BogDan Vatra <bogdan@kde.org>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// @scope main.qml

import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0

Item {
    Component.onDestruction: fuse.debuggerRun()

    readonly property color backgroudColor : Qt.rgba(0, 0, 0, 0.85);
    ColumnLayout {
        spacing: 2.5 * Screen.pixelDensity
        anchors.fill: parent
        RowLayout {
            spacing: 2.5 * Screen.pixelDensity
            Layout.fillWidth: true
            Layout.fillHeight: true
            Rectangle {
                id: dissasambleRect
                color: backgroudColor
                radius: Screen.pixelDensity
                border.width: (disassembleView.focus ? 1 : 0.5) * Screen.pixelDensity
                border.color: "white"

                width: 65 * Screen.pixelDensity
                Layout.fillHeight: true

                DisassembleView {
                    id: disassembleView
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    activeFocusOnTab: true
                    focus: true
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    id: infoRect
                    visible: true
                    anchors.fill: parent
                    radius: Screen.pixelDensity
                    color: backgroudColor
                    border.width: (focus ? 1 : 0.5) * Screen.pixelDensity
                    border.color: "white"

                    FancyText {
                        anchors.centerIn: parent
                        text: "info"
                    }
                }
            }
            ColumnLayout {
                spacing: 2.5 * Screen.pixelDensity
                width: 60 * Screen.pixelDensity
                Layout.fillWidth: false
                Layout.fillHeight: true
                Rectangle {
                    id: registersRect
                    color: backgroudColor
                    radius: Screen.pixelDensity
                    border.width: (focus ? 1 : 0.5) * Screen.pixelDensity
                    border.color: "white"
                    height: 60 * Screen.pixelDensity
                    Layout.fillWidth: true
                    activeFocusOnTab: true
                    RegistersView {
                        anchors.fill: parent
                        anchors.topMargin: parent.border.width + Screen.pixelDensity
                        anchors.leftMargin: parent.border.width + Screen.pixelDensity
                        anchors.rightMargin: parent.border.width + Screen.pixelDensity
                        columnSpacing: Screen.pixelDensity
                    }
                }
                Rectangle {
                    id: breakPointsRect
                    color: backgroudColor
                    radius: Screen.pixelDensity
                    border.width: (focus ? 1 : 0.5) * Screen.pixelDensity
                    border.color: "white"
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    activeFocusOnTab: true
                    FancyText {
                        anchors.centerIn: parent
                        text: "breakPoints"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: dissasambleRect.focus = true
                    }
                }
            }
        }
        Rectangle {
            id: toolBarRect
            height: 10 * Screen.pixelDensity
            Layout.fillWidth: true
            color: backgroudColor
            radius: Screen.pixelDensity
            border.width: (focus ? 1 : 0.5) * Screen.pixelDensity
            border.color: "white"
            FancyText {
                anchors.centerIn: parent
                text: "toolBar"
            }
        }
    }
}
