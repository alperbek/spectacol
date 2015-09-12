/*
    Copyright (c) 2015, BogDan Vatra <bogdan@kde.org>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "breakpointsmodel.h"
#include "qmlui.h"

BreakpointsModel::BreakpointsModel(QObject *parent)
    : FuseListModel(parent)
{
    qRegisterMetaType<BreakpointType>("BreakpointType");
}

void BreakpointsModel::breakpointsUpdated()
{
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_breakPointsTmp.clear();
        m_addresses.clear();
        for (GSList *ptr = debugger_breakpoints; ptr; ptr = ptr->next ) {
            debugger_breakpoint *bp = reinterpret_cast<debugger_breakpoint *>(ptr->data);
            m_breakPointsTmp.emplace_back(DebuggerBreakpoint(bp));
            switch (bp->type) {
            case DEBUGGER_BREAKPOINT_TYPE_EXECUTE:
            case DEBUGGER_BREAKPOINT_TYPE_READ:
            case DEBUGGER_BREAKPOINT_TYPE_WRITE:
                m_addresses[bp->value.address].insert(bp->type);
                break;
            default:
                break;
            }
        }
    }

    callFunction([this](){
        beginResetModel();
        std::lock_guard<std::mutex> lock(m_mutex);
        m_breakPoints = std::move(m_breakPointsTmp);
        m_breakPointsTmp.clear();
        endResetModel();
    });
}

int BreakpointsModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_breakPoints.size();
}

QVariant BreakpointsModel::data(const QModelIndex &index, int role) const
{
    if (size_t(index.row()) >= m_breakPoints.size())
        return QVariant();

    const auto &value = m_breakPoints[index.row()];
    switch (role) {
    case Qt::DisplayRole:
    case Id:
        return value.id;
    case Type:
        return value.type;
    case Value:
        return breakPointValue(value);
    case Ignore:
        return QString::number(value.ignore);
    case Life:
        return value.life;
    case Condition:
        return value.condition;
    case Commands:
        return value.commands;
    }
    return QVariant();
}

QHash<int, QByteArray> BreakpointsModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[Id] = "Id";
    roles[Type] = "Type";
    roles[Value] = "Value";
    roles[Ignore] = "Ignore";
    roles[Life] = "Life";
    roles[Condition] = "Condition";
    roles[Commands] = "Commands";
    return roles;
}

QVariant BreakpointsModel::breakPointValue(const BreakpointsModel::DebuggerBreakpoint &bp) const
{
    switch (bp.type) {
    case BreakOnExecute:
    case BreakOnRead:
    case BreakOnWrite:
        if (bp.value.address.source== memory_source_any)
            return formatNumber(bp.value.address.offset);
        return QLatin1String(memory_source_description(bp.value.address.source)) + QLatin1Char(':') +
                formatNumber(bp.value.address.page) + QLatin1Char(':') +
                formatNumber(bp.value.address.offset) + QLatin1Char(':');

    case BreakOnPortRead:
    case BreakOnPortWrite:
        return  formatNumber(bp.value.port.mask) + QLatin1Char(':') +
                formatNumber(bp.value.port.port) + QLatin1Char(':');

    case BreakOnTime:
        return QString::number(bp.value.time.tstates);

    case BreakOnEvent:
        return bp.value.event->type + ":" + bp.value.event->detail;
    }
    return QVariant();
}


BreakpointsModel::DebuggerBreakpoint::DebuggerBreakpoint(debugger_breakpoint *bp)
{
    id = bp->id;
    type = BreakpointType(bp->type);
    switch (type) {
    case BreakOnExecute:
    case BreakOnRead:
    case BreakOnWrite:
        value.address = bp->value.address;
        break;

    case BreakOnPortRead:
    case BreakOnPortWrite:
        value.port = bp->value.port;
        break;

    case BreakOnTime:
        value.time = bp->value.time;
        break;

    case BreakOnEvent:
        value.event = new DebuggerEvent(bp->value.event);
    }
    ignore = bp->ignore;
    life = BreakpointLife(bp->life);
    if (bp->condition) {
        condition.reserve(100);
        debugger_expression_deparse(condition.data(), condition.size(), bp->condition);
    }

    if (bp->commands)
        commands = bp->commands;
}

BreakpointsModel::DebuggerBreakpoint::~DebuggerBreakpoint()
{
    if (type == BreakOnEvent)
        delete value.event;
}
