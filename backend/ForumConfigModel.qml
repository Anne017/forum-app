/*************************************************************************
** Forum Browser
**
** Copyright (c) 2014 Niklas Wenzel <nikwen.developer@gmail.com>
**
** $QT_BEGIN_LICENSE:GPL$
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
** General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; see the file COPYING. If not, write to
** the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
** Boston, MA 02110-1301, USA.
**
**
** $QT_END_LICENSE$
**
*************************************************************************/

import QtQuick 2.2
import QtQuick.XmlListModel 2.0
import Ubuntu.Components 1.1
import "../stringutils.js" as StringUtils

//The respective ApiRequest had to be placed in ForumBackend.qml as XmlListModel does not allow Items as children

XmlListModel {
    id: configModel
    objectName: "configModel"

    query: "/methodResponse/params/param/value/struct"

    property bool hasLoaded: false
    property bool isVBulletin: false

    XmlRole { name: "support_md5"; query: "member[name='support_md5']/value/string()" }
    XmlRole { name: "support_sha1"; query: "member[name='support_sha1']/value/string()" }
    XmlRole { name: "version"; query: "member[name='version']/value/string()" }

    onStatusChanged: {
        if (status === XmlListModel.Ready) {
            var element = get(0)
            if (element.version.trim().indexOf("vb") === 0) {
                isVBulletin = true
            }
            console.log("version: " + element.version.trim())

            console.log("configModel has loaded")

            hasLoaded = true
        }
    }

    function loadConfig() {
        hasLoaded = false
        configModel.xml = ""

        loadConfigRequest.start()
    }

}
