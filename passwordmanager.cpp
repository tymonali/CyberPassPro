#include "passwordmanager.h"
#include <QRegularExpression>

#include <QClipboard>
#include <QGuiApplication>

#include <QFile>
#include <QTextStream>
#include <QDateTime>

#include <utility>

PasswordManager::PasswordManager(QObject *parent)
    : QObject{parent}, m_networkManager(new QNetworkAccessManager(this)) {}

void PasswordManager::setManualPassword(const QString &password) {
    if (password.isEmpty()) return;
    m_lastPassword = password;
    emit passwordChanged();
}

void PasswordManager::generate(int length, bool upper, bool lower, bool digits, bool special) {
    if (length <= 0) {
        m_lastPassword = "";
        emit passwordChanged();
        return;
    }
    QString charset;
    if (upper)   charset += "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    if (lower)   charset += "abcdefghijklmnopqrstuvwxyz";
    if (digits)  charset += "0123456789";

    // Если выбраны только спецсимволы, добавляем их в общий набор
    if (special && charset.isEmpty()) {
        charset = m_safeSet;
    }

    if (charset.isEmpty()) {
        m_lastPassword = "";
        emit passwordChanged();
        return;
    }

    QString result;
    // 1. Сначала генерируем весь пароль из доступного набора (charset)
    for (int i = 0; i < length; ++i) {
        int index = QRandomGenerator::global()->bounded(charset.length());
        result += charset.at(index);
    }

    // 2. Если галочка "спецсимволы" стоит, но в пароле их ещё нет
    // (потому что в наборе были и буквы/цифры), принудительно заменяем один символ
    if (special) {
        bool hasSpecial = false;
        for (const QChar &c : std::as_const(result)) {
            if (m_safeSet.contains(c)) {
                hasSpecial = true;
                break;
            }
        }

        if (!hasSpecial) {
            int pos = QRandomGenerator::global()->bounded(result.length());
            int specIndex = QRandomGenerator::global()->bounded(m_safeSet.length());
            result.replace(pos, 1, m_safeSet.at(specIndex));
        }
    }

    m_lastPassword = result;
    emit passwordChanged();
}

void PasswordManager::fetchSiteTitle(const QString &urlString) {
    QUrl url(urlString);
    if (!url.isValid()) return;

    QNetworkRequest request(url);
    // Представимся браузером, чтобы сайты не блокировали запрос
    request.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_networkManager->get(request);

    connect(reply, &QNetworkReply::finished, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            QString html = QString::fromUtf8(reply->readAll());

            // Улучшенная регулярка: ищет заголовок, игнорируя регистр и работая с несколькими строками
            QRegularExpression re("<title[^>]*>(.*?)<\\/title>",
                                  QRegularExpression::CaseInsensitiveOption |
                                      QRegularExpression::DotMatchesEverythingOption);

            auto match = re.match(html);
            if (match.hasMatch()) {
                QString title = match.captured(1).trimmed();
                title.replace("&amp;", "&").replace("&quot;", "\"").replace("&#39;", "'");

                // Убираем дефис [-] из списка, оставляем только серьезные знаки:
                // двоеточие, точку, запятую, вертикальную черту и длинные тире
                QRegularExpression separator("[:.,|—–]");
                auto sepMatch = separator.match(title);

                if (sepMatch.hasMatch()) {
                    title = title.left(sepMatch.capturedStart()).trimmed();
                }

                // Если всё же получилось слишком длинно (больше 40 символов) — мягко обрезаем
                if (title.length() > 40) {
                    title = title.left(37) + "...";
                }

                emit titleFetched(title);
            } else {
                // Если тег title не найден, попробуем хотя бы вытащить домен
                emit titleFetched(QUrl(reply->url()).host());
            }
        }
        reply->deleteLater();
    });
}

bool PasswordManager::saveToFile(QString resource, QString url, QString nick, QString password, bool isOld)
{
    QFile file("passwords.txt");
    // Открываем для добавления (Append)
    if (!file.open(QIODevice::Append | QIODevice::Text)) return false;

    QTextStream out(&file);

    // В Qt 6 вместо setCodec используем setEncoding
    out.setEncoding(QStringConverter::Utf8);

    QString dateStr = isOld ? "Давно" : QDateTime::currentDateTime().toString("dd.MM.yyyy hh:mm");

    // Формат: Дата | Ресурс | Ссылка | Ник | Пароль
    out << dateStr << " | "
        << (resource.isEmpty() ? "Нет названия" : resource) << " | "
        << (url.isEmpty() ? "Нет ссылки" : url) << " | "
        << (nick.isEmpty() ? "Аноним" : nick) << " | "
        << password << Qt::endl; // В Qt 6 лучше использовать Qt::endl вместо \n для очистки буфера

    file.close();
    return true;
}

void PasswordManager::copyToClipboard(const QString &text) {
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(text);
}
