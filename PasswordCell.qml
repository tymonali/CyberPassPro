import QtQuick

Rectangle {
    id: root
    property string targetChar: "" // Реальный символ пароля
    property bool isAnimating: false

    width: 35; height: 45
    color: "#1e293b"
    radius: 4
    border.color: isAnimating ? "#f0abfc" : (targetChar === "" ? "#475569" : "#38bdf8") // Розовый при анимации, голубой в покое
    border.width: isAnimating ? 2 : 1
    // Делаем ячейку полупрозрачной, если в ней нет символа
    opacity: targetChar === "" ? 0.3 : 1.0

    // Плавное изменение прозрачности
    Behavior on opacity { NumberAnimation { duration: 200 } }



    Text {
        id: displayText
        anchors.centerIn: parent
        text: targetChar
        color: isAnimating ? "#f0abfc" : "#38bdf8"
        font.pixelSize: 22
        font.bold: true
        font.family: "Monospace"
    }

    // Таймер для перебора символов
    Timer {
        id: scrambleTimer
        interval: 50
        repeat: true
        running: root.isAnimating
        onTriggered: {
            const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
            displayText.text = chars.charAt(Math.floor(Math.random() * chars.length))
        }
    }

    // Запуск анимации при изменении целевого символа
    onTargetCharChanged: {
        if (targetChar !== "") {
            isAnimating = true
            // Каждый квадратик "замирает" с небольшой задержкой для эффекта волны
            stopTimer.interval = 300 + (Math.random() * 500)
            stopTimer.start()
        }
    }

    Timer {
        id: stopTimer
        repeat: false
        onTriggered: {
            root.isAnimating = false
            displayText.text = targetChar
        }
    }
}
