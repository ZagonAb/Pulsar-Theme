import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2
import QtMultimedia 5.15
import QtQuick.Window 2.15

FocusScope {
    id: root
    focus: true

    property var game: null
    property string currentCollectionName: ""
    property string currentShortName: ""
    property bool inButtons: false
    property bool collectionsVisible: true
    property bool collectionsFocused: true
    property bool gamesVisible: false
    property bool gamesFocused: false

    ShaderEffect {
        anchors.fill: parent
        property real time: 0.0

        vertexShader: "
            uniform highp mat4 qt_Matrix;
            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;
            varying highp vec2 coord;
            void main() {
                coord = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;
            }"

        fragmentShader: "
            varying highp vec2 coord;
            uniform lowp float time;
            highp float rand(highp vec2 co) {
                return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
            }
            void main() {
                highp vec2 uv = coord;
                highp vec3 color = vec3(0.0, 0.0, 0.0);
                for (int i = 0; i < 3; i++) {
                    highp float speed = 0.1 + 0.05 * float(i);
                    highp float size = 0.002 + 0.001 * float(i);
                    //highp float fade = min(1.0, time / 10.0) * (0.5 * sin(time * speed) * 0.5 + 0.5); // Ajustado para aumentar gradualmente
                    highp float fade = 0.05 + min(0.8, time / 10.0) * (0.5 * sin(time * speed) * 0.5 + 0.5); // Ajustado para comenzar en 0.2
                    highp vec2 pos = vec2(uv.x + time * speed, uv.y);
                    highp vec2 rep = vec2(100.0, 100.0);
                    highp vec2 id = floor(pos * rep);
                    highp float rnd = rand(id);
                    highp vec2 starPos = (fract(pos * rep) - 0.5) / rep;
                    highp float star = smoothstep(size, 0.0, length(starPos - vec2(rnd, rnd) + 0.5));
                    color += vec3(star * fade);
                }
                gl_FragColor = vec4(color, 1.0);
            }"

        NumberAnimation on time {
            from: 0
            to: 100
            duration: 180000
            loops: Animation.Infinite
        }
    }

    Item {
        id: allItem
        width: parent.width
        height: parent.height

        FontLoader {
            id: fontLoaderName
            source: "assets/font/BlackHanSans-Regular.ttf"
        }

        FontLoader {
            id: fontLoaderDesc
            source: "assets/font/Prompt-SemiBold.ttf"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            Item {
                id: items
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.5 

                Text {
                    id: wellcomeTo
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: (parent.height >= 800 ? parent.height * 0.50 : parent.height * 0.10)
                    text: "Welcome to Pegasus"
                    color: "#FF4081"
                    font.family: fontLoaderDesc.name
                    font.pixelSize: 24
                }

                Text {
                    id: collectionName
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: wellcomeTo.bottom
                    anchors.topMargin: 10
                    text: currentCollectionName
                    color: "white"
                    font.family: fontLoaderName.name
                    font.pixelSize: parent.width * 0.030
                    font.bold: false
                }
                
                Item {
                    id: descriptionText
                    width: (parent.width >= 900 ? parent.width * 0.70 : parent.width * 0.90)
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.top: collectionName.bottom

                    Text {
                        id: collectionDes
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        anchors.topMargin: 10
                        color: "lightgray"
                        font.family: fontLoaderDesc.name
                        font.pixelSize: Math.max(12, collectionDes.width * 0.018)
                        wrapMode: Text.WordWrap
                    }
                }

                Row {
                    id: buttons
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: parent.width * 0.02

                    Rectangle {
                        id: favo
                        width: parent.parent.width * 0.2
                        height: parent.parent.width * 0.04
                        radius: height * 0.2
                        color: favo.focus ? "#FF4081" : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "FAVORITE GAMES"
                            font.pixelSize: parent.height * 0.4
                            font.family: fontLoaderDesc.name
                            color: "white"
                        }
                    }

                    Rectangle {
                        id: cont
                        width: parent.parent.width * 0.2
                        height: parent.parent.width * 0.04
                        radius: height * 0.2
                        color: cont.focus ? "#FF4081" : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "CONTINUE PLAYING"
                            font.pixelSize: parent.height * 0.4
                            font.family: fontLoaderDesc.name
                            color: "white"
                        }
                    }

                    Keys.onReleased: {
                        if (root.inButtons) {
                            if (event.key === Qt.Key_Right) {
                                if (favo.focus) {
                                    cont.forceActiveFocus();
                                }
                            } else if (event.key === Qt.Key_Left) {
                                if (cont.focus) {
                                    favo.forceActiveFocus();
                                }
                            } else if (event.key === Qt.Key_Down) {
                                pathView.forceActiveFocus();
                                root.inButtons = false;
                            }
                        }
                    }
                }

            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.bottomMargin: 20

                PathView {
                    id: pathView
                    width: parent.width
                    height: parent.height
                    anchors.bottom: parent.bottom
                    model: api.collections
                    pathItemCount: 9
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    visible: collectionsVisible

                    path: Path {
                        id: pathViewPath
                        startX: -pathView.width * 0.2
                        startY: pathView.height / 2
                        PathAttribute { name: "z"; value: 0 }
                        PathAttribute { name: "scale"; value: 0.6 }
                        PathLine {
                            x: pathView.width * 0.5
                            y: pathView.height / 2
                        }
                        PathAttribute { name: "z"; value: 100 }
                        PathAttribute { name: "scale"; value: 1.2 }
                        PathLine {
                            x: pathView.width * 1.2
                            y: pathView.height / 2
                        }
                        PathAttribute { name: "z"; value: 0 }
                        PathAttribute { name: "scale"; value: 0.6 }
                    }

                    delegate: Item {
                        id: delegateItem
                        width: pathView.width * 0.25
                        height: pathView.height * 0.85
                        scale: PathView.scale
                        z: PathView.z
                        property bool selected: PathView.isCurrentItem

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: "assets/systems/" + model.shortName + ".jpg"
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            antialiasing: true
                            visible: true
                        }

                        ColorOverlay {
                            anchors.fill: coverImage
                            source: coverImage
                            color: "black"
                            opacity: selected ? 0 : 0.7
                            Behavior on opacity {
                                NumberAnimation { duration: 300 }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: PathView.isCurrentItem ? "white" : "transparent"
                            border.width: 4
                            radius: 10
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 200 }
                        }

                        Behavior on x {
                            NumberAnimation { duration: 200 }
                        }

                        Behavior on y {
                            NumberAnimation { duration: 200 }
                        }
                    }

                    focus: collectionsFocused

                    highlightMoveDuration: 200

                    Keys.onReleased: {
                        if (!root.inButtons) {
                            if (event.key === Qt.Key_Right) {
                                if (currentIndex < model.count - 1) {
                                    currentIndex += 1;
                                }
                            } else if (event.key === Qt.Key_Left) {
                                if (currentIndex > 0) {
                                    currentIndex -= 1;
                                }
                            } else if (event.key === Qt.Key_Up) {
                                favo.forceActiveFocus();
                                root.inButtons = true;
                            }
                        }
                    }

                    Component.onCompleted: {
                        if (model.count > 0) {
                            currentCollectionName = model.get(0).name;
                            currentShortName = model.get(0).shortName;
                            loadCollectionMetadata();
                        }
                    }

                    onCurrentIndexChanged: {
                        const selectedCollection = api.collections.get(currentIndex)
                        pathViewGames.model = selectedCollection.games

                        currentCollectionName = model.get(currentIndex).name;
                        currentShortName = model.get(currentIndex).shortName;
                        loadCollectionMetadata();
                    }
                }

                //Posible pahtview para juegos de la coleccion.!
                PathView {
                    id: pathViewGames
                    width: parent.width
                    height: parent.height
                    anchors.bottom: parent.bottom
                    pathItemCount: 9
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    visible: gamesVisible

                    path: Path {
                        id: pathViewPathGames
                        startX: -pathViewGames.width * 0.2
                        startY: pathViewGames.height / 2
                        PathAttribute { name: "z"; value: 0 }
                        PathAttribute { name: "scale"; value: 0.6 }
                        PathLine {
                            x: pathViewGames.width * 0.5
                            y: pathViewGames.height / 2
                        }
                        PathAttribute { name: "z"; value: 100 }
                        PathAttribute { name: "scale"; value: 1.2 }
                        PathLine {
                            x: pathViewGames.width * 1.2
                            y: pathViewGames.height / 2
                        }
                        PathAttribute { name: "z"; value: 0 }
                        PathAttribute { name: "scale"; value: 0.6 }
                    }

                    delegate: Item {
                        id: delegateItem
                        width: pathViewGames.width * 0.25
                        height: pathViewGames.height * 0.85
                        scale: PathView.scale
                        z: PathView.z
                        property bool selected: PathView.isCurrentItem

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: model.assets.boxFront
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            antialiasing: true
                            visible: true
                        }

                        Text {
                            anchors.centerIn: parent
                            text: game ? game.title : ""
                            color: "white"
                            font.pixelSize: 16
                        }

                        ColorOverlay {
                            anchors.fill: coverImage
                            source: coverImage
                            color: "black"
                            opacity: selected ? 0 : 0.7
                            Behavior on opacity {
                                NumberAnimation { duration: 300 }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: PathView.isCurrentItem ? "white" : "transparent"
                            border.width: 4
                            radius: 10
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 200 }
                        }

                        Behavior on x {
                            NumberAnimation { duration: 200 }
                        }

                        Behavior on y {
                            NumberAnimation { duration: 200 }
                        }
                    }

                    focus: gamesFocused

                    highlightMoveDuration: 200

                    Keys.onReleased: {
                        if (!root.inButtons) {
                            if (event.key === Qt.Key_Right) {
                                if (currentIndex < model.count - 1) {
                                    currentIndex += 1;
                                }
                            } else if (event.key === Qt.Key_Left) {
                                if (currentIndex > 0) {
                                    currentIndex -= 1;
                                }
                            }
                        }
                    }

                    Component.onCompleted: {
                        if (model.count > 0) {
                            //Por si quiero agregar algo al cargar los juegos por ejempli
                        }
                    }

                    onCurrentIndexChanged: {
                        //Por si quiero agregar algo en el currentindex
                        game = pathViewGames.model.get(currentIndex);
                    }
                }
            }
        }
    }

    function loadCollectionMetadata() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "assets/metadata/collections-metadata.txt", false);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var collections = xhr.responseText.split('----------------------------------------');
                var metadataFound = false;
                var systemName = "None";
                var releaseYear = "None";
                var description = "None";
                
                for (var i = 0; i < collections.length; i++) {
                    var collection = collections[i].trim();
                    var shortNameMatch = collection.match(/Short Name: (.+)/);
                    if (shortNameMatch && shortNameMatch[1].trim() === currentShortName) {
                        var systemNameMatch = collection.match(/System Name: (.+)/);
                        var releaseYearMatch = collection.match(/Release Year: (.+)/);
                        var descriptionMatch = collection.match(/Description: (.+(?:\n.+)*)/);
                        
                        systemName = systemNameMatch ? systemNameMatch[1].trim() : "None";
                        releaseYear = releaseYearMatch ? releaseYearMatch[1].trim() : "None";
                        description = descriptionMatch ? descriptionMatch[1].trim() : "None";
                        
                        metadataFound = true;
                        break;
                    }
                }
                
                collectionDes.text = "Release Year: " + releaseYear + "\n" +
                                "" + description;
            }
        }
        xhr.send();
    }
}