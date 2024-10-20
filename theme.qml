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
    property bool proxyVisible: false
    property bool proxyFocused: false
    property string gameTitle: ""
    property string collectionDescription: ""
    property string gameDescription: ""
    property string lastFocusedView: "collections"

    Audio {
        id: backgroundMusic
        source: "assets/audio/background7.wav"
        loops: Audio.Infinite
        autoPlay: true
        volume: 1.0
    }

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

        SortFilterProxyModel {
            id: historyProxyModel
            sourceModel: api.allGames
            sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
        }

        SortFilterProxyModel {
            id: favoritesProxyModel
            sourceModel: api.allGames
            filters: ValueFilter { roleName: "favorite"; value: true }
        }

        ListModel {
            id: continuePlayingProxyModel
            Component.onCompleted: {
                var currentDate = new Date()
                var sevenDaysAgo = new Date(currentDate.getTime() - 7 * 24 * 60 * 60 * 1000)
                for (var i = 0; i < historyProxyModel.count; ++i) {
                    var game = historyProxyModel.get(i)
                    var lastPlayedDate = new Date(game.lastPlayed)
                    var playTimeInMinutes = game.playTime / 60
                    if (lastPlayedDate >= sevenDaysAgo && playTimeInMinutes > 1) {
                        continuePlayingProxyModel.append(game)
                    }
                }
            }
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
                    visible: collectionsVisible || gamesVisible
                }

                Text {
                    id: collectionName
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: wellcomeTo.bottom
                    anchors.topMargin: 10
                    text: pathViewGames.visible && pathViewGames.focus ? gameTitle : currentCollectionName
                    color: "white"
                    font.family: fontLoaderName.name
                    font.pixelSize: parent.width * 0.030
                    font.bold: false
                    visible: collectionsVisible || gamesVisible
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
                        text: pathViewGames.visible && pathViewGames.focus ? gameDescription : collectionDescription
                        visible: collectionsVisible || gamesVisible
                    }
                }

                Row {
                    id: buttons
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: parent.width * 0.02
                    visible: collectionsVisible || gamesVisible

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

                    Keys.onRightPressed: {
                        if (root.inButtons && favo.focus) {
                            cont.forceActiveFocus();
                            event.accepted = true;
                        }
                    }

                    Keys.onLeftPressed: {
                        if (root.inButtons && cont.focus) {
                            favo.forceActiveFocus();
                            event.accepted = true;
                        }
                    }

                    Keys.onDownPressed: {
                        if (root.inButtons) {
                            if (root.lastFocusedView === "collections") {
                                pathView.forceActiveFocus();
                            } else if (root.lastFocusedView === "games") {
                                pathViewGames.forceActiveFocus();
                            }
                            root.inButtons = false;
                            event.accepted = true;
                        }
                    }


                    Keys.onPressed: {
                        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            if (favo.focus) {
                                collectionsVisible = false;
                                collectionsFocused = false;
                                gamesVisible = false
                                gamesFocused = false
                                proxyVisible = true;
                                proxyFocused = true;
                                gridView.model = favoritesProxyModel;
                            } else if (cont.focus) {
                                collectionsVisible = false;
                                collectionsFocused = false;
                                gamesVisible = false
                                gamesFocused = false
                                proxyVisible = true;
                                proxyFocused = true;
                                gridView.model = continuePlayingProxyModel;
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
                    opacity: collectionsVisible ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }

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

                        /*ColorOverlay {
                            anchors.fill: coverImage
                            source: coverImage
                            color: "black"
                            opacity: selected ? 0 : 0.7
                            Behavior on opacity {
                                NumberAnimation { duration: 300 }
                            }
                        }*/

                        ColorOverlay {
                            anchors.fill: coverImage
                            source: coverImage
                            color: "black"

                            // Cambiamos la opacidad según si la colección está seleccionada y si el PathView tiene el foco
                            opacity: selected && pathView.focus ? 0 : 0.7

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
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
                                root.lastFocusedView = "collections";
                            }
                        }
                    }

                    Keys.onPressed: {
                        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            event.accepted = true;
                            if (collectionsVisible && collectionsFocused) {
                                collectionsVisible = false
                                collectionsFocused = false
                                gamesVisible = true
                                gamesFocused = true
                                pathViewGames.forceActiveFocus()
                            }
                        }
                    }

                    onCurrentIndexChanged: {
                        const selectedCollection = api.collections.get(currentIndex);
                        pathViewGames.model = selectedCollection.games;

                        currentCollectionName = model.get(currentIndex).name;
                        currentShortName = model.get(currentIndex).shortName;
                        loadCollectionMetadata();
                        
                        if (pathViewGames.model.count > 0) {
                            game = pathViewGames.model.get(0);
                            gameTitle = game ? game.title : "";

                            if (game && game.description) {
                                var firstDotIndex = game.description.indexOf(".");
                                var secondDotIndex = game.description.indexOf(".", firstDotIndex + 1);
                                if (secondDotIndex !== -1) {
                                    gameDescription = game.description.substring(0, secondDotIndex + 1);
                                } else {
                                    gameDescription = game.description;
                                }
                            } else {
                                gameDescription = "";
                            }
                        } else {
                            game = null;
                            gameTitle = "";
                            gameDescription = "";
                        }
                    }

                    Component.onCompleted: {
                        if (model.count > 0) {
                            currentCollectionName = model.get(0).name;
                            currentShortName = model.get(0).shortName;
                            loadCollectionMetadata();

                            const initialCollection = api.collections.get(0);
                            pathViewGames.model = initialCollection.games;

                            if (pathViewGames.model.count > 0) {
                                game = pathViewGames.model.get(0);
                                gameTitle = game ? game.title : "";

                                // Recorta la descripción del juego a las primeras dos oraciones
                                if (game && game.description) {
                                    var firstDotIndex = game.description.indexOf(".");
                                    var secondDotIndex = game.description.indexOf(".", firstDotIndex + 1);
                                    if (secondDotIndex !== -1) {
                                        gameDescription = game.description.substring(0, secondDotIndex + 1);
                                    } else {
                                        gameDescription = game.description;
                                    }
                                } else {
                                    gameDescription = "";
                                }
                            } else {
                                game = null;
                                gameTitle = "";
                                gameDescription = "";
                            }
                        }
                    }
                }

                PathView {
                    id: pathViewGames
                    width: parent.width
                    height: parent.height
                    anchors.bottom: parent.bottom
                    pathItemCount: 9
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    opacity: gamesVisible ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }

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
                        Rectangle {
                            id: favoriteIcon
                            width: parent.width * 0.3
                            height: parent.height * 0.1
                            anchors.bottom: parent.bottom
                            //anchors.left: parent.left
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "white"
                            radius: 5
                            anchors.margins: 8
                            visible: model.favorite

                            Image{
                                source: "assets/icons/favo.png"
                                width: parent.height * 0.8
                                height: parent.height * 0.8
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                        }

                        ColorOverlay {
                            id: overlayblack
                            anchors.fill: coverImage
                            source: coverImage
                            color: "black"
                            opacity: selected && pathViewGames.focus ? 0 : 0.7

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
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

                    onCurrentIndexChanged: {
                        game = pathViewGames.model.get(currentIndex);
                        gameTitle = game ? game.title : "";

                        // Recorta la descripción del juego a las primeras dos oraciones
                        if (game && game.description) {
                            var firstDotIndex = game.description.indexOf(".");
                            var secondDotIndex = game.description.indexOf(".", firstDotIndex + 1);
                            if (secondDotIndex !== -1) {
                                gameDescription = game.description.substring(0, secondDotIndex + 1);
                            } else {
                                gameDescription = game.description;
                            }
                        } else {
                            gameDescription = "";
                        }
                    }

                    SoundEffect {
                        id: favSound
                        source: "assets/audio/Fav.wav"
                        volume: 0.5
                    }

                    Keys.onPressed: {
                        if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                            event.accepted = true;
                            if (gamesVisible && gamesFocused) {
                                gamesVisible = false
                                gamesFocused = false
                                collectionsVisible = true
                                collectionsFocused = true
                                pathView.forceActiveFocus()
                            }
                        } else if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            event.accepted = true;
                            game.launch();
                        } else if (!event.isAutoRepeat && api.keys.isDetails(event)) {
                            favSound.play();
                            var selectedGame = pathViewGames.model.get(pathViewGames.currentIndex);
                            var collectionName = getNameCollecForGame(selectedGame);
                            for (var i = 0; i < api.collections.count; ++i) {
                                var collection = api.collections.get(i);
                                if (collection.name === collectionName) {
                                    for (var j = 0; j < collection.games.count; ++j) {
                                        var gamefound = collection.games.get(j);
                                        if (gamefound.title === selectedGame.title) {
                                            gamefound.favorite = !gamefound.favorite;
                                            updateContinuePlayingModel();
                                            break;
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }


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
                                root.lastFocusedView = "games";
                            }
                        }
                    }
                }
            }
        }
    
        Item {
            id: gridViewProxymodel
            width: parent.width * 0.90
            height: parent.height * 0.90
            anchors.centerIn: parent
            
            GridView {
                id: gridView
                anchors.fill: parent
                cellWidth: (gridView.model === favoritesProxyModel) ? parent.width / 4 : parent.width / 4
                cellHeight: (gridView.model === favoritesProxyModel) ? parent.height / 2 : parent.height / 4

                opacity: proxyVisible ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                delegate: Item {
                    width: gridView.cellWidth * 0.90
                    height: gridView.cellHeight * 0.90
                    z: GridView.isCurrentItem ? 1 : 0 

                    scale: GridView.isCurrentItem ? 1.2 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200 } }

                    OpacityMask {
                        anchors.fill: parent
                        source: Image {
                            source: (gridView.model === favoritesProxyModel) ? model.assets.boxFront : model.assets.screenshot
                            fillMode: Image.PreserveAspectFit
                        }

                        maskSource: Rectangle {
                            width: gridView.cellWidth
                            height: gridView.cellHeight
                            radius: 20
                            color: "white"
                        }

                        Rectangle {
                            id: favoriteView
                            width: parent.width * 0.2
                            height: parent.height * 0.2
                            color: "white"
                            radius: 5
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 8
                            visible: gridView.model === favoritesProxyModel 
                            Image{
                                source: "assets/icons/favo.png"
                                width: parent.height * 0.5
                                height: parent.height * 0.5
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                        }

                        Rectangle {
                            id: playTimeview
                            width: parent.width * 0.3
                            height: parent.height * 0.2
                            color: "white"
                            radius: 5
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 8
                            visible: gridView.model === continuePlayingProxyModel 

                            Image {
                                    source: "assets/icons/play.png"
                                    width: parent.height * 0.6
                                    height: parent.height * 0.6
                                    anchors.verticalCenter: parent.verticalCenter                                  
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                            }

                            Text {
                                anchors.centerIn: parent
                                text: model ? "" + formatPlayTime(model.playTime) : ""
                                color: "#666b6a"
                                font.pixelSize: parent.height * 0.4 
                                font.bold: true
                            }
                        }
                    }
                }

                Text {
                    id: noGamesText
                    anchors.centerIn: parent
                    visible: gridView.model && gridView.model.count > 0 ? false : true
                    text: "No games available, please go back."
                    font.pixelSize: 20
                    color: "lightgray"
                    font.family: fontLoaderDesc.name
                }


                property int countPerRow: 4
                property int countPerColumn: 4
                property int count: countPerRow * countPerColumn

                focus: proxyFocused

                Keys.onPressed: {
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true;
                        var selectedGame = gridView.model.get(gridView.currentIndex);
                        var collectionName = getNameCollecForGame(selectedGame);
                        for (var i = 0; i < api.collections.count; ++i) {
                            var collection = api.collections.get(i);
                            if (collection.name === collectionName) {
                                for (var j = 0; j < collection.games.count; ++j) {
                                    var game = collection.games.get(j);
                                    if (game.title === selectedGame.title) {
                                        game.launch();
                                        break;
                                    }
                                }
                                break;
                            }
                        }
                    } else if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                        event.accepted = true;
                        proxyVisible = false;
                        proxyFocused = false;

                        if (root.lastFocusedView === "collections") {
                            collectionsVisible = true;
                            collectionsFocused = true;
                        } else if (root.lastFocusedView === "games") {
                            gamesVisible = true;
                            gamesFocused = true;
                        }

                        favo.forceActiveFocus();
                        root.inButtons = true;
                    }
                }

                onCurrentItemChanged: {
    
                }

                Component.onCompleted: {
                    gridView.currentIndex = 0;
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
                
                collectionDescription = "Release Year: " + releaseYear + "\n" +
                                        "" + description;
            }
        }
        xhr.send();
    }
    
    function getNameCollecForGame(game) {
        if (game && game.collections && game.collections.count > 0) {
            var firstCollection = game.collections.get(0);
            for (var i = 0; i < api.collections.count; ++i) {
                var collection = api.collections.get(i);
                if (collection.name === firstCollection.name) {
                    return collection.name;
                }
            }
        }
        return "default";
    }
    
    function formatPlayTime(seconds) {
        if (seconds <= 0) return "0 min";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        if (hours > 0) {
            return hours + " h " + (minutes > 0 ? minutes + " m" : ""); 
        } else {
            return minutes + " min";
        }
    }

    function updateContinuePlayingModel() {
        continuePlayingProxyModel.clear();

        var currentDate = new Date();
        var sevenDaysAgo = new Date(currentDate.getTime() - 7 * 24 * 60 * 60 * 1000);

        for (var i = 0; i < historyProxyModel.count; ++i) {
            var game = historyProxyModel.get(i);
            var lastPlayedDate = new Date(game.lastPlayed);
            var playTimeInMinutes = game.playTime / 60;

            if (lastPlayedDate >= sevenDaysAgo && playTimeInMinutes > 1) {
                continuePlayingProxyModel.append(game);
            }
        }
    }
}
