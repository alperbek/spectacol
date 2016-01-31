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

import QtQuick 2.6
import QtQuick.Window 2.2
import Qt.labs.controls 1.0

TextField {
    property real fontSize : 5
    focus: true
    font.pixelSize: fontSize * Screen.pixelDensity
    font.bold: true
    color: "white"
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter
    inputMethodHints: Qt.ImhNoPredictiveText
}
