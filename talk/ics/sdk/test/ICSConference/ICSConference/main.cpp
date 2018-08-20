﻿/*
 * Copyright © 2018 Intel Corporation. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
// main.cpp : implementation file
//
#include "ICSConference.h"
#include "qt_windows.h"
#include <QtWidgets/QApplication>
#include <QtTest>
#include "TestSdk.h"


QT_BEGIN_NAMESPACE

#if defined(Q_OS_WINCE)
extern void __cdecl qWinMain(HINSTANCE, HINSTANCE, LPSTR, int, int &, QVector<char *> &);
#else
extern void qWinMain(HINSTANCE, HINSTANCE, LPSTR, int, int &, QVector<char *> &);
#endif

QT_END_NAMESPACE

QT_USE_NAMESPACE


#if defined(QT_NEEDS_QMAIN)
int qMain(int, char **);
#define main qMain
#else
#ifdef Q_OS_WINCE
extern "C" int __cdecl main(int, char **);
#else
extern "C" int main(int, char **);
#endif
#endif

/*
WinMain() - Initializes Windows and calls user's startup function main().
NOTE: WinMain() won't be called if the application was linked as a "console"
application.
*/

#ifndef Q_OS_WINCE

// Convert a wchar_t to char string, equivalent to QString::toLocal8Bit()
// when passed CP_ACP.
static inline char *wideToMulti(int codePage, const wchar_t *aw)
{
    const int required = WideCharToMultiByte(codePage, 0, aw, -1, NULL, 0, NULL, NULL);
    char *result = new char[required];
    WideCharToMultiByte(codePage, 0, aw, -1, result, required, NULL, NULL);
    return result;
}

extern "C" int APIENTRY WinMain(HINSTANCE, HINSTANCE, LPSTR /*cmdParamarg*/, int /* cmdShow */)
{
    int argc;
    wchar_t **argvW = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (!argvW)
        return -1;
    char **argv = new char *[argc + 1];
    for (int i = 0; i < argc; ++i)
        argv[i] = wideToMulti(CP_ACP, argvW[i]);
    argv[argc] = Q_NULLPTR;
    LocalFree(argvW);
    const int exitCode = main(argc, argv);
    for (int i = 0; i < argc && argv[i]; ++i)
        delete[] argv[i];
    delete[] argv;
    return exitCode;
}

#else // !Q_OS_WINCE

int WINAPI WinMain(HINSTANCE instance, HINSTANCE prevInstance, LPWSTR /*wCmdParam*/, int cmdShow)
{
    QByteArray cmdParam = QString::fromWCharArray(GetCommandLine()).toLocal8Bit();

    wchar_t appName[MAX_PATH];
    GetModuleFileName(0, appName, MAX_PATH);
    cmdParam.prepend(QString(QLatin1String("\"%1\" ")).arg(QString::fromWCharArray(appName)).toLocal8Bit());

    int argc = 0;
    QVector<char *> argv(8);
    qWinMain(instance, prevInstance, cmdParam.data(), cmdShow, argc, argv);

    wchar_t uniqueAppID[MAX_PATH];
    GetModuleFileName(0, uniqueAppID, MAX_PATH);
    QString uid = QString::fromWCharArray(uniqueAppID).toLower().replace(QLatin1String("\\"), QLatin1String("_"));

    // If there exists an other instance of this application
    // it will be the owner of a mutex with the unique ID.
    HANDLE mutex = CreateMutex(NULL, TRUE, (LPCWSTR)uid.utf16());
    if (mutex && ERROR_ALREADY_EXISTS == GetLastError()) {
        CloseHandle(mutex);

        // The app is already running, so we use the unique
        // ID to create a unique messageNo, which is used
        // as the registered class name for the windows
        // created. Set the first instance's window to the
        // foreground, else just terminate.
        // Use bitwise 0x01 OR to reactivate window state if
        // it was hidden
        UINT msgNo = RegisterWindowMessage((LPCWSTR)uid.utf16());
        HWND aHwnd = FindWindow((LPCWSTR)QString::number(msgNo).utf16(), 0);
        if (aHwnd)
            SetForegroundWindow((HWND)(((ULONG)aHwnd) | 0x01));
        return 0;
    }

    int result = main(argc, argv.data());
    CloseHandle(mutex);
    return result;
}

#endif // Q_OS_WINCE

int main(int argc, char *argv[])
{
    QString path = argv[0];
    if (argc > 1) {
        //-xml -vs -xunitxml -o join.xml  testPublish_withVideoCodec_shouldSucceed
        CTestSdk tc;
        QTEST_SET_MAIN_SOURCE_PATH
        return QTest::qExec(&tc, argc, argv);
        //QTEST_APPLESS_MAIN(CTestSdk)
        /*QStringList sList;
        QStringList arguments;
        arguments << "-xml" << "-vs" << "-xunitxml" << "-o" << m_xml;
        for (int i = 0; i < CTestSdk.listWidget->count(); i++) {
            QListWidgetItem* item = ui.listWidget->item(i);
            QMap<QString, QVariant> qMap = item->data(Qt::UserRole).toMap();
            QCheckBox * checkBox = (QCheckBox *)(qMap["checkBox"].toInt());
            sList.push_back(checkBox->text());
            arguments.push_back(checkBox->text());
        }
        CTestSdk tc;
        tc.setLogRedirect(false);
        QTest::qExec(&tc, arguments);*/
    }
    QApplication a(argc, argv);
    QStringList strlist = path.split('\\');
    QString    appName = strlist[strlist.size() - 1];
    appName = appName.split('.')[0];
    ICSConference w(appName);
    w.setWindowFlags(w.windowFlags() & ~Qt::WindowMaximizeButtonHint);
    w.setFixedSize(1081, 880);
    w.show();
    return a.exec();
}