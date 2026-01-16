#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "passwordmanager.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    PasswordManager pwdManager;
    QQmlApplicationEngine engine;

    // Регистрация бэкенда для QML
    engine.rootContext()->setContextProperty("backend", &pwdManager);

    // В Qt 6 путь к главному файлу обычно выглядит так:
    const QUrl url(u"qrc:/qt/qml/CyberPassPro/Main.qml"_s);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
