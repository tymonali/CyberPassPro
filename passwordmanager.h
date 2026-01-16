#ifndef PASSWORDMANAGER_H
#define PASSWORDMANAGER_H

#include <QObject>
#include <QString>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class PasswordManager : public QObject
{
    Q_OBJECT
    // Позволяет QML читать пароль через backend.lastPassword
    Q_PROPERTY(QString lastPassword READ lastPassword NOTIFY passwordChanged)

public:
    explicit PasswordManager(QObject *parent = nullptr);

    Q_INVOKABLE void copyToClipboard(const QString &text);

    // Метод для генерации
    Q_INVOKABLE void generate(int length, bool upper, bool lower, bool digits, bool special);

    // Метод для парсинга заголовка сайта
    Q_INVOKABLE void fetchSiteTitle(const QString &url);

    // Добавь эту строку (убедись, что аргументы совпадают с .cpp):
    Q_INVOKABLE bool saveToFile(QString resource, QString url, QString nick, QString password, bool isOld = false);

    QString lastPassword() const { return m_lastPassword; }

signals:
    void passwordChanged();
    void titleFetched(const QString &title);

private:
    QString m_lastPassword;
    QNetworkAccessManager *m_networkManager;
    const QString m_safeSet = "!@#$%^&*()_+-=[]{};:,./<>?";
};

#endif // PASSWORDMANAGER_H
