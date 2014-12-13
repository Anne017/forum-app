import QtQuick 2.2
import Ubuntu.Components 1.1

//TODO-r: Move parsing algorithmn into ThreadList, so that parsing will happen only once. This will also fix scrolling issues which arise from asynchronous parsing.

Item {
    id: rootItem

    readonly property variant tagsWithChildren: [ "quote", "code", "hide", "img" ] //lower-case

    property string code: ""
    property var bbRoot: parse("", [], code) //of type passage

    height: passageView.height

    PassageView {
        id: passageView
        dataItem: bbRoot
        width: parent.width
    }

    Component {
        id: passage
        Item {
            property string tagType: ""
            property var tagArguments: []
            //Only one of the following two is used at a time
            property string text: ""
            property var childElements: []
        }
    }

    //TODO-r: Tags with arguments, What to do with line breaks at the beginning and at the end of passages?
    function parse(tagType, tagArguments, content) { //Post content which should be parsed
        var oldPos = 0
        var pos = -1
        var root = passage.createObject(rootItem, { "tagType": tagType, "tagArguments": tagArguments }) //TODO-r: Proper parent here

        while ((pos = content.indexOf("[", pos + 1)) !== -1) {
            var bracketClosePos = content.indexOf("]", pos + 1)

            //Check if the tag has arguments
            var equalsPos = content.indexOf("=", pos + 1)
            var spacePos = content.indexOf(" ", pos + 1)
//            console.log(pos, spacePos, equalsPos, bracketClosePos)
            var argumentsStartPos = (spacePos === -1) ? Math.min(equalsPos, bracketClosePos) : ((equalsPos === -1) ? Math.min(spacePos, bracketClosePos) : Math.min(spacePos, equalsPos, bracketClosePos))
            var hasArguments = (argumentsStartPos !== -1) && (argumentsStartPos !== bracketClosePos)
            var hasArgumentNames = hasArguments && (argumentsStartPos === spacePos)

            var tag = content.substring(pos + 1, hasArguments ? argumentsStartPos : bracketClosePos).toLowerCase()
//            console.log("Tag: \"" + tag + "\"")
            var arguments = []
//            if (hasArguments) { //TODO-r: Only works for some forums, e.g. not for XDA
//                var argumentString = content.substring(equalsPos + 2, bracketClosePos) // +2 also excludes the "equals"
//                arguments = argumentString.split(";")
//            }

            if (arrayContains(tagsWithChildren, tag)) { //else: don't parse
                var notFormattedText = content.substring(oldPos, pos).trim()
                if (notFormattedText !== "") {
                    root.childElements.push(parse("", [], notFormattedText))
                }
                var endPos = pos + tag.length //TODO-r: Add arguments string length
                var moreStartTags = 1
                while (moreStartTags > 0) {
                    endPos = content.toLowerCase().indexOf(tag, endPos + tag.length) //TODO-r: currentTag.length???
                    if (endPos === -1) {
                        console.log("Error: endPos === -1")
                        break
                    }
                    var currentTag = content.substring(content.lastIndexOf("[", endPos), content.indexOf("]", endPos) + 1).toLowerCase() //TODO-r: Why lastIndexOf()???
//                    console.log("Current tag: \"" + tag + "\"")
                    if (currentTag === "[" + tag + "]") {
                        moreStartTags++
                    } else if (currentTag === "[/" + tag + "]") { //TODO-r: What's about other tags which are closed?
                        moreStartTags--
                    }
                }
                if (moreStartTags === 0) { //else: user forgot closing tag => ignore tag
                    root.childElements.push(parse(tag, arguments, content.substring(bracketClosePos + 1, endPos - 2).trim()))
                    oldPos = endPos + tag.length + 1
                    pos = oldPos
                } else {
                    if (endPos === -1) { //TODO-r: Check if done right
                        oldPos = pos
                        pos = pos + tag.length
                    }
                }
            }
        }
        if (root.childElements.length === 0) {
            root.text = content.trim()
        } else {
            var restText = content.substring(oldPos, content.length).trim()
            if (restText !== "") {
                root.childElements.push(parse("", [], restText))
            }
        }
        return root
    }

    function arrayContains(array, value) {
        for (var i = 0; i < array.length; i++) {
            if (array[i] === value) {
                return true
            }
        }
        return false
    }
}
