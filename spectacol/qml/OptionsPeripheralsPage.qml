/*
    Copyright (c) 2016, BogDan Vatra <bogdan@kde.org>

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

import QtQuick 2.12
import QtQuick.Window 2.12
import QtGamepad 1.0
import QtQuick.Controls 2.12

// @scope main.qml

Flickable {
    contentHeight: pane.height
    Component.onCompleted: fuse.paused = true
    Component.onDestruction: fuse.paused = false
    anchors.margins: Screen.pixelDensity

    GamepadKeyNavigation {
        gamepad: Gamepad { deviceId: fuse.gamepadId }
        buttonBKey: Qt.Key_Escape
        buttonAKey: Qt.Key_Space
    }

    FancyPane {
        id: pane
        Column {
            spacing: 2.5 * Screen.pixelDensity
            anchors.horizontalCenter: parent.horizontalCenter
            Label {
                text: qsTr("Peripherals Options")
            }

            CheckBox {
                id: kempstonJoystick
                KeyNavigation.up: deadZone
                KeyNavigation.down: kempstonMouse
                focus: true
                text: qsTr("Kempston joystick")
                checked: fuseSettings.kempstonJoystick
                onCheckedChanged: fuseSettings.kempstonJoystick = checked
            }

            CheckBox {
                id: kempstonMouse
                KeyNavigation.up: kempstonJoystick
                KeyNavigation.down: interface1
                text: qsTr("Kempston mouse")
                checked: fuseSettings.kempstonMouse
                onCheckedChanged: fuseSettings.kempstonMouse = checked
            }

            CheckBox {
                id: interface1
                KeyNavigation.up: kempstonMouse
                KeyNavigation.down: interface2
                text: qsTr("Interface 1")
                checked: fuseSettings.interface1
                onCheckedChanged: fuseSettings.interface1 = checked
            }

            CheckBox {
                id: interface2
                KeyNavigation.up: interface1
                KeyNavigation.down: full48kOSK
                text: qsTr("Interface 2")
                checked: fuseSettings.interface2
                onCheckedChanged: fuseSettings.interface2 = checked
            }

            CheckBox {
                id: full48kOSK
                KeyNavigation.up: interface2
                KeyNavigation.down: recreatedSpectrum
                text: qsTr("Full On Screen 48k Keyboard")
                checked: fuseSettings.full48kOSK
                onCheckedChanged: fuseSettings.full48kOSK = checked
            }

            CheckBox {
                id: recreatedSpectrum
                KeyNavigation.up: full48kOSK
                KeyNavigation.down: joystickPrompt
                text: qsTr("Recreated spectrum keyboard")
                checked: fuseSettings.recreatedSpectrum
                onCheckedChanged: fuseSettings.recreatedSpectrum = checked
            }

            CheckBox {
                id: joystickPrompt
                KeyNavigation.up: recreatedSpectrum
                KeyNavigation.down: deadZone
                text: qsTr("Snapshot joystick prompt")
                checked: fuseSettings.joystickPrompt
                onCheckedChanged: fuseSettings.joystickPrompt = checked
            }
            Row {
                Label {
                    text: "Joystick deadzone"
                }
                Slider {
                    id: deadZone
                    KeyNavigation.up: joystickPrompt
                    KeyNavigation.down: kempstonJoystick
                    from: 0
                    to: 0.5
                    stepSize: 0.05
                    value: fuseSettings.deadZone
                    onValueChanged: fuseSettings.deadZone = value
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Close (B)")
                onClicked: pageLoader.source = ""
            }
        }
    }
}
