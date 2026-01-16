import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window
{
    width: 500
    height: 800
    visible: true
    title: "Cyber Pass Master Pro"
    color: "#0f172a" // Цвет фона (тёмно-синий)

    // Таймер для анимации точек ( . -> .. -> ... )
    Timer {
        id: dotsTimer
        interval: 500
        repeat: true
        property int count: 0
        onTriggered: {
            count = (count + 1) % 4
            let dots = ".".repeat(count)
            resourceInput.text = "🔍 Ищу название" + dots
        }
    }

    // Таймер на 5 секунд (тайм-аут)
    Timer {
        id: timeoutTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (dotsTimer.running) {
                dotsTimer.stop()
                resourceInput.text = "⚠️ Название не определено"
                resourceInput.color = "#f87171" // Подсветим красным
            }
        }
    }

    // Остановка анимации, когда C++ прислал ответ
    Connections {
        target: backend
        onTitleFetched: {
            dotsTimer.stop()
            timeoutTimer.stop()
            resourceInput.color = "white" // Возвращаем обычный цвет
        }
    }

    Menu
    {
        id: contextMenu
        property var targetField: null // Поле, для которого вызвано меню

        MenuItem {
            text: "Копировать"
            enabled: contextMenu.targetField ? contextMenu.targetField.selectedText.length > 0 : false
            onTriggered: contextMenu.targetField.copy()
        }
        MenuItem {
            text: "Вставить"
            enabled: contextMenu.targetField ? contextMenu.targetField.canPaste : false
            onTriggered: contextMenu.targetField.paste()
        }
        MenuItem {
            text: "Выделить всё"
            onTriggered: contextMenu.targetField.selectAll()
        }
    }

    // Слушаем сигналы от нашего C++ класса (backend)
    Connections
    {
        target: backend
        // Когда C++ нашел заголовок сайта, записываем его в поле "Ресурс"
        onTitleFetched: (title) =>
                        {
            resourceInput.text = title
        }
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // Заголовок
        Text
        {
            text: "CYBER PASS PRO"
            font.pixelSize: 28
            font.bold: true
            color: "#38bdf8"
            Layout.alignment: Qt.AlignHCenter
        }

        // Блок ввода ссылки
        ColumnLayout
        {
            Layout.fillWidth: true
            Text { text: "ССЫЛКА (URL)"; color: "#94a3b8"; font.pixelSize: 12 }
            TextField
            {
                id: urlInput
                Layout.fillWidth: true
                placeholderText: "https://example.com"
                color: "white"
                background: Rectangle { color: "#1e293b"; radius: 6; border.color: parent.activeFocus ? "#38bdf8" : "transparent" }

                // Триггер интеллектуального ввода
                onTextChanged: {
                        if (text.includes("http")) {
                            dotsTimer.count = 0
                            dotsTimer.start()
                            timeoutTimer.start()
                            backend.fetchSiteTitle(text)
                        } else if (text === "") {
                            dotsTimer.stop()
                            timeoutTimer.stop()
                            resourceInput.text = ""
                        }
                    }

                // Обработка правой кнопки мыши
                MouseArea
                {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.targetField = parent // Указываем текущее поле
                            contextMenu.popup()
                        }
                    }
                }
            }
        }

        // Блок названия ресурса
        ColumnLayout
        {
            Layout.fillWidth: true
            Text { text: "РЕСУРС"; color: "#94a3b8"; font.pixelSize: 12 }
            TextField {
                id: resourceInput
                Layout.fillWidth: true
                placeholderText: "Название определится само или введите вручную..."
                color: text === "" ? "#fb7185" : "white" // Подсветка розовым, если пусто

                background: Rectangle {
                    color: "#1e293b"
                    radius: 6
                    border.color: parent.text === "" ? "#e11d48" : "#334155" // Красная рамка, если пусто
                    border.width: parent.text === "" ? 2 : 1
                }
            }
        }

        // Поле Ник/Логин
        ColumnLayout
        {
            Layout.fillWidth: true
            Text { text: "НИК / ЛОГИН"; color: "#94a3b8"; font.pixelSize: 12 }
            TextField
            {
                id: nickInput
                Layout.fillWidth: true
                color: "white"
                background: Rectangle { color: "#1e293b"; radius: 6 }

                // Обработка правой кнопки мыши
                MouseArea
                {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.targetField = parent // Указываем текущее поле
                            contextMenu.popup()
                        }
                    }
                }
            }
        }

        // --- НАСТРОЙКИ ГЕНЕРАЦИИ ---
                ColumnLayout
                {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "ДЛИНА ПАРОЛЯ: " + Math.round(lenSlider.value); color: "#94a3b8" }
                    Slider {
                        id: lenSlider
                        Layout.fillWidth: true
                        from: 4
                        to: 12
                        value: 8
                        stepSize: 1

                        // Когда пользователь двигает ползунок рукой
                        onMoved: {
                            // Мы вызываем генерацию пустого пароля или просто сбрасываем свойство в C++,
                            // но проще всего — обнулить строку в бэкенде, если мы добавим туда такой метод.
                            // Но пока можно просто игнорировать отображение символов в ячейке (как мы сделали в Шаге 1).
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        // Расстояние между самими группами "Чекбокс + Текст"
                        spacing: 25
                        CheckBox
                        {
                            id: checkUpper
                            checked: true
                            // Расстояние между иконкой галочки и текстом (уменьшаем)
                            spacing: 5
                            contentItem: Text
                            {
                                text: "A-Z"
                                color: "white"
                                font.pixelSize: 14
                                // Убираем лишние отступы у текста
                                leftPadding: parent.indicator.width + parent.spacing
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        CheckBox
                        {
                            id: checkLower;
                            text: "a-z";
                            checked: true;
                            spacing: 5
                            contentItem: Text
                            {
                                text: "a-z";
                                color: "white";
                                leftPadding: parent.indicator.width + parent.spacing
                            }
                        }

                        CheckBox
                        {
                            id: checkDigits
                            checked: true
                            spacing: 5
                            contentItem: Text {
                                text: "0-9"
                                color: "white"
                                font.pixelSize: 14
                                leftPadding: parent.indicator.width + parent.spacing
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        CheckBox
                        {
                            id: checkSpec
                            checked: true
                            spacing: 5
                            contentItem: Text {
                                text: "(!@#)"
                                color: "white"
                                font.pixelSize: 14
                                leftPadding: parent.indicator.width + parent.spacing
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // Обновленная кнопка генерации (теперь берет данные из настроек)
                Button
                {
                    text: "СГЕНЕРИРОВАТЬ"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    onClicked:
                    {
                        // Проверяем, что хотя бы одна галочка стоит
                        if (!checkUpper.checked && !checkLower.checked &&
                            !checkDigits.checked && !checkSpec.checked) {

                            errorDialog.open() // Показываем окно ошибки
                        } else {
                            // Передаем все 4 параметра в C++
                            backend.generate(lenSlider.value,
                                             checkUpper.checked,
                                             checkLower.checked,
                                             checkDigits.checked,
                                             checkSpec.checked)
                        }
                    }
                }

                Dialog
                {
                    id: errorDialog
                    title: "Ошибка конфигурации"
                    anchors.centerIn: parent
                    standardButtons: Dialog.Ok
                    modal: true

                    Text
                    {
                        text: "Выберите хотя бы один тип символов для генерации!"
                        color: "black"
                        padding: 20
                    }
                }

                // --- ВИЗУАЛИЗАЦИЯ (она у тебя уже есть, оставляем) ---
                // ... твой код с Repeater ...

                // КНОПКА СОХРАНЕНИЯ
                Button {
                    text: "СОХРАНИТЬ В БАЗУ (.TXT)"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    enabled: backend.lastPassword !== "" // Активна, только если пароль есть

                    background: Rectangle {
                        color: parent.pressed ? "#064e3b" : "#10b981" // Зеленый цвет для сохранения
                        radius: 6
                    }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

                    onClicked: {
                        let success = backend.saveToFile(resourceInput.text, urlInput.text, nickInput.text, backend.lastPassword)
                        if (success) {
                            console.log("Сохранено!")
                            // Можно очистить поля после сохранения для удобства
                            resourceInput.text = ""
                            urlInput.text = ""
                            nickInput.text = ""
                        }
                    }
                }

                Button {
                    text: "ОЧИСТИТЬ ФОРМУ"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    // Стилизуем под "второстепенную" кнопку
                    background: Rectangle {
                        color: "transparent"
                        border.color: parent.pressed ? "#f0abfc" : "#475569"
                        radius: 6
                    }

                    contentItem: Text {
                        text: parent.text
                        color: parent.pressed ? "#f0abfc" : "#94a3b8"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        // 1. Очищаем все текстовые поля
                        urlInput.text = ""
                        resourceInput.text = ""
                        nickInput.text = ""

                        // 2. Сбрасываем пароль (чтобы ячейки стали пустыми)
                        backend.generate(0, false, false, false, false)

                        // 3. ПЕРЕВОДИМ ФОКУС (самое важное для удобства)
                        urlInput.forceActiveFocus()
                    }
                }

                // --- ОБНОВЛЕННАЯ ВИЗУАЛИЗАЦИЯ ПАРОЛЯ ---
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            color: "#020617"
                            radius: 10
                            border.color: "#1e293b"

                            Flow { // Flow лучше чем Row, если пароль станет длинным
                                anchors.centerIn: parent
                                spacing: 8
                                width: parent.width - 40
                                layoutDirection: Qt.LeftToRight

                                Repeater {
                                    //model: backend.lastPassword.length
                                    // Теперь количество квадратиков всегда равно значению слайдера
                                        model: Math.round(lenSlider.value)

                                    // Используем наш новый хакерский компонент
                                    PasswordCell {
                                            // Логика отображения символа:
                                            // Если длина пароля в бэкенде совпадает с текущим количеством слотов,
                                            // показываем символ. Иначе (при движении ползунка) — оставляем пустым.
                                            targetChar: (backend.lastPassword.length === Math.round(lenSlider.value))
                                                        ? backend.lastPassword[index]
                                                        : ""
                                        }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 5

                            // Надпись "Скопировано!", которая изначально невидима
                            Text {
                                id: copyNotify
                                text: "Скопировано!"
                                color: "#10b981" // Зеленый
                                font.bold: true
                                opacity: 0
                                Layout.alignment: Qt.AlignHCenter

                                // Анимация прозрачности
                                NumberAnimation on opacity {
                                    id: notifyAnim
                                    from: 1; to: 0; duration: 1500; easing.type: Easing.InQuad
                                }
                            }

                            Button {
                                text: "КОПИРОВАТЬ ПАРОЛЬ"
                                Layout.preferredWidth: 200
                                onClicked: {
                                    if (backend.lastPassword === "") {
                                        // Если пароль не сгенерирован — показываем системное предупреждение
                                        emptyPassDialog.open()
                                    } else {
                                        backend.copyToClipboard(backend.lastPassword)
                                        notifyAnim.restart() // Запускаем надпись "Скопировано!"
                                    }
                                }
                            }
                        }

                        // Диалоговое окно предупреждения
                        Dialog {
                            id: emptyPassDialog
                            title: "Внимание"
                            standardButtons: Dialog.Ok
                            anchors.centerIn: parent
                            modal: true

                            Text {
                                text: "Сначала сгенерируйте пароль!"
                                padding: 20
                                color: "black"
                            }
                        }

                        //Button
                        //{
                        //    text: "КОПИРОВАТЬ ПАРОЛЬ"
                        //    Layout.alignment: Qt.AlignHCenter
                        //    Layout.preferredWidth: 200
                        //    flat: true // Делаем её более аккуратной
//
                        //    contentItem: Text
                        //    {
                        //        text: parent.text
                        //        color: parent.pressed ? "#f0abfc" : "#38bdf8"
                        //        font.bold: true
                        //        horizontalAlignment: Text.AlignHCenter
                        //    }
//
                        //    onClicked:
                        //    {
                        //        // Копирование в буфер обмена
                        //        backend.copyToClipboard(backend.lastPassword)
                        //    }
                        //
                        //
                        //}
        // Кнопка Генерации
//        Button {
//            text: "СГЕНЕРИРОВАТЬ"
//            Layout.fillWidth: true
//            Layout.preferredHeight: 50
//            contentItem: Text {
//                text: parent.text
//                color: "white"
//                font.bold: true
//                horizontalAlignment: Text.AlignHCenter
//                verticalAlignment: Text.AlignVCenter
//            }
//            background: Rectangle {
//                color: parent.pressed ? "#075985" : "#0ea5e9"
//                radius: 6
//            }
//            onClicked: backend.generate(12, true, true, true, true)
//        }
//
//        Item { Layout.fillHeight: true } // Распорка
    }

    Shortcut
    {
        sequence: "StandardKey.Copy" // Это умный способ Qt понимать Ctrl+C на любой раскладке
        onActivated:
        {
            if (backend.lastPassword !== "")
            {
                backend.copyToClipboard(backend.lastPassword)
                notifyAnim.restart()
            }
        }
    }
}
