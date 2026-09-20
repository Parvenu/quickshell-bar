pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    signal toastRequested(var notification)

    property var items: []
    readonly property int count: items.length
    readonly property int unreadCount: _unreadCount
    property bool dnd: Boolean(persistentState.persistedDnd)

    onDndChanged: {
        if (persistentState.persistedDnd !== dnd)
            persistentState.persistedDnd = dnd
    }

    readonly property int defaultLowTimeoutMs: 5000
    readonly property int defaultNormalTimeoutMs: 10000

    property int _unreadCount: 0
    property var _keyById: ({})
    property var _ownerIdByKey: ({})
    property var _pendingUpdateIds: ({})

    function toggleDnd(): void {
        dnd = !dnd
    }

    function markAllRead(): void {
        const records = Object.assign({}, persistentState.records ?? {})
        let changed = false

        for (const notification of items.slice()) {
            if (!notification)
                continue

            const key = _storedKey(notification)
            const record = records[key]
            if (record && !record.read) {
                records[key] = Object.assign({}, record, { read: true })
                changed = true
            }
        }

        if (changed)
            persistentState.records = records
        _recalculateUnread()
    }

    function markRead(notification): void {
        if (!notification || notification.transient)
            return

        const key = _storedKey(notification)
        const record = _record(key)
        if (!record || record.read)
            return

        _setRecord(key, Object.assign({}, record, { read: true }))
        _recalculateUnread()
    }

    function isUnread(notification): bool {
        if (!notification || notification.transient || items.indexOf(notification) === -1)
            return false

        const record = _record(_storedKey(notification))
        return record ? !record.read : false
    }

    function dismissAll(): void {
        const active = server.trackedNotifications.values.slice()
        for (const notification of active) {
            if (_isActive(notification))
                notification.dismiss()
        }
    }

    function dismiss(notification): bool {
        if (!_isActive(notification))
            return false

        notification.dismiss()
        return true
    }

    function defaultAction(notification): var {
        if (!_isActive(notification))
            return null

        for (const action of notification.actions) {
            if (action.identifier === "default")
                return action
        }

        return null
    }

    function invokeDefault(notification): bool {
        const action = defaultAction(notification)
        if (action)
            return invokeAction(notification, action)

        return dismiss(notification)
    }

    function invokeAction(notification, action): bool {
        if (!_isActive(notification) || !action
                || notification.actions.indexOf(action) === -1)
            return false

        action.invoke()
        return true
    }

    function sendInlineReply(notification, text): bool {
        if (!_isActive(notification) || !notification.hasInlineReply)
            return false

        notification.sendInlineReply(String(text ?? ""))
        return true
    }

    function receivedAt(notification): real {
        if (!notification)
            return 0

        const record = _record(_storedKey(notification))
        return record ? Number(record.receivedAt ?? 0) : 0
    }

    function notificationKey(notification): string {
        if (!notification)
            return ""

        const synchronousId = _synchronousId(notification)
        if (synchronousId.length > 0)
            return `sync:${_synchronousScope(notification)}:${synchronousId}`

        return `id:${notification.id}`
    }

    function _accept(notification): void {
        notification.tracked = true

        const id = _idKey(notification)
        const key = notificationKey(notification)
        const carriedRecord = _record(key)
        const superseded = _supersededSynchronousNotifications(notification)

        _registerIdentity(id, key)

        const now = Date.now()
        let record

        if (notification.lastGeneration && carriedRecord) {
            record = Object.assign({}, carriedRecord)
            record.transient = notification.transient
            if (notification.transient && record.deadline === undefined)
                record.deadline = _deadlineFor(notification, now)
            else if (!notification.transient)
                record.deadline = 0
        } else {
            record = {
                receivedAt: now,
                read: notification.transient || notification.lastGeneration,
                transient: notification.transient,
                deadline: notification.transient ? _deadlineFor(notification, now) : 0
            }
        }

        _setRecord(key, record)

        if (notification.transient)
            _removeCenterItem(notification)
        else
            _insertCenterItem(notification)

        _recalculateUnread()

        if (!notification.lastGeneration && _shouldShowToast(notification))
            toastRequested(notification)

        _expireNotifications(superseded)
    }

    function _queueUpdate(notification): void {
        if (!notification)
            return

        const pending = Object.assign({}, _pendingUpdateIds)
        pending[_idKey(notification)] = true
        _pendingUpdateIds = pending
        updateCoalescer.restart()
    }

    function _flushUpdates(): void {
        const pending = _pendingUpdateIds
        _pendingUpdateIds = ({})

        for (const notification of server.trackedNotifications.values.slice()) {
            if (notification && pending[_idKey(notification)])
                _handleUpdate(notification)
        }
    }

    function _handleUpdate(notification): void {
        if (!_isActive(notification))
            return

        const id = _idKey(notification)
        const oldKey = _keyById[id] ?? notificationKey(notification)
        const newKey = notificationKey(notification)
        const superseded = _supersededSynchronousNotifications(notification)
        let record = _record(oldKey) ?? {
            receivedAt: Date.now(),
            read: notification.transient,
            transient: notification.transient,
            deadline: 0
        }

        if (oldKey !== newKey) {
            _deleteRecordIfOwned(oldKey, id)
            _unregisterIdentity(id, oldKey)
            _registerIdentity(id, newKey)
        }

        record = Object.assign({}, record)

        if (notification.transient) {
            record.read = true
            record.deadline = _deadlineFor(notification, Date.now())
            _removeCenterItem(notification)
        } else {
            if (record.transient)
                record.read = false
            record.deadline = 0
            _insertCenterItem(notification)
        }

        record.transient = notification.transient
        _setRecord(newKey, record)
        _recalculateUnread()

        if (_shouldShowToast(notification))
            toastRequested(notification)

        _expireNotifications(superseded)
    }

    function _forgetNotification(notification): void {
        if (!notification)
            return

        const id = _idKey(notification)
        const key = _keyById[id] ?? notificationKey(notification)

        _removeCenterItem(notification)
        _deleteRecordIfOwned(key, id)
        _unregisterIdentity(id, key)

        const pending = Object.assign({}, _pendingUpdateIds)
        delete pending[id]
        _pendingUpdateIds = pending

        _recalculateUnread()
    }

    function _insertCenterItem(notification): void {
        const active = server.trackedNotifications.values
        const next = []

        for (const item of items) {
            if (item && item !== notification && active.indexOf(item) !== -1
                    && !item.transient)
                next.push(item)
        }

        next.push(notification)
        next.sort((left, right) => receivedAt(right) - receivedAt(left))
        items = next
    }

    function _removeCenterItem(notification): void {
        const next = items.filter(item => item && item !== notification)
        if (next.length !== items.length)
            items = next
    }

    function _recalculateUnread(): void {
        let total = 0
        for (const notification of items) {
            if (isUnread(notification))
                total++
        }
        _unreadCount = total
    }

    function _record(key): var {
        if (key.length === 0)
            return null
        return (persistentState.records ?? {})[key] ?? null
    }

    function _setRecord(key, record): void {
        if (key.length === 0)
            return

        const records = Object.assign({}, persistentState.records ?? {})
        records[key] = record
        persistentState.records = records
    }

    function _deleteRecordIfOwned(key, id): void {
        if (_ownerIdByKey[key] !== id)
            return

        const records = Object.assign({}, persistentState.records ?? {})
        delete records[key]
        persistentState.records = records
    }

    function _registerIdentity(id, key): void {
        const keys = Object.assign({}, _keyById)
        keys[id] = key
        _keyById = keys

        const owners = Object.assign({}, _ownerIdByKey)
        owners[key] = id
        _ownerIdByKey = owners
    }

    function _unregisterIdentity(id, key): void {
        const keys = Object.assign({}, _keyById)
        if (keys[id] === key)
            delete keys[id]
        _keyById = keys

        const owners = Object.assign({}, _ownerIdByKey)
        if (owners[key] === id)
            delete owners[key]
        _ownerIdByKey = owners
    }

    function _storedKey(notification): string {
        if (!notification)
            return ""
        return _keyById[_idKey(notification)] ?? notificationKey(notification)
    }

    function _idKey(notification): string {
        return String(notification.id)
    }

    function _synchronousId(notification): string {
        const value = notification?.hints?.["x-canonical-private-synchronous"]
        if (value === undefined || value === null || value === false)
            return ""
        return String(value)
    }

    function _synchronousScope(notification): string {
        const desktopEntry = String(notification?.desktopEntry ?? "")
            .trim()
            .toLowerCase()
        if (desktopEntry.length > 0)
            return desktopEntry

        const appName = String(notification?.appName ?? "").trim().toLowerCase()
        if (appName.length > 0)
            return appName

        const appIcon = String(notification?.appIcon ?? "").trim().toLowerCase()
        return appIcon.length > 0 ? appIcon : "unknown"
    }

    function _supersededSynchronousNotifications(notification): var {
        const synchronousId = _synchronousId(notification)
        if (synchronousId.length === 0)
            return []

        const scope = _synchronousScope(notification)
        const active = server.trackedNotifications.values.slice()
        const superseded = []
        for (const candidate of active) {
            if (candidate && candidate !== notification
                    && _synchronousId(candidate) === synchronousId
                    && _synchronousScope(candidate) === scope)
                superseded.push(candidate)
        }
        return superseded
    }

    function _expireNotifications(notifications): void {
        for (const notification of notifications) {
            if (_isActive(notification))
                notification.expire()
        }
    }

    function _shouldShowToast(notification): bool {
        if (!dnd)
            return true
        if (notification.urgency === NotificationUrgency.Critical)
            return true

        const hints = notification.hints ?? {}
        return _truthyHint(hints["swaync-bypass-dnd"])
            || _truthyHint(hints["x-swaync-bypass-dnd"])
            || _truthyHint(hints["swaync_bypass_dnd"])
            || _truthyHint(hints["SWAYNC_BYPASS_DND"])
    }

    function _truthyHint(value): bool {
        if (value === true || value === 1)
            return true
        if (value === undefined || value === null)
            return false

        const normalized = String(value).trim().toLowerCase()
        return normalized === "1" || normalized === "true"
            || normalized === "yes" || normalized === "on"
    }

    function _deadlineFor(notification, startedAt): real {
        const timeout = _transientTimeoutMs(notification)
        return timeout > 0 ? startedAt + timeout : 0
    }

    function _transientTimeoutMs(notification): int {
        const requested = Number(notification.expireTimeout)
        if (requested === 0)
            return 0
        if (requested > 0)
            return Math.max(1, Math.round(requested))
        if (notification.urgency === NotificationUrgency.Critical)
            return 0

        return notification.urgency === NotificationUrgency.Low
            ? defaultLowTimeoutMs
            : defaultNormalTimeoutMs
    }

    function _expireDueTransients(): void {
        const now = Date.now()
        const due = []

        for (const notification of server.trackedNotifications.values.slice()) {
            if (!notification || !notification.transient)
                continue

            const record = _record(_storedKey(notification))
            const deadline = Number(record?.deadline ?? 0)
            if (deadline > 0 && deadline <= now)
                due.push(notification)
        }

        for (const notification of due) {
            if (_isActive(notification))
                notification.expire()
        }
    }

    function _isActive(notification): bool {
        return Boolean(notification)
            && server.trackedNotifications.values.indexOf(notification) !== -1
    }

    property var persistentState: PersistentProperties {
        reloadableId: "notification-service-state"

        property bool persistedDnd: false
        property var records: ({})
    }

    property NotificationServer server: NotificationServer {
        keepOnReload: true

        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: true

        onNotification: notification => root._accept(notification)
    }

    property Connections trackedModelConnections: Connections {
        target: root.server.trackedNotifications

        function onObjectRemovedPre(notification, index): void {
            root._forgetNotification(notification)
        }
    }

    property Instantiator updateWatchers: Instantiator {
        model: root.server.trackedNotifications

        delegate: Connections {
            required property var modelData

            target: modelData

            function onExpireTimeoutChanged(): void { root._queueUpdate(modelData) }
            function onAppNameChanged(): void { root._queueUpdate(modelData) }
            function onAppIconChanged(): void { root._queueUpdate(modelData) }
            function onSummaryChanged(): void { root._queueUpdate(modelData) }
            function onBodyChanged(): void { root._queueUpdate(modelData) }
            function onUrgencyChanged(): void { root._queueUpdate(modelData) }
            function onActionsChanged(): void { root._queueUpdate(modelData) }
            function onHasActionIconsChanged(): void { root._queueUpdate(modelData) }
            function onResidentChanged(): void { root._queueUpdate(modelData) }
            function onTransientChanged(): void { root._queueUpdate(modelData) }
            function onDesktopEntryChanged(): void { root._queueUpdate(modelData) }
            function onImageChanged(): void { root._queueUpdate(modelData) }
            function onHasInlineReplyChanged(): void { root._queueUpdate(modelData) }
            function onInlineReplyPlaceholderChanged(): void { root._queueUpdate(modelData) }
            function onHintsChanged(): void { root._queueUpdate(modelData) }
        }
    }

    property Timer updateCoalescer: Timer {
        interval: 0
        onTriggered: root._flushUpdates()
    }

    property Timer transientExpiryTimer: Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: root._expireDueTransients()
    }
}
