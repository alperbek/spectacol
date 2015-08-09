/* qmlui.cpp: convenient functions to post runnables on fuse thread.

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

#include "qmlui.h"

#include <fuse.h>
#include <ui/uidisplay.h>
#include <ui/widget/widget.h>

#include <mutex>
#include <deque>

static std::mutex s_eventsMutex;
static std::deque<SpectrumEventFunction> s_events;

extern "C" int ui_init( int *, char ***)
{
    ui_mouse_present = 1;

    return ui_widget_init();
}

extern "C" int ui_end(void)
{
    return ui_widget_end();
}

extern "C" int ui_mouse_grab( int /*startup*/ )
{
    return 0;
}

extern "C" int ui_mouse_release( int /*suspend*/ )
{
    return 0;
}

SpectrumEventFunction peekEvent()
{
    SpectrumEventFunction event;
    s_eventsMutex.lock();
    if (!s_events.empty()) {
        event = std::move(s_events.back());
        s_events.pop_back();
    }
    s_eventsMutex.unlock();
    return std::move(event);
}

extern "C" int ui_event( void )
{
    for(;;) {
        SpectrumEventFunction event(peekEvent());
        if (event)
            event();
        else
            break;
    }
    return 0;
}

void pokeEvent(const SpectrumEventFunction &event)
{
    s_eventsMutex.lock();
    s_events.push_back(event);
    s_eventsMutex.unlock();
}