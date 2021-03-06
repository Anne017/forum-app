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
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Themes.Ambiance 0.1
import U1db 1.0 as U1db
import "../../backend"
import "../components"

Page {
    id: postCreationPage

    signal posted(string subject, int forumId, int topicId)

    property int forum_id: -1
    property int topic_id: -1

    property string mode: "post" //Can be either "post" or "thread"
                                 //Needs to be the first property set!!!

    title: (mode === "post") ? i18n.tr("Reply") : i18n.tr("New Topic")

    property var dialog

    property string docId: ""

    U1db.Query {
        id: draftsQuery
        index: draftsIndex
        query: [ backend.currentSession.forumUrl, backend.currentSession.user, mode, forum_id, topic_id, "*", "*" ]

        onResultsChanged: {
            var results = draftsQuery.results //NOTE: The first two checks of the if condition will have to be fixed when adding proper replying with quoting
            if (subjectTextField.text === "" && messageTextField.text === "" && forum_id !== -1 && (mode === "thread" || topic_id !== -1) && results[0] !== undefined && results[0].subject !== undefined && results[0].message !== undefined && (results[0].subject !== "" || results[0].message !== "")) {
                console.log("Filling composer with draft data")
                docId = draftsQuery.documents[0]
                subjectTextField.text = results[0].subject
                messageTextField.text = results[0].message
            }
        }
    }

    head.actions: [
        Action {
            id: submitAction
            text: i18n.tr("Submit")
            iconName: "ok"

            onTriggered: submit()

            function submit() {
                var message = messageTextField.text

                if (message.trim() === "") {
                    var errorDialog = PopupUtils.open(Qt.resolvedUrl("../components/ErrorDialog.qml"))
                    errorDialog.title = qsTr(i18n.tr("%1 failed")).arg(submitRequest.actionName) //for consistency ;)
                    errorDialog.text = i18n.tr("Please enter a message")
                    return
                }

                if (backend.signature !== "") {
                    message += "\n\n" + backend.signature
                }

                if (mode === "post") {
                    submitRequest.query = '<?xml version="1.0"?><methodCall><methodName>reply_post</methodName><params><param><value>' + forum_id + '</value></param><param><value>' + topic_id + '</value></param><param><value><base64>' + Qt.btoa(subjectTextField.text) + '</base64></value></param><param><value><base64>' + Qt.btoa(message) + '</base64></value></param></params></methodCall>'
                } else {
                    submitRequest.query = '<?xml version="1.0"?><methodCall><methodName>new_topic</methodName><params><param><value>' + forum_id + '</value></param><param><value><base64>' + Qt.btoa(subjectTextField.text) + '</base64></value></param><param><value><base64>' + Qt.btoa(message) + '</base64></value></param></params></methodCall>'
                }

                submitRequest.start()
                Qt.inputMethod.hide()
                dialog = PopupUtils.open(loadingDialog)
            }
        }
    ]

    head.backAction: Action {
        id: backAction
        text: i18n.tr("Back")
        iconName: "back"

        onTriggered: {
            if (subjectTextField.text !== "" || messageTextField.text !== "") {
                var doc = { "forum_url": backend.currentSession.forumUrl, "username": backend.currentSession.user, "mode": mode, "forum_id": forum_id, "topic_id": topic_id, "subject": subjectTextField.text, "message": messageTextField.text }
                if (docId === "") {
                    draftsDb.putDoc(doc)
                } else {
                    draftsDb.putDoc(doc, docId)
                }
            } else if (docId !== "") {
                draftsDb.deleteDoc(docId)
            }

            pageStack.pop()
        }
    }

    ApiRequest {
        id: submitRequest
        checkSuccess: true

        onQuerySuccessResult: {
            if (success) {
                if (docId !== "") {
                    draftsDb.deleteDoc(docId)
                }

                subjectTextField.enabled = false //Needed, otherwise the keyboard will show again after closing the dialog
                messageTextField.enabled = false
                PopupUtils.close(dialog)

                if (mode === "post") {
                    pageStack.pop()
                    posted(subjectTextField.text, forum_id, topic_id)
                } else {
                    var idIndex = responseXml.indexOf("topic_id")
                    var stringTag = responseXml.indexOf("<string>", idIndex)
                    var stringEndTag = responseXml.indexOf("</string>", idIndex)
                    var id = parseInt(responseXml.substring(stringTag + 8, stringEndTag))

                    pageStack.pop()
                    posted(subjectTextField.text, forum_id, id)
                }
            } else {
                PopupUtils.close(dialog)
            }
        }
    }

    Column {
        id: column
        anchors.fill: parent

        ListItem.Base {
            id: subjectListItem
            visible: mode === "thread" || backend.subjectFieldWhenReplying

            TextField {
                id: subjectTextField
                placeholderText: i18n.tr("Enter Subject")

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: - units.gu(1) //Margins needed due to the TextFieldStyle
                    rightMargin: - units.gu(1)
                    verticalCenter: parent.verticalCenter
                }

                style: TextFieldStyle {
                    background: Item {}
                }

                KeyNavigation.priority: KeyNavigation.BeforeItem
                KeyNavigation.tab: messageTextField
            }
        }

        ListItem.Base {
            height: postCreationPage.height - (subjectListItem.visible ? subjectListItem.height : 0) + units.gu(1) //We do not want the lower border to be visible

            Column {
                anchors.fill: parent
                anchors.topMargin: units.gu(2)
                anchors.bottomMargin: units.gu(3)

                TextArea {
                    id: messageTextField
                    autoSize: false
                    maximumLineCount: 0
                    placeholderText: i18n.tr("Enter Message")

                    width: parent.width
                    height: parent.height

                    style: TextAreaStyle {
                        overlaySpacing: 0
                        frameSpacing: 0
                        background: Item {}
                    }

                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.backtab: subjectTextField
                }
            }
        }
    }

    Component {
         id: loadingDialog

         Dialog {
             id: dialog
             modal: true

             Row {
                 width: parent.width
                 spacing: units.gu(2)

                 ActivityIndicator {
                     id: loadingSpinner
                     running: true
                     anchors.verticalCenter: parent.verticalCenter
                 }

                 Label {
                     text: qsTr(i18n.tr("Submitting %1...")).arg((mode === "post") ? i18n.tr("Post") : i18n.tr("Thread"))
                     anchors.verticalCenter: parent.verticalCenter
                 }
             }
         }
    }
}
