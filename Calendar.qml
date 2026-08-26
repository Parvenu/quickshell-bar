pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
    id: root

    required property var theme
    required property var clock

    readonly property int contentPadding: 8
    readonly property int dayCellHeight: 24
    readonly property string protonCalendarUrl: "https://calendar.proton.me"
    readonly property var weekdayLabels: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property int displayedYear: displayedMonth.getFullYear()
    readonly property int displayedMonthIndex: displayedMonth.getMonth()
    readonly property int firstWeekday: (new Date(displayedYear, displayedMonthIndex, 1).getDay() + 6) % 7
    readonly property var frenchHolidays: buildFrenchHolidays(displayedYear)

    property date displayedMonth: new Date(
        root.clock.date.getFullYear(),
        root.clock.date.getMonth(),
        1
    )

    signal openProtonRequested(string url)

    function changeMonth(offset: int): void {
        displayedMonth = new Date(displayedYear, displayedMonthIndex + offset, 1)
    }

    function dateForCell(index: int): date {
        return new Date(displayedYear, displayedMonthIndex, index - firstWeekday + 1)
    }

    function isSameDate(left: date, right: date): bool {
        return left.getFullYear() === right.getFullYear()
            && left.getMonth() === right.getMonth()
            && left.getDate() === right.getDate()
    }

    function protonWeekUrl(selectedDate: date): string {
        return root.protonCalendarUrl
            + "/u/0/week/"
            + selectedDate.getFullYear()
            + "/"
            + (selectedDate.getMonth() + 1)
            + "/"
            + selectedDate.getDate()
    }

    function dateKey(selectedDate: date): string {
        return selectedDate.getFullYear()
            + "-"
            + (selectedDate.getMonth() + 1)
            + "-"
            + selectedDate.getDate()
    }

    function addDays(selectedDate: date, offset: int): date {
        return new Date(
            selectedDate.getFullYear(),
            selectedDate.getMonth(),
            selectedDate.getDate() + offset
        )
    }

    function easterSunday(year: int): date {
        const a = year % 19
        const b = Math.floor(year / 100)
        const c = year % 100
        const d = Math.floor(b / 4)
        const e = b % 4
        const f = Math.floor((b + 8) / 25)
        const g = Math.floor((b - f + 1) / 3)
        const h = (19 * a + b - d - g + 15) % 30
        const i = Math.floor(c / 4)
        const k = c % 4
        const l = (32 + 2 * e + 2 * i - h - k) % 7
        const m = Math.floor((a + 11 * h + 22 * l) / 451)
        const month = Math.floor((h + l - 7 * m + 114) / 31)
        const day = (h + l - 7 * m + 114) % 31 + 1
        return new Date(year, month - 1, day)
    }

    function addFrenchPublicHolidays(holidays, year): void {
        const fixedHolidays = [
            [0, 1, "Jour de l’An"],
            [4, 1, "Fête du Travail"],
            [4, 8, "Victoire 1945"],
            [6, 14, "Fête nationale"],
            [7, 15, "Assomption"],
            [10, 1, "Toussaint"],
            [10, 11, "Armistice 1918"],
            [11, 25, "Noël"]
        ]

        for (let index = 0; index < fixedHolidays.length; ++index) {
            const holiday = fixedHolidays[index]
            const selectedDate = new Date(year, holiday[0], holiday[1])
            holidays[root.dateKey(selectedDate)] = holiday[2]
        }

        const easter = root.easterSunday(year)
        holidays[root.dateKey(root.addDays(easter, 1))] = "Lundi de Pâques"
        holidays[root.dateKey(root.addDays(easter, 39))] = "Ascension"
        holidays[root.dateKey(root.addDays(easter, 50))] = "Lundi de Pentecôte"
    }

    function buildFrenchHolidays(centerYear) {
        const holidays = {}
        for (let year = centerYear - 1; year <= centerYear + 1; ++year)
            root.addFrenchPublicHolidays(holidays, year)
        return holidays
    }

    function frenchHolidayName(selectedDate: date): string {
        return root.frenchHolidays[root.dateKey(selectedDate)] ?? ""
    }

    implicitWidth: 252
    implicitHeight: calendarContent.implicitHeight + root.contentPadding * 2
    radius: root.theme.smallRadius
    color: root.theme.controlBackground

    Column {
        id: calendarContent

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.contentPadding
        }
        spacing: 4

        Item {
            width: parent.width
            height: root.theme.controlHeight

            DrawerActionButton {
                id: previousMonthButton

                anchors.left: parent.left
                theme: root.theme
                glyph: ""
                onClicked: root.changeMonth(-1)
            }

            Rectangle {
                id: monthLauncher

                anchors {
                    left: previousMonthButton.right
                    right: nextMonthButton.left
                    leftMargin: 2
                    rightMargin: 2
                }
                height: root.theme.controlHeight
                radius: root.theme.smallRadius
                color: monthLauncherMouse.containsMouse ? root.theme.controlHover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: root.theme.animationFast }
                }

                Text {
                    anchors.fill: parent
                    text: "  " + Qt.formatDate(root.displayedMonth, "MMMM yyyy") + "  ↗"
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: monthLauncherMouse.containsMouse
                        ? root.theme.drawerLauncherActive
                        : root.theme.drawerTitle
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: monthLauncherMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openProtonRequested(root.protonCalendarUrl)
                }
            }

            DrawerActionButton {
                id: nextMonthButton

                anchors.right: parent.right
                theme: root.theme
                glyph: ""
                onClicked: root.changeMonth(1)
            }
        }

        Row {
            id: weekdayRow

            readonly property real cellWidth: (width - spacing * 6) / 7

            width: parent.width
            height: 18
            spacing: 2

            Repeater {
                model: root.weekdayLabels.length

                delegate: Text {
                    required property int index

                    width: weekdayRow.cellWidth
                    height: weekdayRow.height
                    text: root.weekdayLabels[index]
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.theme.textMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1
                    font.weight: Font.DemiBold
                }
            }
        }

        Grid {
            id: dayGrid

            readonly property real cellWidth: (width - spacing * 6) / 7

            width: parent.width
            height: root.dayCellHeight * 6 + spacing * 5
            columns: 7
            spacing: 2

            Repeater {
                model: 42

                delegate: Rectangle {
                    id: dayCell

                    required property int index

                    readonly property date representedDate: root.dateForCell(index)
                    readonly property bool inDisplayedMonth: representedDate.getFullYear() === root.displayedYear
                        && representedDate.getMonth() === root.displayedMonthIndex
                    readonly property bool isToday: root.isSameDate(representedDate, root.clock.date)
                    readonly property bool isHoliday: root.frenchHolidayName(representedDate).length > 0

                    width: dayGrid.cellWidth
                    height: root.dayCellHeight
                    radius: root.theme.smallRadius
                    color: dayCellMouse.containsMouse ? root.theme.controlHover : "transparent"
                    border.width: dayCell.isToday ? 1 : 0
                    border.color: root.theme.drawerLauncherActive

                    Text {
                        anchors.fill: parent
                        text: dayCell.representedDate.getDate()
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: dayCell.isHoliday
                            ? root.theme.calendarHoliday
                            : dayCell.isToday
                                ? root.theme.textPrimary
                                : dayCell.inDisplayedMonth
                                    ? root.theme.textPrimary
                                    : root.theme.textMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.weight: dayCell.isToday ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: dayCellMouse

                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openProtonRequested(
                            root.protonWeekUrl(dayCell.representedDate)
                        )
                    }
                }
            }
        }
    }
}
