/*
* Forum Browser
*
* Copyright (c) 2014-2015 Niklas Wenzel <nikwen.developer@gmail.com>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.3
import Ubuntu.Components 1.1
import "../components"

Page {
    id: settingsPage
    title: i18n.tr("Settings")

    Column {
        anchors.fill: parent

        OneLineSubtitledListItem {
            text: i18n.tr("Signature")
            subText: (backend.signature !== "") ? backend.signature : i18n.tr("Displays a signature below all of your posts…")
            progression: true

            onClicked: {
                pageStack.push(Qt.resolvedUrl("EditSignaturePage.qml"))
            }
        }
    }
}
